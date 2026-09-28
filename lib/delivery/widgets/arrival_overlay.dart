import 'dart:math';

import 'package:flutter/material.dart';

class ArrivalOverlay extends StatefulWidget {
  const ArrivalOverlay({
    super.key,
    required this.color,
    required this.driverName,
    required this.onDone,
    required this.onOrderAgain,
    this.driverNote,
  });

  final Color color;
  final String driverName;

  final String? driverNote;
  final VoidCallback onDone;
  final VoidCallback onOrderAgain;

  @override
  State<ArrivalOverlay> createState() => _ArrivalOverlayState();
}

class _ArrivalOverlayState extends State<ArrivalOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..forward();

  late final List<_ConfettiPiece> _pieces = _ConfettiPiece.generate(
    count: 90,
    colors: [
      widget.color,
      const Color(0xFF172554),
      const Color(0xFF1D4ED8),
      const Color(0xFF93C5FD),
      const Color(0xFFDBEAFE),
    ],
  );

  int _rating = 0;

  @override
  void dispose() {
    _enter.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fade = CurvedAnimation(parent: _enter, curve: const Interval(0, 0.4));
    final pop = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.1, 1, curve: Curves.elasticOut),
    );
    final slide = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: fade,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black45),
          Center(
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(slide),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: pop,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.color.withValues(alpha: 0.4),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Pesanan sudah sampai!',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Selamat menikmati. Gimana pengantaran '
                        '${widget.driverName}?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (widget.driverNote case final note?) ...[
                        const SizedBox(height: 16),
                        _DriverNote(
                          driverName: widget.driverName,
                          note: note,
                          color: widget.color,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 1; i <= 5; i++)
                            GestureDetector(
                              onTap: () => setState(() => _rating = i),
                              child: AnimatedScale(
                                scale: i <= _rating ? 1.2 : 1,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    i <= _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 38,
                                    color: i <= _rating
                                        ? Colors.amber
                                        : theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onOrderAgain,
                              child: const Text('Pesan lagi'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.onDone,
                              child: const Text('Selesai'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(
                  pieces: _pieces,
                  progress: _confetti.value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverNote extends StatelessWidget {
  const _DriverNote({
    required this.driverName,
    required this.note,
    required this.color,
  });

  final String driverName;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan dari $driverName',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.x,
    required this.delay,
    required this.fallSpeed,
    required this.drift,
    required this.spin,
    required this.size,
    required this.color,
  });

  final double x;
  final double delay;
  final double fallSpeed;
  final double drift;
  final double spin;
  final Size size;
  final Color color;

  static List<_ConfettiPiece> generate({
    required int count,
    required List<Color> colors,
  }) {
    final random = Random();
    return [
      for (var i = 0; i < count; i++)
        _ConfettiPiece(
          x: random.nextDouble(),
          delay: random.nextDouble() * 0.3,
          fallSpeed: 0.8 + random.nextDouble() * 0.7,
          drift: (random.nextDouble() - 0.5) * 0.25,
          spin: (random.nextDouble() - 0.5) * 16,
          size: Size(6 + random.nextDouble() * 6, 4 + random.nextDouble() * 4),
          color: colors[random.nextInt(colors.length)],
        ),
    ];
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.pieces, required this.progress});

  final List<_ConfettiPiece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final t = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (t == 0 || t == 1) continue;

      final dx =
          (piece.x + piece.drift * t + sin(t * 10 + piece.x * 6) * 0.02) *
          size.width;
      final dy = (-0.05 + t * piece.fallSpeed * 1.1) * size.height;
      final opacity = t > 0.8 ? (1 - t) / 0.2 : 1.0;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(t * piece.spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size.width,
          height: piece.size.height,
        ),
        Paint()..color = piece.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
