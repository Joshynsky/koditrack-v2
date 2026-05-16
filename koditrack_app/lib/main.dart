import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/property_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const KoditrackApp());
}

class KoditrackApp extends StatelessWidget {
  const KoditrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PropertyProvider())],
      child: MaterialApp(
        title: 'Koditrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32), // Earthy Green
          ),
          useMaterial3: true,
        ),
        home: SupabaseService.client.auth.currentUser != null
            ? const HomeScreen()
            : const LoginScreen(),
      ),
    );
  }
}
