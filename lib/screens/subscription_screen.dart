import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  bool _hasActiveSubscription = false;
  DateTime? _trialEndDate;
  bool _isYearlyPlan = true; // Default to yearly for best value
  
  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }
  
  Future<void> _checkSubscriptionStatus() async {
    // TODO: RevenueCat'ten abonelik durumu kontrol edilecek
    setState(() {
      _hasActiveSubscription = false;
      _trialEndDate = null;
    });
  }
  
  Future<void> _startFreeTrial() async {
    setState(() => _isLoading = true);
    
    // TODO: RevenueCat ile ücretsiz deneme başlatılacak
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('30 günlük ücretsiz deneme başladı!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
  
  Future<void> _subscribe() async {
    setState(() => _isLoading = true);
    
    // TODO: RevenueCat ile abonelik satın alınacak
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.diamond_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Premium\'a Geç',
                      style: AppTextStyles.headlineLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tüm özelliklere sınırsız erişim',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Features
              _buildFeatureCard(
                icon: Icons.inventory_2_outlined,
                title: 'Sınırsız Ürün',
                description: 'İstediğiniz kadar ürün ekleyin',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.calendar_month_outlined,
                title: 'Gelişmiş Takvim',
                description: 'Rezervasyonları kolayca yönetin',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.analytics_outlined,
                title: 'Detaylı Raporlar',
                description: 'Gelir ve gider analizleri',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.cloud_sync_outlined,
                title: 'Bulut Yedekleme',
                description: 'Verileriniz güvende',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                icon: Icons.support_agent_outlined,
                title: 'Öncelikli Destek',
                description: '7/24 müşteri hizmetleri',
              ),
              
              const SizedBox(height: 40),
              
              // Pricing Cards - Plan Selection
              _buildPlanSelector(),
              
              const SizedBox(height: 20),
              
              // Selected Plan Card
              _buildSelectedPlanCard(),
              
              const SizedBox(height: 24),
              
              // Terms
              Center(
                child: Column(
                  children: [
                    Text(
                      'Devam ederek aşağıdakileri kabul etmiş olursunuz:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // TODO: Kullanım koşulları
                          },
                          child: Text(
                            'Kullanım Koşulları',
                            style: TextStyle(
                              color: const Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          ' ve ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // TODO: Gizlilik politikası
                          },
                          child: Text(
                            'Gizlilik Politikası',
                            style: TextStyle(
                              color: const Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFDC2626), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector() {
    return Row(
      children: [
        // Monthly Plan
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isYearlyPlan = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !_isYearlyPlan ? const Color(0xFFFEE2E2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !_isYearlyPlan ? const Color(0xFFDC2626) : Colors.grey[300]!,
                  width: !_isYearlyPlan ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Aylık',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: !_isYearlyPlan ? const Color(0xFFDC2626) : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺999',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: !_isYearlyPlan ? const Color(0xFFDC2626) : Colors.grey[800],
                    ),
                  ),
                  Text(
                    '/ay',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Yearly Plan
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _isYearlyPlan = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isYearlyPlan ? const Color(0xFFFEE2E2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isYearlyPlan ? const Color(0xFFDC2626) : Colors.grey[300]!,
                  width: _isYearlyPlan ? 2 : 1,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      Text(
                        'Yıllık',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _isYearlyPlan ? const Color(0xFFDC2626) : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₺799',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: _isYearlyPlan ? const Color(0xFFDC2626) : Colors.grey[800],
                        ),
                      ),
                      Text(
                        '/ay',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  // Save badge
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '%20 TASARRUF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPlanCard() {
    final price = _isYearlyPlan ? '799' : '999';
    final period = _isYearlyPlan ? 'ay (yıllık ödeme: ₺9.588)' : 'ay';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  _isYearlyPlan ? 'EN İYİ DEĞer' : 'ESNEK PLAN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Price
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₺',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                '/$period',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'İlk 30 gün ücretsiz!',
            style: TextStyle(
              color: Colors.amber[300],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // CTA Button
          GestureDetector(
            onTap: _isLoading ? null : _startFreeTrial,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.white.withOpacity(0.5) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _isLoading
                    ? [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'İşleniyor...',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : [
                        const Icon(Icons.rocket_launch, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        const Text(
                          'Ücretsiz Deneyin',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'İstediğiniz zaman iptal edebilirsiniz',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
