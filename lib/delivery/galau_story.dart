import 'trip_phase.dart';

class StoryBeat {
  const StoryBeat(
    this.phase,
    this.text, {
    this.at = 0,
    this.duration = const Duration(milliseconds: 3600),
    this.holdDriver = Duration.zero,
  });

  final TripPhase phase;

  final double at;

  final String text;

  final Duration duration;

  final Duration holdDriver;
}

abstract final class GalauStory {
  static const nightMode = true;
  static const rain = true;

  static const orderDetail = 'Nasi goreng pedas · tanpa bawang goreng';

  static const chatAt = 0.58;

  static const driverChat =
      'Mbak, saya udah dekat. Pagarnya masih yang putih kan?';
  static const customerReply = 'Iya mas, masih putih. Kok tau?';

  static const replyThought = 'Karena dulu aku yang bantu ngecat pagar itu.';

  static const driverNote =
      'Nasi gorengnya tanpa bawang goreng, kayak dulu. '
      'Bahagia terus ya.';

  static const endingLines = ['Kadang, yang kita antar', 'bukan cuma pesanan.'];
  static const endingCaption =
      'Pernah ngalamin juga? Cerita di kolom komentar.';

  static const beats = [
    StoryBeat(TripPhase.driverFound, 'Akhirnya, orderan pertama hari ini.'),
    StoryBeat(
      TripPhase.toRestaurant,
      'Dapur Nusantara... tempat pertama kali kita makan bareng.',
      at: 0.3,
    ),
    StoryBeat(
      TripPhase.pickingUp,
      'Nasi goreng pedas, tanpa bawang goreng... kok persis pesanan dia dulu.',
    ),
    StoryBeat(TripPhase.toCustomer, 'Tunggu... alamat ini kan rumah dia?'),
    StoryBeat(
      TripPhase.toCustomer,
      'Jalan ini dulu tiap malam minggu aku lewatin.',
      at: 0.14,
    ),
    StoryBeat(
      TripPhase.toCustomer,
      'Lampu merah. Kayak kita, berhenti di tengah jalan.',
      at: 0.3,
      holdDriver: Duration(seconds: 3),
    ),
    StoryBeat(
      TripPhase.toCustomer,
      'Tenang. Profesional. Kamu cuma driver.',
      at: 0.46,
    ),
    StoryBeat(
      TripPhase.toCustomer,
      'Rumahnya masih sama. Yang berubah cuma kita.',
      at: 0.88,
    ),
    StoryBeat(
      TripPhase.arrived,
      'Semoga yang sekarang nggak pernah telat jemput kamu.',
      duration: Duration(seconds: 4),
    ),
  ];
}
