import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/property_provider.dart';
import 'providers/payment_method_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/koditrack_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/properties_screen.dart';
import 'screens/tenants_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding/onboarding_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  final initialTheme = await ThemeProvider.loadSavedMode();
  runApp(KoditrackApp(initialThemeMode: initialTheme));
}

class KoditrackApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const KoditrackApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialThemeMode)),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => PaymentMethodProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Koditrack',
            debugShowCheckedModeBanner: false,
            themeMode: theme.themeMode,
            theme: KoditrackTheme.light(),
            darkTheme: KoditrackTheme.dark(),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _gateLoading = true;
  bool _needsOnboarding = false;
  DateTime? _pausedAt;
  static const _sessionTimeout = Duration(minutes: 5);

  final _homeKey = GlobalKey<HomeScreenState>();

  late final _pages = <Widget>[
    HomeScreen(key: _homeKey),
    const PropertiesScreen(),
    const TenantsScreen(),
    const LedgerScreen(),
    const ProfileScreen(),
  ];

  Future<void> _runGate() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _gateLoading = false);
      return;
    }

    final settings = context.read<SettingsProvider>();
    final pm = context.read<PaymentMethodProvider>();
    final theme = context.read<ThemeProvider>();
    final propertyProvider = context.read<PropertyProvider>();

    await settings.ensureProfile();
    await settings.fetchProfile();
    theme.applyFromProfile(settings);
    await pm.fetchMethods();

    // Preload dashboard data
    await propertyProvider.fetchProperties();

    if (mounted) {
      setState(() {
        _gateLoading = false;
        _needsOnboarding = !settings.onboardingCompleted;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() => _needsOnboarding = false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runGate();
    SupabaseService.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null &&
          DateTime.now().difference(_pausedAt!) > _sessionTimeout) {
        SupabaseService.client.auth.signOut();
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;
    final kt = context.kt;

    if (user == null) {
      return const LoginScreen();
    }

    if (_gateLoading) {
      return Scaffold(
        backgroundColor: kt.pageBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsOnboarding) {
      return OnboardingShell(onComplete: _onOnboardingComplete);
    }

    return Scaffold(
      backgroundColor: kt.pageBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kt.navBarBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.watch<ThemeProvider>().isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
                if (index == 0) {
                  _homeKey.currentState?.onTabActive();
                } else {
                  _homeKey.currentState?.onTabInactive();
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: kt.brandGreen.withValues(alpha: 0.12),
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(icon: const Icon(Icons.dashboard_outlined, size: 22), selectedIcon: Icon(Icons.dashboard, size: 22, color: kt.brandGreen), label: 'Dashboard'),
                NavigationDestination(icon: const Icon(Icons.apartment_outlined, size: 22), selectedIcon: Icon(Icons.apartment, size: 22, color: kt.brandGreen), label: 'Properties'),
                NavigationDestination(icon: const Icon(Icons.people_outline, size: 22), selectedIcon: Icon(Icons.people, size: 22, color: kt.brandGreen), label: 'Tenants'),
                NavigationDestination(icon: const Icon(Icons.receipt_long_outlined, size: 22), selectedIcon: Icon(Icons.receipt_long, size: 22, color: kt.brandGreen), label: 'Ledger'),
                NavigationDestination(icon: const Icon(Icons.person_outline, size: 22), selectedIcon: Icon(Icons.person, size: 22, color: kt.brandGreen), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}