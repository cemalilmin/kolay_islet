import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/accounting_screen.dart';
import 'widgets/custom_bottom_nav.dart';
import 'widgets/auth_wrapper.dart';
import 'config/supabase_config.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Initialize services
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Initialize settings
  await SettingsService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mağaza İsmi',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Ana Sayfa default
  int _refreshKey = 0; // Key to force rebuild

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AccountingScreen(key: ValueKey('accounting_$_refreshKey')),
          DashboardScreen(key: ValueKey('dashboard_$_refreshKey')),
          ProductsScreen(key: ValueKey('products_$_refreshKey')),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
          _refreshKey++; // Force rebuild to show fresh data
        }),
      ),
    );
  }
}
