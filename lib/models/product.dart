/// Sản phẩm lấy từ backend (GET /products, /trending, /products/{id}).
///
/// Backend hiện chỉ trả: id, name, price, image_url, is_trending.
/// Các trường còn lại là tuỳ chọn: khi backend bổ sung thì trang chi tiết tự
/// hiển thị thêm mà không cần sửa lại code Flutter.
class Product {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final bool isTrending;
  final bool isSale;
  final bool isDealOfTheDay;
  final bool isNew;
  final double? discountPrice;
  final String? category;

  final String? description;
  final double? originalPrice; // giá gốc, để hiện giá gạch ngang + % giảm
  final double? rating;
  final int? ratingCount;
  final List<String> images; // nhiều ảnh cho slider, rỗng thì dùng imageUrl
  final List<String> sizes; // rỗng thì trang chi tiết dùng danh sách mặc định

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isTrending = false,
    this.isSale = false,
    this.isDealOfTheDay = false,
    this.isNew = false,
    this.discountPrice,
    this.category,
    this.description,
    this.originalPrice,
    this.rating,
    this.ratingCount,
    this.images = const [],
    this.sizes = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) =>
        (value as List?)?.map((e) => e.toString()).toList() ?? const [];

    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String,
      isTrending: json['is_trending'] as bool? ?? false,
      isSale: json['is_sale'] as bool? ?? false,
      isDealOfTheDay: json['is_deal_of_the_day'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      category: json['category'] as String?,
      description: json['description'] as String?,
      originalPrice: (json['original_price'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int?,
      images: stringList(json['images']),
      sizes: stringList(json['sizes']),
    );
  }

  /// Ngược lại với fromJson, dùng để lưu giỏ hàng xuống máy
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'image_url': imageUrl,
    'is_trending': isTrending,
    'is_sale': isSale,
    'is_deal_of_the_day': isDealOfTheDay,
    'is_new': isNew,
    'discount_price': discountPrice,
    'category': category,
    'description': description,
    'original_price': originalPrice,
    'rating': rating,
    'rating_count': ratingCount,
    'images': images,
    'sizes': sizes,
  };

  /// Danh sách ảnh dùng cho slider (luôn có ít nhất 1 ảnh)
  List<String> get gallery => images.isNotEmpty ? images : [imageUrl];
}
