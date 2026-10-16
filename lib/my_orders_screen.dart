import 'widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/order.dart';
import 'services/order_service.dart';
import 'utils/currency.dart';
import 'widgets/bank_transfer_card.dart';
import 'widgets/order_tracking_map.dart';
import 'widgets/review_sheet.dart';
import 'utils/network_image.dart';

const _pink = Color(0xFFFE3E6C);

/// Các tab lọc đơn, null là "Tất cả"
const _tabStatuses = <String?>[
  null,
  'pending',
  'confirmed',
  'shipping',
  'completed',
  'cancelled',
];

/// Các bước của thanh tiến trình, theo thứ tự
const _progressSteps = [
  ('pending', 'Đặt hàng', Icons.receipt_long_rounded),
  ('confirmed', 'Xác nhận', Icons.inventory_2_rounded),
  ('shipping', 'Đang giao', Icons.local_shipping_rounded),
  ('completed', 'Đã nhận', Icons.check_circle_rounded),
];

String _errorText(Object error) => error is OrderException
    ? error.message
    : 'Không thể kết nối máy chủ, vui lòng thử lại';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Order>? _orders;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = _orders == null;
      _errorMessage = null;
    });
    try {
      final orders = await OrderService.fetchMyOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _errorText(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _openOrder(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)),
    );
    // Đơn có thể vừa bị hủy hoặc đổi trạng thái trong trang chi tiết
    if (mounted) _loadOrders();
  }

  String _tabLabel(String? status) {
    if (status == null) return 'Tất cả';
    final count = _orders?.where((o) => o.status == status).length ?? 0;
    final label = orderStatusLabels[status]!;
    return count > 0 ? '$label ($count)' : label;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabStatuses.length,
      child: Scaffold(
        backgroundColor: context.colors.page,
        appBar: _buildAppBar(
          context,
          'Đơn hàng của tôi',
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: _pink,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: _pink,
            labelStyle: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 12),
            tabs: [
              for (final status in _tabStatuses) Tab(text: _tabLabel(status)),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _pink));
    }
    final orders = _orders;
    if (orders == null) {
      return _MessageView(
        icon: Icons.cloud_off_rounded,
        title: _errorMessage ?? 'Không thể tải đơn hàng',
        actionLabel: 'Thử lại',
        onAction: _loadOrders,
      );
    }

    return TabBarView(
      children: [
        for (final status in _tabStatuses)
          _buildOrderList(
            status == null
                ? orders
                : orders.where((o) => o.status == status).toList(),
          ),
      ],
    );
  }

  Widget _buildOrderList(List<Order> orders) {
    return RefreshIndicator(
      color: _pink,
      onRefresh: _loadOrders,
      child: orders.isEmpty
          ? ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 60),
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Chưa có đơn hàng',
                  message: 'Các đơn bạn đặt sẽ được theo dõi tại đây.',
                ),
              ],
            )
          : ListView.separated(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 12, 16, 116),
              itemCount: orders.length,
              separatorBuilder: (_, _) => SizedBox(height: 10),
              itemBuilder: (context, index) => _OrderCard(
                order: orders[index],
                onTap: () => _openOrder(orders[index]),
              ),
            ),
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _cancelReasons = [
    'Muốn thay đổi địa chỉ giao hàng',
    'Muốn thay đổi sản phẩm trong đơn',
    'Tìm thấy giá rẻ hơn ở chỗ khác',
    'Đổi ý, không muốn mua nữa',
  ];

  late Order _order = widget.order;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _refresh(silent: true);
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final order = await OrderService.fetchOrder(_order.id);
      if (mounted) setState(() => _order = order);
    } catch (error) {
      if (!silent && mounted) _showMessage(_errorText(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reviewItem(OrderLine item) async {
    final changed = await showReviewSheet(
      context,
      productId: item.productId,
      productName: item.productName,
    );
    if (changed == true && mounted) _showMessage('Cảm ơn bạn đã đánh giá!');
  }

  Future<void> _cancelOrder() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(
          'Chọn lý do hủy đơn',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          for (final reason in _cancelReasons)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, reason),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(reason, style: GoogleFonts.montserrat(fontSize: 13)),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Không hủy'),
              ),
            ),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final order = await OrderService.cancelOrder(_order.id, reason: reason);
      if (!mounted) return;
      setState(() => _order = order);
      _showMessage('Đã hủy đơn hàng ${order.code}');
    } catch (error) {
      if (mounted) _showMessage(_errorText(error));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final note = order.note;
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: _buildAppBar(context, 'Đơn ${order.code}'),
      body: RefreshIndicator(
        color: _pink,
        onRefresh: _refresh,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 116),
          children: [
            _StatusBanner(order: order),
            if (order.status != 'cancelled') ...[
              SizedBox(height: 10),
              _Section(child: _ProgressStepper(order: order)),
            ],
            if (order.status == 'shipping') ...[
              SizedBox(height: 10),
              OrderTrackingMap(
                orderId: order.id,
                // Shipper bấm "đã giao" thì tải lại để cập nhật trạng thái
                onStatusChanged: (_) => _refresh(),
              ),
            ],
            if (order.awaitingTransfer) ...[
              SizedBox(height: 10),
              BankTransferCard(transfer: order.bankTransfer!),
            ],
            SizedBox(height: 10),
            _Section(
              title: 'Lịch sử đơn hàng',
              child: _Timeline(events: order.timeline.reversed.toList()),
            ),
            SizedBox(height: 10),
            _Section(
              title: 'Địa chỉ nhận hàng',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailText('${order.fullName} · ${order.phone}', bold: true),
                  SizedBox(height: 4),
                  _DetailText(order.address),
                  if (note != null && note.isNotEmpty) ...[
                    SizedBox(height: 6),
                    _DetailText('Ghi chú: $note'),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10),
            _Section(
              title: 'Sản phẩm',
              child: Column(
                children: [
                  for (final item in order.items) ...[
                    _OrderLineRow(
                      item: item,
                      onReview: order.status == 'completed'
                          ? () => _reviewItem(item)
                          : null,
                    ),
                    if (item != order.items.last) Divider(height: 20),
                  ],
                ],
              ),
            ),
            SizedBox(height: 10),
            _Section(
              child: Column(
                children: [
                  _SummaryRow(label: 'Mã đơn hàng', value: order.code),
                  SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Thời gian đặt',
                    value: order.createdAtLabel,
                  ),
                  SizedBox(height: 8),
                  _SummaryRow(label: 'Thanh toán', value: order.paymentLabel),
                  SizedBox(height: 8),
                  _SummaryRow(label: 'Phí vận chuyển', value: 'Miễn phí'),
                  if (order.discount > 0) ...[
                    SizedBox(height: 8),
                    _SummaryRow(
                      label: order.couponCode == null
                          ? 'Giảm giá'
                          : 'Mã ${order.couponCode}',
                      value: '-${formatVnd(order.discount)}',
                    ),
                  ],
                  Divider(height: 22),
                  _SummaryRow(
                    label: 'Tổng cộng',
                    value: formatVnd(order.total),
                    emphasized: true,
                  ),
                ],
              ),
            ),
            if (order.canCancel) ...[
              SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _cancelling ? null : _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFDA294F),
                    side: BorderSide(color: Color(0xFFDA294F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _cancelling
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Text(
                          'Hủy đơn hàng',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dải màu đầu trang chi tiết, giống phần trạng thái ở Shopee
class _StatusBanner extends StatelessWidget {
  final Order order;

  const _StatusBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final (message, icon) = switch (order.status) {
      'pending' => (
        order.awaitingTransfer
            ? 'Vui lòng chuyển khoản để cửa hàng xác nhận đơn'
            : 'Đơn hàng đang chờ cửa hàng xác nhận',
        Icons.hourglass_top_rounded,
      ),
      'confirmed' => (
        'Cửa hàng đang chuẩn bị hàng cho bạn',
        Icons.inventory_2_rounded,
      ),
      'shipping' => (
        'Đơn hàng đang trên đường giao đến bạn',
        Icons.local_shipping_rounded,
      ),
      'completed' => (
        'Giao hàng thành công. Cảm ơn bạn đã mua sắm!',
        Icons.verified_rounded,
      ),
      'cancelled' => ('Đơn hàng đã bị hủy', Icons.cancel_rounded),
      _ => ('', Icons.info_outline_rounded),
    };
    final cancelled = order.status == 'cancelled';
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cancelled
              ? [Color(0xFF8A8A8A), Color(0xFFA9A9A9)]
              : [Color(0xFFFE3E6C), Color(0xFFFF7A95)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.statusLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(icon, size: 40, color: Colors.white),
        ],
      ),
    );
  }
}

/// Thanh 4 bước: Đặt hàng → Xác nhận → Đang giao → Đã nhận
class _ProgressStepper extends StatelessWidget {
  final Order order;

  const _ProgressStepper({required this.order});

  @override
  Widget build(BuildContext context) {
    final current = _progressSteps.indexWhere((s) => s.$1 == order.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _progressSteps.length; i++)
          Expanded(child: _buildStep(context, i, current)),
      ],
    );
  }

  Widget _buildStep(BuildContext context, int index, int current) {
    final (status, label, icon) = _progressSteps[index];
    final done = index <= current;
    final color = done ? _pink : context.colors.border;
    // Thời điểm gần nhất đơn chuyển sang bước này
    final reachedAt = order.timeline
        .where((event) => event.status == status)
        .lastOrNull
        ?.createdAt;

    Widget line(bool active) => Expanded(
      child: Container(
        height: 2,
        color: active ? _pink : context.colors.border,
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            index == 0 ? Spacer() : line(index <= current),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: done ? _pink : context.colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 17, color: done ? Colors.white : color),
            ),
            index == _progressSteps.length - 1
                ? Spacer()
                : line(index < current),
          ],
        ),
        SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: index == current ? FontWeight.w700 : FontWeight.w500,
            color: done ? context.colors.textPrimary : context.colors.textSecondary,
          ),
        ),
        if (done && reachedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            '${reachedAt.hour.toString().padLeft(2, '0')}:'
            '${reachedAt.minute.toString().padLeft(2, '0')} '
            '${reachedAt.day.toString().padLeft(2, '0')}/'
            '${reachedAt.month.toString().padLeft(2, '0')}',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              color: context.colors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Dòng thời gian các mốc, mới nhất ở trên
class _Timeline extends StatelessWidget {
  final List<OrderEvent> events;

  const _Timeline({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 22,
                  child: Column(
                    children: [
                      const SizedBox(height: 3),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? _pink : context.colors.border,
                          border: i == 0
                              ? Border.all(
                                  color: const Color(0xFFFFD3DE),
                                  width: 3,
                                )
                              : null,
                        ),
                      ),
                      if (i < events.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: context.colors.border,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < events.length - 1 ? 16 : 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          events[i].statusLabel,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: i == 0 ? _pink : context.colors.textSecondary,
                          ),
                        ),
                        if (events[i].note case final note?
                            when note.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          _DetailText(note),
                        ],
                        SizedBox(height: 3),
                        Text(
                          events[i].createdAtLabel,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

PreferredSizeWidget _buildAppBar(
  BuildContext context,
  String title, {
  PreferredSizeWidget? bottom,
}) => AppBar(
  backgroundColor: context.colors.page,
  bottom: bottom,
  elevation: 0,
  centerTitle: true,
  leading: IconButton(
    tooltip: 'Quay lại',
    onPressed: () => Navigator.maybePop(context),
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
    color: context.colors.textPrimary,
  ),
  title: Text(
    title,
    style: GoogleFonts.montserrat(
      color: context.colors.textPrimary,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  ),
);

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final first = order.items.isEmpty ? null : order.items.first;
    final others = order.items.length - 1;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.code,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  _StatusChip(order: order),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                order.createdAtLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: context.colors.textMuted,
                ),
              ),
              if (first != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Thumbnail(url: first.imageUrl, size: 48),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        others > 0
                            ? '${first.productName} và $others sản phẩm khác'
                            : first.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              Divider(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.itemCount} sản phẩm',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    formatVnd(order.total),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _pink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderLineRow extends StatelessWidget {
  final OrderLine item;

  /// Chỉ có với đơn đã nhận: mở hộp đánh giá sản phẩm này
  final VoidCallback? onReview;

  const _OrderLineRow({required this.item, this.onReview});

  @override
  Widget build(BuildContext context) {
    final size = item.size;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Thumbnail(url: item.imageUrl, size: 56),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailText(item.productName, bold: true),
              const SizedBox(height: 4),
              _DetailText(
                [
                  if (size != null && size.isNotEmpty) 'Size $size',
                  '${formatVnd(item.unitPrice)} × ${item.quantity}',
                ].join(' · '),
              ),
              if (onReview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.star_outline_rounded, size: 16),
                    label: const Text('Đánh giá'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _pink,
                      side: BorderSide(color: _pink),
                      visualDensity: VisualDensity.compact,
                      textStyle: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          formatVnd(item.lineTotal),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Order order;

  const _StatusChip({required this.order});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (lightBg, lightFg, darkFg) = switch (order.status) {
      'completed' => (0xFFE6F6EC, 0xFF1E8E4A, 0xFF4CD08A),
      'cancelled' => (0xFFF0F0F0, 0xFF777777, 0xFFAEAEB2),
      'shipping' || 'confirmed' => (0xFFE8F0FE, 0xFF2F62C9, 0xFF7FA8F5),
      _ => (0xFFFFEDF1, 0xFFD93358, 0xFFFF6B8B),
    };
    final foreground = Color(dark ? darkFg : lightFg);
    final background = dark
        ? foreground.withValues(alpha: 0.16)
        : Color(lightBg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        order.statusLabel,
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;
  final double size;

  const _Thumbnail({required this.url, required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image(
      image: cachedImage(url, width: 180),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: size,
        height: size,
        color: context.colors.surfaceAlt,
        child: const Icon(Icons.image_not_supported_outlined, size: 18),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Section({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  final String text;
  final bool bold;

  const _DetailText(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.montserrat(
      fontSize: 12,
      height: 1.4,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: bold ? context.colors.textPrimary : context.colors.textSecondary,
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: emphasized ? 14 : 12,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: context.colors.textSecondary,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.montserrat(
          fontSize: emphasized ? 15 : 12,
          fontWeight: FontWeight.w700,
          color: emphasized ? _pink : context.colors.textSecondary,
        ),
      ),
    ],
  );
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: context.colors.textMuted),
          SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: _pink),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}
