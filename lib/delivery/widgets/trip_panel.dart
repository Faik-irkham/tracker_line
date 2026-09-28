import 'package:flutter/material.dart';

import '../trip_phase.dart';

class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.rating,
    required this.vehicle,
    required this.plate,
  });

  final String name;
  final String rating;
  final String vehicle;
  final String plate;
}

class TripPanel extends StatelessWidget {
  const TripPanel({
    super.key,
    required this.phase,
    required this.isNear,
    required this.legRemainingMeters,
    required this.progress,
    required this.etaMinutes,
    required this.nearbyDriverCount,
    required this.restaurantName,
    required this.driver,
    required this.color,
  });

  final TripPhase phase;

  final bool isNear;

  final double legRemainingMeters;

  final double progress;

  final double etaMinutes;

  final int nearbyDriverCount;
  final String restaurantName;
  final DriverProfile driver;
  final Color color;

  String get _title => switch (phase) {
    TripPhase.searching => 'Mencari driver terdekat...',
    TripPhase.driverFound => 'Driver ditemukan!',
    TripPhase.toRestaurant => 'Driver menuju restoran',
    TripPhase.pickingUp => 'Driver sedang mengambil pesanan',
    TripPhase.toCustomer =>
      isNear ? 'Driver sudah dekat!' : 'Driver sedang menuju lokasimu',
    TripPhase.arrived => 'Pesanan sudah sampai',
  };

  String get _subtitle => switch (phase) {
    TripPhase.searching => 'Menghubungi driver di sekitar restoran',
    TripPhase.driverFound => '${driver.name} akan mengambil pesananmu',
    TripPhase.toRestaurant =>
      '$restaurantName · ${_formatDistance(legRemainingMeters)}',
    TripPhase.pickingUp => restaurantName,
    TripPhase.toCustomer => _formatDistance(legRemainingMeters),
    TripPhase.arrived => 'Silakan temui driver di lokasimu',
  };

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m lagi';
    final km = (meters / 1000).toStringAsFixed(1).replaceAll('.', ',');
    return '$km km lagi';
  }

  String get _etaText {
    if (phase == TripPhase.arrived) return 'Tiba';
    if (etaMinutes < 1) return '< 1 mnt';
    return '${etaMinutes.ceil()} mnt';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indeterminate =
        phase == TripPhase.searching || phase == TripPhase.pickingUp;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Column(
                        key: ValueKey(_title),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (phase.hasDriver)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _etaText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Color.lerp(color, Colors.black, 0.2),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _TripStepper(
                step: phase.step,
                done: phase == TripPhase.arrived,
                color: color,
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: indeterminate ? null : progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: phase.hasDriver
                      ? _DriverInfo(driver: driver, color: color)
                      : _SearchingInfo(count: nearbyDriverCount, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripStepper extends StatelessWidget {
  const _TripStepper({
    required this.step,
    required this.done,
    required this.color,
  });

  final int step;

  final bool done;
  final Color color;

  static const _steps = [
    (icon: Icons.person_search, label: 'Cari driver'),
    (icon: Icons.storefront, label: 'Ambil pesanan'),
    (icon: Icons.delivery_dining, label: 'Diantar'),
    (icon: Icons.home_rounded, label: 'Sampai'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive = theme.colorScheme.outlineVariant;

    Widget line({required bool visible, required bool active}) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 3,
          color: !visible
              ? Colors.transparent
              : active
              ? color
              : inactive,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      line(visible: i > 0, active: i <= step),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= step ? color : theme.colorScheme.surface,
                          border: Border.all(
                            color: i <= step ? color : inactive,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          i < step || done
                              ? Icons.check_rounded
                              : _steps[i].icon,
                          size: 18,
                          color: i <= step
                              ? Colors.white
                              : theme.colorScheme.outline,
                        ),
                      ),
                      line(visible: i < _steps.length - 1, active: i < step),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[i].label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: i == step ? FontWeight.w700 : FontWeight.w400,
                    color: i <= step
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SearchingInfo extends StatelessWidget {
  const _SearchingInfo({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const ValueKey('searching'),
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.two_wheeler, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$count driver dalam jangkauan radar',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        ),
      ],
    );
  }
}

class _DriverInfo extends StatelessWidget {
  const _DriverInfo({required this.driver, required this.color});

  final DriverProfile driver;
  final Color color;

  void _notImplemented(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature belum tersedia')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const ValueKey('driver'),
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.sports_motorsports, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      driver.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                  Text(driver.rating, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                driver.vehicle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  driver.plate,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Chat',
          onPressed: () => _notImplemented(context, 'Chat'),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          tooltip: 'Telepon',
          onPressed: () => _notImplemented(context, 'Telepon'),
          icon: const Icon(Icons.call_outlined),
        ),
      ],
    );
  }
}
