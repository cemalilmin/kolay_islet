import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> 
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Hoş Geldiniz',
      subtitle: 'KOLAY İŞLET',
      description: 'Butik kıyafet kiralama işletmenizi\nprofesyonelce yönetin.',
      icon: Icons.diamond_rounded,
      buttonText: 'Hemen Başla',
      gradientColors: [
        const Color(0xFF1A0000),
        const Color(0xFF4A0E0E),
        const Color(0xFF8B1A1A),
      ],
      iconGlow: const Color(0xFFDC2626),
      accentColor: const Color(0xFFD4A574),
    ),
    OnboardingPage(
      title: 'Akıllı Takip',
      subtitle: 'KİRALAMA & SATIŞ',
      description: 'Rezervasyonları takvimle takip edin.\nÇakışmaları otomatik önleyin.',
      icon: Icons.calendar_month_rounded,
      buttonText: 'Devam Et',
      gradientColors: [
        const Color(0xFF0A0015),
        const Color(0xFF1A0A3E),
        const Color(0xFF4C1D95),
      ],
      iconGlow: const Color(0xFF7C3AED),
      accentColor: const Color(0xFFC4B5FD),
    ),
    OnboardingPage(
      title: 'Detaylı Analiz',
      subtitle: 'GELİR & GİDER',
      description: 'Finansal durumunuzu grafiklerle görün.\nKârlılığınızı anlık takip edin.',
      icon: Icons.trending_up_rounded,
      buttonText: 'Başlayın',
      gradientColors: [
        const Color(0xFF00150A),
        const Color(0xFF0A3E1A),
        const Color(0xFF065F46),
      ],
      iconGlow: const Color(0xFF10B981),
      accentColor: const Color(0xFF6EE7B7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeController.reset();
    _fadeController.forward();
    _scaleController.reset();
    _scaleController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: page.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${_pages.length}',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'Atla',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => _buildPage(_pages[index]),
                ),
              ),
              
              // Bottom section
              Padding(
                padding: EdgeInsets.fromLTRB(32, 16, 32, bottomPadding + 24),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive 
                                ? page.accentColor 
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isActive ? [
                              BoxShadow(
                                color: page.accentColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ] : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    
                    // CTA Button
                    GestureDetector(
                      onTap: _nextPage,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              page.iconGlow,
                              page.iconGlow.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: page.iconGlow.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              page.buttonText,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return FadeTransition(
      opacity: _fadeController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glassmorphism icon container
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _scaleController,
                curve: Curves.elasticOut,
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.iconGlow.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              page.accentColor,
                              page.iconGlow,
                            ],
                          ).createShader(bounds);
                        },
                        child: Icon(
                          page.icon,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Subtitle badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: page.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: page.accentColor.withOpacity(0.25),
                ),
              ),
              child: Text(
                page.subtitle,
                style: GoogleFonts.inter(
                  color: page.accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Description
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String buttonText;
  final List<Color> gradientColors;
  final Color iconGlow;
  final Color accentColor;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.buttonText,
    required this.gradientColors,
    required this.iconGlow,
    required this.accentColor,
  });
}
