import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/data_service.dart';
import 'dress_detail_screen.dart';

class ProductListPage extends StatelessWidget {
  final CategoryModel category;

  const ProductListPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final products = data.getProductsByCategory(category.id);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product.title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DressDetailScreen(dress: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
