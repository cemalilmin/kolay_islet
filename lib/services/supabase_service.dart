import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dress_model.dart';
import '../models/booking_model.dart';
import '../models/category_model.dart';
import '../models/maintenance_event_model.dart';
import '../config/supabase_config.dart';
import 'settings_service.dart';
import 'image_helper.dart';

/// 3-Level Availability Status for Pool Inventory
enum AvailabilityStatus {
  available,    // GREEN - At least 1 unit free, allow booking
  hardBlocked,  // RED - ALL units rented by customers, no override
  softBlocked,  // ORANGE - Units in maintenance/buffer, allow override
}

// Legacy alias for backward compatibility
typedef ProductAvailability = AvailabilityStatus;

/// Detailed stock availability result for pool inventory logic
/// Formula: Available = TotalStock - (RentedCount + MaintenanceCount)
class StockAvailabilityResult {
  final int totalStock;
  final int rentedCount;      // Hard blocks - customer has the item
  final int maintenanceCount; // Soft blocks - cleaning/repair/buffer
  final AvailabilityStatus status;
  final String? conflictingMaintenanceId; // ID of maintenance to cancel for override
  
  const StockAvailabilityResult({
    required this.totalStock,
    required this.rentedCount,
    required this.maintenanceCount,
    required this.status,
    this.conflictingMaintenanceId,
  });
  
  /// Total occupied units (rentals + maintenance)
  int get occupiedCount => rentedCount + maintenanceCount;
  
  /// Available units = Total - Occupied
  int get availableCount => (totalStock - occupiedCount).clamp(0, totalStock);
  
  /// True if at least 1 unit is available
  bool get hasAvailable => availableCount > 0;
  
  /// True if can override (soft blocked by maintenance, not full rentals)
  bool get canOverride => status == AvailabilityStatus.softBlocked && maintenanceCount > 0;
  
  /// Is this a hard block (no override possible)?
  bool get isHardBlocked => status == AvailabilityStatus.hardBlocked;
  
  /// Is this a soft block (override possible)?
  bool get isSoftBlocked => status == AvailabilityStatus.softBlocked;
  
  /// Display string: "2 / 3 Mevcut"
  String get displayText => '$availableCount / $totalStock Mevcut';
  
  /// Reason why blocked
  String get blockReason {
    if (status == AvailabilityStatus.available) return '';
    if (status == AvailabilityStatus.hardBlocked) {
      return 'Tüm $totalStock adet kirada';
    }
    return '$rentedCount kirada, $maintenanceCount temizlikte';
  }
}

/// Fallback constants (used if SettingsService not initialized)
const kDefaultCleaningDuration = Duration(days: 2);
const kDefaultShippingBufferDays = 3;

/// Get cleaning duration from settings (dynamic)
Duration get kCleaningDuration {
  try {
    return SettingsService().cleaningDuration;
  } catch (_) {
    return kDefaultCleaningDuration;
  }
}

/// Get shipping buffer from settings (dynamic)
int get kShippingBufferDays {
  try {
    return SettingsService().shippingBufferDays;
  } catch (_) {
    return kDefaultShippingBufferDays;
  }
}



