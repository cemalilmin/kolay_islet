import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Play Store & App Store için In-App Review servisi
/// 
/// Kullanıcıdan belirli koşullar sağlandığında app review istemek için kullanılır.
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;
  
  // SharedPreferences keys
  static const String _hasRatedKey = 'has_rated_app';
  static const String _actionCountKey = 'review_action_count';
  static const String _firstOpenDateKey = 'first_open_date';
  static const String _lastPromptDateKey = 'last_review_prompt_date';
  
  // Review prompt koşulları
  static const int _minActionsBeforePrompt = 5; // Minimum işlem sayısı
  static const int _minDaysSinceInstall = 3; // Kurulumdan sonra minimum gün
  static const int _daysBetweenPrompts = 14; // Promptlar arası minimum gün

  SharedPreferences? _prefs;

  /// Servisi başlat
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // İlk açılış tarihini kaydet
    if (_prefs!.getString(_firstOpenDateKey) == null) {
      _prefs!.setString(_firstOpenDateKey, DateTime.now().toIso8601String());
    }
  }

  /// Kullanıcı bir işlem yaptığında çağır (ürün ekleme, kiralama vb.)
  Future<void> recordAction() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    final currentCount = _prefs!.getInt(_actionCountKey) ?? 0;
    await _prefs!.setInt(_actionCountKey, currentCount + 1);
  }

  /// Review dialog'u göstermeye uygun mu kontrol et
  Future<bool> _shouldShowReviewPrompt() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Zaten değerlendirme yaptıysa gösterme
    if (_prefs!.getBool(_hasRatedKey) ?? false) {
      return false;
    }
    
    // Minimum işlem sayısına ulaşıldı mı?
    final actionCount = _prefs!.getInt(_actionCountKey) ?? 0;
    if (actionCount < _minActionsBeforePrompt) {
      return false;
    }
    
    // Kurulumdan bu yana yeterli gün geçti mi?
    final firstOpenStr = _prefs!.getString(_firstOpenDateKey);
    if (firstOpenStr != null) {
      final firstOpen = DateTime.parse(firstOpenStr);
      final daysSinceInstall = DateTime.now().difference(firstOpen).inDays;
      if (daysSinceInstall < _minDaysSinceInstall) {
        return false;
      }
    }
    
    // Son prompttan bu yana yeterli gün geçti mi?
    final lastPromptStr = _prefs!.getString(_lastPromptDateKey);
    if (lastPromptStr != null) {
      final lastPrompt = DateTime.parse(lastPromptStr);
      final daysSinceLastPrompt = DateTime.now().difference(lastPrompt).inDays;
      if (daysSinceLastPrompt < _daysBetweenPrompts) {
        return false;
      }
    }
    
    return true;
  }

  /// In-app review isteği gönder (Play Store / App Store native dialog)
  /// 
  /// Bu method uygun koşullar sağlandığında otomatik olarak native review
  /// dialog'unu gösterir. Dialog'un gösterilip gösterilmeyeceği Google/Apple
  /// tarafından kontrol edilir (spam önleme için).
  Future<void> requestReview() async {
    try {
      // Koşulları kontrol et
      if (!await _shouldShowReviewPrompt()) {
        return;
      }
      
      // Review available mı kontrol et
      final isAvailable = await _inAppReview.isAvailable();
      
      if (isAvailable) {
        // Native review dialog'u göster
        await _inAppReview.requestReview();
        
        // Son prompt tarihini güncelle
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setString(_lastPromptDateKey, DateTime.now().toIso8601String());
        
        print('DEBUG: In-app review dialog requested');
      } else {
        print('DEBUG: In-app review not available on this device');
      }
    } catch (e) {
      print('DEBUG: Error requesting review: $e');
    }
  }

  /// Kullanıcı değerlendirme yaptığını işaretle
  /// (Eğer kendi custom dialog'unuz varsa kullanın)
  Future<void> markAsRated() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_hasRatedKey, true);
  }

  /// Store sayfasını aç (fallback olarak kullanılabilir)
  Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: '6740057555', // App Store ID
      );
    } catch (e) {
      print('DEBUG: Error opening store listing: $e');
    }
  }

  /// Test için: Action count'u sıfırla
  Future<void> resetForTesting() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_hasRatedKey);
    await _prefs!.remove(_actionCountKey);
    await _prefs!.remove(_lastPromptDateKey);
    print('DEBUG: Review service reset for testing');
  }
}
