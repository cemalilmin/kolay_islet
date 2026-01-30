import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/data_service.dart';
import '../widgets/smart_product_thumbnail.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});

  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen> {
  final DataService _dataService = DataService();
  
  // Time period filter
  String _selectedPeriod = 'Bu Ay';
  final List<String> _periods = ['Bugün', 'Bu Hafta', 'Bu Ay', 'Bu Yıl', 'Tüm Zamanlar'];

  // Transaction type filters (multi-select)
  Set<String> _activeFilters = {};
  
  // Filter options
  static const Map<String, String> _filterLabels = {
    'kiralama': 'Kiralama',
    'satis': 'Satış',
    'kalan_odeme': 'Kalan Ödeme',
    'gider': 'Gider',
    'gelir_ekle': 'Gelir Ekle',
    'iptal': 'İptal Edilenler',
  };

  // Filtered transactions based on selected period and type filters
  List<TransactionModel> get _filteredTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    var filtered = _dataService.transactions.where((t) {
      // Period filter
      switch (_selectedPeriod) {
        case 'Bugün':
          if (!(t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)) return false;
          break;
        case 'Bu Hafta':
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          if (!t.date.isAfter(weekStart.subtract(const Duration(days: 1)))) return false;
          break;
        case 'Bu Ay':
          if (!(t.date.year == now.year && t.date.month == now.month)) return false;
          break;
        case 'Bu Yıl':
          if (!(t.date.year == now.year)) return false;
          break;
        case 'Tüm Zamanlar':
        default:
          break;
      }
      
      // Type filter (if any active)
      if (_activeFilters.isNotEmpty) {
        if (_activeFilters.contains('kiralama') && t.type == 'kiralama' && !t.productName.contains('(Kalan Ödeme)') && t.status != 'cancelled') return true;
        if (_activeFilters.contains('satis') && t.type == 'satis' && t.status != 'cancelled') return true;
        if (_activeFilters.contains('kalan_odeme') && t.productName.contains('(Kalan Ödeme)')) return true;
        if (_activeFilters.contains('gider') && t.type == 'gider') return true;
        if (_activeFilters.contains('gelir_ekle') && t.type == 'gelir_ekle') return true;
        if (_activeFilters.contains('iptal') && t.status == 'cancelled') return true;
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  // Dynamic data based on filtered transactions
  double get kiralamaGelir => _filteredTransactions
      .where((t) => t.type == 'kiralama')
      .fold(0, (sum, t) => sum + t.amount);
  double get satisGelir => _filteredTransactions
      .where((t) => t.type == 'satis')
      .fold(0, (sum, t) => sum + t.amount);
  double get giderTutar => _filteredTransactions
      .where((t) => t.type == 'gider')
      .fold(0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (scrolls with content)
            _buildHeader(),

            // Content with negative margin overlap
            Transform.translate(
              offset: const Offset(0, -24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                    child: _buildMonthlyOverview(),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İşlem Listesi
                        _buildTransactionList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 12, 24, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFB91C1C), // Deeper red-700
            const Color(0xFF991B1B), // red-800
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Time Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Muhasebe',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => setState(() => _selectedPeriod = value),
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                color: Colors.white.withOpacity(0.95),
                elevation: 20,
                itemBuilder: (context) => _periods.map((period) => PopupMenuItem(
                  value: period,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedPeriod == period 
                                ? const Color(0xFFDC2626) 
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          color: _selectedPeriod == period 
                              ? const Color(0xFFFEE2E2) 
                              : Colors.transparent,
                        ),
                        child: _selectedPeriod == period
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        period,
                        style: TextStyle(
                          color: _selectedPeriod == period 
                              ? const Color(0xFFDC2626) 
                              : Colors.grey[700],
                          fontWeight: _selectedPeriod == period 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPeriod,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gider Ekle Button - Inside Header
          GestureDetector(
            onTap: () => _showAddExpenseDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFEA580C), // Deeper orange-600
                    const Color(0xFFC2410C), // orange-700
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C2D12).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gider Ekle',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fatura, kira, malzeme',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Gelir Ekle Button
          GestureDetector(
            onTap: () => _showAddIncomeDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF059669), // green-600
                    const Color(0xFF047857), // green-700
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF064E3B).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.attach_money, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gelir Ekle',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aksesuar, hizmet, diğer',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
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

  void _showAddExpenseDialog() {
    DateTime selectedDate = DateTime.now();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shopping_bag_outlined, color: Colors.orange[700], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yeni Gider Ekle',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Date Picker
                Text('Tarih', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDate.day} ${turkishMonths[selectedDate.month - 1]} ${selectedDate.year}',
                          style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text('Açıklama', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: descriptionController,
                    style: AppTextStyles.titleMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ör: Elektrik faturası',
                      prefixIcon: Icon(Icons.description_outlined, color: AppColors.textSecondary.withOpacity(0.7)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 30, maxHeight: 24),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Amount
                Text('Tutar', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.titleMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Tutar',
                      prefixText: '₺',
                      prefixIcon: Icon(Icons.attach_money, color: AppColors.textSecondary.withOpacity(0.7)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 30, maxHeight: 24),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Note
                Text('Not (Opsiyonel)', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: noteController,
                    maxLines: 2,
                    style: AppTextStyles.titleMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ek not ekleyin...',
                      prefixIcon: Icon(Icons.note_outlined, color: AppColors.textSecondary.withOpacity(0.7)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 30, maxHeight: 24),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                GestureDetector(
                  onTap: () async {
                    if (descriptionController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Açıklama ve tutar zorunludur'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Geçerli bir tutar girin'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    
                    // Show loading snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 10),
                            const Text('Kaydediliyor...'),
                          ],
                        ),
                        backgroundColor: Colors.orange[700],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 5),
                      ),
                    );

                    final success = await _dataService.addExpense(
                      description: descriptionController.text,
                      amount: amount,
                      date: selectedDate,
                      note: noteController.text.isNotEmpty ? noteController.text : null,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      setState(() {}); // Refresh UI
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(success ? '₺${amount.toInt()} gider eklendi' : 'Hata oluştu'),
                            ],
                          ),
                          backgroundColor: success ? Colors.orange[700] : Colors.red,
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
                      gradient: LinearGradient(colors: [Colors.orange[600]!, Colors.orange[400]!]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
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
                          'Gideri Kaydet',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
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

  void _showAddIncomeDialog() {
    DateTime selectedDate = DateTime.now();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Aksesuar';
    final categories = ['Aksesuar', 'Hizmet', 'Diğer'];

    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
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
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.attach_money, color: Colors.green[700], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yeni Gelir Ekle',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Category Selector
                Text('Kategori', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: categories.map((cat) => Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedCategory = cat),
                      child: Container(
                        margin: EdgeInsets.only(right: cat != categories.last ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedCategory == cat 
                              ? Colors.green.withOpacity(0.1) 
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedCategory == cat ? Colors.green : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selectedCategory == cat ? Colors.green[700] : Colors.grey[600],
                              fontWeight: selectedCategory == cat ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 16),

                // Date Picker
                Text('Tarih', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setModalState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.green[700], size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${selectedDate.day} ${turkishMonths[selectedDate.month - 1]} ${selectedDate.year}',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text('Açıklama', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: descriptionController,
                    style: AppTextStyles.titleMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Örn: Taç satışı, Ütü hizmeti',
                      prefixIcon: Icon(Icons.description_outlined, color: AppColors.textSecondary.withOpacity(0.7)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 30, maxHeight: 24),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Amount
                Text('Tutar', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.titleMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Tutar',
                      prefixText: '₺',
                      prefixIcon: Icon(Icons.attach_money, color: AppColors.textSecondary.withOpacity(0.7)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 30, maxHeight: 24),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                GestureDetector(
                  onTap: () async {
                    if (descriptionController.text.isEmpty || amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Açıklama ve tutar zorunludur'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Geçerli bir tutar girin'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    
                    // Show loading snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 10),
                            const Text('Kaydediliyor...'),
                          ],
                        ),
                        backgroundColor: Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 5),
                      ),
                    );

                    // Add manual income as a transaction
                    final success = await _dataService.addTransaction(
                      type: 'satis', // Using 'satis' type for manual income
                      productName: '[$selectedCategory] ${descriptionController.text}',
                      amount: amount,
                      fullPrice: amount,
                      status: 'completed',
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      setState(() {}); // Refresh UI
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                              const SizedBox(width: 10),
                              Text(success ? '₺${amount.toInt()} gelir eklendi' : 'Hata oluştu'),
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
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.green[600]!, Colors.green[400]!]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
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
                          'Geliri Kaydet',
                          style: AppTextStyles.button.copyWith(color: Colors.white),
                        ),
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

  Widget _buildMonthlyOverview() {
    final total = kiralamaGelir + satisGelir + giderTutar;
    final net = kiralamaGelir + satisGelir - giderTutar;
    final hasData = total > 0;
    
    // Calculate percentages
    final kiralamaPercent = hasData ? (kiralamaGelir / total * 100).round() : 0;
    final satisPercent = hasData ? (satisGelir / total * 100).round() : 0;
    final giderPercent = hasData ? (giderTutar / total * 100).round() : 0;
    
    // Calculate counts (exclude cancelled and kalan ödeme)
    final kiralamaCount = _filteredTransactions.where((t) => 
      t.type == 'kiralama' && 
      t.status != 'cancelled' && 
      !t.productName.contains('(Kalan Ödeme)')
    ).length;
    final satisCount = _filteredTransactions.where((t) => 
      t.type == 'satis' && 
      t.status != 'cancelled'
    ).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title - Deeper red gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF450A0A).withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              _selectedPeriod.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donut Chart - larger size
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Chart
                    hasData
                      ? CustomPaint(
                          size: const Size(140, 140),
                          painter: PieChartPainter(
                            kiralama: kiralamaGelir / total,
                            satis: satisGelir / total,
                            gider: giderTutar / total,
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
                        gradient: net >= 0
                            ? const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)])
                            : const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (net >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626)).withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          net.abs() >= 1000000 ? '₺${(net.abs() / 1000000).toStringAsFixed(1)}M' : '₺${net.toInt().abs()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    // Percentage labels shown in legend section instead
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Legend - Clean professional cards
              Expanded(
                child: Column(
                  children: [
                    // Kiralama - with percent badge and count
                    _buildAccountingLegendCard(
                      label: 'Kiralama',
                      amount: kiralamaGelir,
                      percent: kiralamaPercent,
                      count: kiralamaCount,
                      color: const Color(0xFF9333EA),
                      bgColor: const Color(0xFFFAF5FF),
                      borderColor: const Color(0xFFE9D5FF),
                      isIncome: true,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Satış - with percent badge and count
                    _buildAccountingLegendCard(
                      label: 'Satış',
                      amount: satisGelir,
                      percent: satisPercent,
                      count: satisCount,
                      color: const Color(0xFF0891B2),
                      bgColor: const Color(0xFFF0FDFA),
                      borderColor: const Color(0xFFCCFBF1),
                      isIncome: true,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Gider - with percent badge
                    _buildAccountingLegendCard(
                      label: 'Gider',
                      amount: giderTutar,
                      percent: giderPercent,
                      count: null,
                      color: const Color(0xFF6B7280),
                      bgColor: const Color(0xFFF9FAFB),
                      borderColor: const Color(0xFFE5E7EB),
                      isIncome: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Full net amount below chart
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Net: ${net >= 0 ? '+' : ''}₺${net.toInt()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: net >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingLegendCard({
    required String label,
    required double amount,
    required int percent,
    required int? count,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required bool isIncome,
  }) {
    // Format amount for display - full numbers with thousand separators
    String formattedAmount;
    final intAmount = amount.toInt();
    if (intAmount >= 1000) {
      // Add thousand separator
      final parts = <String>[];
      String numStr = intAmount.toString();
      while (numStr.length > 3) {
        parts.insert(0, numStr.substring(numStr.length - 3));
        numStr = numStr.substring(0, numStr.length - 3);
      }
      parts.insert(0, numStr);
      formattedAmount = '₺${parts.join('.')}';
    } else {
      formattedAmount = '₺$intAmount';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Label + Percent badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF374151)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                      child: Text('%$percent', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Row 2: Amount
                Text(
                  '${isIncome ? '+' : '-'}$formattedAmount',
                  style: TextStyle(
                    color: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626), 
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                // Row 3: Count
                if (count != null)
                  Text(
                    '$count adet',
                    style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, double amount, Color color, bool isIncome) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Text(
          '${isIncome ? '+' : '-'}₺${amount.toInt()}',
          style: AppTextStyles.titleSmall.copyWith(
            color: isIncome ? AppColors.success : AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList() {
    final transactions = _dataService.transactions;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFB91C1C), Color(0xFF991B1B)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF450A0A).withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text(
                'İşlemler',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Clear all button (only if filters active)
              if (_activeFilters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeFilters.clear()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_all, size: 14, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text('Temizle', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ),
                ),
              // Filter chips
              ..._filterLabels.entries.map((entry) {
                final isActive = _activeFilters.contains(entry.key);
                Color chipColor;
                switch (entry.key) {
                  case 'kiralama': chipColor = AppColors.chartKiralama; break;
                  case 'satis': chipColor = AppColors.chartSatis; break;
                  case 'kalan_odeme': chipColor = Colors.amber[700]!; break;
                  case 'gider': chipColor = Colors.red[400]!; break;
                  case 'gelir_ekle': chipColor = Colors.green; break;
                  case 'iptal': chipColor = Colors.grey[600]!; break;
                  default: chipColor = Colors.grey;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isActive) {
                          _activeFilters.remove(entry.key);
                        } else {
                          _activeFilters.add(entry.key);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? chipColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? chipColor : Colors.grey[300]!),
                        boxShadow: isActive ? [
                          BoxShadow(color: chipColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                        ] : null,
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Transaction count
        if (_filteredTransactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${_filteredTransactions.length} işlem',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),

        if (_filteredTransactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text(
                    _activeFilters.isNotEmpty ? 'Bu filtreye uygun işlem yok' : 'Henüz işlem yok',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeFilters.isNotEmpty 
                        ? 'Farklı bir filtre seçin veya filtreleri temizleyin'
                        : 'Kiralama veya satış yaptığınızda\nburada görünecek',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._filteredTransactions.map((tx) {
            const turkishMonths = [
              'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
              'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
            ];
            final now = DateTime.now();
            
            // Format time as HH:MM
            final timeStr = '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';
            
            String dateStr;
            if (tx.date.day == now.day && tx.date.month == now.month && tx.date.year == now.year) {
              dateStr = 'Bugün $timeStr';
            } else if (tx.date.day == now.day - 1 && tx.date.month == now.month && tx.date.year == now.year) {
              dateStr = 'Dün $timeStr';
            } else {
              dateStr = '${tx.date.day} ${turkishMonths[tx.date.month - 1]} $timeStr';
            }
            
            String typeLabel;
            String amountPrefix;
            if (tx.type == 'kiralama') {
              typeLabel = tx.productName.contains('(Kalan Ödeme)') ? 'Kalan Ödeme' : 'Kiralama';
              amountPrefix = '+';
            } else if (tx.type == 'satis') {
              typeLabel = 'Satış';
              amountPrefix = '+';
            } else if (tx.type == 'gelir_ekle') {
              typeLabel = 'Gelir';
              amountPrefix = '+';
            } else {
              typeLabel = 'Gider';
              amountPrefix = '-';
            }
            
            // Clean product name (remove duplicate type info)
            String cleanProductName = tx.productName;
            if (cleanProductName.contains(' (Kalan Ödeme)')) {
              cleanProductName = cleanProductName.replaceAll(' (Kalan Ödeme)', '');
            }
            
            return _buildTransactionItemWithDelete(
              tx,
              cleanProductName,
              typeLabel,
              '$amountPrefix${tx.amount.toInt()} TL',
              dateStr,
            );
          }),
      ],
    );
  }

  Widget _buildTransactionItemReal(String title, String amount, String date, String? customer, String type) {
    final isRental = type == 'kiralama';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isRental 
                  ? LinearGradient(colors: [AppColors.chartKiralama, AppColors.chartKiralama.withOpacity(0.7)])
                  : LinearGradient(colors: [AppColors.chartSatis, AppColors.chartSatis.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isRental ? Icons.calendar_today : Icons.sell,
              color: Colors.white,
              size: 20,
            ),
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
                Row(
                  children: [
                    Text(
                      date,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (customer != null) ...[
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
            amount,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItemWithDelete(TransactionModel tx, String productName, String typeLabel, String amount, String date) {
    Color iconBgColor;
    IconData iconData;
    Color amountColor;
    Color typeBadgeColor;
    
    if (tx.type == 'kiralama') {
      iconBgColor = AppColors.chartKiralama;
      iconData = Icons.calendar_today;
      amountColor = AppColors.success;
      typeBadgeColor = productName.contains('Kalan') ? Colors.amber[700]! : AppColors.chartKiralama;
    } else if (tx.type == 'satis') {
      iconBgColor = AppColors.chartSatis;
      iconData = Icons.sell;
      amountColor = AppColors.success;
      typeBadgeColor = AppColors.chartSatis;
    } else if (tx.type == 'gelir_ekle') {
      iconBgColor = Colors.green;
      iconData = Icons.add_circle_outline;
      amountColor = AppColors.success;
      typeBadgeColor = Colors.green;
    } else {
      iconBgColor = Colors.orange;
      iconData = Icons.receipt_long;
      amountColor = Colors.red;
      typeBadgeColor = Colors.orange;
    }
    
    // Check if cancelled
    final isCancelled = tx.status == 'cancelled';
    if (isCancelled) {
      typeBadgeColor = Colors.grey[600]!;
      amountColor = Colors.grey[500]!;
    }
    
    return GestureDetector(
      onLongPress: () => _showDeleteConfirmation(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCancelled ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // Product image if available, otherwise icon
            (tx.productImageUrl != null && tx.productImageUrl!.isNotEmpty)
                ? SmartProductThumbnail(
                    imageUrl: tx.productImageUrl,
                    size: 44,
                    borderRadius: 12,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [iconBgColor, iconBgColor.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: Colors.white, size: 20),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: isCancelled ? TextDecoration.lineThrough : null,
                            color: isCancelled ? Colors.grey[500] : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeBadgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isCancelled ? 'İptal' : typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: typeBadgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Date and customer row
                  Row(
                    children: [
                      Text(
                        date,
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (tx.customerName != null && tx.customerName!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.person_outline, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            tx.customerName!,
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
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
            const SizedBox(width: 8),
            // Amount
            Text(
              amount,
              style: AppTextStyles.titleMedium.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(TransactionModel tx) {
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
            Text('Bu işlemi silmek istediğinizden emin misiniz?'),
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
              // Store messenger reference BEFORE popping dialog
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
}

// Pie Chart Painter
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
      startAngle += 2 * math.pi * satis;
    }

    // Gider (orange-red gradient effect)
    if (gider > 0) {
      paint.shader = LinearGradient(
        colors: [AppColors.chartGider, AppColors.chartGider.withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * gider - gapAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
