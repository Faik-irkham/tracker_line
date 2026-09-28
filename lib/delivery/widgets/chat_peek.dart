import 'dart:math';

import 'package:flutter/material.dart';

enum ChatStep { hidden, driverSent, typing, replied }

class ChatPeek extends StatelessWidget {
  const ChatPeek({
    super.key,
    required this.step,
    required this.driverName,
    required this.driverMessage,
    required this.reply,
    required this.color,
  });

  final ChatStep step;
  final String driverName;
  final String driverMessage;
  final String reply;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween(
          begin: const Offset(0, -1.3),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
      child: step == ChatStep.hidden
          ? const SizedBox.shrink()
          : _ChatCard(
              key: const ValueKey('chat'),
              step: step,
              driverName: driverName,
              driverMessage: driverMessage,
              reply: reply,
              color: color,
            ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    super.key,
    required this.step,
    required this.driverName,
    required this.driverMessage,
    required this.reply,
    required this.color,
  });

  final ChatStep step;
  final String driverName;
  final String driverMessage;
  final String reply;
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(Icons.sports_motorsports, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driverName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('online', style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 10),
            _Bubble(text: driverMessage, fromMe: false, color: color),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: switch (step) {
                ChatStep.typing => const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _TypingIndicator(),
                  ),
                ),
                ChatStep.replied => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _Bubble(text: reply, fromMe: true, color: color),
                ),
                _ => const SizedBox(width: double.infinity),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.fromMe,
    required this.color,
  });

  final String text;
  final bool fromMe;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = Radius.circular(16);
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: fromMe ? color : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              bottomLeft: fromMe ? radius : const Radius.circular(4),
              bottomRight: fromMe ? const Radius.circular(4) : radius,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fromMe ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              if (fromMe)
                const Icon(Icons.done_all, size: 14, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(
                  0,
                  -3 * max(0, sin((_controller.value - i * 0.2) * 2 * pi)),
                ),
                child: Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
