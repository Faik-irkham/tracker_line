import 'dart:async';
import 'dart:math';

class DriverSimulator {
  DriverSimulator({
    required this.totalDistance,
    required this.duration,
    this.interval = const Duration(seconds: 1),
  });

  final double totalDistance;

  final Duration duration;

  final Duration interval;

  final _random = Random();
  final _controller = StreamController<double>.broadcast();
  Timer? _timer;
  double _traveled = 0;
  int _ticks = 0;
  int _pausedTicks = 0;

  Stream<double> get updates => _controller.stream;

  void start() {
    _timer?.cancel();
    _traveled = 0;
    _ticks = 0;
    _pausedTicks = 0;
    _controller.add(_traveled);
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void pause(Duration duration) {
    _pausedTicks = (duration.inMilliseconds / interval.inMilliseconds).ceil();
  }

  void _tick() {
    if (_pausedTicks > 0) {
      _pausedTicks--;
      _controller.add(_traveled);
      return;
    }
    _ticks++;
    final tickCount = max(1, duration.inMilliseconds / interval.inMilliseconds);
    final averageStep = totalDistance / tickCount;

    final warmUp = _ticks <= 2 ? 0.5 : 1.0;
    final speedFactor = 0.7 + _random.nextDouble() * 0.6;
    _traveled += averageStep * speedFactor * warmUp;

    if (_traveled >= totalDistance) {
      _traveled = totalDistance;
      _timer?.cancel();
    }
    _controller.add(_traveled);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
