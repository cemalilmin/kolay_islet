import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../models/booking_model.dart';
import '../widgets/smart_product_thumbnail.dart';
import 'profile_screen.dart';
import 'maintenance_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  
  // Start with cached values for instant display
  late String _storeName;
  late String _storeSlogan;

  // Real data from DataService - only kiralama and satis for pie chart
  double get kiralamaGelir => _dataService.getTodayKiralama();
  double get satisGelir => _dataService.getTodaySatis();
  
  // Expansion states for dashboard sections
  // Collapsed = 3 items, Expanded = 7 items
  bool _todayTransactionsExpanded = false;
  bool _upcomingRentalsExpanded = false;
  bool _activeRentalsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Use cached values immediately
    _storeName = _authService.cachedStoreName.isNotEmpty 
        ? _authService.cachedStoreName 
        : 'Mağaza İsmi';
    _storeSlogan = _authService.cachedStoreSlogan;
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
        _storeSlogan = profile['store_slogan']?.isNotEmpty == true 
            ? profile['store_slogan'] 
            : 'RENTAL BOUTIQUE';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header with store name
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⚠️ Overdue Alerts - at top for visibility
                  _buildOverdueAlerts(),

                  // Bugün Section with Pie Chart
                  _buildTodaySection(),

                  const SizedBox(height: 24),

                  // Bugünkü İşlemler
                  _buildTodayTransactions(),

                  const SizedBox(height: 24),

                  // Yaklaşan Kiralamalar
                  _buildUpcomingRentals(),

                  const SizedBox(height: 24),

                  // Kiradaki Ürünler (Ödeme tamam, teslim bekleniyor)
                  _buildActiveRentals(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueAlerts() {
    final overdueRentals = _dataService.getOverdueRentals();
    
    if (overdueRentals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Gecikmiş Teslimler (${overdueRentals.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Overdue cards
        ...overdueRentals.map((booking) => _buildOverdueCard(booking)),
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOverdueCard(BookingModel booking) {
    final now = DateTime.now();
    final daysOverdue = now.difference(booking.endDate).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Alert icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFFDC2626),
              size: 22,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.dressTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$daysOverdue gün gecikti',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bitiş: ${booking.endDate.day}/${booking.endDate.month}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action button
          GestureDetector(
            onTap: () => _handleOverdueReturn(booking),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Teslim Al',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleOverdueReturn(BookingModel booking) {
    // Find matching transaction for this booking
    final tx = _dataService.transactions.where((t) =>
      t.productId == booking.dressId &&
      t.type == 'kiralama' &&
      t.status == 'completed'
    ).firstOrNull;
    
    if (tx != null) {
      _showReturnConfirmDialog(tx);
    } else {
      // Direct booking return
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.assignment_return, color: Colors.green[600], size: 28),
              const SizedBox(width: 12),
              const Text('Teslim Al'),
            ],
          ),
          content: Text('${booking.dressTitle} ürününü teslim aldınız mı?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _dataService.refreshBookings();
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Teslim Al', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 44), // Spacer for balance
              Expanded(
                child: Column(
                  children: [
                    // Decorative line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.diamond_outlined, color: Colors.white.withOpacity(0.7), size: 14),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Store name
                    Text(
                      _storeName,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Subtitle
                    Text(
                      _storeSlogan.toUpperCase(),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 3,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Maintenance Button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MaintenancePage()),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.local_laundry_service, color: Colors.white, size: 20),
                ),
              ),
              // Profile Button
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
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection() {
    final total = kiralamaGelir + satisGelir;
    final hasData = total > 0;
    
    // Calculate percentages
    final kiralamaPercent = hasData ? (kiralamaGelir / total * 100).round() : 0;
    final satisPercent = hasData ? (satisGelir / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pie Chart with percentage labels
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Chart
                hasData
                  ? SizedBox(
                      width: 140,
                      height: 140,
                      child: CustomPaint(
                        painter: PieChartPainterSimple(
                          kiralama: kiralamaGelir / total,
                          satis: satisGelir / total,
                        ),
                      ),
                    )
                  : Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[200]!, width: 14),
                      ),
                    ),
                
                // Center content badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      total >= 1000000 ? '₺${(total / 1000000).toStringAsFixed(1)}M' : '₺${total.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                // Percentage labels moved to stats section
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUGÜN',
                  style: AppTextStyles.headlineSmall.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Calculate counts (exclude cancelled and kalan ödeme)
                Builder(builder: (context) {
                  final todayTransactions = _dataService.getTodayTransactions();
                  final kiralamaCount = todayTransactions.where((t) => 
                    t.type == 'kiralama' && 
                    t.status != 'cancelled' && 
                    !t.productName.contains('(Kalan Ödeme)')
                  ).length;
                  final satisCount = todayTransactions.where((t) => 
                    t.type == 'satis' && 
                    t.status != 'cancelled'
                  ).length;
                  
                  return Column(
                    children: [
                      _buildStatRowWithDetails('Kiralama', kiralamaGelir, kiralamaPercent, kiralamaCount, AppColors.chartKiralama),
                      const SizedBox(height: 8),
                      _buildStatRowWithDetails('Satış', satisGelir, satisPercent, satisCount, AppColors.chartSatis),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, double amount, Color color) {
    // Get background color based on the main color
    final isKiralama = color == AppColors.chartKiralama;
    final bgColor = isKiralama ? const Color(0xFFFAF5FF) : const Color(0xFFF0FDFA);
    final borderColor = isKiralama ? const Color(0xFFE9D5FF) : const Color(0xFFCCFBF1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          // Label and price in column to prevent text wrap
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+₺${amount.toInt()}',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatRowWithDetails(String label, double amount, int percent, int count, Color color) {
    final isKiralama = color == AppColors.chartKiralama;
    final bgColor = isKiralama ? const Color(0xFFFAF5FF) : const Color(0xFFF0FDFA);
    final borderColor = isKiralama ? const Color(0xFFE9D5FF) : const Color(0xFFCCFBF1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Color(0xFF374151))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    child: Text('%$percent', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 2),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '+${amount >= 1000000 ? '₺${(amount / 1000000).toStringAsFixed(1)}M' : '₺${amount.toInt()}'}',
                        style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('$count adet', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTransactions() {
    // Get real transactions from DataService
    final todayTransactions = _dataService.getTodayTransactions();
    
    // Fixed height per item (approximately 80 pixels per transaction item)
    const itemHeight = 80.0;
    // Container height: 3 items when collapsed, 7 items when expanded
    final maxVisibleItems = _todayTransactionsExpanded ? 7 : 3;
    final containerHeight = (todayTransactions.length.clamp(0, maxVisibleItems) * itemHeight).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clickable header to toggle expansion
        GestureDetector(
          onTap: () {
            setState(() {
              _todayTransactionsExpanded = !_todayTransactionsExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.today, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Bugünkü İşlemler',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (todayTransactions.length > 3) ...[
                  const SizedBox(width: 8),
                  Icon(
                    _todayTransactionsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 20,
                  ),
                  Text(
                    '(${todayTransactions.length})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (todayTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: AppColors.textLight),
                  const SizedBox(height: 8),
                  Text(
                    'Bugün henüz işlem yok',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: containerHeight,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: todayTransactions.length, // ALL items, scrollable
              itemBuilder: (context, index) {
                return _buildTransactionItemWithDelete(todayTransactions[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(String title, String customer, int amount, String type) {
    // Determine styling based on transaction type
    Color iconBgColor;
    IconData iconData;
    String typeLabel;
    Color typeLabelColor;
    String amountPrefix;
    Color amountColor;
    
    if (type == 'kiralama') {
      iconBgColor = AppColors.chartKiralama;
      iconData = Icons.calendar_today;
      typeLabel = 'Kiralama';
      typeLabelColor = AppColors.chartKiralama;
      amountPrefix = '+₺';
      amountColor = AppColors.success;
    } else if (type == 'satis') {
      iconBgColor = AppColors.chartSatis;
      iconData = Icons.sell;
      typeLabel = 'Satış';
      typeLabelColor = AppColors.chartSatis;
      amountPrefix = '+₺';
      amountColor = AppColors.success;
    } else {
      // gider
      iconBgColor = Colors.orange;
      iconData = Icons.receipt_long;
      typeLabel = 'Gider';
      typeLabelColor = Colors.orange;
      amountPrefix = '-₺';
      amountColor = Colors.red;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [iconBgColor, iconBgColor.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeLabelColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: typeLabelColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (type != 'gider') ...[
                      const SizedBox(width: 8),
                      Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          customer,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix$amount',
            style: AppTextStyles.titleMedium.copyWith(
              color: amountColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemWithDelete(TransactionModel tx) {
    // Determine styling based on transaction type
    Color iconBgColor;
    IconData iconData;
    String typeLabel;
    Color typeLabelColor;
    String amountPrefix;
    Color amountColor;
    
    if (tx.type == 'kiralama') {
      iconBgColor = AppColors.chartKiralama;
      iconData = Icons.calendar_today;
      typeLabel = 'Kiralama';
      typeLabelColor = AppColors.chartKiralama;
      amountPrefix = '+₺';
      amountColor = AppColors.success;
    } else if (tx.type == 'satis') {
      iconBgColor = AppColors.chartSatis;
      iconData = Icons.sell;
      typeLabel = 'Satış';
      typeLabelColor = AppColors.chartSatis;
      amountPrefix = '+₺';
      amountColor = AppColors.success;
    } else {
      // gider
      iconBgColor = Colors.orange;
      iconData = Icons.receipt_long;
      typeLabel = 'Gider';
      typeLabelColor = Colors.orange;
      amountPrefix = '-₺';
      amountColor = Colors.red;
    }
    
    return GestureDetector(
      onLongPress: () => _showDeleteConfirmationDashboard(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product image or fallback icon
            // Show product image if available, otherwise show icon
            (tx.productImageUrl != null && tx.productImageUrl!.isNotEmpty)
                ? SmartProductThumbnail(
                    imageUrl: tx.productImageUrl,
                    size: 48,
                    borderRadius: 12,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [iconBgColor, iconBgColor.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: Colors.white, size: 22),
                  ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.productName,
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeLabelColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: typeLabelColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      if (tx.type != 'gider' && tx.customerName != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            tx.customerName!,
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${tx.amount.toInt()}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Basılı tut: sil',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textLight,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDashboard(TransactionModel tx) {
    String typeLabel;
    if (tx.type == 'kiralama') {
      typeLabel = 'Kiralama';
    } else if (tx.type == 'satis') {
      typeLabel = 'Satış';
    } else {
      typeLabel = 'Gider';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('İşlemi Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bu işlemi silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.productName,
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('$typeLabel • ₺${tx.amount.toInt()}'),
                  if (tx.customerName != null)
                    Text('Müşteri: ${tx.customerName}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ Bu işlem geri alınamaz!',
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
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
              
              final success = await _dataService.deleteTransaction(tx.id);
              
              if (mounted) {
                setState(() {}); // Refresh UI
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(success ? Icons.delete : Icons.error, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(success ? '$typeLabel silindi' : 'Hata oluştu'),
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRentals() {
    final upcomingRentals = _dataService.getUpcomingRentals();
    
    // Fixed height per item (approximately 90 pixels per rental item)
    const itemHeight = 90.0;
    // Container height: 3 items when collapsed, 7 items when expanded
    final maxVisibleItems = _upcomingRentalsExpanded ? 7 : 3;
    final containerHeight = (upcomingRentals.length.clamp(0, maxVisibleItems) * itemHeight).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clickable header to toggle expansion
        GestureDetector(
          onTap: () {
            setState(() {
              _upcomingRentalsExpanded = !_upcomingRentalsExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Yaklaşan kiralamalar',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (upcomingRentals.length > 3) ...[
                  const SizedBox(width: 8),
                  Icon(
                    _upcomingRentalsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 20,
                  ),
                  Text(
                    '(${upcomingRentals.length})',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (upcomingRentals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 40, color: AppColors.textLight),
                  const SizedBox(height: 8),
                  Text(
                    'Yaklaşan kiralama yok',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: containerHeight,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: upcomingRentals.length, // ALL items, scrollable
              itemBuilder: (context, index) {
                return _buildUpcomingRentalItem(upcomingRentals[index]);
              },
            ),
          ),
      ],
    );
  }

  // Kiradaki Ürünler - ödeme tamam, müşteride olan ürünler
  Widget _buildActiveRentals() {
    final activeRentals = _dataService.getActiveRentals();
    
    // Fixed height per item (larger because of customer info + return button)
    const itemHeight = 180.0;
    // Container height: 2 items when collapsed, 4 items when expanded
    final maxVisibleItems = _activeRentalsExpanded ? 4 : 2;
    final containerHeight = (activeRentals.length.clamp(0, maxVisibleItems) * itemHeight).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clickable header to toggle expansion
        GestureDetector(
          onTap: () {
            setState(() {
              _activeRentalsExpanded = !_activeRentalsExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[600]!, Colors.orange[400]!],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Kiradaki Ürünler',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activeRentals.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  if (activeRentals.length > 3) 
                    Icon(
                      _activeRentalsExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                      size: 20,
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeRentals.length}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (activeRentals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 40, color: AppColors.success),
                  const SizedBox(height: 8),
                  Text(
                    'Kirada ürün yok',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tüm ürünler mağazada',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: containerHeight,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: activeRentals.length, // ALL items, scrollable
              itemBuilder: (context, index) {
                return _buildActiveRentalItem(activeRentals[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActiveRentalItem(TransactionModel rental) {
    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final rentalDate = rental.rentalDate ?? rental.date;
    final dateStr = '${rentalDate.day} ${turkishMonths[rentalDate.month - 1]}';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Product image
              SmartProductThumbnail(
                imageUrl: rental.productImageUrl,
                size: 50,
                borderRadius: 14,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rental.productName,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₺${rental.fullPrice.toInt()}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Customer info
          if (rental.customerName != null || rental.customerPhone != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (rental.customerName != null)
                          Text(
                            rental.customerName!,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (rental.customerPhone != null)
                          Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                rental.customerPhone!,
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
            ),
          ],
          
          // Return button
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showReturnConfirmDialog(rental),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[400]!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_return, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Teslim Alındı',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  void _showReturnConfirmDialog(TransactionModel rental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.assignment_return, color: Colors.green[600], size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Teslim Al', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rental.productName,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            if (rental.customerName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Müşteri: ${rental.customerName}',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            
            // Two simple button options - no toggles, no date pickers
            Row(
              children: [
                // HAZIR - Ready to rent
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      
                      final success = await _dataService.returnRental(rental.id);
                      
                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                                const SizedBox(width: 10),
                                Flexible(child: Text(success ? '${rental.productName} hazır' : 'Hata')),
                              ],
                            ),
                            backgroundColor: success ? Colors.green[700] : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                          const SizedBox(height: 6),
                          Text(
                            'Hazır',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // TEMİZLİĞE GÖNDER - One-tap, no date picker
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      
                      final returnSuccess = await _dataService.returnRental(rental.id);
                      bool cleaningSuccess = false;
                      
                      if (returnSuccess && rental.productId != null) {
                        cleaningSuccess = await _dataService.quickSendToCleaning(rental.productId!);
                      }
                      
                      if (mounted) {
                        setState(() {});
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(cleaningSuccess ? Icons.local_laundry_service : Icons.error, color: Colors.white),
                                const SizedBox(width: 10),
                                Flexible(child: Text(cleaningSuccess ? '${rental.productName} temizliğe gönderildi (${SettingsService().cleaningDurationDays} gün)' : 'Hata')),
                              ],
                            ),
                            backgroundColor: cleaningSuccess ? Colors.orange[700] : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_laundry_service, color: Colors.orange[700], size: 28),
                          const SizedBox(height: 6),
                          Text(
                            'Temizlik',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingRentalItem(TransactionModel rental) {
    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final rentalDate = rental.rentalDate ?? rental.date;
    final dateStr = '${rentalDate.day} ${turkishMonths[rentalDate.month - 1]}';
    final remainingAmount = rental.fullPrice - rental.paidAmount;
    
    return GestureDetector(
      onTap: () => _showRentalDetailDialog(rental),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SmartProductThumbnail(
              imageUrl: rental.productImageUrl,
              size: 60,
              borderRadius: 8,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rental.productName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    dateStr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        rental.customerName ?? 'Müşteri',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (remainingAmount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Kalan: ₺${remainingAmount.toInt()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Tam Ödeme',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Teslim Et button - opens detail dialog
            GestureDetector(
              onTap: () => _showRentalDetailDialog(rental, isUpcoming: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Teslim Et',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  // Handle customer pickup - move from upcoming to active
  void _handlePickup(TransactionModel rental) async {
    // If there's remaining payment, ask for confirmation
    final remainingAmount = rental.fullPrice - rental.paidAmount;
    
    if (remainingAmount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kalan Ödeme'),
          content: Text('Müşteriden ₺${remainingAmount.toInt()} kalan ödeme alındı mı?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hayır'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Evet, Alındı', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // Record remaining payment with product image
      await _dataService.addTransaction(
        productName: '${rental.productName} (Kalan Ödeme)',
        productId: rental.productId,
        productImageUrl: rental.productImageUrl,
        amount: remainingAmount,
        fullPrice: remainingAmount,
        type: 'kiralama',
        status: 'completed',
      );
    }
    
    // Update status to in_progress (picked up)
    await _dataService.updateTransactionStatus(rental.id, 'in_progress');
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${rental.productName} teslim edildi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showRentalDetailDialog(TransactionModel rental, {bool isUpcoming = false}) {
    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final rentalDate = rental.rentalDate ?? rental.date;
    final dateStr = '${rentalDate.day} ${turkishMonths[rentalDate.month - 1]}';
    final hasRemainingPayment = rental.remainingAmount > 0;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header with product image
            Row(
              children: [
                Container(
                  width: 80,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: rental.productImageUrl != null && rental.productImageUrl!.isNotEmpty
                        ? Image.network(
                            rental.productImageUrl!,
                            width: 80,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.checkroom, size: 36, color: AppColors.textLight),
                          )
                        : const Icon(Icons.checkroom, size: 36, color: AppColors.textLight),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.productName,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.chartKiralama.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Kiralama',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.chartKiralama,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (hasRemainingPayment) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Kapora',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info Cards
            _buildDetailRow(Icons.calendar_today, 'Tarih', dateStr),
            _buildDetailRow(Icons.attach_money, 'Toplam Ücret', '₺${rental.fullPrice.toInt()}'),
            _buildDetailRow(Icons.payment, 'Ödenen', '₺${rental.paidAmount.toInt()}'),
            if (hasRemainingPayment)
              _buildDetailRow(Icons.money_off, 'Kalan', '₺${rental.remainingAmount.toInt()}', isWarning: true),
            _buildDetailRow(Icons.person, 'Müşteri', rental.customerName ?? 'Müşteri'),
            _buildDetailRow(Icons.phone, 'Telefon', rental.customerPhone ?? '-'),
            
            // Notes & Measurements
            if (rental.note != null && rental.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Notlar & Ölçüler',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rental.note!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[900],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (isUpcoming) {
                        // Upcoming rental - handle pickup (move to active)
                        Navigator.pop(context);
                        _handlePickup(rental);
                      } else if (hasRemainingPayment) {
                        // Show confirmation dialog for remaining payment
                        _showRemainingPaymentConfirmation(rental);
                      } else {
                        // Already fully paid, mark complete
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        final success = await _dataService.completeRental(rental.id);
                        
                        if (mounted) {
                          setState(() {}); // Refresh dashboard
                          messenger.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(success ? 'Kiralama tamamlandı' : 'Hata oluştu'),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUpcoming 
                              ? [Colors.green[600]!, Colors.green[400]!]
                              : [const Color(0xFFDC2626), const Color(0xFFB91C1C)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isUpcoming ? Colors.green[600]! : const Color(0xFFDC2626)).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isUpcoming ? Icons.local_shipping : Icons.check, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isUpcoming 
                                ? (hasRemainingPayment ? 'Teslimi Tamamla (₺${rental.remainingAmount.toInt()} kalan)' : 'Teslimi Tamamla')
                                : (hasRemainingPayment ? 'Tamamla (₺${rental.remainingAmount.toInt()})' : 'Tamamlandı'),
                            style: AppTextStyles.button.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Cancel Rental Button
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showCancelRentalDialog(rental),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.grey[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Kiralamayı İptal Et',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelRentalDialog(TransactionModel rental) {
    Navigator.pop(context); // Close detail dialog first
    
    final depositAmount = rental.paidAmount; // Kapora olarak alınan miktar
    final refundController = TextEditingController(text: depositAmount.toInt().toString());
    bool isRefunding = true; // Default: kapora iade edilecek
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red[600]),
              const SizedBox(width: 12),
              const Text('Kiralama İptali'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rental.productName} için kiralama iptal edilecek.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Deposit info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Alınan Kapora: ₺${depositAmount.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Text('Kapora iade edilecek mi?', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              
              // Refund options
              GestureDetector(
                onTap: () => setDialogState(() => isRefunding = true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRefunding ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRefunding ? Colors.green : Colors.grey[300]!,
                      width: isRefunding ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRefunding ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isRefunding ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text('Kapora iade edildi'),
                    ],
                  ),
                ),
              ),
              
              if (isRefunding) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: refundController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'İade Miktarı',
                    prefixText: '₺ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              GestureDetector(
                onTap: () => setDialogState(() => isRefunding = false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !isRefunding ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !isRefunding ? Colors.red : Colors.grey[300]!,
                      width: !isRefunding ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !isRefunding ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: !isRefunding ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text('Kapora iade edilmedi'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Vazgeç', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                
                final messenger = ScaffoldMessenger.of(context);
                
                // 1. Cancel the booking (this frees up the calendar)
                final rentalDate = rental.rentalDate ?? rental.date;
                if (rental.productId != null) {
                  await _dataService.cancelBookingByProductAndDate(rental.productId!, rentalDate);
                }
                
                // 2. If refunding, create a refund transaction (as expense/gider)
                if (isRefunding) {
                  final refundAmount = double.tryParse(refundController.text) ?? depositAmount;
                  await _dataService.addTransaction(
                    type: 'gider', // Use gider (expense) type for refunds
                    productName: 'Kira İptali Kapora İadesi',
                    productId: rental.productId,
                    productImageUrl: rental.productImageUrl,
                    customerName: rental.customerName,
                    customerPhone: rental.customerPhone,
                    amount: refundAmount, // Positive amount (will show as expense)
                    fullPrice: rental.fullPrice,
                    rentalDate: DateTime.now(),
                    note: 'Kiralama iptali - Kapora iade',
                  );
                }
                
                // 3. Mark original transaction as cancelled (so it won't show in upcoming)
                await _dataService.updateTransactionStatus(rental.id, 'cancelled');
                
                if (mounted) {
                  setState(() {}); // Refresh dashboard
                  messenger.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(isRefunding 
                            ? 'Kiralama iptal edildi, kapora iade edildi' 
                            : 'Kiralama iptal edildi'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('İptal Et', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemainingPaymentConfirmation(TransactionModel rental) {
    Navigator.pop(context); // Close detail dialog first
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Kalan Ödeme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product with image
            Row(
              children: [
                SmartProductThumbnail(
                  imageUrl: rental.productImageUrl,
                  size: 50,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.productName,
                        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        rental.customerName ?? 'Müşteri',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Kalan ödeme tutarı:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '₺${rental.remainingAmount.toInt()}',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Bu tutar tahsil edildi mi?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              // Complete the rental and record remaining payment
              final remainingAmt = rental.remainingAmount.toInt();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await _dataService.completeRental(rental.id);
              
              if (mounted) {
                // Force UI refresh
                setState(() {});
                
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(success ? '₺$remainingAmt tahsil edildi ve kaydedildi' : 'Hata oluştu'),
                      ],
                    ),
                    backgroundColor: success ? AppColors.success : Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Evet, Tahsil Edildi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isWarning = false}) {
    final color = isWarning ? Colors.orange[700]! : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Simple Pie Chart Painter (2 segments: kiralama, satis) - matches accounting style
class PieChartPainterSimple extends CustomPainter {
  final double kiralama;
  final double satis;

  PieChartPainterSimple({
    required this.kiralama,
    required this.satis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 24.0;
    const gapAngle = 0.1;
    
    // Draw shadow circle
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius, shadowPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    // Kiralama (purple gradient effect)
    if (kiralama > 0) {
      paint.shader = LinearGradient(
        colors: [AppColors.chartKiralama, AppColors.chartKiralama.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * kiralama - gapAngle,
        false,
        paint,
      );
      startAngle += 2 * math.pi * kiralama;
    }

    // Satış (cyan gradient effect)
    if (satis > 0) {
      paint.shader = LinearGradient(
        colors: [AppColors.chartSatis, AppColors.chartSatis.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * satis - gapAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Pie Chart Painter (3 segments: kiralama, satis, gider) - for accounting
class PieChartPainter extends CustomPainter {
  final double kiralama;
  final double satis;
  final double gider;

  PieChartPainter({
    required this.kiralama,
    required this.satis,
    required this.gider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;
    const strokeWidth = 28.0;
    const gapAngle = 0.08; // Small gap between segments
    
    // Draw shadow first
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawCircle(center, radius, shadowPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;

    // Kiralama (purple)
    paint.color = AppColors.chartKiralama;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * kiralama - gapAngle,
      false,
      paint,
    );
    startAngle += 2 * math.pi * kiralama;

    // Satış (cyan)
    paint.color = AppColors.chartSatis;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * satis - gapAngle,
      false,
      paint,
    );
    startAngle += 2 * math.pi * satis;

    // Gider (grey)
    paint.color = AppColors.chartGider;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * gider - gapAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
