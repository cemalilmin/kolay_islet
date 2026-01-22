import 'package:flutter/material.dart';
import '../models/dress_model.dart';
import 'dress_detail_screen.dart';

class ProductPage extends StatelessWidget {
  final DressModel product;

  const ProductPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return DressDetailScreen(dress: product);
  }
}
