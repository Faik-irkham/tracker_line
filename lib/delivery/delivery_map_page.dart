import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'driver_simulator.dart';
import 'galau_story.dart';
import 'route_path.dart';
import 'route_service.dart';
import 'trip_phase.dart';
import 'widgets/arrival_overlay.dart';
import 'widgets/chat_peek.dart';
import 'widgets/ending_card.dart';
import 'widgets/motor_driver_marker.dart';
import 'widgets/night_map.dart';
import 'widgets/notification_banner.dart';
import 'widgets/person_marker.dart';
import 'widgets/radar_layer.dart';
import 'widgets/rain_overlay.dart';
import 'widgets/store_marker.dart';
import 'widgets/thought_bubble.dart';
import 'widgets/trip_panel.dart';

enum _CameraMode { auto, overview, follow, free }

typedef _IdleDriver = ({LatLng point, double heading});

class DeliveryMapPage extends StatefulWidget {
  const DeliveryMapPage({super.key});

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage>
    with TickerProviderStateMixin {
  static const _driverStart = LatLng(-6.1885, 106.8375);
  static const _restaurant = LatLng(-6.1905, 106.8395);
  static const _customer = LatLng(-6.2025, 106.8495);
  static const _restaurantName = 'Dapur Nusantara';

  static const _driver = DriverProfile(
    name: 'Mas Driver',
    rating: '4,9',
    vehicle: 'Honda Vario 125 · Hitam',
    plate: 'B 4821 KZT',
  );

  static const _brandColor = Color(0xFF3B82F6);

  static const _etaSpeedMetersPerSecond = 7.0;
  static const _pickupMinutes = 3.0;

  static const _nearMeters = 450.0;

  static const _searchRadiusMeters = 600.0;

  static const _otherDriversInRadar = 3;
  static const _driversOutsideRadar = 2;

  final _mapController = MapController();
  final _routeService = const RouteService();
  final _topBarKey = GlobalKey();
  final _panelKey = GlobalKey();
  final _chatKey = GlobalKey();

  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  late final Ticker _cameraTicker = createTicker(_onCameraTick);
  Duration _lastCameraTick = Duration.zero;

  RoutePath? _toRestaurant;
  RoutePath? _toCustomer;
  List<_IdleDriver> _nearbyDrivers = const [];
  double _radarRadius = _searchRadiusMeters;

  TripPhase _phase = TripPhase.searching;

  RoutePath? _leg;
  double _fromMeters = 0;
  double _toMeters = 0;
  DriverSimulator? _simulator;
  StreamSubscription<double>? _subscription;
  Completer<void>? _legDone;

  int _runId = 0;
  bool _chatPlayed = false;
  ChatStep _chatStep = ChatStep.hidden;

  BannerMessage? _banner;
  Timer? _bannerTimer;
  bool _showArrival = false;
  bool _showEnding = false;

  String? _thought;
  Timer? _thoughtTimer;
  final _playedBeats = <int>{};

  bool _recordingMode = false;

  bool _mapReady = false;
  bool _snapCamera = true;
  _CameraMode _cameraMode = _CameraMode.auto;

  double get _traveled => lerpDouble(_fromMeters, _toMeters, _move.value)!;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _runId++;
    _stopLeg();
    _bannerTimer?.cancel();
    _thoughtTimer?.cancel();
    _cameraTicker.dispose();
    _move.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    final routes = await Future.wait([
      _routeService.fetchRoute(_driverStart, _restaurant),
      _routeService.fetchRoute(_restaurant, _customer),
    ]);
    if (!mounted) return;
    setState(() {
      _toRestaurant = routes[0];
      _toCustomer = routes[1];
      _nearbyDrivers = _generateNearbyDrivers(routes[0]);
    });
    _cameraTicker.start();
    _runTrip();
  }

  List<_IdleDriver> _generateNearbyDrivers(RoutePath toRestaurant) {
    const distance = Distance();
    final random = Random(7);
    final chosen = toRestaurant.start;
    final chosenDistance = distance(_restaurant, chosen);
    final chosenBearing = distance.bearing(_restaurant, chosen);

    final radius = max(_searchRadiusMeters, chosenDistance + 200);
    _radarRadius = radius;

    const others = _otherDriversInRadar + _driversOutsideRadar;
    _IdleDriver other(int i) {
      final inside = i <= _otherDriversInRadar;
      final (minMeters, maxMeters) = inside
          ? (chosenDistance + 80, radius - 40)
          : (radius + 120, radius + 450);
      return (
        point: distance.offset(
          _restaurant,
          minMeters + random.nextDouble() * (maxMeters - minMeters),
          chosenBearing + i * 360 / (others + 1) + random.nextDouble() * 20,
        ),
        heading: random.nextDouble() * 360,
      );
    }

    return [
      (point: chosen, heading: toRestaurant.headingAt(0)),
      for (var i = 1; i <= others; i++) other(i),
    ];
  }

