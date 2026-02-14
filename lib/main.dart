import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'services/notification_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/review_service.dart';

// Global navigator key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global key for MainLayout to access its state
final GlobalKey<MainLayoutState> mainLayoutKey = GlobalKey<MainLayoutState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('DEBUG: Failed to load .env file: $e');
    // Continue without .env - will use hardcoded fallbacks
  }
  
  // Initialize Supabase with safety check
  try {
    final supabaseUrl = SupabaseConfig.supabaseUrl;
    final supabaseKey = SupabaseConfig.supabaseAnonKey;
    
    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
    } else {
      print('DEBUG: Supabase credentials missing - running in offline mode');
    }
  } catch (e) {
    print('DEBUG: Failed to initialize Supabase: $e');
  }
  
  // Initialize settings (with error handling)
  try {
    await SettingsService().init();
  } catch (e) {
    print('DEBUG: Failed to initialize SettingsService: $e');
  }
  
  // Initialize notifications (with error handling)
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('DEBUG: Failed to initialize NotificationService: $e');
  }
  
  // Initialize review service (with error handling)
  try {
    await ReviewService().init();
  } catch (e) {
    print('DEBUG: Failed to initialize ReviewService: $e');
  }
  
  // Initialize RevenueCat subscription service
  try {
    await RevenueCatService().init();
  } catch (e) {
    print('DEBUG: Failed to initialize RevenueCat: $e');
  }
  
  // Set up notification tap handler
  NotificationService.onNotificationTap = (bookingId) {
    print('DEBUG: Notification tapped for booking: $bookingId');
    // Navigate to Dashboard (index 1) when notification is tapped
    if (mainLayoutKey.currentState != null) {
      mainLayoutKey.currentState!.navigateToDashboard();
    }
  };
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Mağaza İsmi',
      theme: AppTheme.lightTheme,
      // Turkish localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      home: const AuthWrapper(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  MainLayoutState createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1; // Ana Sayfa default
  int _refreshKey = 0; // Key to force rebuild
  DateTime? _lastBackPress;

  // Method to navigate to Dashboard from notification
  void navigateToDashboard() {
    setState(() {
      _currentIndex = 1; // Dashboard index
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        final now = DateTime.now();
        if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Çıkmak için tekrar basın'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF374151),
            ),
          );
        } else {
          // Exit app on double back press
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}
