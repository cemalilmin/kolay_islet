import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  
  // Cached profile data for instant access
  Map<String, dynamic>? _cachedProfile;
  
  // Get cached store name (instant, no async)
  String get cachedStoreName => _cachedProfile?['store_name'] ?? '';
  
  // Get cached store slogan (instant, no async)
  String get cachedStoreSlogan => _cachedProfile?['store_slogan'] ?? 'RENTAL BOUTIQUE';

  // Get current user
  User? get currentUser => _client.auth.currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? storeName,
    String? phone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'store_name': storeName,
          'phone': phone,
        },
      );
      
      // Update profile with additional info
      if (response.user != null) {
        await _client.from('profiles').update({
          'full_name': fullName,
          'store_name': storeName,
          'phone': phone,
        }).eq('id', response.user!.id);
      }
      
      return response;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear all cached user data
      DataService().clearData();
      _cachedProfile = null;
      
      await _client.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      if (currentUser == null) return null;
      
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      
      // Cache the profile for instant access
      _cachedProfile = response;
      
      return response;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? storeName,
    String? storeSlogan,
    String? phone,
  }) async {
    try {
      if (currentUser == null) return;
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (fullName != null) updates['full_name'] = fullName;
      if (storeName != null) updates['store_name'] = storeName;
      if (storeSlogan != null) updates['store_slogan'] = storeSlogan;
      if (phone != null) updates['phone'] = phone;
      
      await _client
          .from('profiles')
          .update(updates)
          .eq('id', currentUser!.id);
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }
}
