import 'package:flutter/material.dart';
import '../controllers/notification_controller.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with WidgetsBindingObserver {
  final NotificationController _controller = NotificationController();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUnreadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final notifications = await _controller.getAllNotifications();
      final unreadNotifications = notifications.where((n) => !n.isRead).length;
      if (mounted) {
        setState(() {
          _unreadCount = unreadNotifications;
        });
      }
    } catch (e) {
      print('Erro ao carregar contador de notificações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        widget.onTap();
        // Recarregar contador após um pequeno delay
        await Future.delayed(const Duration(milliseconds: 500));
        _loadUnreadCount();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