  Future<void> _runTrip() async {
    final toRestaurant = _toRestaurant;
    final toCustomer = _toCustomer;
    if (toRestaurant == null || toCustomer == null) return;

    final runId = ++_runId;
    bool cancelled() => !mounted || runId != _runId;

    _stopLeg();
    _bannerTimer?.cancel();
    _thoughtTimer?.cancel();
    _playedBeats.clear();
    _move.value = 0;
    setState(() {
      _phase = TripPhase.searching;
      _leg = toRestaurant;
      _fromMeters = 0;
      _toMeters = 0;
      _chatPlayed = false;
      _chatStep = ChatStep.hidden;
      _showArrival = false;
      _showEnding = false;
      _banner = null;
      _thought = null;
      _cameraMode = _CameraMode.auto;
    });

    await Future<void>.delayed(DemoTimeline.searching);
    if (cancelled()) return;
    _setPhase(TripPhase.driverFound);
    _notify(
      BannerMessage(
        title: 'Driver ditemukan!',
        body: '${_driver.name} (${_driver.plate}) menuju restoran',
        icon: Icons.two_wheeler,
      ),
    );

    await Future<void>.delayed(DemoTimeline.driverFound);
    if (cancelled()) return;
    _setPhase(TripPhase.toRestaurant);
    await _driveLeg(toRestaurant, DemoTimeline.toRestaurant);
    if (cancelled()) return;

    _setPhase(TripPhase.pickingUp);
    _notify(
      const BannerMessage(
        title: 'Driver sampai di restoran',
        body: 'Pesananmu sedang diambil dari $_restaurantName',
        icon: Icons.storefront,
      ),
    );

    await Future<void>.delayed(DemoTimeline.pickingUp);
    if (cancelled()) return;
    _setPhase(TripPhase.toCustomer);
    _notify(
      BannerMessage(
        title: 'Pesanan dalam perjalanan',
        body: '${_driver.name} sedang menuju lokasimu',
      ),
    );
    await _driveLeg(toCustomer, DemoTimeline.toCustomer);
    if (cancelled()) return;

    _setPhase(TripPhase.arrived);
    _notify(
      BannerMessage(
        title: 'Driver sudah sampai',
        body: 'Silakan temui ${_driver.name} di depan',
        icon: Icons.home_rounded,
      ),
    );

    await Future<void>.delayed(DemoTimeline.beforeArrivalOverlay);
    if (cancelled()) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _banner = null;
      _showArrival = true;
    });
  }

  Future<void> _driveLeg(RoutePath leg, Duration duration) {
    _stopLeg();
    _move.value = 0;
    setState(() {
      _leg = leg;
      _fromMeters = 0;
      _toMeters = 0;
    });

    final done = Completer<void>();
    _legDone = done;
    final simulator = DriverSimulator(
      totalDistance: leg.totalDistance,
      duration: duration,
      interval: _move.duration!,
    );
    _simulator = simulator;
    _subscription = simulator.updates.listen((traveled) {
      _fromMeters = _traveled;
      _toMeters = traveled;
      final animation = _move.forward(from: 0);
      _playStoryBeat();

      if (_phase == TripPhase.toCustomer &&
          !_chatPlayed &&
          traveled >= leg.totalDistance * GalauStory.chatAt) {
        _chatPlayed = true;
        _playChat();
      }

      if (traveled >= leg.totalDistance) {
        animation.whenCompleteOrCancel(() {
          if (!done.isCompleted) done.complete();
        });
      }
    });
    simulator.start();
    return done.future;
  }

  void _stopLeg() {
    _subscription?.cancel();
    _subscription = null;
    _simulator?.dispose();
    _simulator = null;
    _move.stop();
    final done = _legDone;
    if (done != null && !done.isCompleted) done.complete();
  }

  void _setPhase(TripPhase phase) {
    setState(() => _phase = phase);
    if (!_isDriving) _playStoryBeat();
  }

  bool get _isDriving =>
      _phase == TripPhase.toRestaurant || _phase == TripPhase.toCustomer;

  void _playStoryBeat() {
    final leg = _leg;
    final progress = _isDriving && leg != null && leg.totalDistance > 0
        ? _toMeters / leg.totalDistance
        : 0.0;

    for (var i = 0; i < GalauStory.beats.length; i++) {
      final beat = GalauStory.beats[i];
      if (_playedBeats.contains(i) ||
          beat.phase != _phase ||
          progress < beat.at) {
        continue;
      }
      _playedBeats.add(i);
      if (beat.holdDriver > Duration.zero) _simulator?.pause(beat.holdDriver);
      _showThought(beat.text, beat.duration);
      return;
    }
  }

  void _showThought(String text, Duration duration) {
    setState(() => _thought = text);
    _thoughtTimer?.cancel();
    _thoughtTimer = Timer(duration, () {
      if (mounted) setState(() => _thought = null);
    });
  }

  Future<void> _playChat() async {
    final runId = _runId;
    bool cancelled() => !mounted || runId != _runId;

    Future<bool> step(ChatStep next, Duration wait) async {
      await Future<void>.delayed(wait);
      if (cancelled()) return false;
      setState(() => _chatStep = next);
      return true;
    }

    _bannerTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _banner = null;
      _chatStep = ChatStep.driverSent;
    });
    if (!await step(ChatStep.typing, const Duration(milliseconds: 1600))) {
      return;
    }
    if (!await step(ChatStep.replied, const Duration(milliseconds: 1800))) {
      return;
    }
    HapticFeedback.mediumImpact();

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (cancelled()) return;
    _showThought(GalauStory.replyThought, const Duration(milliseconds: 3800));
    await step(ChatStep.hidden, const Duration(milliseconds: 2600));
  }

  void _notify(BannerMessage message) {
    HapticFeedback.mediumImpact();
    setState(() => _banner = message);
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  void _toggleRecordingMode() {
    setState(() => _recordingMode = !_recordingMode);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            _recordingMode
                ? 'Mode rekam aktif. Ketuk 2x bar atas untuk mengulang.'
                : 'Mode rekam nonaktif',
          ),
        ),
      );
  }

  LatLng get _driverPosition => _leg!.pointAt(_traveled);

  EdgeInsets get _mapPadding {
    final chatHeight = _chatStep == ChatStep.hidden
        ? 0.0
        : _chatKey.currentContext?.size?.height ?? 0.0;
    final top = max(_topBarKey.currentContext?.size?.height ?? 120, chatHeight);
    final bottom = _panelKey.currentContext?.size?.height ?? 380;
    final bubbleRoom = _phase.hasDriver;
    final side = bubbleRoom ? 110.0 : 40.0;
    return EdgeInsets.fromLTRB(
      side,
      top + (bubbleRoom ? 150 : 64),
      _recordingMode ? side : max(side, 96),
      bottom + 40,
    );
  }

  CameraFit _fit(List<LatLng> points, {double maxZoom = 17}) {
    return CameraFit.coordinates(
      coordinates: points,
      padding: _mapPadding,
      maxZoom: maxZoom,
    );
  }

  CameraFit? _cameraTarget() {
    if (_leg == null) return null;
    final driver = _driverPosition;

    switch (_cameraMode) {
      case _CameraMode.free:
        return null;
      case _CameraMode.follow:
        return _fit([driver], maxZoom: 16.5);
      case _CameraMode.overview:
        return _fit([
          driver,
          if (!_phase.onDeliveryLeg) _restaurant,
          _customer,
        ]);
      case _CameraMode.auto:
        return switch (_phase) {
          TripPhase.searching => _fit([
            _restaurant,
            for (final d in _nearbyDrivers) d.point,
          ], maxZoom: 16),
          TripPhase.driverFound ||
          TripPhase.toRestaurant => _fit([driver, _restaurant], maxZoom: 16.5),
          TripPhase.pickingUp => _fit([_restaurant]),
          TripPhase.toCustomer => _deliveryShot(driver),
          TripPhase.arrived => _fit([_customer]),
        };
    }
  }

  CameraFit _deliveryShot(LatLng driver) {
    final leg = _leg!;
    final progress = leg.totalDistance == 0
        ? 1.0
        : _traveled / leg.totalDistance;
    if (progress < 0.12 || progress >= 0.7) {
      return _fit([driver, _customer]);
    }
    return _fit([driver], maxZoom: 16);
  }

  void _onCameraTick(Duration elapsed) {
    final dt = (elapsed - _lastCameraTick).inMicroseconds / 1e6;
    _lastCameraTick = elapsed;
    if (!_mapReady) return;

    final fit = _cameraTarget();
    if (fit == null) return;

    final camera = _mapController.camera;
    final target = fit.fit(camera);
    final t = _snapCamera ? 1.0 : 1 - exp(-dt * 2.5);
    _snapCamera = false;

    final center = LatLng(
      lerpDouble(camera.center.latitude, target.center.latitude, t)!,
      lerpDouble(camera.center.longitude, target.center.longitude, t)!,
    );
    final zoom = lerpDouble(camera.zoom, target.zoom, t)!;
    if (center == camera.center && zoom == camera.zoom) return;
    _mapController.move(center, zoom);
  }

  void _setCameraMode(_CameraMode mode) {
    setState(() => _cameraMode = mode);
  }

  Widget _buildRouteLayer() {
    final toRestaurant = _toRestaurant!;
    final toCustomer = _toCustomer!;
    final traveled = _traveled;
    const traveledColor = Color(0xFFB0BEC5);
    final borderColor = Color.lerp(_brandColor, Colors.black, 0.35)!;

    Polyline active(RoutePath route) => Polyline(
      points: route.remaining(traveled),
      strokeWidth: 6,
      color: _brandColor,
      borderStrokeWidth: 2,
      borderColor: borderColor,
    );
    Polyline passed(RoutePath route) => Polyline(
      points: route.traveled(traveled),
      strokeWidth: 5,
      color: traveledColor,
    );

    return PolylineLayer(
      polylines: [
        if (_phase.hasDriver && !_phase.onDeliveryLeg) ...[
          Polyline(
            points: toCustomer.points,
            strokeWidth: 4,
            color: _brandColor.withValues(alpha: 0.6),
            pattern: StrokePattern.dashed(segments: const [12, 10]),
          ),
          passed(toRestaurant),
          active(toRestaurant),
        ],
        if (_phase.onDeliveryLeg) ...[passed(toCustomer), active(toCustomer)],
      ],
    );
  }

  Widget _buildMarkerLayer() {
    final leg = _leg!;
    final traveled = _traveled;
    return MarkerLayer(
      markers: [
        if (_phase == TripPhase.searching) ...[
          for (final d in _nearbyDrivers)
            Marker(
              point: d.point,
              width: 60,
              height: 60,
              child: MotorDriverMarker(
                heading: d.heading,
                color: _brandColor,
                size: 60,
                showPulse: false,
              ),
            ),
        ],
        const Marker(
          point: _restaurant,
          width: StoreMarker.width,
          height: StoreMarker.height,
          child: StoreMarker(),
        ),
        const Marker(
          point: _customer,
          width: PersonMarker.width,
          height: PersonMarker.height,
          child: PersonMarker(),
        ),
        if (_phase.hasDriver)
          Marker(
            point: leg.pointAt(traveled),
            width: 72,
            height: 72,
            child: MotorDriverMarker(
              heading: leg.headingAt(traveled),
              color: _brandColor,
            ),
          ),
      ],
    );
  }

  Widget _buildPanel() {
    final toRestaurant = _toRestaurant!;
    final toCustomer = _toCustomer!;
    final leg = _leg!;
    final traveled = _traveled;
    final legRemaining = leg.totalDistance - traveled;

    final beforePickup = !_phase.onDeliveryLeg;
    final remainingToCustomer = beforePickup
        ? legRemaining + toCustomer.totalDistance
        : legRemaining;
    final totalDistance = toRestaurant.totalDistance + toCustomer.totalDistance;
    final etaMinutes =
        remainingToCustomer / _etaSpeedMetersPerSecond / 60 +
        (beforePickup ? _pickupMinutes : 0);

    return TripPanel(
      key: _panelKey,
      phase: _phase,
      isNear: _phase == TripPhase.toCustomer && legRemaining < _nearMeters,
      legRemainingMeters: legRemaining,
      progress: totalDistance == 0
          ? 1
          : 1 - remainingToCustomer / totalDistance,
      etaMinutes: etaMinutes,
      nearbyDriverCount: 1 + _otherDriversInRadar,
      restaurantName: _restaurantName,
      driver: _driver,
      color: _brandColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _toRestaurant != null && _toCustomer != null;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _restaurant,
              initialZoom: 15,
              backgroundColor: GalauStory.nightMode
                  ? const Color(0xFF0E1628)
                  : const Color(0xFFE0E0E0),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () => _mapReady = true,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _cameraMode != _CameraMode.free) {
                  setState(() => _cameraMode = _CameraMode.free);
                }
              },
            ),
            children: [
              // Tile OpenStreetMap publik: gratis tanpa API key, tapi hanya
              // untuk pengembangan/trafik kecil. Untuk produksi ganti ke
              // penyedia tile (Mapbox, MapTiler, Stadia, dll.) dan API key-nya.
              // Kebijakan: https://operations.osmfoundation.org/policies/tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.tracker_line',
                maxNativeZoom: 19,
                tileBuilder: GalauStory.nightMode ? nightTileBuilder : null,
              ),
              if (ready) ...[
                if (_phase == TripPhase.searching)
                  RadarLayer(
                    center: _restaurant,
                    radiusMeters: _radarRadius,
                    color: _brandColor,
                  ),
                AnimatedBuilder(
                  animation: _move,
                  builder: (context, _) => _buildRouteLayer(),
                ),
                AnimatedBuilder(
                  animation: _move,
                  builder: (context, _) => _buildMarkerLayer(),
                ),
                if (_phase.hasDriver)
                  AnimatedBuilder(
                    animation: _move,
                    builder: (context, _) => MarkerLayer(
                      markers: [
                        Marker(
                          point: _driverPosition,
                          width: ThoughtBubble.markerWidth,
                          height: ThoughtBubble.markerHeight,
                          child: ThoughtBubble(
                            text: _thought,
                            author: _driver.name,
                            color: _brandColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
          if (GalauStory.rain) const Positioned.fill(child: RainOverlay()),
          if (!ready) const _LoadingOverlay(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              key: _topBarKey,
              onDoubleTap: ready ? _runTrip : null,
              onLongPress: _toggleRecordingMode,
              child: const _TopBar(subtitle: GalauStory.orderDetail),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              key: _chatKey,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Stack(
                  children: [
                    NotificationBanner(message: _banner, color: _brandColor),
                    ChatPeek(
                      step: _chatStep,
                      driverName: _driver.name,
                      driverMessage: GalauStory.driverChat,
                      reply: GalauStory.customerReply,
                      color: _brandColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(child: _MapAttribution()),
                        if (!_recordingMode) ...[
                          const SizedBox(width: 12),
                          _CameraButtons(
                            mode: _cameraMode,
                            onChanged: _setCameraMode,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _move,
                    builder: (context, _) => _buildPanel(),
                  ),
                ],
              ),
            ),
          if (_showArrival)
            Positioned.fill(
              child: ArrivalOverlay(
                color: _brandColor,
                driverName: _driver.name,
                driverNote: GalauStory.driverNote,
                onDone: () => setState(() {
                  _showArrival = false;
                  _showEnding = true;
                }),
                onOrderAgain: _runTrip,
              ),
            ),
          if (_showEnding)
            Positioned.fill(
              child: EndingCard(
                lines: GalauStory.endingLines,
                caption: GalauStory.endingCaption,
                onTap: _runTrip,
              ),
            ),
        ],
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: Colors.black87),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Material(
          elevation: 3,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan #TL-2048',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraButtons extends StatelessWidget {
  const _CameraButtons({required this.mode, required this.onChanged});

  final _CameraMode mode;
  final ValueChanged<_CameraMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget button(_CameraMode value, IconData icon, String tooltip) {
      final selected = mode == value;
      return IconButton.filled(
        tooltip: tooltip,
        isSelected: selected,
        style: IconButton.styleFrom(
          backgroundColor: selected ? colors.primary : colors.surface,
          foregroundColor: selected ? colors.onPrimary : colors.onSurface,
          elevation: 3,
          shadowColor: Colors.black26,
        ),
        onPressed: () => onChanged(value),
        icon: Icon(icon),
      );
    }

    return Column(
      children: [
        button(
          _CameraMode.auto,
          Icons.movie_filter_outlined,
          'Kamera otomatis',
        ),
        const SizedBox(height: 8),
        button(_CameraMode.overview, Icons.route, 'Lihat rute'),
        const SizedBox(height: 8),
        button(_CameraMode.follow, Icons.navigation, 'Ikuti driver'),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black26,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 14),
                Text('Mencari rute...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
