import 'package:flutter/material.dart';

class MuhasebePage extends StatelessWidget {
  const MuhasebePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Muhasebe')),
      body: const Center(
        child: Text(
          'Gelir / Gider / Raporlar',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
