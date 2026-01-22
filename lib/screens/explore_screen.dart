import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/dress_model.dart';
import '../services/data_service.dart';
import '../widgets/dress_card.dart';
import '../widgets/shimmer_loading.dart';
import 'dress_detail_screen.dart';
import 'search_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final DataService _dataService = DataService();
  String _selectedCategory = 'Tümü';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _toggleFavorite(String dressId) {
    setState(() {
      _dataService.toggleFavorite(dressId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dresses = _dataService.getDressesByCategory(_selectedCategory);
    final featured = _dataService.getFeaturedDresses();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar with Search
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),

            // Categories
            SliverToBoxAdapter(
              child: _buildCategories(),
            ),

            // Featured Section
            if (_selectedCategory == 'Tümü') ...[
              SliverToBoxAdapter(
                child: _buildSectionTitle('✨ Öne Çıkanlar'),
              ),
              SliverToBoxAdapter(
                child: _buildFeaturedList(featured),
              ),
              SliverToBoxAdapter(
                child: _buildSectionTitle('🎀 Tüm Abiyeler'),
              ),
            ],

            // All Dresses Grid
            _isLoading
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const DressCardSkeleton(),
                        childCount: 4,
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final dress = dresses[index];
                          return DressCard(
                            dress: dress,
                            onTap: () => _navigateToDetail(dress),
                            onFavoritePressed: () => _toggleFavorite(dress.id),
                          );
                        },
                        childCount: dresses.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba! 👋',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hayalindeki Abiyeyi Bul',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Profile Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                  shape: BoxShape.circle,
                  boxShadow: AppDecorations.primaryGlow,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search Bar
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: AppDecorations.card,
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Abiye, tasarımcı veya stil ara...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: const Color(0xFFDC2626),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _dataService.categories.length,
        itemBuilder: (context, index) {
          final category = _dataService.categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.textLight.withOpacity(0.3)),
                boxShadow: isSelected ? AppDecorations.primaryGlow : null,
              ),
              child: Text(
                category,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: AppTextStyles.titleLarge,
      ),
    );
  }

  Widget _buildFeaturedList(List<DressModel> featured) {
    return SizedBox(
      height: 340,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: featured.length,
        itemBuilder: (context, index) {
          final dress = featured[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: DressCard(
              dress: dress,
              onTap: () => _navigateToDetail(dress),
              onFavoritePressed: () => _toggleFavorite(dress.id),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(DressModel dress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DressDetailScreen(dress: dress),
      ),
    );
  }
}
