class ProductCategory {
  final int id;
  final String name;

  const ProductCategory({required this.id, required this.name});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(id: json['id'] as int, name: json['name'] as String);
  }
}
