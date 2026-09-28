import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

Widget nightTileBuilder(BuildContext context, Widget tile, TileImage image) {
  return ColorFiltered(colorFilter: _nightFilter, child: tile);
}

final _nightFilter = ColorFilter.matrix(_invertAndTint());

List<double> _invertAndTint() {
  const lr = 0.2126, lg = 0.7152, lb = 0.0722;
  const channels = [(0.42, 10.0), (0.52, 16.0), (0.78, 34.0)];
  return [
    for (final (scale, base) in channels) ...[
      -scale * lr,
      -scale * lg,
      -scale * lb,
      0,
      scale * 255 + base,
    ],
    0,
    0,
    0,
    1,
    0,
  ];
}