class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Lazy getter - only accesses Supabase when needed, not at class instantiation
  // All methods have try/catch so this will gracefully fail if Supabase is not initialized
  SupabaseClient get _client => Supabase.instance.client;

  // ============== CATEGORIES ==============

  Future<List<CategoryModel>> getCategories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Try with sort_order first, fallback to created_at if column doesn't exist
      List<dynamic> response;
      try {
        response = await _client.from('user_categories')
            .select()
            .eq('user_id', userId)
            .order('sort_order', ascending: true);
      } catch (e) {
        // sort_order column might not exist, fallback to created_at
        response = await _client.from('user_categories')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: true);
      }
      return response.map((json) => CategoryModel(
        id: json['id'],
        name: json['name'] ?? '',
        icon: json['icon'] ?? '📦',
        productCount: 0,
      )).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<void> addCategory({required String name, required String icon}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      await _client.from('user_categories').insert({
        'user_id': userId,
        'name': name,
        'icon': icon,
      });
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _client.from('user_categories').delete().eq('id', id);
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> updateCategory(String id, {String? name, String? icon, int? sortOrder}) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (icon != null) data['icon'] = icon;
      if (sortOrder != null) data['sort_order'] = sortOrder;
      if (data.isNotEmpty) {
        await _client.from('user_categories').update(data).eq('id', id);
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // ============== PRODUCTS ==============

  Future<List<DressModel>> getProducts() async {
    if (_currentUserId == null) return [];
    
    try {
      final response = await _client.from('products')
          .select('*, product_images(*)')
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) {
        final images = (json['product_images'] as List?)
            ?.map<String>((img) => img['image_url'] as String)
            .toList() ?? [];
        
        return DressModel(
          id: json['id'],
          title: json['name'] ?? '',
          designer: '',
          images: images,
          pricePerDay: (json['daily_price'] ?? json['price_per_day'] ?? 0).toDouble(),
          originalPrice: (json['original_price'] ?? 0).toDouble(),
          salePrice: (json['sale_price'] ?? 0).toDouble(),
          availableSizes: List<String>.from(json['b_sizes'] ?? ['S', 'M', 'L']),
          color: json['color'] ?? 'Standart',
          colorHex: json['color_hex'] ?? '#808080',
          style: json['style'] ?? '',
          rating: (json['rating'] ?? 0).toDouble(),
          reviewCount: json['review_count'] ?? 0,
          description: json['description'] ?? '',
          tags: List<String>.from(json['tags'] ?? []),
          category: json['category_name'] ?? json['category_id'] ?? 'abiye',
          categoryId: json['category_name'] ?? json['category_id'] ?? 'abiye',
          stockCount: json['total_stock'] ?? json['stock_count'] ?? 1,
        );
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<List<DressModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _client.from('products')
          .select('*, product_images(*)')
          .eq('category_id', categoryId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) {
        final images = (json['product_images'] as List?)
            ?.map<String>((img) => img['image_url'] as String)
            .toList() ?? [];
        
        return DressModel(
          id: json['id'],
          title: json['title'] ?? '',
          designer: '',
          images: images,
          pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
          originalPrice: (json['original_price'] ?? 0).toDouble(),
          availableSizes: List<String>.from(json['available_sizes'] ?? ['S', 'M', 'L']),
          color: json['color'] ?? 'Standart',
          colorHex: json['color_hex'] ?? '#808080',
          style: json['style'] ?? '',
          rating: (json['rating'] ?? 0).toDouble(),
          reviewCount: json['review_count'] ?? 0,
          description: json['description'] ?? '',
          tags: List<String>.from(json['tags'] ?? []),
          category: json['category_id'] ?? '',
          categoryId: json['category_id'] ?? '',
          stockCount: json['stock_count'] ?? 1,
        );
      }).toList();
    } catch (e) {
      print('Error fetching products by category: $e');
      return [];
    }
  }

  Future<String> addProduct({
    required String title,
    required String categoryId,
    required double pricePerDay,
    double? originalPrice,
    double? salePrice,
    String? description,
    int stockCount = 1,
  }) async {
    if (_currentUserId == null) throw Exception('User not logged in');
    
    try {
      
      final data = <String, dynamic>{
        'user_id': _currentUserId,
        'name': title,
        'daily_price': pricePerDay,
        'original_price': originalPrice ?? pricePerDay * 5,
        'sale_price': salePrice ?? 0,
        'description': description ?? '',
        'total_stock': stockCount,
        'size': 'M',
        'category_name': categoryId, // Store category string ID for filtering
      };
      
      final response = await _client.from('products').insert(data).select().single();
      
      return response['id'];
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(String id, {
    String? title,
    double? pricePerDay,
    double? salePrice,
    String? description,
    int? stockCount,
  }) async {
    print('DEBUG: updateProduct called - id: $id, pricePerDay: $pricePerDay, salePrice: $salePrice, stockCount: $stockCount');
    
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updates['name'] = title;
      if (pricePerDay != null) updates['daily_price'] = pricePerDay;
      if (salePrice != null) updates['sale_price'] = salePrice;
      if (description != null) updates['description'] = description;
      if (stockCount != null) updates['total_stock'] = stockCount;

      await _client.from('products').update(updates).eq('id', id);
      print('DEBUG: Product updated successfully');
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // ============== PRODUCT IMAGES ==============

  Future<String> uploadProductImage(String productId, File imageFile) async {
    try {
      // 🔥 Compress image before upload (10MB → ~300KB)
      final compressedFile = await ImageHelper().compressImage(imageFile);
      final fileToUpload = compressedFile ?? imageFile;
      
      final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from(SupabaseConfig.productImagesBucket)
          .upload(fileName, fileToUpload);
      
      final imageUrl = _client.storage
          .from(SupabaseConfig.productImagesBucket)
          .getPublicUrl(fileName);
      
      // Save image reference to database
      await _client.from('product_images').insert({
        'product_id': productId,
        'image_url': imageUrl,
        'display_order': 0,
      });
      
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // ============== BOOKINGS ==============

  // Helper to parse shipping info from notes
  Map<String, dynamic> _parseShippingFromNotes(String? notes) {
    if (notes == null) return {'isShipping': false, 'bufferDays': null};
    
    // Check for [SHIPPING:X] format first
    final shippingMatch = RegExp(r'\[SHIPPING:(\d+)\]').firstMatch(notes);
    if (shippingMatch != null) {
      return {
        'isShipping': true,
        'bufferDays': int.tryParse(shippingMatch.group(1) ?? '3') ?? 3,
      };
    }
    
    // Legacy [SHIPPING] format (no buffer specified)
    if (notes.contains('[SHIPPING]')) {
      return {'isShipping': true, 'bufferDays': null};
    }
    
    return {'isShipping': false, 'bufferDays': null};
  }

  Future<List<BookingModel>> getBookings() async {
    if (_currentUserId == null) return [];
    
    try {
      final response = await _client.from('bookings')
          .select('*, products(name)')
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) {
        final productName = json['products']?['name'] ?? json['product_name'] ?? '';
        final shippingInfo = _parseShippingFromNotes(json['notes']);
        return BookingModel(
          id: json['id'],
          dressId: json['product_id'] ?? '',
          dressTitle: productName,
          dressImage: '',
          selectedSize: json['selected_size'] ?? 'M',
          startDate: DateTime.parse(json['start_date']),
          endDate: DateTime.parse(json['end_date']),
          pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
          totalPrice: (json['total_price'] ?? 0).toDouble(),
          depositAmount: (json['deposit_amount'] ?? 0).toDouble(),
          status: _parseBookingStatus(json['status']),
          createdAt: DateTime.parse(json['created_at']),
          notes: json['notes'],
          isShipping: shippingInfo['isShipping'],
          shippingBufferDays: shippingInfo['bufferDays'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  Future<List<BookingModel>> getActiveBookingsForProduct(String productId) async {
    try {
      final response = await _client.from('bookings')
          .select()
          .eq('product_id', productId)
          .not('status', 'in', '("cancelled","completed","returned")');
      
      return (response as List).map((json) {
        final shippingInfo = _parseShippingFromNotes(json['notes']);
        return BookingModel(
          id: json['id'],
          dressId: json['product_id'] ?? '',
          dressTitle: '',
          dressImage: '',
          selectedSize: json['selected_size'] ?? 'M',
          startDate: DateTime.parse(json['start_date']),
          endDate: DateTime.parse(json['end_date']),
          pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
          totalPrice: (json['total_price'] ?? 0).toDouble(),
          depositAmount: (json['deposit_amount'] ?? 0).toDouble(),
          status: _parseBookingStatus(json['status']),
          createdAt: DateTime.parse(json['created_at']),
          notes: json['notes'],
          isShipping: shippingInfo['isShipping'],
          shippingBufferDays: shippingInfo['bufferDays'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching active bookings: $e');
      return [];
    }
  }

  Future<String?> createBooking({
    required String productId,
    String? productName,
    String? customerName,
    String? customerPhone,
    required String selectedSize,
    required DateTime startDate,
    required DateTime endDate,
    required double pricePerDay,
    required double totalPrice,
    double depositAmount = 0,
    String? notes,
    bool isShipping = false,
    int? shippingBufferDays, // Custom buffer days for this booking
  }) async {
    if (_currentUserId == null) return null;
    
    print('DEBUG: Creating booking for product: $productId (isShipping: $isShipping, bufferDays: $shippingBufferDays)');
    
    // Check if productId is a valid UUID
    final isUuid = productId.length == 36 && productId.contains('-');
    if (!isUuid) {
      print('DEBUG: Product ID is not a UUID, skipping Supabase booking');
      return null;
    }
    
    try {
      // Store isShipping and shippingBufferDays in notes since DB doesn't have these columns
      String notesWithShipping = notes ?? '';
      if (isShipping) {
        // Format: [SHIPPING:3] means shipping with 3 days buffer
        notesWithShipping = '${notesWithShipping} [SHIPPING:${shippingBufferDays ?? 3}]'.trim();
      }
      
      final response = await _client.from('bookings').insert({
        'user_id': _currentUserId,
        'product_id': productId,
        'product_name': productName,
        'customer_name': customerName ?? 'Müşteri',
        'customer_phone': customerPhone ?? '',
        'selected_size': selectedSize,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'price_per_day': pricePerDay,
        'total_price': totalPrice,
        'deposit_amount': depositAmount,
        'paid_amount': depositAmount,
        'status': 'confirmed',
        'notes': notesWithShipping,
      }).select('id').single();
      
      final bookingId = response['id'] as String;
      print('DEBUG: Booking created successfully with ID: $bookingId');
      return bookingId;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  Future<void> updateBookingStatus(String id, String status) async {
    try {
      await _client.from('bookings').update({'status': status}).eq('id', id);
    } catch (e) {
      print('Error updating booking status: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      await _client.from('bookings').delete().eq('id', id);
      print('DEBUG: Booking deleted from Supabase');
    } catch (e) {
      print('Error deleting booking: $e');
      rethrow;
    }
  }

  // ============== TRANSACTIONS ==============

  // Get current user ID helper
  String? get _currentUserId => _client.auth.currentUser?.id;

  Future<String?> addTransaction({
    required String type,
    required String productName,
    String? productId,
    String? productImageUrl,
    String? customerName,
    String? customerPhone,
    required double amount,
    required double fullPrice,
    DateTime? rentalDate,
    String? note,
    String status = 'pending',
  }) async {
    if (_currentUserId == null) return null;
    
    print('DEBUG: Adding transaction - type: $type, product: $productName, amount: $amount');
    
    try {
      // NOTE: product_image_url is stored locally but not in Supabase (column doesn't exist)
      // Image URLs are retrieved from products table via product_id join
      final response = await _client.from('transactions').insert({
        'user_id': _currentUserId,
        'transaction_type': type,
        'product_name': productName,
        'product_id': productId,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'amount': amount,
        'full_price': fullPrice,
        'paid_amount': amount,
        'payment_method': 'nakit',
        'rental_date': rentalDate?.toIso8601String().split('T')[0],
        'note': note,
        'status': amount >= fullPrice ? 'completed' : status,
      }).select('id').single();
      
      final id = response['id'] as String;
      print('DEBUG: Transaction saved successfully with ID: $id');
      return id;
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions() async {
    if (_currentUserId == null) return [];
    
    try {
      final response = await _client.from('transactions')
          .select('*, products(product_images(image_url))')
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }
  
  Future<void> updateTransactionStatus(String id, String status, {double? paidAmount}) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (paidAmount != null) {
        data['paid_amount'] = paidAmount;
      }
      await _client.from('transactions').update(data).eq('id', id);
      print('DEBUG: Transaction status updated to $status');
    } catch (e) {
      print('Error updating transaction status: $e');
    }
  }
  
  Future<void> deleteTransaction(String id) async {
    try {
      await _client.from('transactions').delete().eq('id', id);
      print('DEBUG: Transaction deleted from Supabase');
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTodayTransactions() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
      
      final response = await _client.from('transactions')
          .select()
          .gte('transaction_date', startOfDay)
          .lte('transaction_date', endOfDay);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching today transactions: $e');
      return [];
    }
  }

  // ============== HELPERS ==============

  BookingStatus _parseBookingStatus(String? status) {
    switch (status) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'returned':
        return BookingStatus.returned;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  // ============== INVENTORY POOL LOGIC ==============
  
  /// Get detailed stock availability using inventory math
  /// Formula: Available = TotalStock - (RentedCount + MaintenanceCount)
  Future<StockAvailabilityResult> getStockAvailability(String productId, DateTime start, DateTime end) async {
    try {
      // 1. Fetch total stock
      final product = await _client.from('products')
          .select('stock_count')
          .eq('id', productId)
          .single();
      
      final totalStock = product['stock_count'] ?? 1;
      
      // 2. Count overlapping bookings (Range Intersection)
      final bookings = await _client.from('bookings')
          .select()
          .eq('product_id', productId)
          .not('status', 'in', '("cancelled","returned")')
          .lte('start_date', end.toIso8601String().split('T')[0])
          .gte('end_date', start.toIso8601String().split('T')[0]);
      
      final rentedCount = (bookings as List).length;
      
      // 3. Get overlapping maintenance events (need IDs for override)
      final maintenanceEvents = await getMaintenanceEventsForProduct(productId);
      final overlappingMaintenance = maintenanceEvents.where((m) => 
        m.overlapsWithRange(start, end)
      ).toList();
      final maintenanceCount = overlappingMaintenance.length;
      
      // Get first conflicting maintenance ID for override
      String? conflictingId;
      if (overlappingMaintenance.isNotEmpty) {
        conflictingId = overlappingMaintenance.first.id;
      }
      
      // 4. Calculate availability using Pool Math
      final occupiedCount = rentedCount + maintenanceCount;
      final availableCount = (totalStock - occupiedCount).clamp(0, totalStock);
      
      // 5. Determine 3-Level Status
      AvailabilityStatus status;
      if (availableCount > 0) {
        status = AvailabilityStatus.available; // GREEN - can rent
      } else if (rentedCount >= totalStock) {
        status = AvailabilityStatus.hardBlocked; // RED - all units with customers
      } else {
        status = AvailabilityStatus.softBlocked; // ORANGE - maintenance, can override
      }
      
      return StockAvailabilityResult(
        totalStock: totalStock,
        rentedCount: rentedCount,
        maintenanceCount: maintenanceCount,
        status: status,
        conflictingMaintenanceId: conflictingId,
      );
    } catch (e) {
      print('Error getting stock availability: $e');
      return StockAvailabilityResult(
        totalStock: 1,
        rentedCount: 0,
        maintenanceCount: 0,
        status: AvailabilityStatus.available,
      );
    }
  }

  // Check stock availability with soft blocking support (simplified wrapper)
  Future<ProductAvailability> checkProductAvailability(String productId, DateTime start, DateTime end) async {
    final result = await getStockAvailability(productId, start, end);
    return result.status;
  }

  // Legacy wrapper for backward compatibility
  Future<bool> isProductAvailable(String productId, DateTime start, DateTime end) async {
    final result = await getStockAvailability(productId, start, end);
    return result.hasAvailable || result.canOverride;
  }

  // One-tap maintenance - indefinite until marked as ready (1 year max)
  Future<MaintenanceEvent?> quickAddMaintenance(String productId, {String? description}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Set end date far in future - user must manually mark as ready
    final farFutureDate = today.add(const Duration(days: 365));
    return addMaintenanceEvent(
      productId: productId,
      startDate: today,
      endDate: farFutureDate,
      description: description ?? 'Temizlik/Bakım',
    );
  }

  // Instant "Mark as Ready" - clear all maintenance
  Future<bool> clearAllMaintenanceForProduct(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    
    try {
      await _client.from('maintenance_events')
          .delete()
          .eq('product_id', productId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error clearing maintenance: $e');
      return false;
    }
  }

  // Get booked dates for a product (includes maintenance dates)
  Future<Set<DateTime>> getBookedDatesForProduct(String productId) async {
    try {
      final product = await _client.from('products')
          .select('stock_count')
          .eq('id', productId)
          .single();
      
      final stockCount = product['stock_count'] ?? 1;
      
      final bookings = await getActiveBookingsForProduct(productId);
      final dateBookingCount = <DateTime, int>{};
      
      for (final booking in bookings) {
        for (var date = booking.startDate;
            date.isBefore(booking.endDate.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          final normalizedDate = DateTime(date.year, date.month, date.day);
          dateBookingCount[normalizedDate] = (dateBookingCount[normalizedDate] ?? 0) + 1;
        }
      }
      
      // Get booked dates where all stock is booked
      final bookedDates = dateBookingCount.entries
          .where((e) => e.value >= stockCount)
          .map((e) => e.key)
          .toSet();
      
      // Add maintenance dates
      final maintenanceEvents = await getMaintenanceEventsForProduct(productId);
      for (final event in maintenanceEvents) {
        for (var date = event.startDate;
            date.isBefore(event.endDate.add(const Duration(days: 1)));
            date = date.add(const Duration(days: 1))) {
          bookedDates.add(DateTime(date.year, date.month, date.day));
        }
      }
      
      return bookedDates;
    } catch (e) {
      print('Error getting booked dates: $e');
      return {};
    }
  }

  // ============== MAINTENANCE EVENTS ==============

  Future<List<MaintenanceEvent>> getMaintenanceEventsForProduct(String productId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      // Get maintenance events for this product (filtered by date on calendar display)
      final response = await _client.from('maintenance_events')
          .select()
          .eq('product_id', productId)
          .eq('user_id', userId);
      
      return (response as List)
          .map((json) => MaintenanceEvent.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting maintenance events: $e');
      return [];
    }
  }

  /// Get ALL active maintenance events for current user (for maintenance dashboard)
  Future<List<Map<String, dynamic>>> getAllMaintenanceEvents() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    
    try {
      final response = await _client.from('maintenance_events')
          .select('*, products(name, product_images(image_url))')
          .eq('user_id', userId)
          .gte('end_date', DateTime.now().toIso8601String().split('T')[0])
          .order('end_date', ascending: true);
      
      print('DEBUG: Maintenance events query returned ${(response as List).length} items');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting all maintenance events: $e');
      return [];
    }
  }

  Future<MaintenanceEvent?> addMaintenanceEvent({
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    
    try {
      final response = await _client.from('maintenance_events').insert({
        'product_id': productId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'description': description,
        'user_id': userId,
      }).select().single();
      
      return MaintenanceEvent.fromJson(response);
    } catch (e) {
      print('Error adding maintenance event: $e');
      return null;
    }
  }

  Future<bool> deleteMaintenanceEvent(String id) async {
    try {
      await _client.from('maintenance_events').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting maintenance event: $e');
      return false;
    }
  }
}
