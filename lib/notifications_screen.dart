import 'widgets/empty_state.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'my_orders_screen.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await NotificationService.fetchAll();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errorText(e);
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = [for (final n in _items) n.copyWith(isRead: true)];
      });
    } catch (e) {
      _toast(errorText(e));
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      setState(() {
        _items = [
          for (final x in _items) x.id == n.id ? x.copyWith(isRead: true) : x,
        ];
      });
      NotificationService.markRead(n.id).catchError((Object _) {});
    }
    final orderId = n.orderId;
    if (orderId == null) return;
    try {
      final order = await OrderService.fetchOrder(orderId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      );
    } catch (e) {
      _toast(errorText(e));
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        backgroundColor: context.colors.page,
        elevation: 0,
        title: Text(
          'Thông báo',
          style: GoogleFonts.montserrat(
            color: context.colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Đọc tất cả',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: brandPink,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: brandPink));
    }
    if (_error != null) {
      return _Message(
        icon: Icons.wifi_off_rounded,
        text: _error!,
        onRetry: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Chưa có thông báo',
        message: 'Trạng thái đơn hàng của bạn sẽ hiện ở đây.',
      );
    }
    return RefreshIndicator(
      color: brandPink,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _NotificationTile(
          notification: _items[i],
          onTap: () => _open(_items[i]),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Material(
      color: n.isRead
          ? context.colors.surface
          : brandPink.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: brandPink.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: brandPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: n.isRead
                            ? FontWeight.w600
                            : FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.body,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        height: 1.4,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(n.createdAt),
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: brandPink,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.day)}/${two(time.month)}/${time.year}';
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  const _Message({required this.icon, required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: context.colors.textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.5,
                color: context.colors.textSecondary,
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
