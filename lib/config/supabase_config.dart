import 'package:flutter_dotenv/flutter_dotenv.dart';

// Supabase Configuration - Now reads from .env file
class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Storage bucket for product images
  static String get productImagesBucket => dotenv.env['PRODUCT_IMAGES_BUCKET'] ?? 'product-images';
  
  // Privacy Policy URL for store compliance
  static String get privacyPolicyUrl => dotenv.env['PRIVACY_POLICY_URL'] ?? 'https://example.com/privacy';
}
