import 'dart:io';
import '../models/dress_model.dart';
import '../models/review_model.dart';
import '../models/booking_model.dart';
import '../models/category_model.dart';
import '../models/maintenance_event_model.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

// Transaction Model
class TransactionModel {
  final String id;
  final String type; // 'kiralama' or 'satis' or 'gider'
  final String productName;
  final String? productId;
  final String? productImageUrl; // Product image for thumbnails
  final String? customerName;
  final String? customerPhone;
  final double amount;
  final double fullPrice;
  final double paidAmount;
  final DateTime date;
  final DateTime? rentalDate;
  final String? note;
  String status; // 'pending', 'completed', 'returned'

  double get remainingAmount => fullPrice - paidAmount;
  bool get isFullyPaid => paidAmount >= fullPrice;

  TransactionModel({
    required this.id,
    required this.type,
    required this.productName,
    this.productId,
    this.productImageUrl,
    this.customerName,
    this.customerPhone,
    required this.amount,
    required this.fullPrice,
    required this.paidAmount,
    required this.date,
    this.rentalDate,
    this.note,
    this.status = 'pending',
  });
}

class DataService {
  // Singleton pattern
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Supabase service instance
  final SupabaseService _supabase = SupabaseService();

  // Local cache lists (READ-ONLY - populated from Supabase)
  final List<TransactionModel> transactions = [];
  final List<DressModel> dresses = [];
  final List<ReviewModel> reviews = [];
  final List<BookingModel> bookings = [];
  final List<CategoryModel> productCategories = [];

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ============== DATA LOADING ==============

  // Clear all cached data
  void clearData() {
    transactions.clear();
    dresses.clear();
    reviews.clear();
    bookings.clear();
    productCategories.clear();
    print('DEBUG: DataService cleared all cached data');
  }

