import 'package:flutter/widgets.dart';

/// Lays out a row of stat/KPI tiles that reflows to fewer columns as width
/// shrinks, so dense desktop strips stay readable (and never overflow) when a
/// two-pane power layout is forced onto a narrow tablet.
///
/// Columns: 4 when wide, 2 when medium, 1 when very narrow.
class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key, required this.tiles, this.gap = 12});

  final List<Widget> tiles;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 560
            ? 4
            : width >= 320
                ? 2
                : 1;
        final effectiveColumns = columns.clamp(1, tiles.length);
        final itemWidth =
            (width - gap * (effectiveColumns - 1)) / effectiveColumns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: itemWidth, child: tile),
          ],
        );
      },
    );
  }
}
