import 'package:flutter/material.dart';

class EndingCard extends StatefulWidget {
  const EndingCard({
    super.key,
    required this.lines,
    required this.caption,
    required this.onTap,
  });

  final List<String> lines;
  final String caption;
  final VoidCallback onTap;

  @override
  State<EndingCard> createState() => _EndingCardState();
}

class _EndingCardState extends State<EndingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1400 * (widget.lines.length + 2)),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _reveal(int index) {
    final steps = widget.lines.length + 2;
    final start = index / steps;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, start + 0.9 / steps, curve: Curves.easeOut),
    );
  }

  Widget _appear(int index, Widget child) {
    final animation = _reveal(index);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: FadeTransition(
        opacity: _reveal(0),
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.lines.length; i++)
                    _appear(
                      i + 1,
                      Text(
                        widget.lines[i],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  _appear(
                    widget.lines.length + 1,
                    Text(
                      widget.caption,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
