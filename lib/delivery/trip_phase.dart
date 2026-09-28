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
  static const searching = Duration(milliseconds: 3500);
  static const driverFound = Duration(seconds: 3);
  static const toRestaurant = Duration(seconds: 8);
  static const pickingUp = Duration(seconds: 4);
  static const toCustomer = Duration(seconds: 32);
  static const beforeArrivalOverlay = Duration(milliseconds: 4200);
}
