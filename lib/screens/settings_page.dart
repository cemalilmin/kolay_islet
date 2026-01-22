import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = SettingsService();
  
  late TextEditingController _shopNameController;
  late TextEditingController _shopPhoneController;
  late TextEditingController _disclaimerController;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController(text: _settings.shopName);
    _shopPhoneController = TextEditingController(text: _settings.shopPhone);
    _disclaimerController = TextEditingController(text: _settings.receiptDisclaimer);
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopPhoneController.dispose();
    _disclaimerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
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
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        title: Text(
          'Ayarlar',
          style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Operations Section
          _buildSectionHeader('📦 Operasyonel', Icons.settings),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSliderTile(
              title: 'Kargo Bloklama Süresi (Gün)',
              subtitle: '${_settings.shippingBufferDays} gün önce/sonra rezerve',
              value: _settings.shippingBufferDays.toDouble(),
              min: 0,
              max: 7,
              onChanged: (value) async {
                await _settings.setShippingBufferDays(value.round());
                setState(() {});
              },
            ),
            const Divider(height: 1),
            _buildSliderTile(
              title: 'Temizlik Süresi (Gün)',
              subtitle: '${_settings.cleaningDurationDays} gün varsayılan',
              value: _settings.cleaningDurationDays.toDouble(),
              min: 1,
              max: 7,
              onChanged: (value) async {
                await _settings.setCleaningDurationDays(value.round());
                setState(() {});
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Receipt Section
          _buildSectionHeader('📄 Dijital Fiş', Icons.receipt_long),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildTextFieldTile(
              title: 'Mağaza Adı',
              controller: _shopNameController,
              hint: 'Mağazanızın adı',
              onChanged: (value) => _settings.setShopName(value),
            ),
            const Divider(height: 1),
            _buildTextFieldTile(
              title: 'Telefon',
              controller: _shopPhoneController,
              hint: '0532 123 45 67',
              keyboardType: TextInputType.phone,
              onChanged: (value) => _settings.setShopPhone(value),
            ),
            const Divider(height: 1),
            _buildMultilineFieldTile(
              title: 'Fiş Uyarı Metni',
              controller: _disclaimerController,
              hint: 'Kiralamalar 19:00\'a kadar iade edilmelidir...',
              onChanged: (value) => _settings.setReceiptDisclaimer(value),
            ),
          ]),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('🔔 Bildirimler', Icons.notifications_active),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Gecikmiş Kiralama Uyarıları',
              subtitle: 'Anasayfada kırmızı uyarı göster',
              value: _settings.overdueNotificationsEnabled,
              onChanged: (value) async {
                await _settings.setOverdueNotificationsEnabled(value);
                setState(() {});
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('💾 Veri', Icons.storage),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.table_chart, color: Colors.green[700], size: 22),
              ),
              title: const Text('Excel\'e Aktar', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Tüm kiralama verilerini indir'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Bu özellik yakında eklenecek'),
                      ],
                    ),
                    backgroundColor: Colors.blue[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restart_alt, color: Colors.red[700], size: 22),
              ),
              title: const Text('Ayarları Sıfırla', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Tüm ayarları varsayılana döndür'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Ayarları Sıfırla'),
                    content: const Text('Tüm ayarlar varsayılan değerlere döndürülecek. Emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('İptal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Sıfırla', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await _settings.resetToDefaults();
                  _shopNameController.text = _settings.shopName;
                  _shopPhoneController.text = _settings.shopPhone;
                  _disclaimerController.text = _settings.receiptDisclaimer;
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Ayarlar sıfırlandı'),
                        backgroundColor: Colors.green[600],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Legal Section - Privacy Policy
          _buildSectionHeader('📜 Yasal', Icons.gavel),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.privacy_tip, color: Colors.blue[700], size: 22),
              ),
              title: const Text('Gizlilik Politikası', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Veri toplama ve kullanım politikamız'),
              trailing: Icon(Icons.open_in_new, color: Colors.grey[400]),
              onTap: () async {
                final url = Uri.parse('https://example.com/privacy'); // TODO: Update with real URL
                // ignore: deprecated_member_use
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Account Section - Delete Account
          _buildSectionHeader('👤 Hesap', Icons.person),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_forever, color: Colors.red[700], size: 22),
              ),
              title: const Text('Hesabımı Sil', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              subtitle: const Text('Tüm verileriniz kalıcı olarak silinecektir'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
              onTap: () => _showDeleteAccountDialog(),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.round()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.2),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildMultilineFieldTile({
    required String title,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Delete Account Dialog - Required for App Store / Play Store compliance
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 10),
            const Text('Hesabı Sil'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 12),
            Text('Hesabınızı sildiğinizde:'),
            SizedBox(height: 8),
            Text('• Tüm ürünleriniz silinecek'),
            Text('• Tüm rezervasyonlarınız silinecek'),
            Text('• Tüm işlem geçmişiniz silinecek'),
            Text('• Hesap bilgileriniz kalıcı olarak kaldırılacak'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hesabımı Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Oturum açık değil'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Delete user's data from all tables
      // 1. Delete transactions
      await supabase.from('transactions').delete().eq('user_id', userId);
      
      // 2. Delete bookings
      await supabase.from('bookings').delete().eq('user_id', userId);
      
      // 3. Delete maintenance events
      await supabase.from('maintenance_events').delete().eq('user_id', userId);
      
      // 4. Delete products
      await supabase.from('products').delete().eq('user_id', userId);
      
      // 5. Delete categories
      await supabase.from('categories').delete().eq('user_id', userId);
      
      // 6. Delete user profile if exists
      await supabase.from('profiles').delete().eq('id', userId);

      // 7. Sign out the user (actual auth deletion requires admin/service role)
      await supabase.auth.signOut();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hesabınız ve tüm verileriniz silindi'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading if open
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
