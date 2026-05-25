import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/tenant.dart';
import '../providers/payment_method_provider.dart';
import '../providers/property_provider.dart';
import '../providers/settings_provider.dart';
import '../services/supabase_service.dart';
import '../services/whatsapp_service.dart';
import '../theme/koditrack_theme.dart';
import '../utils/user_display.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  double _expected = 0;
  double _received = 0;
  final List<_OverdueItem> _overdueItems = [];
  List<Payment> _recentPayments = [];
  bool _activityLoading = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchProfile();
      _loadData();
      _startAutoRefresh();
    });
  }

  void onTabActive() {
    _isVisible = true;
    _loadData();
    _startAutoRefresh();
  }

  void onTabInactive() {
    _isVisible = false;
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () async {
      if (mounted) {
        if (_isVisible) {
          await _loadData();
        }
        _startAutoRefresh();
      }
    });
  }

  Map<String, double>? _cachedSummary;
  DateTime? _summaryLastFetched;

  Future<void> _loadData() async {
    _isVisible = true;
    final provider = context.read<PropertyProvider>();
    await provider.fetchProperties();

    // ── Cache: skip heavy summary if fresh (<60s) ──
    Map<String, double> summary;
    if (_cachedSummary != null &&
        _summaryLastFetched != null &&
        DateTime.now().difference(_summaryLastFetched!).inSeconds < 60) {
      summary = _cachedSummary!;
    } else {
      summary = await provider.getMonthlySummary();
      _cachedSummary = summary;
      _summaryLastFetched = DateTime.now();
    }

    // Overdue items
    final now = DateTime.now();
    final overdue = <_OverdueItem>[];
    for (final property in provider.properties) {
      await provider.fetchTenants(property.id);
      for (final tenant in provider.selectedPropertyTenants) {
        if (tenant.openingBalance > 0) {
          final dueDate = DateTime(now.year, now.month, property.rentDueDay);
          final daysOverdue = now.day > property.rentDueDay
              ? now.difference(dueDate).inDays
              : 0;
          if (daysOverdue > 0) {
            overdue.add(_OverdueItem(
              tenant: tenant,
              propertyName: property.name,
              unitName: 'N/A',
              daysOverdue: daysOverdue,
              paymentMethodId: property.paymentMethodId,
            ));
          }
        }
      }
    }
    overdue.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

    final payments = await _fetchRecentPayments();

    if (mounted) {
      setState(() {
        _expected = summary['expected'] ?? 0;
        _received = summary['received'] ?? 0;
        _overdueItems
          ..clear()
          ..addAll(overdue);
        _recentPayments = payments;
      });
    }
  }

  Future<List<Payment>> _fetchRecentPayments() async {
    setState(() => _activityLoading = true);
    try {
      final data = await SupabaseService.client
          .from('payments')
          .select()
          .order('payment_date', ascending: false)
          .limit(4);
      return data.map((json) => Payment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching recent payments: $e');
      return [];
    } finally {
      if (mounted) setState(() => _activityLoading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.properties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        if (_expected > 0) _buildFinancialSection(context),
                        const SizedBox(height: 24),
                        _buildNeedsAttentionSection(context),
                        const SizedBox(height: 24),
                        _buildRecentActivitySection(context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context) {
    final kt = context.kt;
    final displayName = resolveUserFirstName(context);

    return SliverAppBar(
      expandedHeight: 88,
      floating: true,
      snap: true,
      backgroundColor: kt.pageBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
            ),
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section A: Financial Command Center ─────────────────────────────────

  Widget _buildFinancialSection(BuildContext context) {
    final kt = context.kt;
    final progress = _expected > 0
        ? (_received / _expected).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).round();
    final remaining = (_expected - _received).clamp(0.0, double.infinity);
    final now = DateTime.now();
    final monthLabel =
        '${_monthName(now.month)} ${now.year}';

    return Container(
      decoration: BoxDecoration(
        color: kt.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kt.borderSubtle),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kt.chipBackground,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: kt.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: context.cs.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Gauge row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular gauge
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          final animatedPct = (value * 100).round();
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 88,
                                height: 88,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 9,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: kt.chipBackground,
                                  color: kt.accentTeal,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$animatedPct%',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: kt.accentTeal,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    'collected',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),

              // Numbers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _received),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          'KES ${_fmt(value)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: kt.accentTealDark,
                            height: 1,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'received this month',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'of KES ${_fmt(_expected)} expected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: context.cs.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Split cards
          Row(
            children: [
              Expanded(
                child: _SplitCard(
                  label: 'Collected',
                  amount: _received,
                  bgColor: kt.accentTealLight,
                  labelColor: kt.accentTealDark,
                  amountColor: kt.accentTealDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SplitCard(
                  label: 'Outstanding',
                  amount: remaining,
                  bgColor: remaining > 0 ? kt.accentAmberLight : kt.accentTealLight,
                  labelColor: remaining > 0 ? kt.accentAmberDark : kt.accentTealDark,
                  amountColor: remaining > 0 ? kt.accentAmberDark : kt.accentTealDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section B: Needs Attention Carousel ─────────────────────────────────

  Widget _buildNeedsAttentionSection(BuildContext context) {
    final kt = context.kt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: kt.accentRed),
            const SizedBox(width: 6),
            Text(
              'Needs attention',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (_overdueItems.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kt.accentRedLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_overdueItems.length} overdue',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kt.accentRedDark,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_overdueItems.isEmpty)
          _buildAllClearCard(context)
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _overdueItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _buildOverdueCard(context, _overdueItems[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildAllClearCard(BuildContext context) {
    final kt = context.kt;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kt.accentTealLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kt.accentTeal.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: kt.accentTeal, size: 22),
            const SizedBox(width: 10),
            Text(
              'All rent flows are up to date!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kt.accentTealDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverdueCard(BuildContext context, _OverdueItem item) {
    final kt = context.kt;
    final isUrgent = item.daysOverdue >= 10;
    final accentColor = isUrgent ? kt.accentRed : kt.accentAmber;
    final accentLight = isUrgent ? kt.accentRedLight : kt.accentAmberLight;
    final accentDark = isUrgent ? kt.accentRedDark : kt.accentAmberDark;
    final initials = item.tenant.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kt.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUrgent
              ? kt.accentRed.withValues(alpha: 0.35)
              : kt.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tenant row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentLight,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentDark,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.tenant.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Unit ${item.unitName} · ${item.propertyName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount — the hero number
          Text(
            'KES ${_fmt(item.tenant.openingBalance)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accentColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '${item.daysOverdue} days overdue',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentDark,
              ),
            ),
          ),
          const Spacer(),

          // Full-width nudge button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: item.tenant.whatsappEnabled
                  ? () => _sendNudge(item)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kt.accentTeal,
                foregroundColor: kt.onPrimaryButton,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.send, size: 14),
              label: const Text('Send reminder · WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendNudge(_OverdueItem item) async {
    final pay = context.read<PaymentMethodProvider>().getById(item.paymentMethodId);
    final message = WhatsAppService.overdueMessage(
      name: item.tenant.name,
      unitNumber: item.unitName,
      daysOverdue: item.daysOverdue,
      balance: item.tenant.openingBalance,
      paymentInstructions: pay?.paymentInstructions,
    );
    await WhatsAppService.sendMessage(item.tenant.phone, message);
  }

  // ─── Section C: Recent Activity ──────────────────────────────────────────

  Widget _buildRecentActivitySection(BuildContext context) {
    final kt = context.kt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: kt.accentTeal,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: kt.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kt.borderSubtle),
          ),
          child: _activityLoading && _recentPayments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                      child: CircularProgressIndicator(
                    color: kt.accentTeal,
                    strokeWidth: 2,
                  )),
                )
              : _recentPayments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No payments recorded yet.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : Column(
                      children: [
                        ..._recentPayments
                            .map((p) => _buildActivityRow(context, p)),
                        _buildViewAllRow(context),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(BuildContext context, Payment payment) {
    final kt = context.kt;
    final isMpesa = (payment.paymentMethod ?? '')
        .toLowerCase()
        .contains('mpesa');
    final iconColor = isMpesa ? kt.accentTeal : kt.accentBlue;
    final iconBg = isMpesa ? kt.accentTealLight : kt.accentBlueLight;
    final icon =
        isMpesa ? Icons.phone_android_outlined : Icons.payments_outlined;
    final timeLabel = _relativeTime(payment.paymentDate);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.reference ?? 'Payment',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${payment.paymentMethod ?? 'Payment'} · $timeLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '+${_fmt(payment.amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kt.accentTealDark,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, indent: 14, endIndent: 14, color: kt.borderSubtle),
      ],
    );
  }

  Widget _buildViewAllRow(BuildContext context) {
    final onVariant = context.cs.onSurfaceVariant;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const TransactionHistoryScreen()),
        );
      },
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View all transactions',
              style: TextStyle(fontSize: 13, color: onVariant),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 14, color: onVariant),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _fmt(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}

// ─── Data class for overdue items ─────────────────────────────────────────────

class _OverdueItem {
  final Tenant tenant;
  final String propertyName;
  final String unitName;
  final int daysOverdue;
  final String? paymentMethodId;

  const _OverdueItem({
    required this.tenant,
    required this.propertyName,
    required this.unitName,
    required this.daysOverdue,
    this.paymentMethodId,
  });
}

// ─── Split card widget ────────────────────────────────────────────────────────

class _SplitCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color bgColor;
  final Color labelColor;
  final Color amountColor;

  const _SplitCard({
    required this.label,
    required this.amount,
    required this.bgColor,
    required this.labelColor,
    required this.amountColor,
  });

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _fmt(amount),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
          Text(
            'KES',
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
        ],
      ),
    );
  }
}