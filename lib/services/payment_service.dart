import 'package:supabase_flutter/supabase_flutter.dart';

/// Payment Service for Stripe integration via Supabase Edge Functions
/// 
/// KULLANIM:
/// 1. Önce Supabase Edge Function deploy et (implementation_plan.md'ye bak)
/// 2. Stripe secret key'i Supabase Secrets'a ekle
/// 3. flutter_stripe paketini pubspec.yaml'a ekle
/// 
/// NOT: Bu dosya şu an DEAKTIF. Ödeme entegrasyonu hazır olduğunda aktifleştirilecek.
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final _client = Supabase.instance.client;

  /// Create a Stripe PaymentIntent via Edge Function
  /// 
  /// [amountTRY] - Ödeme tutarı (TL cinsinden, örn: 150.50)
  /// Returns: clientSecret for Stripe SDK
  Future<String?> createPaymentIntent(double amountTRY) async {
    try {
      // Convert TL to kuruş (Stripe expects smallest currency unit)
      final amountKurus = (amountTRY * 100).round();
      
      if (amountKurus < 100) {
        throw Exception('Minimum ödeme tutarı 1 TL');
      }

      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': amountKurus,
          'currency': 'try',
        },
      );

      if (response.status != 200) {
        throw Exception('Ödeme başlatılamadı: ${response.data}');
      }

      return response.data['clientSecret'] as String?;
    } catch (e) {
      print('Payment error: $e');
      rethrow;
    }
  }

  /// Confirm payment was successful (webhook verification)
  /// This should be called after Stripe SDK confirms payment
  Future<bool> verifyPayment(String paymentIntentId) async {
    try {
      final response = await _client.functions.invoke(
        'verify-payment',
        body: {'paymentIntentId': paymentIntentId},
      );

      return response.status == 200 && response.data['verified'] == true;
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }
}

/* 
================================================================================
KULLANIM ÖRNEĞİ (Subscription ekranında):
================================================================================

import 'package:flutter_stripe/flutter_stripe.dart';

// 1. PaymentIntent oluştur
final clientSecret = await PaymentService().createPaymentIntent(99.90);

if (clientSecret != null) {
  // 2. Stripe Payment Sheet'i göster
  await Stripe.instance.initPaymentSheet(
    paymentSheetParameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: clientSecret,
      merchantDisplayName: 'Kolay İşlet',
    ),
  );
  
  // 3. Ödeme formunu aç
  await Stripe.instance.presentPaymentSheet();
  
  // 4. Başarılı ödeme callback'i
  print('Ödeme başarılı!');
}

================================================================================
EDGE FUNCTION DEPLOY ADIMLARI:
================================================================================

1. Supabase CLI kur:
   npm install -g supabase

2. Proje root'unda:
   supabase init
   supabase functions new create-payment-intent

3. Edge Function kodunu yapıştır (implementation_plan.md'den)

4. Deploy et:
   supabase functions deploy create-payment-intent

5. Secret ekle:
   supabase secrets set STRIPE_SECRET_KEY=sk_test_...

================================================================================
*/
