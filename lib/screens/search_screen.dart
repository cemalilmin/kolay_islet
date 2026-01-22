import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/dress_model.dart';
import '../services/data_service.dart';
import '../widgets/dress_card.dart';
import 'dress_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedStyle;
  String? _selectedSize;
  RangeValues _priceRange = const RangeValues(0, 3000);
  List<DressModel> _results = [];
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _results = _dataService.dresses;
  }

  void _search() {
    setState(() {
      _results = _dataService.searchDresses(
        query: _searchController.text,
        category: _selectedCategory,
        style: _selectedStyle,
        size: _selectedSize,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedStyle = null;
      _selectedSize = null;
      _priceRange = const RangeValues(0, 3000);
      _searchController.clear();
      _results = _dataService.dresses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ara',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: const Color(0xFFDC2626),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: AppDecorations.card,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Abiye, tasarımcı veya stil ara...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textLight,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _search();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Filters
          if (_showFilters) ...[
            const SizedBox(height: 16),
            _buildFilters(),
          ],

          // Results Count & Clear
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_results.length} sonuç bulundu',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_hasActiveFilters())
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'Temizle',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Results Grid
          Expanded(
            child: _results.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.5,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final dress = _results[index];
                      return DressCard(
                        dress: dress,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DressDetailScreen(dress: dress),
                          ),
                        ),
                        onFavoritePressed: () {
                          _dataService.toggleFavorite(dress.id);
                          _search();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _selectedStyle != null ||
        _selectedSize != null ||
        _priceRange.start > 0 ||
        _priceRange.end < 3000 ||
        _searchController.text.isNotEmpty;
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Style Filter
          Text('Stil', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dataService.styles.map((style) {
              final isSelected = _selectedStyle == style;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStyle = isSelected ? null : style;
                  });
                  _search();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
                    color: isSelected ? null : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    style,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Size Filter
          Text('Beden', style: AppTextStyles.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dataService.allSizes.map((size) {
              final isSelected = _selectedSize == size;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSize = isSelected ? null : size;
                  });
                  _search();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
                    color: isSelected ? null : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Price Range
          Text(
            'Fiyat Aralığı: ₺${_priceRange.start.toInt()} - ₺${_priceRange.end.toInt()}',
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceVariant,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
              ),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 0,
              max: 3000,
              divisions: 30,
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
              },
              onChangeEnd: (_) => _search(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı filtreler deneyin',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
