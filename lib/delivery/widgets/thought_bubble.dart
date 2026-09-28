import 'package:flutter/material.dart';

class ThoughtBubble extends StatelessWidget {
  const ThoughtBubble({
    super.key,
    required this.text,
    required this.author,
    required this.color,
  });

  static const double markerWidth = 240;
  static const double markerHeight = 320;

  static const double _gapAboveDriver = 30;

  final String? text;
  final String author;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: markerHeight / 2 + _gapAboveDriver,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
                child: text == null
                    ? const SizedBox.shrink()
                    : _Bubble(
                        key: ValueKey(text),
                        text: text,
                        author: author,
                        color: color,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.text,
    required this.author,
    required this.color,
  });

  final String text;
  final String author;
  final Color color;

  static const _shadow = [
    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _shadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isi hati $author',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black87,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _dot(10),
        const SizedBox(height: 3),
        _dot(6),
      ],
    );
  }

  Widget _dot(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: _shadow,
    ),
  );
}
