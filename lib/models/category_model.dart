class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.productCount = 0,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    int? productCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      productCount: productCount ?? this.productCount,
    );
  }
}
