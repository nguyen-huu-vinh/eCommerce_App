/// Một dòng sản phẩm trong đơn, giữ nguyên giá tại thời điểm mua
class OrderLine {
  final int productId;
  final String productName;
  final String imageUrl;
  final String? size;
  final double unitPrice;
  final int quantity;

  const OrderLine({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.size,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    productId: json['product_id'] as int,
    productName: json['product_name'] as String,
    imageUrl: json['image_url'] as String,
    size: json['size'] as String?,
    unitPrice: (json['unit_price'] as num).toDouble(),
    quantity: json['quantity'] as int,
  );

  double get lineTotal => unitPrice * quantity;
}

/// Backend lưu giờ UTC nhưng không kèm múi giờ
DateTime _parseServerTime(String raw) {
  final hasZone = raw.endsWith('Z') || raw.contains('+');
  return DateTime.parse(hasZone ? raw : '${raw}Z').toLocal();
}

String _formatTime(DateTime d) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)} ${two(d.day)}/${two(d.month)}/${d.year}';
}

const orderStatusLabels = {
  'pending': 'Chờ xác nhận',
  'confirmed': 'Đã xác nhận',
  'shipping': 'Đang giao',
  'completed': 'Hoàn thành',
  'cancelled': 'Đã hủy',
};

/// Một mốc trong hành trình đơn hàng
class OrderEvent {
  final String status;
  final String? note;
  final DateTime createdAt;

  const OrderEvent({required this.status, this.note, required this.createdAt});

  factory OrderEvent.fromJson(Map<String, dynamic> json) => OrderEvent(
    status: json['status'] as String,
    note: json['note'] as String?,
    createdAt: _parseServerTime(json['created_at'] as String),
  );

  String get statusLabel => orderStatusLabels[status] ?? status;

  String get createdAtLabel => _formatTime(createdAt);
}

/// Thông tin chuyển khoản VietQR do backend tạo cho đơn chọn "bank"
class BankTransfer {
  final String bankId;
  final String accountNo;
  final String accountName;
  final double amount;
  final String content;
  final String qrUrl;

  const BankTransfer({
    required this.bankId,
    required this.accountNo,
    required this.accountName,
    required this.amount,
    required this.content,
    required this.qrUrl,
  });

  factory BankTransfer.fromJson(Map<String, dynamic> json) => BankTransfer(
    bankId: json['bank_id'] as String,
    accountNo: json['account_no'] as String,
    accountName: json['account_name'] as String,
    amount: (json['amount'] as num).toDouble(),
    content: json['content'] as String,
    qrUrl: json['qr_url'] as String,
  );
}

/// Đơn hàng từ backend (POST /orders, GET /orders/me)
class Order {
  final int id;
  final String fullName;
  final String phone;
  final String address;
  final String? note;
  final String paymentMethod;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<OrderLine> items;
  final BankTransfer? bankTransfer;

  /// Các mốc trạng thái theo thứ tự thời gian, cũ nhất trước
  final List<OrderEvent> timeline;

  const Order({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.note,
    required this.paymentMethod,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    this.bankTransfer,
    this.timeline = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      note: json['note'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      status: json['status'] as String? ?? 'pending',
      total: (json['total'] as num).toDouble(),
      createdAt: _parseServerTime(json['created_at'] as String),
      items: (json['items'] as List? ?? const [])
          .map((item) => OrderLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      bankTransfer: json['bank_transfer'] == null
          ? null
          : BankTransfer.fromJson(
              json['bank_transfer'] as Map<String, dynamic>,
            ),
      timeline: (json['timeline'] as List? ?? const [])
          .map((event) => OrderEvent.fromJson(event as Map<String, dynamic>))
          .toList(),
    );
  }

  String get code => 'DH$id';

  /// Chỉ hiện QR khi đơn chuyển khoản còn đang chờ xác nhận
  bool get awaitingTransfer => bankTransfer != null && status == 'pending';

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  String get paymentLabel => paymentMethod == 'bank'
      ? 'Chuyển khoản ngân hàng'
      : 'Thanh toán khi nhận hàng';

  String get statusLabel => orderStatusLabels[status] ?? status;

  String get createdAtLabel => _formatTime(createdAt);

  bool get canCancel => status == 'pending';
}
