import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Ảnh mạng được lưu xuống máy (mở lại app không phải tải lại) và giải mã
/// ở chiều rộng [width] pixel thay vì kích thước gốc, giúp tiết kiệm RAM và
/// cuộn mượt hơn. Không truyền [width] thì giải mã kích thước gốc.
ImageProvider cachedImage(String url, {int? width}) =>
    ResizeImage.resizeIfNeeded(width, null, CachedNetworkImageProvider(url));
