class ProductModel {
  final int id;
  final int categoryId;
  final String name;
  final int price;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.isAvailable,
  });
}
