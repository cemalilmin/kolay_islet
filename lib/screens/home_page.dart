import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mağaza İsmi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // İleride profil ekranı
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GunlukOzetKart(),
          const SizedBox(height: 24),
          _YaklasanKiralamalar(),
        ],
      ),
    );
  }
}

/* ---------------- GÜNLÜK ÖZET ---------------- */

class _GunlukOzetKart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bugün',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _OzetItem(title: 'Kiralama', value: '1200 TL'),
              _OzetItem(title: 'Satış', value: '2000 TL'),
              _OzetItem(title: 'Gider', value: '500 TL'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                '+ 2700 TL',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _OzetItem extends StatelessWidget {
  final String title;
  final String value;

  const _OzetItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

/* ---------------- YAKLAŞAN KİRALAMALAR ---------------- */

class _YaklasanKiralamalar extends StatelessWidget {
  final List<Map<String, dynamic>> kiralamalar = const [
    {
      'urun': 'Fistan 1',
      'tarih': '30 Kasım',
      'gun': 2,
    },
    {
      'urun': 'Fistan 3',
      'tarih': '2 Aralık',
      'gun': 5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yaklaşan Kiralamalar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...kiralamalar
            .where((e) => e['gun'] >= 2) // 🔥 EN AZ 2 GÜN KALANLAR
            .map(
              (item) => _KiralamaKart(
                urun: item['urun'],
                tarih: item['tarih'],
                gun: item['gun'],
              ),
            )
            .toList(),
      ],
    );
  }
}

class _KiralamaKart extends StatelessWidget {
  final String urun;
  final String tarih;
  final int gun;

  const _KiralamaKart({
    required this.urun,
    required this.tarih,
    required this.gun,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Detay ekranı buradan açılacak
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$urun detayı açılacak')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: gun <= 2 ? Colors.red : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: gun <= 2 ? Colors.red : AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urun,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    tarih,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$gun gün',
              style: TextStyle(
                color: gun <= 2 ? Colors.red : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
