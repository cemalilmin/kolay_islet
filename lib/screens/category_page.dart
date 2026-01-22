import 'package:flutter/material.dart';
import '../models/category_model.dart';
import 'product_list_page.dart';

class CategoryPage extends StatelessWidget {
  final CategoryModel category;

  const CategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Center(
        child: ElevatedButton(
          child: const Text('Ürünleri Gör'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListPage(category: category),
              ),
            );
          },
        ),
      ),
    );
  }
}
