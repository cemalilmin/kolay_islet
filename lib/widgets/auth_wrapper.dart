import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/data_service.dart';
import '../main.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _showOnboarding = false;
  String? _currentUserId;
  int _rebuildKey = 0;
  bool _supabaseAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    if (!onboardingCompleted) {
      if (mounted) {
        setState(() {
          _showOnboarding = true;
          _isLoading = false;
        });
      }
    } else {
      _initializeAuth();
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
      _isLoading = true;
    });
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Check if Supabase is available
    try {
      final client = Supabase.instance.client;
      _supabaseAvailable = true;
      
      // Set up auth listener
      client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedIn || 
            event.event == AuthChangeEvent.signedOut ||
            event.event == AuthChangeEvent.tokenRefreshed) {
          _checkAuthAndLoadData();
        }
      });
      
      // Check initial auth state
      await _checkAuthAndLoadData();
    } catch (e) {
      print('DEBUG: Supabase not available: $e');
      _supabaseAvailable = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
      }
    }
  }

  Future<void> _checkAuthAndLoadData() async {
    if (!_supabaseAvailable) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
      }
      return;
    }
    
    try {
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session != null) {
        final userId = session.user.id;
        
        // Only reload if user changed
        if (_currentUserId != userId) {
          _currentUserId = userId;
          
          if (mounted) setState(() => _isLoading = true);
          
          try {
            await DataService().loadUserData();
            _rebuildKey++; // Force rebuild of MainLayout
          } catch (e) {
            print('Error loading user data: $e');
          }
          
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isLoggedIn = true;
            });
          }
        } else if (_isLoading && mounted) {
          setState(() {
            _isLoading = false;
            _isLoggedIn = true;
          });
        }
      } else {
        // Logged out
        if (_currentUserId != null) {
          _currentUserId = null;
          DataService().clearData();
          _rebuildKey++;
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoggedIn = false;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Auth check error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show onboarding on first launch
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _onOnboardingComplete);
    }
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Veriler yükleniyor...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      return MainLayout(key: mainLayoutKey);
    } else {
      return const LoginScreen();
    }
  }
}