  // Load all user data from Supabase
  Future<void> loadUserData() async {
    if (_isLoading) return;
    _isLoading = true;
    
    print('DEBUG: Loading user data from Supabase...');
    clearData();
    
    try {
      await Future.wait([
        _loadProducts(),
        _loadBookings(),
        _loadTransactions(),
        _loadCategories(),
      ]);
      
      // Sort transactions by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      print('DEBUG: All data loaded successfully');
    } catch (e) {
      print('DEBUG: Error loading user data: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadProducts() async {
    final products = await _supabase.getProducts();
    dresses.clear();
    dresses.addAll(products);
    print('DEBUG: Loaded ${products.length} products');
  }

  Future<void> _loadBookings() async {
    final userBookings = await _supabase.getBookings();
    bookings.clear();
    bookings.addAll(userBookings);
    print('DEBUG: Loaded ${userBookings.length} bookings');
  }

  Future<void> _loadTransactions() async {
    final userTransactions = await _supabase.getTransactions();
    transactions.clear();
    
    for (final tx in userTransactions) {
      // Extract product image from joined products -> product_images
      String? productImageUrl;
      final productsData = tx['products'];
      
      if (productsData != null && productsData is Map) {
        final productImages = productsData['product_images'];
        if (productImages is List && productImages.isNotEmpty) {
          productImageUrl = productImages.first['image_url']?.toString();
        }
      }
      
      // Fallback: If no image from Supabase, try to find from product name
      final productName = tx['product_name'] ?? '';
      if (productImageUrl == null) {
        // Clean product name (remove suffixes like "(Kalan Ödeme)")
        String searchName = productName;
        if (searchName.contains('(Kalan Ödeme)')) {
          searchName = searchName.replaceAll(' (Kalan Ödeme)', '');
        }
        
        // Try to find matching product by name (case-insensitive)
        final matchingProduct = dresses.where((d) => 
          d.title.toLowerCase() == searchName.toLowerCase() ||
          d.title.toLowerCase().contains(searchName.toLowerCase()) ||
          searchName.toLowerCase().contains(d.title.toLowerCase())
        ).firstOrNull;
        
        if (matchingProduct != null && matchingProduct.images.isNotEmpty) {
          productImageUrl = matchingProduct.images.first;
        }
      }
      
      transactions.add(TransactionModel(
        id: tx['id'] ?? '',
        type: tx['transaction_type'] ?? tx['type'] ?? 'kiralama',
        productName: productName,
        productId: tx['product_id'],
        productImageUrl: productImageUrl,
        customerName: tx['customer_name'],
        customerPhone: tx['customer_phone'],
        amount: (tx['amount'] ?? 0).toDouble(),
        fullPrice: (tx['full_price'] ?? tx['amount'] ?? 0).toDouble(),
        paidAmount: (tx['paid_amount'] ?? tx['amount'] ?? 0).toDouble(),
        date: tx['created_at'] != null ? DateTime.parse(tx['created_at']) : DateTime.now(),
        rentalDate: tx['rental_date'] != null ? DateTime.parse(tx['rental_date']) : null,
        note: tx['note'],
        status: tx['status'] ?? 'pending',
      ));
    }
    print('DEBUG: Loaded ${transactions.length} transactions');
  }

  Future<void> _loadCategories() async {
    final userCategories = await _supabase.getCategories();
    productCategories.clear();
    productCategories.addAll(userCategories);
    print('DEBUG: Loaded ${userCategories.length} categories');
  }

  // Refresh specific data types
  Future<void> refreshTransactions() async {
    await _loadTransactions();
  }

  Future<void> refreshBookings() async {
    await _loadBookings();
  }

  Future<void> refreshProducts() async {
    await _loadProducts();
  }

  // ============== TRANSACTIONS (Optimistic Updates) ==============

  Future<bool> addTransaction({
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
    final finalStatus = amount >= fullPrice ? 'completed' : status;
    
    // If productId is provided and no imageUrl, try to get it from the product
    String? imageUrl = productImageUrl;
    if (imageUrl == null && productId != null) {
      final product = dresses.where((d) => d.id == productId).firstOrNull;
      if (product != null && product.images.isNotEmpty) {
        imageUrl = product.images.first;
      }
    }
    
    // 1. OPTIMISTIC UPDATE: Add to local cache immediately (instant UI)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final newTransaction = TransactionModel(
      id: tempId,
      type: type,
      productName: productName,
      productId: productId,
      productImageUrl: imageUrl,
      customerName: customerName,
      customerPhone: customerPhone,
      amount: amount,
      fullPrice: fullPrice,
      paidAmount: amount,
      date: DateTime.now(),
      rentalDate: rentalDate,
      note: note,
      status: finalStatus,
    );
    transactions.insert(0, newTransaction); // Add at top of list
    
    // 2. BACKGROUND SYNC: Send to Supabase
    try {
      final realId = await _supabase.addTransaction(
        type: type,
        productName: productName,
        productId: productId,
        customerName: customerName,
        customerPhone: customerPhone,
        amount: amount,
        fullPrice: fullPrice,
        rentalDate: rentalDate,
        note: note,
        status: finalStatus,
      );
      
      // 3. Replace temp ID with real ID (silent update)
      if (realId != null) {
        final index = transactions.indexWhere((t) => t.id == tempId);
        if (index != -1) {
          transactions[index] = TransactionModel(
            id: realId,
            type: type,
            productName: productName,
            productId: productId,
            productImageUrl: imageUrl,
            customerName: customerName,
            customerPhone: customerPhone,
            amount: amount,
            fullPrice: fullPrice,
            paidAmount: amount,
            date: DateTime.now(),
            rentalDate: rentalDate,
            note: note,
            status: finalStatus,
          );
        }
      }
      return true;
    } catch (e) {
      // 4. ROLLBACK on error: Remove from local cache
      print('Error adding transaction: $e');
      transactions.removeWhere((t) => t.id == tempId);
      return false;
    }
  }

  // Update transaction status (for cancellation, completion, etc.)
  Future<bool> updateTransactionStatus(String transactionId, String status) async {
    final tx = getTransaction(transactionId);
    if (tx == null) return false;
    
    final originalStatus = tx.status;
    tx.status = status;
    
    try {
      await _supabase.updateTransactionStatus(transactionId, status);
      print('DEBUG: Transaction $transactionId status updated to $status');
      return true;
    } catch (e) {
      print('Error updating transaction status: $e');
      tx.status = originalStatus;
      return false;
    }
  }

  Future<bool> completeRental(String transactionId) async {
    final tx = getTransaction(transactionId);
    if (tx == null) return false;
    
    // 1. OPTIMISTIC UPDATE: Update local cache immediately
    final originalStatus = tx.status;
    tx.status = 'completed';
    
    final remaining = tx.remainingAmount;
    TransactionModel? newTx;
    
    if (remaining > 0) {
      // Add kalan ödeme to local cache immediately
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      newTx = TransactionModel(
        id: tempId,
        type: 'kiralama',
        productName: '${tx.productName} (Kalan Ödeme)',
        productId: tx.productId,
        productImageUrl: tx.productImageUrl,
        customerName: tx.customerName,
        customerPhone: tx.customerPhone,
        amount: remaining,
        fullPrice: remaining,
        paidAmount: remaining,
        date: DateTime.now(),
        rentalDate: tx.rentalDate,
        note: 'Kapora tamamlama ödemesi',
        status: 'completed',
      );
      transactions.insert(0, newTx);
    }
    
    // 2. BACKGROUND SYNC
    try {
      if (remaining > 0) {
        await _supabase.addTransaction(
          type: 'kiralama',
          productName: '${tx.productName} (Kalan Ödeme)',
          productId: tx.productId,
          customerName: tx.customerName,
          customerPhone: tx.customerPhone,
          amount: remaining,
          fullPrice: remaining,
          rentalDate: tx.rentalDate,
          note: 'Kapora tamamlama ödemesi',
          status: 'completed',
        );
      }
      
      await _supabase.updateTransactionStatus(transactionId, 'completed', paidAmount: tx.fullPrice);
      
      // Update booking if exists
      if (tx.productId != null && tx.rentalDate != null) {
        final booking = bookings.where((b) => 
          b.dressId == tx.productId &&
          b.startDate.year == tx.rentalDate!.year &&
          b.startDate.month == tx.rentalDate!.month &&
          b.startDate.day == tx.rentalDate!.day
        ).firstOrNull;
        
        if (booking != null) {
          await _supabase.updateBookingStatus(booking.id, 'completed');
        }
      }
      
      return true;
    } catch (e) {
      // ROLLBACK on error
      print('Error completing rental: $e');
      tx.status = originalStatus;
      if (newTx != null) {
        transactions.removeWhere((t) => t.id == newTx!.id);
      }
      return false;
    }
  }

  Future<bool> returnRental(String transactionId, {bool addToCleaningQueue = false}) async {
    final tx = getTransaction(transactionId);
    if (tx == null) return false;
    
    // 1. OPTIMISTIC UPDATE: Update local cache immediately
    final originalStatus = tx.status;
    tx.status = 'returned';
    
    // Also update local booking status
    BookingModel? booking;
    BookingStatus? originalBookingStatus;
    if (tx.productId != null && tx.rentalDate != null) {
      booking = bookings.where((b) => 
        b.dressId == tx.productId &&
        b.startDate.year == tx.rentalDate!.year &&
        b.startDate.month == tx.rentalDate!.month &&
        b.startDate.day == tx.rentalDate!.day
      ).firstOrNull;
      
      if (booking != null) {
        originalBookingStatus = booking.status;
        // Update booking in local list
        final bookingIndex = bookings.indexOf(booking);
        if (bookingIndex != -1) {
          bookings[bookingIndex] = booking.copyWith(status: BookingStatus.returned);
        }
      }
    }
    
    // 2. BACKGROUND SYNC
    try {
      await _supabase.updateTransactionStatus(transactionId, 'returned');
      
      if (booking != null) {
        await _supabase.updateBookingStatus(booking.id, 'returned');
        print('DEBUG: Booking marked as returned for ${tx.productName}');
        
        // 3. Optionally create maintenance event for cleaning period
        // This is now controlled by addToCleaningQueue parameter
        // End date is set far in future - user must manually mark as ready
        if (addToCleaningQueue && tx.productId != null) {
          final today = DateTime.now();
          final cleaningStart = DateTime(today.year, today.month, today.day);
          final farFutureDate = cleaningStart.add(const Duration(days: 365)); // 1 year
          
          await addMaintenanceEvent(
            productId: tx.productId!,
            startDate: cleaningStart,
            endDate: farFutureDate,
            description: 'Yıkama/Bakım (${tx.customerName ?? "Müşteri"} teslimi)',
          );
          print('DEBUG: Created cleaning maintenance (indefinite until marked ready)');
        }
      }
      
      return true;
    } catch (e) {
      // ROLLBACK on error
      print('Error returning rental: $e');
      tx.status = originalStatus;
      if (booking != null && originalBookingStatus != null) {
        final bookingIndex = bookings.indexWhere((b) => b.id == booking!.id);
        if (bookingIndex != -1) {
          bookings[bookingIndex] = booking.copyWith(status: originalBookingStatus);
        }
      }
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    // 1. OPTIMISTIC UPDATE: Remove from local cache immediately
    final index = transactions.indexWhere((t) => t.id == id);
    TransactionModel? removed;
    if (index != -1) {
      removed = transactions.removeAt(index);
    }
    
    // 2. BACKGROUND SYNC
    try {
      await _supabase.deleteTransaction(id);
      return true;
    } catch (e) {
      // ROLLBACK on error: Add back to local cache
      print('Error deleting transaction: $e');
      if (removed != null) {
        transactions.insert(index, removed);
      }
      return false;
    }
  }

  TransactionModel? getTransaction(String id) {
    try {
      return transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============== EXPENSES ==============

  Future<bool> addExpense({
    required String description,
    required double amount,
    DateTime? date,
    String? note,
  }) async {
    return await addTransaction(
      type: 'gider',
      productName: description,
      amount: amount,
      fullPrice: amount,
      rentalDate: date,
      note: note,
      status: 'completed',
    );
  }

  // ============== TRANSACTION QUERIES ==============

  List<TransactionModel> getTodayTransactions() {
    final now = DateTime.now();
    return transactions.where((t) => 
      t.date.year == now.year && 
      t.date.month == now.month && 
      t.date.day == now.day
    ).toList();
  }

  List<TransactionModel> getMonthTransactions() {
    final now = DateTime.now();
    return transactions.where((t) => 
      t.date.year == now.year && 
      t.date.month == now.month
    ).toList();
  }

  double getTodayKiralama() => getTodayTransactions()
      .where((t) => t.type == 'kiralama')
      .fold(0, (sum, t) => sum + t.amount);

  double getTodaySatis() => getTodayTransactions()
      .where((t) => t.type == 'satis')
      .fold(0, (sum, t) => sum + t.amount);

  double getTodayGider() => getTodayTransactions()
      .where((t) => t.type == 'gider')
      .fold(0, (sum, t) => sum + t.amount);

  double getMonthKiralama() => getMonthTransactions()
      .where((t) => t.type == 'kiralama')
      .fold(0, (sum, t) => sum + t.amount);

  double getMonthSatis() => getMonthTransactions()
      .where((t) => t.type == 'satis')
      .fold(0, (sum, t) => sum + t.amount);

  double getMonthGider() => getMonthTransactions()
      .where((t) => t.type == 'gider')
      .fold(0, (sum, t) => sum + t.amount);

  // Upcoming rentals - rentals that haven't been picked up yet
  // Includes all rentals where customer hasn't picked up, regardless of payment status
  List<TransactionModel> getUpcomingRentals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return transactions.where((t) => 
      t.type == 'kiralama' && 
      (t.status == 'pending' || t.status == 'completed') && // Both payment statuses
      !t.productName.contains('(Kalan Ödeme)') &&
      t.rentalDate != null &&
      // Rental date is today or in future, AND not yet picked up
      (t.rentalDate!.isAfter(today) || 
       (t.rentalDate!.year == today.year && t.rentalDate!.month == today.month && t.rentalDate!.day == today.day))
    ).where((t) => t.status != 'in_progress').toList(); // Exclude already picked up
  }

  // Active rentals - customer has picked up the product, not yet returned
  // Status must be 'in_progress' (set when customer picks up)
  List<TransactionModel> getActiveRentals() {
    return transactions.where((t) => 
      t.type == 'kiralama' && 
      t.status == 'in_progress' && // Customer has picked up
      !t.productName.contains('(Kalan Ödeme)')
    ).toList();
  }

  // Overdue rentals - bookings past their end date but not returned
  List<BookingModel> getOverdueRentals() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return bookings.where((b) => 
      (b.status == BookingStatus.inProgress || b.status == BookingStatus.completed) &&
      b.endDate.isBefore(today)
    ).toList();
  }

  // ============== MAINTENANCE EVENTS ==============

  Future<MaintenanceEvent?> addMaintenanceEvent({
    required String productId,
    required DateTime startDate,
    required DateTime endDate,
    String? description,
  }) async {
    try {
      final event = await _supabase.addMaintenanceEvent(
        productId: productId,
        startDate: startDate,
        endDate: endDate,
        description: description,
      );
      return event;
    } catch (e) {
      print('Error adding maintenance event: $e');
      return null;
    }
  }

  // One-tap: Send to cleaning (default 2 days)
  Future<bool> quickSendToCleaning(String productId) async {
    try {
      final event = await _supabase.quickAddMaintenance(productId);
      return event != null;
    } catch (e) {
      print('Error sending to cleaning: $e');
      return false;
    }
  }

  // One-tap: Mark as ready (clear all maintenance)
  Future<bool> markProductReady(String productId) async {
    try {
      return await _supabase.clearAllMaintenanceForProduct(productId);
    } catch (e) {
      print('Error marking ready: $e');
      return false;
    }
  }

  // Delete specific maintenance event by ID
  Future<bool> deleteMaintenanceEvent(String eventId) async {
    try {
      return await _supabase.deleteMaintenanceEvent(eventId);
    } catch (e) {
      print('Error deleting maintenance event: $e');
      return false;
    }
  }

  // Get maintenance events for a specific product
  Future<List<MaintenanceEvent>> getMaintenanceEventsForProduct(String productId) async {
    try {
      return await _supabase.getMaintenanceEventsForProduct(productId);
    } catch (e) {
      print('Error getting maintenance events: $e');
      return [];
    }
  }

  // ============== CATEGORIES (Backend-First) ==============

  Future<bool> addCategory(String name, String icon) async {
    try {
      await _supabase.addCategory(name: name, icon: icon);
      await _loadCategories();
      return true;
    } catch (e) {
      print('Error adding category: $e');
      return false;
    }
  }

  Future<bool> removeCategory(String id) async {
    try {
      await _supabase.deleteCategory(id);
      await _loadCategories();
      return true;
    } catch (e) {
      print('Error removing category: $e');
      return false;
    }
  }

  Future<bool> updateCategoryName(String id, String newName) async {
    try {
      await _supabase.updateCategory(id, name: newName);
      await _loadCategories();
      return true;
    } catch (e) {
      print('Error updating category name: $e');
      return false;
    }
  }

  Future<bool> updateCategoryIcon(String id, String newIcon) async {
    try {
      await _supabase.updateCategory(id, icon: newIcon);
      await _loadCategories();
      return true;
    } catch (e) {
      print('Error updating category icon: $e');
      return false;
    }
  }

  Future<bool> updateCategoryOrder(List<CategoryModel> orderedCategories) async {
    try {
      for (int i = 0; i < orderedCategories.length; i++) {
        await _supabase.updateCategory(orderedCategories[i].id, sortOrder: i);
      }
      await _loadCategories();
      return true;
    } catch (e) {
      print('Error updating category order: $e');
      return false;
    }
  }

  List<DressModel> getProductsByCategory(String categoryId) {
    if (categoryId == 'all') return dresses;
    return dresses.where((d) => d.categoryId == categoryId).toList();
  }

  // ============== PRODUCTS (Backend-First) ==============

  Future<String?> addProduct({
    required String title,
    required String categoryId,
    required double pricePerDay,
    double? originalPrice,
    double salePrice = 0,
    String? description,
    List<String>? images,
    List<String>? availableSizes,
    String? color,
    String? colorHex,
    List<String>? tags,
    int stockCount = 1,
  }) async {
    try {
      final id = await _supabase.addProduct(
        title: title,
        categoryId: categoryId,
        pricePerDay: pricePerDay,
        originalPrice: originalPrice,
        salePrice: salePrice,
        description: description,
        stockCount: stockCount,
      );
      
      // Upload images if provided (with 30 second timeout per image)
      if (images != null && images.isNotEmpty) {
        for (final imagePath in images) {
          try {
            final file = File(imagePath);
            if (await file.exists()) {
              await _supabase.uploadProductImage(id, file)
                  .timeout(const Duration(seconds: 30), onTimeout: () {
                print('DEBUG: Image upload timed out after 30 seconds');
                return ''; // Return empty string on timeout
              });
            }
          } catch (e) {
            print('DEBUG: Failed to upload image: $e');
            // Continue without image - product is already created
          }
        }
      }
      
      await refreshProducts();
      return id;
    } catch (e) {
      print('Error adding product: $e');
      return null;
    }
  }

  Future<bool> updateProduct(String id, {
    String? title,
    double? pricePerDay,
    double? salePrice,
    String? description,
    List<String>? images,
    int? stockCount,
  }) async {
    try {
      await _supabase.updateProduct(
        id,
        title: title,
        pricePerDay: pricePerDay,
        salePrice: salePrice,
        description: description,
        stockCount: stockCount,
      );
      await refreshProducts();
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> removeProduct(String id) async {
    try {
      await _supabase.deleteProduct(id);
      await refreshProducts();
      return true;
    } catch (e) {
      print('Error removing product: $e');
      return false;
    }
  }

  // ============== BOOKINGS (Backend-First) ==============

  Future<String?> createBooking({
    required String dressId,
    required String dressTitle,
    required String dressImage,
    required String selectedSize,
    required DateTime startDate,
    required DateTime endDate,
    required double pricePerDay,
    required double totalPrice,
    double depositAmount = 500,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? notes,
    bool isShipping = false, // true = şehir dışı, false = normal kiralama
    int? shippingBufferDays, // Custom buffer days for this booking
  }) async {
    try {
      final bookingId = await _supabase.createBooking(
        productId: dressId,
        productName: dressTitle,
        customerName: customerName,
        customerPhone: customerPhone,
        selectedSize: selectedSize,
        startDate: startDate,
        endDate: endDate,
        pricePerDay: pricePerDay,
        totalPrice: totalPrice,
        depositAmount: depositAmount,
        notes: notes,
        isShipping: isShipping,
        shippingBufferDays: shippingBufferDays,
      );
      
      await refreshBookings();
      
      // Schedule notifications for this booking
      if (bookingId != null) {
        await NotificationService().scheduleBookingNotifications(
          bookingId: bookingId,
          productName: dressTitle,
          rentalDate: startDate,
        );
      }
      
      return bookingId;
    } catch (e) {
      print('Error creating booking: $e');
      return null;
    }
  }

  Future<bool> completeBooking(String bookingId) async {
    try {
      await _supabase.updateBookingStatus(bookingId, 'completed');
      await refreshBookings();
      return true;
    } catch (e) {
      print('Error completing booking: $e');
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _supabase.updateBookingStatus(bookingId, 'cancelled');
      await refreshBookings();
      
      // Cancel scheduled notifications
      await NotificationService().cancelBookingNotifications(bookingId);
      
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  // Cancel booking by finding it via product ID and rental date
  Future<bool> cancelBookingByProductAndDate(String productId, DateTime rentalDate) async {
    try {
      // Find the booking matching this product and date
      final matchingBooking = bookings.firstWhere(
        (b) => b.dressId == productId && 
               b.startDate.year == rentalDate.year &&
               b.startDate.month == rentalDate.month &&
               b.startDate.day == rentalDate.day &&
               b.status != BookingStatus.cancelled &&
               b.status != BookingStatus.returned,
        orElse: () => throw Exception('Booking not found'),
      );
      
      await _supabase.updateBookingStatus(matchingBooking.id, 'cancelled');
      await refreshBookings();
      print('DEBUG: Cancelled booking ${matchingBooking.id} for product $productId on ${rentalDate.day}/${rentalDate.month}');
      return true;
    } catch (e) {
      print('Error cancelling booking by product/date: $e');
      return false;
    }
  }

  Future<bool> deleteBooking(String bookingId) async {
    try {
      await _supabase.deleteBooking(bookingId);
      bookings.removeWhere((b) => b.id == bookingId);
      return true;
    } catch (e) {
      print('Error deleting booking: $e');
      return false;
    }
  }

  // Mark all old bookings as returned (for cleanup)
  // Set forceAll=true to clean ALL active bookings regardless of date
  Future<int> cleanupOldBookingsForProduct(String productId, {bool forceAll = false}) async {
    int cleaned = 0;
    final activeBookings = getActiveBookingsForProduct(productId);
    
    for (final booking in activeBookings) {
      // If forceAll=true OR booking end date is in the past, mark as returned
      if (forceAll || booking.endDate.isBefore(DateTime.now())) {
        try {
          await _supabase.updateBookingStatus(booking.id, 'returned');
          final index = bookings.indexWhere((b) => b.id == booking.id);
          if (index != -1) {
            bookings[index] = booking.copyWith(status: BookingStatus.returned);
          }
          cleaned++;
          print('DEBUG: Cleaned up booking: ${booking.dressTitle} ${booking.startDate} - ${booking.endDate}');
        } catch (e) {
          print('Error cleaning booking: $e');
        }
      }
    }
    return cleaned;
  }

  // ============== BOOKING QUERIES ==============

  // Active bookings = product is with customer, not yet returned
  // confirmed = booking confirmed, pending pickup
  // inProgress = customer has the product
  // completed = payment done, product still with customer
  // Only cancelled, completed and returned bookings make dates available again
  List<BookingModel> getActiveBookingsForProduct(String productId) {
    return bookings.where((b) =>
      b.dressId == productId &&
      b.status != BookingStatus.cancelled &&
      b.status != BookingStatus.completed &&  // Payment done = dates available
      b.status != BookingStatus.returned  // Returned = available again
    ).toList();
  }

  Set<DateTime> getBookedDatesForProduct(String productId) {
    final activeBookings = getActiveBookingsForProduct(productId);
    final bookedDates = <DateTime>{};
    
    // DEBUG: Show which bookings are blocking dates
    if (activeBookings.isNotEmpty) {
      print('DEBUG: Active bookings blocking dates for product $productId:');
      for (final booking in activeBookings) {
        print('  - ${booking.dressTitle}: ${booking.startDate.day}/${booking.startDate.month} - ${booking.endDate.day}/${booking.endDate.month}, status: ${booking.status}');
      }
    }
    
    for (final booking in activeBookings) {
      for (var date = booking.startDate;
          date.isBefore(booking.endDate.add(const Duration(days: 1)));
          date = date.add(const Duration(days: 1))) {
        bookedDates.add(DateTime(date.year, date.month, date.day));
      }
    }
    
    return bookedDates;
  }

  int getAvailableStockCount(String productId, DateTime start, DateTime end) {
    final product = getDressById(productId);
    if (product == null) return 0;
    
    final activeBookings = getActiveBookingsForProduct(productId);
    int overlappingBookings = 0;
    
    for (final booking in activeBookings) {
      // Range intersection check
      if (start.isBefore(booking.endDate.add(const Duration(days: 1))) &&
          end.isAfter(booking.startDate.subtract(const Duration(days: 1)))) {
        overlappingBookings++;
      }
    }
    
    return (product.stockCount - overlappingBookings).clamp(0, product.stockCount);
  }

  bool isProductAvailable(String productId, DateTime start, DateTime end) {
    return getAvailableStockCount(productId, start, end) > 0;
  }

  /// Get detailed stock availability with inventory pool math
  Future<StockAvailabilityResult> getStockAvailability(String productId, DateTime start, DateTime end) {
    return _supabase.getStockAvailability(productId, start, end);
  }

  BookingModel? getBookingById(String id) {
    try {
      return bookings.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  // ============== STATIC DATA ==============

  final List<String> categories = [
    'Tümü',
    'Gece Elbiseleri',
    'Düğün Abiyeleri',
    'Kokteyl Elbiseleri',
    'Nişan Elbiseleri',
    'Mezuniyet Elbiseleri',
  ];

  final List<String> styles = [
    'Gece',
    'Düğün',
    'Kokteyl',
    'Nişan',
    'Mezuniyet',
  ];

  final List<String> allSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  final List<Map<String, String>> colors = [
    {'name': 'Siyah', 'hex': '#000000'},
    {'name': 'Beyaz', 'hex': '#FFFFFF'},
    {'name': 'Kırmızı', 'hex': '#FF0000'},
    {'name': 'Bordo', 'hex': '#800020'},
    {'name': 'Lacivert', 'hex': '#000080'},
    {'name': 'Yeşil', 'hex': '#008000'},
    {'name': 'Altın', 'hex': '#FFD700'},
    {'name': 'Gümüş', 'hex': '#C0C0C0'},
    {'name': 'Pembe', 'hex': '#FFC0CB'},
    {'name': 'Mor', 'hex': '#800080'},
  ];

  // ============== HELPER METHODS ==============

  DressModel? getDressById(String id) {
    try {
      return dresses.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ReviewModel> getReviewsForDress(String dressId) {
    return reviews.where((r) => r.dressId == dressId).toList();
  }

  List<DressModel> getFeaturedDresses() {
    return dresses.where((d) => d.rating >= 4.8).take(4).toList();
  }

  List<DressModel> getDressesByCategory(String category) {
    if (category == 'Tümü') return dresses;
    return dresses.where((d) => d.category == category).toList();
  }

  List<DressModel> searchDresses({
    String? query,
    String? category,
    String? style,
    String? size,
    double? minPrice,
    double? maxPrice,
  }) {
    return dresses.where((dress) {
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!dress.title.toLowerCase().contains(q) &&
            !dress.designer.toLowerCase().contains(q) &&
            !dress.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (category != null && category != 'Tümü' && dress.category != category) {
        return false;
      }
      if (style != null && dress.style != style) {
        return false;
      }
      if (size != null && !dress.availableSizes.contains(size)) {
        return false;
      }
      if (minPrice != null && dress.pricePerDay < minPrice) {
        return false;
      }
      if (maxPrice != null && dress.pricePerDay > maxPrice) {
        return false;
      }
      return true;
    }).toList();
  }

  void toggleFavorite(String dressId) {
    final index = dresses.indexWhere((d) => d.id == dressId);
    if (index != -1) {
      dresses[index] = dresses[index].copyWith(
        isFavorite: !dresses[index].isFavorite,
      );
    }
  }

  List<DressModel> getFavorites() {
    return dresses.where((d) => d.isFavorite).toList();
  }
}
