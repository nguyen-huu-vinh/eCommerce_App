import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_button.dart';
import '../models/product.dart'; // sửa đường dẫn cho khớp vị trí file product.dart
import '../product_detail_screen.dart'; // sửa đường dẫn cho khớp vị trí file product_detail_screen.dart
import '../utils/network_image.dart';

class ProductCard extends StatelessWidget {
  final String title;
  final String? description;
  final String price;
  final String? originalPrice;
  final String? discount;
  final double? rating;
  final int? ratingCount;
  final String image;

  /// Id sản phẩm trên backend. Có giá trị thì thẻ TỰ mở trang chi tiết khi
  /// bấm vào, không cần nơi gọi tự viết onTap.
  final int? id;

  /// Dữ liệu đã có sẵn (nếu có) để trang chi tiết hiện ngay, không cần chờ tải.
  final Product? product;

  /// Muốn tự xử lý khi bấm (thay vì mở trang chi tiết mặc định) thì truyền vào đây.
  /// Có giá trị thì onTap này được ưu tiên hơn hành vi mở trang chi tiết.
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.title,
    this.description,
    required this.price,
    this.originalPrice,
    this.discount,
    this.rating,
    this.ratingCount,
    required this.image,
    this.id,
    this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Ưu tiên onTap được truyền vào; không có thì tự mở trang chi tiết theo id;
    // không có cả hai thì thẻ không phản ứng khi bấm (chỉ hiển thị).
    final VoidCallback? effectiveOnTap =
        onTap ??
        (id != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: id!,
                      initialProduct: product,
                    ),
                  ),
                );
              }
            : null);

    return BouncingButton(
      onTap: effectiveOnTap ?? () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProductCardImage(image: image),

              // 2. PHẦN THÔNG TIN SẢN PHẨM
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),

                    if (description != null && description!.isNotEmpty) ...[
                      Text(
                        description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // GIÁ CẢ & GIẢM GIÁ
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          price,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF000000),
                          ),
                        ),
                        if (originalPrice != null)
                          Text(
                            originalPrice!,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.lineThrough,
                              color: const Color(0xFF808488),
                            ),
                          ),
                        if (discount != null)
                          Text(
                            discount!,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFE3E6C),
                            ),
                          ),
                      ],
                    ),

                    if (rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating!.floor()
                                  ? Icons.star
                                  : (index < rating!
                                        ? Icons.star_half
                                        : Icons.star_border),
                              size: 11,
                              color: const Color(0xFFEDB310),
                            );
                          }),
                          const SizedBox(width: 4),
                          if (ratingCount != null)
                            Text(
                              '($ratingCount)',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF808488),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCardImage extends StatefulWidget {
  final String image;

  const _ProductCardImage({required this.image});

  @override
  State<_ProductCardImage> createState() => _ProductCardImageState();
}

class _ProductCardImageState extends State<_ProductCardImage> {
  static const _minAspectRatio = 0.8;
  static const _maxAspectRatio = 1.35;

  late ImageProvider<Object> _imageProvider;
  ImageStream? _imageStream;
  late final ImageStreamListener _imageListener;
  double _aspectRatio = 1;

  @override
  void initState() {
    super.initState();
    _imageProvider = _createImageProvider(widget.image);
    _imageListener = ImageStreamListener((imageInfo, _) {
      final image = imageInfo.image;
      final aspectRatio = (image.width / image.height).clamp(
        _minAspectRatio,
        _maxAspectRatio,
      );
      if (mounted && aspectRatio != _aspectRatio) {
        setState(() => _aspectRatio = aspectRatio);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenToImage();
  }

  @override
  void didUpdateWidget(covariant _ProductCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _removeImageListener();
      _aspectRatio = 1;
      _imageProvider = _createImageProvider(widget.image);
      _listenToImage();
    }
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  ImageProvider<Object> _createImageProvider(String image) {
    // Thẻ chiếm nửa màn hình nên 540px là đủ nét kể cả máy màn hình dày điểm ảnh
    return image.startsWith('http')
        ? cachedImage(image, width: 540)
        : AssetImage(image);
  }

  void _listenToImage() {
    final stream = _imageProvider.resolve(
      createLocalImageConfiguration(context),
    );
    _imageStream = stream;
    stream.addListener(_imageListener);
  }

  void _removeImageListener() {
    _imageStream?.removeListener(_imageListener);
    _imageStream = null;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Container(
        color: Colors.grey.shade100,
        child: Image(
          image: _imageProvider,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }
}
