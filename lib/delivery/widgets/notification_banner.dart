import 'package:flutter/material.dart';

class BannerMessage {
  const BannerMessage({
    required this.title,
    required this.body,
    this.icon = Icons.delivery_dining,
  });

  final String title;
  final String body;
  final IconData icon;
}

class NotificationBanner extends StatelessWidget {
  const NotificationBanner({
    super.key,
    required this.message,
    required this.color,
  });

  final BannerMessage? message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween(
          begin: const Offset(0, -1.5),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      child: message == null
          ? const SizedBox.shrink()
          : _BannerCard(
              key: ObjectKey(message),
              message: message,
              color: color,
            ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({super.key, required this.message, required this.color});

  final BannerMessage message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(message.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'TRACKER LINE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        'sekarang',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(message.body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
