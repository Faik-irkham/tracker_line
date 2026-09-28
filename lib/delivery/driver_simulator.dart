import 'dart:async';
import 'dart:math';

class DriverSimulator {
  DriverSimulator({
    required this.totalDistance,
    required this.cruiseSpeed,
    required this.slowSpeed,
    required this.shouldSlowDown,
    this.interval = const Duration(milliseconds: 500),
  });

  final double totalDistance;

  final double cruiseSpeed;

  final double slowSpeed;

  final bool Function() shouldSlowDown;

  final Duration interval;

  final _random = Random();
  final _controller = StreamController<double>.broadcast();
  Timer? _timer;
  double _traveled = 0;
  double _speed = 0;
  int _pausedTicks = 0;

  Stream<double> get updates => _controller.stream;

  void start() {
    _timer?.cancel();
    _traveled = 0;
    _speed = 0;
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
      _speed = 0;
      _controller.add(_traveled);
      return;
    }

    final target =
        (shouldSlowDown() ? slowSpeed : cruiseSpeed) *
        (0.85 + _random.nextDouble() * 0.3);
    _speed += (target - _speed) * 0.45;
    _traveled += _speed * interval.inMilliseconds / 1000;

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
