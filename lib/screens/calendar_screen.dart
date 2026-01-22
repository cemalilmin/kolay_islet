import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CalendarScreen extends StatelessWidget {
  final ProductModel product;

  const CalendarScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Takvim')),
      body: Center(
        child: Text(
          '${product.name} için takvim',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
