import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
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
  String? _currentUserId;
  int _rebuildKey = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
    
    // Listen to auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn || 
          event.event == AuthChangeEvent.signedOut ||
          event.event == AuthChangeEvent.tokenRefreshed) {
        _checkAuthAndLoadData();
      }
    });
  }

  Future<void> _checkAuthAndLoadData() async {
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
  }

  @override
  Widget build(BuildContext context) {
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
      return MainLayout(key: ValueKey('main_$_rebuildKey'));
    } else {
      return const LoginScreen();
    }
  }
}
