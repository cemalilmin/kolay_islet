import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../models/dress_model.dart';
import '../models/category_model.dart';
import '../models/booking_model.dart';
import '../models/maintenance_event_model.dart';
import 'profile_screen.dart';

// Day block types for calendar coloring
enum CalendarDayType {
  available,      // Beyaz - müsait
  rental,         // Kırmızı - kirada
  shippingBefore, // Lacivert - kargo öncesi (şehir dışı)
  shippingAfter,  // Lacivert - kargo sonrası (şehir dışı)
  preparation,    // Mor - hazırlık (normal kiralama öncesi)
  cleaning,       // Turuncu - yıkama/bakım
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  String? _selectedCategoryId;
  late String _storeName;

  @override
  void initState() {
    super.initState();
    // Use cached value immediately for instant display
    _storeName = _authService.cachedStoreName.isNotEmpty 
        ? _authService.cachedStoreName 
        : 'Mağaza İsmi';
    // Then load fresh data
    _loadStoreName();
  }

  Future<void> _loadStoreName() async {
    final profile = await _authService.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _storeName = profile['store_name']?.isNotEmpty == true 
            ? profile['store_name'] 
            : 'Mağaza İsmi';
      });
    }
  }

  /// Complete rental helper - creates booking and transaction
  void _completeRental({
    required BuildContext context,
    required DressModel product,
    required DateTime selectedDate,
    required TextEditingController customerNameController,
    required TextEditingController customerPhoneController,
    required TextEditingController priceController,
    required TextEditingController depositController,
    required TextEditingController transactionNotesController,
    required String paymentType,
    required bool isShipping,
    int? shippingBufferDays, // Custom buffer days for this rental
  }) {
    // Calculate amount based on payment type
    final fullPrice = double.tryParse(priceController.text) ?? product.pricePerDay;
    final depositAmount = double.tryParse(depositController.text) ?? 0;
    final recordedAmount = paymentType == 'deposit' ? depositAmount : fullPrice;
    
    // Calculate booking dates 
    // Booking only stores the RENTAL DAY, calendar blocking is calculated separately
    final bufferDays = shippingBufferDays ?? SettingsService().shippingBufferDays;
    final bookingStart = selectedDate; // Always just the rental date
    final bookingEnd = selectedDate;   // Always just the rental date
    
    // Build note with only user notes and shipping info (kapora/kalan stored in amount fields)
    final allNotes = [
      if (transactionNotesController.text.isNotEmpty) transactionNotesController.text,
      if (isShipping) '🚚 Kargo (+${bufferDays * 2} gün bloklama)',
    ].join(' | ');
    
    // Create booking with ghost buffer dates
    _dataService.createBooking(
      dressId: product.id,
      dressTitle: product.title,
      dressImage: product.images.isNotEmpty ? product.images.first : '',
      selectedSize: 'Standart',
      startDate: bookingStart,
      endDate: bookingEnd,
      pricePerDay: product.pricePerDay,
      totalPrice: fullPrice,
      depositAmount: depositAmount,
      notes: 'Müşteri: ${customerNameController.text}${isShipping ? ' (Kargo)' : ''}',
      isShipping: isShipping,
      shippingBufferDays: isShipping ? shippingBufferDays : null,
    );
    
    // Save transaction to DataService
    _dataService.addTransaction(
      type: 'kiralama',
      productName: product.title,
      productId: product.id,
      customerName: customerNameController.text,
      customerPhone: customerPhoneController.text.isNotEmpty 
          ? customerPhoneController.text 
          : null,
      amount: recordedAmount,
      fullPrice: fullPrice,
      rentalDate: selectedDate,
      note: allNotes,
    );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                paymentType == 'deposit'
                    ? '${customerNameController.text} - Kapora: ₺${depositAmount.toInt()}'
                    : '${customerNameController.text} için kiralama kaydedildi',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedCategoryId == null, // Only allow pop if on categories
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedCategoryId != null) {
          // Back from products to categories
          setState(() => _selectedCategoryId = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: _selectedCategoryId == null
                  ? _buildCategoryGrid()
                  : _buildProductGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB91C1C), // Deep red-700
            Color(0xFF991B1B), // red-800
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF450A0A).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_selectedCategoryId != null)
            GestureDetector(
              onTap: () => setState(() => _selectedCategoryId = null),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Text(
              _storeName,
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Category Grid (2 columns like reference)
  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: _dataService.productCategories.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == _dataService.productCategories.length) {
                  return _buildAddCategoryCard();
                }
                final category = _dataService.productCategories[index];
                return _buildCategoryCard(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = category.id),
      onLongPress: () => _showCategoryOptionsMenu(category),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: category.icon.startsWith('assets/')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            category.icon,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Text(
                          category.icon,
                          style: const TextStyle(fontSize: 64),
                        ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(
                category.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryCard() {
    return GestureDetector(
      onTap: _showAddCategoryDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.textLight.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'EKLE',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Product Grid (3 columns like reference)
  Widget _buildProductGrid() {
    final products = _dataService.getProductsByCategory(_selectedCategoryId!);
    final categoryName = _dataService.productCategories
        .firstWhere((c) => c.id == _selectedCategoryId,
            orElse: () => CategoryModel(id: '', name: 'Ürünler', icon: ''))
        .name;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Category title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              categoryName.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Products grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 10,
                childAspectRatio: 0.55,
              ),
              itemCount: products.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return _buildAddProductCard();
                }
                return _buildProductCard(products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(DressModel product) {
    return GestureDetector(
      onTap: () => _showProductOptions(product),
      child: Column(
        children: [
          // Product Image - with shadow and rounded corners
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  child: product.images.isNotEmpty
                      ? _buildProductImage(product.images.first)
                      : _buildProductPlaceholder(),
                ),
              ),
            ),
          ),
          // Gap between image and name
          const SizedBox(height: 6),
          // Product Name - separate box with border and shadow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDDDCDC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF321F20),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCCCCCC),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _toTurkishUpperCase(product.title),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: GoogleFonts.josefinSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF321F20),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Turkish uppercase helper
  String _toTurkishUpperCase(String text) {
    const turkishLower = 'abcçdefgğhıijklmnoöprsştuüvyz';
    const turkishUpper = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';
    
    StringBuffer result = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      int index = turkishLower.indexOf(text[i]);
      if (index != -1) {
        result.write(turkishUpper[index]);
      } else {
        result.write(text[i].toUpperCase());
      }
    }
    return result.toString();
  }

  Widget _buildProductImage(String imagePath) {
    // Check if it's a local file path or network URL
    if (imagePath.startsWith('/')) {
      // Local file
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildProductPlaceholder(),
      );
    } else {
      // Network URL
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildProductPlaceholder(),
      );
    }
  }

  Widget _buildProductPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.checkroom, color: AppColors.textLight, size: 32),
      ),
    );
  }

  Widget _buildAddProductCard() {
    return GestureDetector(
      onTap: () => _showAddProductDialog(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textLight.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              'EKLE',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final salePriceController = TextEditingController();
    final descController = TextEditingController();
    final stockController = TextEditingController(text: '1');
    File? selectedImage;
    bool isSaving = false;
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.checkroom, color: const Color(0xFFDC2626), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Yeni Ürün Ekle',
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.grey[600], size: 20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Photo Selection (REQUIRED)
                Text('Ürün Fotoğrafı *', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.red[700])),
                const SizedBox(height: 8),
                
                if (selectedImage == null)
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        // Camera Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final XFile? photo = await picker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 80,
                              );
                              if (photo != null) {
                                setModalState(() {
                                  selectedImage = File(photo.path);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 32, color: const Color(0xFFDC2626)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Kamera',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: const Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Gallery Button
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final XFile? photo = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (photo != null) {
                                setModalState(() {
                                  selectedImage = File(photo.path);
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: AppColors.chartSatis.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.chartSatis.withOpacity(0.3)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_library, size: 32, color: AppColors.chartSatis),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Galeri',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.chartSatis,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          selectedImage!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Fotoğraf Seçildi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Product Name
                Text('Ürün Adı *', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameController,
                  style: AppTextStyles.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Ör: Kırmızı Abiye',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Price
                Text('Günlük Kiralama Fiyatı (Opsiyonel)', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Ör: 850',
                    prefixText: '₺ ',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Sale Price (optional)
                Text('Satış Fiyatı (Opsiyonel)', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: salePriceController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Ör: 2500 (Satılacaksa)',
                    prefixText: '₺ ',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Description (optional)
                Text('Açıklama (Opsiyonel)', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  style: AppTextStyles.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Ürün açıklaması...',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Stock Count
                Text('Stok Adedi *', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.titleMedium,
                  decoration: InputDecoration(
                    hintText: 'Ör: 1',
                    suffixText: 'adet',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                GestureDetector(
                  onTap: isSaving ? null : () async {
                    // Prevent multiple taps
                    if (isSaving) return;
                    
                    // Validate required fields
                    if (selectedImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Lütfen ürün fotoğrafı ekleyin'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Lütfen ürün adı girin'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    final price = double.tryParse(priceController.text) ?? 0;
                    // Price can be 0 for products that are not rented

                    final stockCount = int.tryParse(stockController.text) ?? 1;
                    if (stockCount < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Stok adedi en az 1 olmalıdır'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    final salePrice = double.tryParse(salePriceController.text) ?? 0;

                    // Set saving state to prevent multiple taps
                    setModalState(() {
                      isSaving = true;
                    });

                    try {
                      await _dataService.addProduct(
                        title: nameController.text,
                        categoryId: _selectedCategoryId!,
                        pricePerDay: price,
                        salePrice: salePrice,
                        description: descController.text.isNotEmpty ? descController.text : null,
                        images: [selectedImage!.path],
                        stockCount: stockCount,
                      );

                      final messenger = ScaffoldMessenger.of(context);
                      final productName = nameController.text;
                      Navigator.pop(context);
                      
                      if (mounted) {
                        setState(() {}); // Refresh UI
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 10),
                                Text('$productName eklendi'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setModalState(() {
                          isSaving = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hata: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: isSaving ? null : const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                      color: isSaving ? Colors.grey[400] : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSaving ? [] : [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSaving) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Kaydediliyor...',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                        ] else ...[
                          const Icon(Icons.save, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Ürünü Kaydet',
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Full screen image viewer on double tap
  void _showFullScreenImage(DressModel product) {
    if (product.images.isEmpty) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen image with zoom
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Hero(
                    tag: 'product_image_${product.id}',
                    child: product.images.first.startsWith('/')
                        ? Image.file(
                            File(product.images.first),
                            fit: BoxFit.contain,
                          )
                        : Image.network(
                            product.images.first,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.black, size: 24),
                ),
              ),
            ),
            // Product name
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Edit product name dialog
  void _showEditProductNameDialog(DressModel product) {
    final nameController = TextEditingController(text: product.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Ürün Adını Düzenle'),
          ],
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ürün adı',
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != product.title) {
                // Update product name
                await _dataService.updateProduct(product.id, title: newName);
                setState(() {});
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ürün adı güncellendi'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Product Options (Kiralama / Satış)
  void _showProductOptions(DressModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Product info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 20),
                Column(
                  children: [
                    GestureDetector(
                      onDoubleTap: () => _showFullScreenImage(product),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: product.images.isNotEmpty
                            ? SizedBox(
                                width: 100,
                                height: 120,
                                child: _buildProductImage(product.images.first),
                              )
                            : Container(
                                width: 100,
                                height: 120,
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.checkroom, size: 40),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Double tap hint
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 12, color: AppColors.textLight),
                        const SizedBox(width: 2),
                        Text(
                          'Çift tıkla',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              style: AppTextStyles.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showEditProductNameDialog(product);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Kiralama fiyatı
                      if (product.pricePerDay > 0)
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: const Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(
                              'Kiralama: ${product.pricePerDay.toInt()} TL',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      // Satış fiyatı
                      if (product.salePrice > 0)
                        Row(
                          children: [
                            Icon(Icons.sell, size: 14, color: const Color(0xFF2563EB)),
                            const SizedBox(width: 4),
                            Text(
                              'Satış: ${product.salePrice.toInt()} TL',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: const Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.inventory_2, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${product.stockCount} adet',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showRentalDialog(product);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Kiralama',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showSaleDialog(product);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Satış',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showStockEditDialog(product);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Stok',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showPriceEditDialog(product);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Fiyat',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Delete Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmDialog(product);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ürünü Sil',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
        ),
      ),
    );
  }

  // Delete Confirmation Dialog
  void _showDeleteConfirmDialog(DressModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Text('Ürünü Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${product.title} ürününü silmek istediğinize emin misiniz?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz!',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              
              final success = await _dataService.removeProduct(product.id);
              
              if (mounted) {
                setState(() {}); // Refresh UI
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(success ? Icons.delete : Icons.error, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(success ? '${product.title} silindi' : 'Hata oluştu'),
                      ],
                    ),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Price Edit Dialog
  void _showPriceEditDialog(DressModel product) {
    final rentalPriceController = TextEditingController(text: product.pricePerDay.toInt().toString());
    final salePriceController = TextEditingController(text: product.salePrice.toInt().toString());
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.attach_money, color: Colors.blue[700], size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fiyat Düzenle',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Rental Price
            Text('Kiralama Fiyatı', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: rentalPriceController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.titleMedium,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Günlük kiralama fiyatı',
                  prefixText: '₺ ',
                  prefixIcon: Icon(Icons.calendar_today, color: AppColors.chartKiralama),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, maxHeight: 24),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sale Price
            Text('Satış Fiyatı', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: salePriceController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.titleMedium,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Satış fiyatı (opsiyonel)',
                  prefixText: '₺ ',
                  prefixIcon: Icon(Icons.sell, color: AppColors.chartSatis),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, maxHeight: 24),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            GestureDetector(
              onTap: () async {
                final newRentalPrice = double.tryParse(rentalPriceController.text) ?? product.pricePerDay;
                final newSalePrice = double.tryParse(salePriceController.text) ?? product.salePrice;
                
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                
                final success = await _dataService.updateProduct(
                  product.id,
                  pricePerDay: newRentalPrice,
                  salePrice: newSalePrice,
                );
                
                if (mounted) {
                  setState(() {}); // Refresh UI
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(success ? 'Fiyatlar güncellendi' : 'Hata oluştu'),
                        ],
                      ),
                      backgroundColor: success ? Colors.blue[700] : Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue[600]!, Colors.blue[400]!]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Fiyatları Kaydet',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stock Edit Dialog
  void _showStockEditDialog(DressModel product) {
    int currentStock = product.stockCount;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Stok Düzenle',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Stock Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decrease Button
                  GestureDetector(
                    onTap: currentStock > 0
                        ? () => setModalState(() => currentStock--)
                        : null,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: currentStock > 0 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.remove,
                        color: currentStock > 0 ? Colors.red : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // Stock Count Display
                  Column(
                    children: [
                      Text(
                        '$currentStock',
                        style: AppTextStyles.headlineLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        'adet',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // Increase Button
                  GestureDetector(
                    onTap: () => setModalState(() => currentStock++),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.add,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              GestureDetector(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  
                  final success = await _dataService.updateProduct(product.id, stockCount: currentStock);
                  
                  if (mounted) {
                    setState(() {}); // Refresh UI
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(success ? 'Stok güncellendi: $currentStock adet' : 'Hata oluştu'),
                          ],
                        ),
                        backgroundColor: success ? AppColors.success : Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Kaydet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // Sale Dialog
  void _showSaleDialog(DressModel product) {
    // Use salePrice if set, otherwise use originalPrice
    final initialPrice = product.salePrice > 0 ? product.salePrice : product.originalPrice;
    final priceController = TextEditingController(text: initialPrice.toInt().toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final customerNameController = TextEditingController();
        final customerPhoneController = TextEditingController();
        
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Satış',
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          product.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Price Section
                _buildSectionTitle('Satış Fiyatı', Icons.attach_money),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: priceController,
                  hint: 'Fiyat',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  prefix: '₺',
                ),
                
                const SizedBox(height: 24),
                
                // Customer Info (Optional)
                _buildSectionTitle('Müşteri Bilgisi (Opsiyonel)', Icons.person_outline),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: customerNameController,
                  hint: 'Müşteri Adı',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: customerPhoneController,
                  hint: 'Telefon Numarası',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                GestureDetector(
                  onTap: () async {
                    final salePrice = double.tryParse(priceController.text) ?? product.originalPrice;
                    final messenger = ScaffoldMessenger.of(context);
                    
                    // CHECK STOCK CONFLICT: Will this sale cause booking issues?
                    final currentStock = product.stockCount;
                    final newStock = currentStock - 1;
                    
                    if (newStock < 0) {
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('❌ Stok yetersiz! Bu ürünün stoğu 0.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Get active bookings for this product
                    final activeBookings = _dataService.getActiveBookingsForProduct(product.id);
                    
                    if (activeBookings.isNotEmpty && newStock < activeBookings.length) {
                      // Check for overlapping booking dates
                      final conflictDates = _getConflictingBookingDates(activeBookings, newStock);
                      
                      if (conflictDates.isNotEmpty) {
                        // Show warning dialog
                        final shouldProceed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                const SizedBox(width: 10),
                                const Text('Stok Uyarısı', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Satış sonrası stok $newStock olacak.',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Çakışan Kiralamalar:',
                                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                                      ),
                                      const SizedBox(height: 8),
                                      ...conflictDates.map((date) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.event, size: 16, color: Colors.orange.shade700),
                                            const SizedBox(width: 6),
                                            Text(date, style: TextStyle(color: Colors.orange.shade900)),
                                          ],
                                        ),
                                      )).toList(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Bu tarihlerde yeterli stok olmayacak. Yine de satmak istiyor musunuz?',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Yine de Sat', style: TextStyle(color: Colors.orange.shade700)),
                              ),
                            ],
                          ),
                        ) ?? false;
                        
                        if (!shouldProceed) return;
                      }
                    }
                    
                    Navigator.pop(context);
                    
                    await _dataService.addTransaction(
                      type: 'satis',
                      productName: product.title,
                      productId: product.id,
                      productImageUrl: product.images.isNotEmpty ? product.images.first : null,
                      customerName: customerNameController.text.isNotEmpty 
                          ? customerNameController.text 
                          : null,
                      customerPhone: customerPhoneController.text.isNotEmpty 
                          ? customerPhoneController.text 
                          : null,
                      amount: salePrice,
                      fullPrice: salePrice,
                    );
                    
                    // Decrease stock after sale
                    await _dataService.updateProduct(product.id, stockCount: newStock);
                    
                    if (mounted) {
                      setState(() {});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 10),
                              Text('Satış kaydedildi - ₺${priceController.text}${customerNameController.text.isNotEmpty ? " - ${customerNameController.text}" : ""}'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Satışı Onayla',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modern Rental Dialog with Customer Info
  void _showRentalDialog(DressModel product) {
    DateTime currentMonth = DateTime.now();
    DateTime? selectedDate;
    String paymentType = 'full'; // 'full' or 'deposit'
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();
    final priceController = TextEditingController(text: product.pricePerDay.toInt().toString());
    final depositController = TextEditingController();
    // Free-text CRM notes (replaces individual measurement fields)
    final transactionNotesController = TextEditingController();
    bool isShipping = false; // Toggle for city-to-city shipping
    int shippingBufferDays = SettingsService().shippingBufferDays; // Default from settings, adjustable per rental
    bool isSaving = false; // Prevent double-click on save button
    List<MaintenanceEvent> maintenanceEvents = []; // Active maintenance for calendar
    bool maintenanceLoaded = false; // Track if maintenance events are loaded

    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Load maintenance events on first build
          if (!maintenanceLoaded) {
            maintenanceLoaded = true;
            _dataService.getMaintenanceEventsForProduct(product.id).then((events) {
              // Backend already filters by status='pending'
              maintenanceEvents = events;
              setModalState(() {}); // Trigger rebuild with loaded events
            });
          }
          
          final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
          final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
          final firstWeekday = firstDayOfMonth.weekday;
          final daysInMonth = lastDayOfMonth.day;
          final today = DateTime.now();
          final isFormValid = selectedDate != null && 
              customerNameController.text.isNotEmpty;

          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Kiralama',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            product.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Müşteri Bilgileri Section
                        _buildSectionTitle('Müşteri Bilgileri', Icons.person_outline),
                        const SizedBox(height: 12),
                        
                        // Customer Name
                        _buildModernTextField(
                          controller: customerNameController,
                          hint: 'Müşteri Adı Soyadı',
                          icon: Icons.person,
                          onChanged: (_) => setModalState(() {}),
                        ),
                        const SizedBox(height: 12),
                        
                        // Customer Phone
                        _buildModernTextField(
                          controller: customerPhoneController,
                          hint: 'Telefon Numarası',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 24),

                        // Tarih Seçimi Section
                        _buildSectionTitle('Kiralama Tarihi', Icons.calendar_today),
                        const SizedBox(height: 12),

                        // Modern Calendar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              // Month Navigation
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.chevron_left, size: 22),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        turkishMonths[currentMonth.month - 1],
                                        style: AppTextStyles.titleLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${currentMonth.year}',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.chevron_right, size: 22),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Weekday Headers
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: weekDays.map((day) => SizedBox(
                                  width: 36,
                                  child: Text(
                                    day,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )).toList(),
                              ),

                              const SizedBox(height: 12),
                              
                              // Color Legend
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    _buildCalendarLegend(const Color(0xFF8B5CF6), 'Hazırlık'),
                                    _buildCalendarLegend(Colors.red.shade400, 'Kirada'),
                                    _buildCalendarLegend(const Color(0xFF1E3A5F), 'Kargo'),
                                    _buildCalendarLegend(Colors.orange.shade400, 'Yıkama'),
                                  ],
                                ),
                              ),

                              // Calendar Grid
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 6,
                                  crossAxisSpacing: 6,
                                ),
                                itemCount: 42,
                                itemBuilder: (context, index) {
                                  final dayOffset = index - (firstWeekday - 1);
                                  if (dayOffset < 1 || dayOffset > daysInMonth) {
                                    return const SizedBox();
                                  }

                                  final date = DateTime(currentMonth.year, currentMonth.month, dayOffset);
                                  final isSelected = selectedDate != null &&
                                      date.year == selectedDate!.year &&
                                      date.month == selectedDate!.month &&
                                      date.day == selectedDate!.day;
                                  final isToday = date.year == today.year &&
                                      date.month == today.month &&
                                      date.day == today.day;
                                  final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
                                  
                                  // Get day type with buffer days
                                  final bookings = _dataService.getActiveBookingsForProduct(product.id);
                                  
                                  // DEBUG: Log bookings only once per build
                                  if (dayOffset == 1 && bookings.isNotEmpty) {
                                    print('DEBUG CALENDAR: ${bookings.length} active bookings for ${product.title} (stock: ${product.stockCount}):');
                                    for (final b in bookings) {
                                      print('  - Status: ${b.status}, Dates: ${b.startDate.day}/${b.startDate.month} - ${b.endDate.day}/${b.endDate.month}, isShipping: ${b.isShipping}');
                                    }
                                  }
                                  
                                  final dayType = _getCalendarDayType(date, bookings, stockCount: product.stockCount, maintenanceEvents: maintenanceEvents);
                                  final isBlocked = dayType != CalendarDayType.available;
                                  final isUnavailable = isPast || isBlocked;
                                  
                                  // Colors based on day type
                                  Color bgColor;
                                  Color textColor;
                                  if (isPast) {
                                    bgColor = Colors.grey[100]!;
                                    textColor = Colors.grey[400]!;
                                  } else if (isSelected) {
                                    bgColor = const Color(0xFFDC2626);
                                    textColor = Colors.white;
                                  } else {
                                    switch (dayType) {
                                      case CalendarDayType.rental:
                                        bgColor = Colors.red.shade400;
                                        textColor = Colors.white;
                                        break;
                                      case CalendarDayType.shippingBefore:
                                      case CalendarDayType.shippingAfter:
                                        bgColor = const Color(0xFF1E3A5F); // Lacivert
                                        textColor = Colors.white;
                                        break;
                                      case CalendarDayType.preparation:
                                        bgColor = const Color(0xFF8B5CF6); // Mor
                                        textColor = Colors.white;
                                        break;
                                      case CalendarDayType.cleaning:
                                        bgColor = Colors.orange.shade400;
                                        textColor = Colors.white;
                                        break;
                                      case CalendarDayType.available:
                                        bgColor = isToday ? const Color(0xFFDC2626).withOpacity(0.1) : Colors.white;
                                        textColor = isToday ? const Color(0xFFDC2626) : AppColors.textPrimary;
                                        break;
                                    }
                                  }

                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: isUnavailable ? null : () {
                                      setModalState(() => selectedDate = date);
                                    },
                                    onLongPress: (isBlocked && !isPast) ? () {
                                      _showUnlockDateDialog(context, date, dayType, bookings, () {
                                        setModalState(() {});
                                      });
                                    } : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: isToday && !isSelected && !isBlocked
                                            ? Border.all(color: const Color(0xFFDC2626), width: 2)
                                            : null,
                                        boxShadow: isSelected ? [
                                          BoxShadow(
                                            color: const Color(0xFFDC2626).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ] : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$dayOffset',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected || isToday || isBlocked ? FontWeight.w700 : FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Selected date indicator
                        if (selectedDate != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFFDC2626).withOpacity(0.1), const Color(0xFFFEE2E2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event_available, color: const Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  '${selectedDate!.day} ${turkishMonths[selectedDate!.month - 1]} ${selectedDate!.year}',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: const Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],


                        const SizedBox(height: 24),

                        // Ödeme Bilgileri Section
                        _buildSectionTitle('Ödeme Bilgileri', Icons.payments_outlined),
                        const SizedBox(height: 12),
                        
                        // Toplam Fiyat Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kiralama Ücreti',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.edit, size: 14, color: AppColors.textLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        'İndirim için düzenle',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
                                ),
                                child: TextField(
                                  controller: priceController,
                                  keyboardType: TextInputType.number,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC2626),
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    prefixText: '₺ ',
                                    prefixStyle: AppTextStyles.headlineSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFDC2626),
                                    ),
                                    suffixIcon: Icon(Icons.edit, color: const Color(0xFFDC2626).withOpacity(0.5), size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Payment Type Selection
                        Text(
                          'Ödeme Şekli',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => paymentType = 'full'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: paymentType == 'full' ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
                                    color: paymentType == 'full' ? null : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: paymentType == 'full' ? [
                                      BoxShadow(
                                        color: const Color(0xFFDC2626).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: paymentType == 'full' ? Colors.white : Colors.grey[400],
                                        size: 24,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tam Ücret',
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: paymentType == 'full' ? Colors.white : AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => paymentType = 'deposit'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    gradient: paymentType == 'deposit' ? LinearGradient(
                                      colors: [Colors.orange[600]!, Colors.orange[400]!],
                                    ) : null,
                                    color: paymentType == 'deposit' ? null : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: paymentType == 'deposit' ? [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        color: paymentType == 'deposit' ? Colors.white : Colors.grey[400],
                                        size: 24,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Kapora',
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: paymentType == 'deposit' ? Colors.white : AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Deposit Amount Input (only shown when deposit selected)
                        if (paymentType == 'deposit') ...[
                          const SizedBox(height: 16),
                          _buildModernTextField(
                            controller: depositController,
                            hint: 'Kapora Miktarı',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            prefix: '₺',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kalan: ₺${((double.tryParse(priceController.text) ?? 0) - (double.tryParse(depositController.text) ?? 0)).toInt()}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        // Shipping Toggle (Ghost Buffer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isShipping ? Colors.blue.withOpacity(0.1) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isShipping ? Colors.blue : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    color: isShipping ? Colors.blue[700] : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Şehir Dışı Kargo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isShipping ? Colors.blue[700] : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: isShipping,
                                    onChanged: (v) => setModalState(() => isShipping = v),
                                    activeColor: Colors.blue,
                                  ),
                                ],
                              ),
                              // Day selector when shipping is enabled
                              if (isShipping) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.blue[600]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Kargo Bloklaması',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                      // Day selector buttons
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () => setModalState(() {
                                                if (shippingBufferDays > 1) shippingBufferDays--;
                                              }),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Icon(Icons.remove, size: 18, color: shippingBufferDays > 1 ? Colors.blue[700] : Colors.grey),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              child: Text(
                                                '$shippingBufferDays gün',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => setModalState(() {
                                                if (shippingBufferDays < 7) shippingBufferDays++;
                                              }),
                                              child: Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Icon(Icons.add, size: 18, color: shippingBufferDays < 7 ? Colors.blue[700] : Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Free-Text CRM Notes
                        _buildSectionTitle('Müşteri Notları (Opsiyonel)', Icons.notes),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: transactionNotesController,
                            maxLines: 3,
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              hintText: 'Ölçüler, adres, özel istekler...',
                              hintStyle: TextStyle(color: AppColors.textLight),
                            ),
                          ),
                        ),

                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                ),

                // Fixed Save Button
                Container(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: (isFormValid && !isSaving)
                        ? () async {
                            // Prevent double-tap
                            if (isSaving) return;
                            setModalState(() => isSaving = true);
                            
                            // If shipping is enabled, check buffer days for conflicts
                            if (isShipping && shippingBufferDays > 0) {
                              bool hasBufferConflict = false;
                              String conflictInfo = '';
                              
                              // Check each buffer day before the rental date
                              for (int i = 1; i <= shippingBufferDays + 1; i++) {
                                final bufferDate = selectedDate!.subtract(Duration(days: i));
                                final dayType = _getCalendarDayType(
                                  bufferDate, 
                                  _dataService.getActiveBookingsForProduct(product.id),
                                  stockCount: product.stockCount,
                                  maintenanceEvents: maintenanceEvents,
                                );
                                
                                // If buffer day is blocked (not available)
                                if (dayType != CalendarDayType.available) {
                                  hasBufferConflict = true;
                                  final dayName = i == shippingBufferDays + 1 ? 'hazırlık günü' : 'kargo gidiş günü';
                                  final dateStr = '${bufferDate.day}/${bufferDate.month}';
                                  conflictInfo = 'Seçilen tarih için $dayName ($dateStr) başka bir rezervasyonla çakışmaktadır.';
                                  break;
                                }
                              }
                              
                              if (hasBufferConflict) {
                                // Show warning dialog with option to proceed
                                final shouldProceed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) {
                                    bool acknowledged = false;
                                    return StatefulBuilder(
                                      builder: (ctx, setDialogState) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
                                            const SizedBox(width: 10),
                                            const Expanded(child: Text('Teslimat Uyarısı', style: TextStyle(fontSize: 18))),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ürün seçilen tarihe yetişmeyebilir.',
                                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              conflictInfo,
                                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.orange[200]!),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange[700]),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Kargo gün sayısını azaltarak veya farklı tarih seçerek çözebilirsiniz.',
                                                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            InkWell(
                                              onTap: () => setDialogState(() => acknowledged = !acknowledged),
                                              child: Row(
                                                children: [
                                                  Checkbox(
                                                    value: acknowledged,
                                                    onChanged: (v) => setDialogState(() => acknowledged = v ?? false),
                                                    activeColor: Colors.orange[700],
                                                  ),
                                                  const Expanded(
                                                    child: Text(
                                                      'Riski kabul ediyorum, yine de kaydet',
                                                      style: TextStyle(fontSize: 13),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('İptal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: acknowledged ? () => Navigator.pop(ctx, true) : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange[700],
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Kaydet'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ) ?? false;
                                
                                if (!shouldProceed) {
                                  setModalState(() => isSaving = false);
                                  return;
                                }
                              }
                            }
                            
                            // Get detailed stock availability for the rental date
                            final availability = await _dataService.getStockAvailability(
                              product.id,
                              selectedDate!,
                              selectedDate!,
                            );
                            
                            // Check if available
                            if (availability.hasAvailable) {
                              // Proceed directly
                              _completeRental(
                                context: context,
                                product: product,
                                selectedDate: selectedDate!,
                                customerNameController: customerNameController,
                                customerPhoneController: customerPhoneController,
                                priceController: priceController,
                                depositController: depositController,
                                transactionNotesController: transactionNotesController,
                                paymentType: paymentType,
                                isShipping: isShipping,
                                shippingBufferDays: isShipping ? shippingBufferDays : null,
                              );
                            } else if (availability.canOverride) {
                              // Show override dialog - maintenance can be cancelled
                              final shouldOverride = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Row(
                                    children: [
                                      Icon(Icons.warning_amber, color: Colors.orange[700], size: 28),
                                      const SizedBox(width: 10),
                                      const Text('Stok Dolu'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        availability.blockReason,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.local_laundry_service, color: Colors.orange[700]),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Temizlikteki ürünü hazır işaretle ve bu kiralamayı onayla?',
                                                style: TextStyle(color: Colors.orange[800], fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('İptal'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange[600],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Temizliği İptal Et ve Kirala', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (shouldOverride == true) {
                                // Delete only the conflicting maintenance event
                                if (availability.conflictingMaintenanceId != null) {
                                  await _dataService.deleteMaintenanceEvent(availability.conflictingMaintenanceId!);
                                } else {
                                  // Fallback: clear all maintenance for this product
                                  await _dataService.markProductReady(product.id);
                                }
                                if (context.mounted) {
                                  _completeRental(
                                    context: context,
                                    product: product,
                                    selectedDate: selectedDate!,
                                    customerNameController: customerNameController,
                                    customerPhoneController: customerPhoneController,
                                    priceController: priceController,
                                    depositController: depositController,
                                    transactionNotesController: transactionNotesController,
                                    paymentType: paymentType,
                                    isShipping: isShipping,
                                    shippingBufferDays: isShipping ? shippingBufferDays : null,
                                  );
                                }
                              }
                            } else {
                              // Hard block - all units rented
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${availability.blockReason}! Override mümkün değil.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: isFormValid ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
                        color: isFormValid ? null : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isFormValid ? [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSaving) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Kaydediliyor...',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.check_circle_outline,
                              color: isFormValid ? Colors.white : Colors.grey[500],
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Kiralamayı Kaydet',
                              style: AppTextStyles.button.copyWith(
                                color: isFormValid ? Colors.white : Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFDC2626)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefix,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          prefixText: prefix,
          prefixStyle: AppTextStyles.titleMedium.copyWith(color: const Color(0xFFDC2626)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // Add Category Dialog
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedIcon = 'assets/category_icons/fistan.png';
    final icons = [
      'assets/category_icons/fistan.png',
      'assets/category_icons/gelinlik.png',
      'assets/category_icons/bindalli.png',
      'assets/category_icons/kina.png',
      'assets/category_icons/abiye.png',
      'assets/category_icons/aksesuar.png',
      'assets/category_icons/taki.png',
      'assets/category_icons/ayakkabi.png',
      'assets/category_icons/kemer.png',
      'assets/category_icons/kumastakimlar.png',
      'assets/category_icons/sallar.png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yeni Kategori', style: AppTextStyles.titleLarge),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: icons.map((icon) {
                  final isSelected = selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedIcon = icon),
                    child: Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFDC2626).withOpacity(0.1) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: const Color(0xFFDC2626), width: 2) : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(icon, fit: BoxFit.cover, width: 48, height: 48),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Kategori adı...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  if (nameController.text.isNotEmpty) {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    
                    final success = await _dataService.addCategory(nameController.text, selectedIcon);
                    
                    if (mounted) {
                      setState(() {});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(success ? 'Kategori eklendi' : 'Kategori eklenemedi'),
                            ],
                          ),
                          backgroundColor: success ? AppColors.success : Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Ekle',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryOptionsMenu(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              category.name,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Kategori Adını Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _showEditCategoryDialog(category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.purple),
              title: const Text('İkonu Değiştir'),
              onTap: () {
                Navigator.pop(context);
                _showChangeIconDialog(category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_vert, color: Colors.orange),
              title: const Text('Kategori Sırasını Değiştir'),
              onTap: () {
                Navigator.pop(context);
                _showReorderCategoriesDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: Text('Kategoriyi Sil', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCategoryDialog(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Change category icon dialog
  void _showChangeIconDialog(CategoryModel category) {
    String selectedIcon = category.icon;
    final icons = [
      'assets/category_icons/fistan.png',
      'assets/category_icons/gelinlik.png',
      'assets/category_icons/bindalli.png',
      'assets/category_icons/kina.png',
      'assets/category_icons/abiye.png',
      'assets/category_icons/aksesuar.png',
      'assets/category_icons/taki.png',
      'assets/category_icons/ayakkabi.png',
      'assets/category_icons/kemer.png',
      'assets/category_icons/kumastakimlar.png',
      'assets/category_icons/sallar.png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('İkon Seç: ${category.name}', style: AppTextStyles.titleLarge),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: icons.map((icon) {
                  final isSelected = selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedIcon = icon),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFDC2626).withOpacity(0.1) : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: const Color(0xFFDC2626), width: 2) : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(icon, fit: BoxFit.cover),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  
                  final success = await _dataService.updateCategoryIcon(category.id, selectedIcon);
                  
                  if (mounted) {
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(success ? 'İkon güncellendi' : 'İkon güncellenemedi'),
                          ],
                        ),
                        backgroundColor: success ? AppColors.success : Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Kaydet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calendar helper: Build legend item
  Widget _buildCalendarLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  // Calendar helper: Get day type based on bookings with buffer days from settings
  // Now supports stock pool: only blocks if bookings >= stockCount
  // Normal Kiralama: 1 gün hazırlık (mor) + kiralama (kırmızı) + yıkama (turuncu)
  // Şehir Dışı: kargo öncesi (lacivert) + kiralama (kırmızı) + kargo sonrası (lacivert) + yıkama (turuncu)
  CalendarDayType _getCalendarDayType(DateTime date, List<BookingModel> bookings, {int stockCount = 1, List<MaintenanceEvent>? maintenanceEvents}) {
    final checkDay = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    // Count active maintenance events - only for TODAY
    // Only TODAY is orange for maintenance, past days are gray
    int maintenanceCount = 0;
    if (maintenanceEvents != null && checkDay.isAtSameMomentAs(todayNormalized)) {
      for (final event in maintenanceEvents) {
        // Event was started on or before today = still active
        final eventStart = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        if (!eventStart.isAfter(todayNormalized)) {
          maintenanceCount++;
        }
      }
    }
    
    final settings = SettingsService();
    final defaultShippingBuffer = settings.shippingBufferDays; // Default from settings
    final cleaningDays = settings.cleaningDurationDays; // Yıkama/bakım günleri
    
    // Count how many bookings block this specific date
    int rentalCount = 0;
    int shippingBeforeCount = 0;
    int shippingAfterCount = 0;
    int prepCount = 0;
    int cleaningCount = 0;
    
    for (final booking in bookings) {
      // Skip returned or cancelled bookings
      if (booking.status == BookingStatus.returned || 
          booking.status == BookingStatus.cancelled) continue;
      
      // Normalize booking dates
      final rentalStart = DateTime(booking.startDate.year, booking.startDate.month, booking.startDate.day);
      final rentalEnd = DateTime(booking.endDate.year, booking.endDate.month, booking.endDate.day);
      final isShippingBooking = booking.isShipping;
      
      // Use booking's own shippingBufferDays or fall back to settings default
      final shippingBuffer = booking.shippingBufferDays ?? defaultShippingBuffer;
      
      // 1. Check if it's a rental day (startDate to endDate inclusive)
      if (_isInDateRange(checkDay, rentalStart, rentalEnd)) {
        rentalCount++;
        continue;
      }
      
      if (isShippingBooking) {
        // ŞEHİR DIŞI KİRALAMA MANTIĞI
        // 1. Hazırlık günü (kargo başlamadan 1 gün önce)
        final prepDay = rentalStart.subtract(Duration(days: shippingBuffer + 1));
        if (checkDay.isAtSameMomentAs(prepDay)) {
          prepCount++;
          continue;
        }
        
        // 2. Kargo gidiş günleri
        if (shippingBuffer > 0) {
          final shippingBeforeStart = rentalStart.subtract(Duration(days: shippingBuffer));
          final shippingBeforeEnd = rentalStart.subtract(const Duration(days: 1));
          if (_isInDateRange(checkDay, shippingBeforeStart, shippingBeforeEnd)) {
            shippingBeforeCount++;
            continue;
          }
          
          // 3. Kargo dönüş günleri
          final shippingAfterStart = rentalEnd.add(const Duration(days: 1));
          final shippingAfterEnd = rentalEnd.add(Duration(days: shippingBuffer));
          if (_isInDateRange(checkDay, shippingAfterStart, shippingAfterEnd)) {
            shippingAfterCount++;
            continue;
          }
        }
        
        // 4. Yıkama/bakım günleri (kargo dönüşünden sonra)
        if (cleaningDays > 0) {
          final cleaningStart = rentalEnd.add(Duration(days: shippingBuffer + 1));
          final cleaningEnd = rentalEnd.add(Duration(days: shippingBuffer + cleaningDays));
          if (_isInDateRange(checkDay, cleaningStart, cleaningEnd)) {
            cleaningCount++;
            continue;
          }
        }
      } else {
        // NORMAL KİRALAMA MANTIĞI (Şehir İçi)
        // Hazırlık günü (1 gün önce)
        final prepDay = rentalStart.subtract(const Duration(days: 1));
        if (checkDay.isAtSameMomentAs(prepDay)) {
          prepCount++;
          continue;
        }
        
        // Yıkama/bakım günleri (kiralama sonrası)
        if (cleaningDays > 0) {
          final cleaningStart = rentalEnd.add(const Duration(days: 1));
          final cleaningEnd = rentalEnd.add(Duration(days: cleaningDays));
          if (_isInDateRange(checkDay, cleaningStart, cleaningEnd)) {
            cleaningCount++;
            continue;
          }
        }
      }
    }
    
    // Calculate total stock usage for this day (including active maintenance for TODAY)
    final totalUsage = rentalCount + shippingBeforeCount + shippingAfterCount + prepCount + cleaningCount + maintenanceCount;
    
    // If there's any rental on this day, show as rental (highest priority)
    if (rentalCount > 0) {
      // If all stock is used (by any combination of bookings), show as blocked rental
      if (totalUsage >= stockCount) return CalendarDayType.rental;
    }
    
    // If total usage reaches stock, show the dominant buffer type
    // Priority: maintenance/cleaning > shippingBefore > shippingAfter > prep
    // Cleaning has priority because it means product is being maintained
    if (totalUsage >= stockCount) {
      // Active maintenance takes priority (only applies to TODAY)
      if (maintenanceCount > 0) return CalendarDayType.cleaning;
      if (cleaningCount > 0) return CalendarDayType.cleaning;
      if (shippingBeforeCount > 0) return CalendarDayType.shippingBefore;
      if (shippingAfterCount > 0) return CalendarDayType.shippingAfter;
      if (prepCount > 0) return CalendarDayType.preparation;
    }
    
    return CalendarDayType.available;
  }
  
  // Calendar helper: Check if a date has maintenance/cleaning
  // NEW BEHAVIOR: If product has active maintenance, only TODAY shows as orange
  // Future dates remain available for booking
  Future<CalendarDayType> _getMaintenanceDayType(DateTime date, String productId) async {
    final checkDay = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    try {
      final maintenanceEvents = await _dataService.getMaintenanceEventsForProduct(productId);
      for (final event in maintenanceEvents) {
        final eventStart = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
        final eventEnd = DateTime(event.endDate.year, event.endDate.month, event.endDate.day);
        
        // Check if maintenance is currently active (today is within range)
        final isMaintenanceActive = _isInDateRange(today, eventStart, eventEnd);
        
        // Only show orange for TODAY if maintenance is active
        // Future dates remain available
        if (isMaintenanceActive && checkDay.isAtSameMomentAs(today)) {
          return CalendarDayType.cleaning;
        }
      }
    } catch (e) {
      // Ignore errors, just return available
    }
    
    return CalendarDayType.available;
  }

  bool _isInDateRange(DateTime day, DateTime start, DateTime end) {
    return (day.isAfter(start) || day.isAtSameMomentAs(start)) &&
           (day.isBefore(end) || day.isAtSameMomentAs(end));
  }

  // Helper: Find booking dates that would conflict if stock is reduced
  List<String> _getConflictingBookingDates(List<BookingModel> bookings, int newStock) {
    final settings = SettingsService();
    final shippingBuffer = settings.shippingBufferDays;
    final cleaningDays = settings.cleaningDurationDays;
    
    // For each day, count how many bookings block it
    final dateUsageMap = <String, int>{};
    final dateToBookingInfo = <String, Set<String>>{};
    
    for (final booking in bookings) {
      if (booking.status == BookingStatus.returned || 
          booking.status == BookingStatus.cancelled) continue;
      
      final rentalStart = DateTime(booking.startDate.year, booking.startDate.month, booking.startDate.day);
      final rentalEnd = DateTime(booking.endDate.year, booking.endDate.month, booking.endDate.day);
      
      // Calculate full blocked range
      DateTime blockStart;
      DateTime blockEnd;
      
      if (booking.isShipping) {
        blockStart = rentalStart.subtract(Duration(days: shippingBuffer + 1));
        blockEnd = rentalEnd.add(Duration(days: shippingBuffer + cleaningDays));
      } else {
        blockStart = rentalStart.subtract(const Duration(days: 1));
        blockEnd = rentalEnd.add(Duration(days: cleaningDays));
      }
      
      // Mark each day in the blocked range
      for (var d = blockStart; !d.isAfter(blockEnd); d = d.add(const Duration(days: 1))) {
        final dateKey = '${d.day}/${d.month}/${d.year}';
        dateUsageMap[dateKey] = (dateUsageMap[dateKey] ?? 0) + 1;
        
        // Track which booking this belongs to
        final bookingLabel = '${booking.startDate.day} ${_monthName(booking.startDate.month)}';
        dateToBookingInfo[dateKey] ??= {};
        dateToBookingInfo[dateKey]!.add(bookingLabel);
      }
    }
    
    // Find dates where usage exceeds new stock
    final conflictBookings = <String>{};
    for (final entry in dateUsageMap.entries) {
      if (entry.value > newStock) {
        // Get the booking labels for this conflicting date
        conflictBookings.addAll(dateToBookingInfo[entry.key] ?? {});
      }
    }
    
    return conflictBookings.toList();
  }
  
  String _monthName(int month) {
    const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 
                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month];
  }

  // Calendar helper: Show unlock date dialog
  void _showUnlockDateDialog(BuildContext ctx, DateTime date, CalendarDayType dayType, List<BookingModel> bookings, VoidCallback onUnlock) {
    // Find the booking causing this block
    BookingModel? blockingBooking;
    final settings = SettingsService();
    final shippingBuffer = settings.shippingBufferDays;
    final cleaningDays = settings.cleaningDurationDays;
    
    for (final booking in bookings) {
      if (booking.status == BookingStatus.returned || 
          booking.status == BookingStatus.cancelled) continue;
          
      final rentalStart = DateTime(booking.startDate.year, booking.startDate.month, booking.startDate.day);
      final rentalEnd = DateTime(booking.endDate.year, booking.endDate.month, booking.endDate.day);
      
      // Calculate block range based on whether it's a shipping booking
      DateTime blockStart;
      DateTime blockEnd;
      
      if (booking.isShipping) {
        // Shipping: prep + shipping before + rental + shipping after + cleaning
        blockStart = rentalStart.subtract(Duration(days: shippingBuffer + 1)); // prep + shipping
        blockEnd = rentalEnd.add(Duration(days: shippingBuffer + cleaningDays)); // shipping + cleaning
      } else {
        // Local: prep + rental + cleaning
        blockStart = rentalStart.subtract(const Duration(days: 1)); // just prep
        blockEnd = rentalEnd.add(Duration(days: cleaningDays));
      }
      
      if (_isInDateRange(date, blockStart, blockEnd)) {
        blockingBooking = booking;
        break;
      }
    }

    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final dateStr = '${date.day} ${turkishMonths[date.month - 1]} ${date.year}';
    
    String blockLabel;
    Color blockColor;
    String blockExplanation;
    switch (dayType) {
      case CalendarDayType.rental:
        blockLabel = 'Kirada (Müşteride)';
        blockColor = Colors.red.shade400;
        blockExplanation = 'Ürün bu tarihte kirada';
        break;
      case CalendarDayType.shippingBefore:
        blockLabel = 'Kargo (Gönderim)';
        blockColor = const Color(0xFF1E3A5F);
        blockExplanation = 'Ürün müşteriye gönderilmek üzere hazırlanıyor';
        break;
      case CalendarDayType.shippingAfter:
        blockLabel = 'Kargo (İade)';
        blockColor = const Color(0xFF1E3A5F);
        blockExplanation = 'Ürün müşteriden geri dönüyor';
        break;
      case CalendarDayType.preparation:
        blockLabel = 'Hazırlık';
        blockColor = const Color(0xFF8B5CF6);
        blockExplanation = 'Ürün bir sonraki kiralama için hazırlanıyor';
        break;
      case CalendarDayType.cleaning:
        blockLabel = 'Yıkama/Temizlik';
        blockColor = Colors.orange.shade400;
        blockExplanation = 'Ürün yıkama ve bakımda';
        break;
      case CalendarDayType.available:
        return; // Should not happen
    }

    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: blockColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_open, color: blockColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Tarihi Aç', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dateStr tarihini açmak istiyor musunuz?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: blockColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: blockColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sebep: $blockLabel', 
                          style: TextStyle(fontWeight: FontWeight.w600, color: blockColor, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(blockExplanation,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        if (blockingBooking != null) ...[
                          const SizedBox(height: 4),
                          Text('Müşteri: ${blockingBooking.notes ?? "Belirtilmemiş"}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (dayType == CalendarDayType.rental)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Bu işlem kirayı ve tüm ilişkili günleri silecektir!', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Bu gün otomatik hesaplanır. Silmek için kira gününü seçin.', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (dayType == CalendarDayType.rental && blockingBooking != null) {
                // RENTAL DAY: Delete the entire booking (unlocks all related days)
                final success = await _dataService.deleteBooking(blockingBooking.id);
                if (success && mounted) {
                  onUnlock();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$dateStr ve ilişkili günler açıldı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                // NON-RENTAL DAY: Just refresh to update UI
                // These days are calculated, not stored - so we just confirm
                onUnlock();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$dateStr bilgi gösterildi'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: Text(
              dayType == CalendarDayType.rental ? 'Kirayı Sil' : 'Tamam',
              style: TextStyle(
                color: dayType == CalendarDayType.rental ? AppColors.error : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReorderCategoriesDialog() {
    List<CategoryModel> orderedCategories = List.from(_dataService.productCategories);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Kategori Sırası'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: orderedCategories.isEmpty
                ? const Center(child: Text('Kategori yok'))
                : ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: orderedCategories.length,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = orderedCategories.removeAt(oldIndex);
                        orderedCategories.insert(newIndex, item);
                      });
                    },
                    proxyDecorator: (child, index, animation) {
                      return Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
                    itemBuilder: (context, index) {
                      final cat = orderedCategories[index];
                      return Container(
                        key: ValueKey(cat.id),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${index + 1}. sıra', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.drag_handle, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _dataService.updateCategoryOrder(orderedCategories);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori sırası güncellendi')),
                  );
                }
              },
              child: Text('Kaydet', style: TextStyle(color: const Color(0xFFDC2626))),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteCategoryDialog(CategoryModel category) {
    // Check if category has products
    final productsInCategory = _dataService.getProductsByCategory(category.id);
    final hasProducts = productsInCategory.isNotEmpty;
    bool confirmed = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Kategori Sil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"${category.name}" silinsin mi?'),
              if (hasProducts) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu kategoride ${productsInCategory.length} ürün var!',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bu ürünler de silinecek. Bu işlem geri alınamaz.',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setDialogState(() => confirmed = !confirmed),
                  child: Row(
                    children: [
                      Checkbox(
                        value: confirmed,
                        onChanged: (val) => setDialogState(() => confirmed = val ?? false),
                        activeColor: AppColors.error,
                      ),
                      const Expanded(
                        child: Text(
                          'Okudum ve anladım, kategoriyi sil',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: (!hasProducts || confirmed) ? () async {
                Navigator.pop(context);
                await _dataService.removeCategory(category.id);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${category.name}" silindi')),
                  );
                }
              } : null,
              child: Text(
                'Sil',
                style: TextStyle(
                  color: (!hasProducts || confirmed) ? AppColors.error : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kategori Düzenle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Kategori Adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != category.name) {
                Navigator.pop(context);
                await _dataService.updateCategoryName(category.id, newName);
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kategori güncellendi: $newName')),
                  );
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Text('Kaydet', style: TextStyle(color: const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}
