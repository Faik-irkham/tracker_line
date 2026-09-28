enum TripPhase {
  searching,
  driverFound,
  toRestaurant,
  pickingUp,
  toCustomer,
  arrived;

  int get step => switch (this) {
    searching => 0,
    driverFound || toRestaurant || pickingUp => 1,
    toCustomer => 2,
    arrived => 3,
  };

  bool get hasDriver => this != searching;

  bool get onDeliveryLeg => this == toCustomer || this == arrived;
}

abstract final class DemoTimeline {
  static const searching = Duration(milliseconds: 2500);
  static const driverFound = Duration(milliseconds: 2000);
  static const pickingUp = Duration(milliseconds: 3600);
  static const beforeArrivalOverlay = Duration(milliseconds: 3500);

  static const gpsInterval = Duration(milliseconds: 500);
  static const cruiseSpeed = 200.0;
  static const storySpeed = 40.0;
}
