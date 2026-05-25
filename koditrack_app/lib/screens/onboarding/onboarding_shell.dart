import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_method_provider.dart';
import '../../providers/settings_provider.dart';
import '../settings/add_payment_method_screen.dart';
import '../property_form_screen.dart';

class OnboardingShell extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingShell({super.key, required this.onComplete});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  static const _green = Color(0xFF2E6F40);
  final _pageController = PageController();
  int _step = 0;
  bool _addedMethod = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PaymentMethodProvider>().fetchMethods();
      if (mounted && context.read<PaymentMethodProvider>().hasMethods) {
        setState(() => _addedMethod = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      setState(() => _step++);
    }
  }

  Future<void> _finish({bool addProperty = false}) async {
    await context.read<SettingsProvider>().completeOnboarding();
    if (!mounted) return;

    if (addProperty) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PropertyFormScreen()),
      );
    }

    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? _green
                            : Colors.grey.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _WelcomeStep(onNext: _next),
                  _PaymentStep(
                    addedMethod: _addedMethod,
                    onMethodAdded: () => setState(() => _addedMethod = true),
                    onNext: () {
                      if (!_addedMethod) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Please add at least one payment method to continue'),
                          ),
                        );
                        return;
                      }
                      _next();
                    },
                    onAdd: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPaymentMethodScreen(
                            isOnboarding: true,
                            onSaved: () {
                              setState(() => _addedMethod = true);
                              context.read<PaymentMethodProvider>().fetchMethods();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _CompleteStep(
                    onFinish: () => _finish(addProperty: false),
                    onAddProperty: () => _finish(addProperty: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.apartment,
              size: 72, color: const Color(0xFF2E6F40).withValues(alpha: 0.85)),
          const SizedBox(height: 24),
          const Text(
            'Welcome to KodiTrack',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Set up how your tenants will pay rent via M-Pesa — Send Money, Paybill, or Till number.',
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade700),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E6F40),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PaymentStep extends StatelessWidget {
  final bool addedMethod;
  final VoidCallback onNext;
  final VoidCallback onAdd;
  final VoidCallback onMethodAdded;

  const _PaymentStep({
    required this.addedMethod,
    required this.onNext,
    required this.onAdd,
    required this.onMethodAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentMethodProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a payment method',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You will choose one of these when adding each property.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (provider.methods.isNotEmpty)
                Expanded(
                  child: ListView(
                    children: provider.methods
                        .map((m) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.check_circle,
                                    color: Color(0xFF2E6F40)),
                                title: Text(m.displayName),
                                subtitle: Text(m.subtitle),
                              ),
                            ))
                        .toList(),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      'No methods added yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add M-Pesa details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E6F40),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6F40),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompleteStep extends StatelessWidget {
  final VoidCallback onFinish;
  final VoidCallback onAddProperty;

  const _CompleteStep({
    required this.onFinish,
    required this.onAddProperty,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.check_circle_outline,
              size: 72, color: Color(0xFF2E6F40)),
          const SizedBox(height: 24),
          const Text(
            "You're all set!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first property, or go to the dashboard and add one later.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onAddProperty,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E6F40),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Add First Property'),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onFinish, child: const Text('Go to Dashboard')),
        ],
      ),
    );
  }
}
