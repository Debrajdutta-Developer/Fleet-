import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../report_providers.dart' show ChartDataPoint;

// Helper to get distinct colors for groups or slices
List<Color> getPalette(ColorScheme scheme) {
  return [
    scheme.primary,
    scheme.tertiary,
    scheme.secondary,
    scheme.error,
    scheme.primaryContainer,
    scheme.secondaryContainer,
    Colors.teal,
    Colors.amber,
    Colors.purple,
    Colors.deepOrange,
  ];
}

// Custom Painter for dashed lines
void drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint,
    double dashWidth, double dashSpace) {
  double dx = p2.dx - p1.dx;
  double dy = p2.dy - p1.dy;
  double len = math.sqrt(dx * dx + dy * dy);
  double udx = dx / len;
  double udy = dy / len;
  double currentDist = 0.0;
  while (currentDist < len) {
    canvas.drawLine(
      Offset(p1.dx + udx * currentDist, p1.dy + udy * currentDist),
      Offset(
        p1.dx + udx * math.min(currentDist + dashWidth, len),
        p1.dy + udy * math.min(currentDist + dashWidth, len),
      ),
      paint,
    );
    currentDist += dashWidth + dashSpace;
  }
}

// --- LINE CHART & AREA CHART PAINTER ---
class LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final ColorScheme colorScheme;
  final bool fillArea;

  LineChartPainter({
    required this.data,
    required this.colorScheme,
    required this.fillArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 1. Identify groups
    final groups = data.map((d) => d.group ?? 'Default').toSet().toList();
    final palette = getPalette(colorScheme);

    // 2. Identify unique X labels and max/min Y values
    final xLabels = data.map((d) => d.label).toSet().toList()..sort();
    final double maxY =
        data.map((d) => d.value).reduce((a, b) => math.max(a, b));
    final double minY = 0.0; // Anchored at zero
    final double targetMaxY = maxY * 1.15; // Give 15% top margin

    // Padding settings
    const double paddingLeft = 60.0;
    const double paddingRight = 20.0;
    const double paddingTop = 25.0;
    const double paddingBottom = 40.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    // Paint for Grid lines & border (1px dashed, secondary text color)
    final gridPaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw Grid Lines (Horizontal)
    const int horizontalSegments = 4;
    for (int i = 0; i <= horizontalSegments; i++) {
      final double yRatio = i / horizontalSegments;
      final double yPos = paddingTop + chartHeight * (1 - yRatio);

      // Draw grid line
      if (i > 0 && i < horizontalSegments) {
        drawDashedLine(
          canvas,
          Offset(paddingLeft, yPos),
          Offset(size.width - paddingRight, yPos),
          gridPaint,
          4,
          4,
        );
      } else {
        canvas.drawLine(
          Offset(paddingLeft, yPos),
          Offset(size.width - paddingRight, yPos),
          borderPaint,
        );
      }

      // Draw Y Labels
      final double yVal = minY + (targetMaxY - minY) * yRatio;
      textPainter.text = TextSpan(
        text: '\$${yVal.toStringAsFixed(0)}',
        style: TextStyle(
          color: colorScheme.onBackground.withOpacity(0.6),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
            paddingLeft - textPainter.width - 8, yPos - textPainter.height / 2),
      );
    }

    // Draw X Axis line
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, size.height - paddingBottom),
      borderPaint,
    );

    // Draw X labels
    if (xLabels.isNotEmpty) {
      final double xStep =
          xLabels.length > 1 ? chartWidth / (xLabels.length - 1) : chartWidth;
      for (int i = 0; i < xLabels.length; i++) {
        final double xPos = paddingLeft + i * xStep;

        // Draw vertical tick marks
        canvas.drawLine(
          Offset(xPos, size.height - paddingBottom),
          Offset(xPos, size.height - paddingBottom + 4),
          borderPaint,
        );

        // Draw X Label text
        // Filter text if too crowded
        if (xLabels.length <= 12 || i % (xLabels.length ~/ 6 + 1) == 0) {
          textPainter.text = TextSpan(
            text: xLabels[i],
            style: TextStyle(
              color: colorScheme.onBackground.withOpacity(0.6),
              fontSize: 10,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
                xPos - textPainter.width / 2, size.height - paddingBottom + 8),
          );
        }
      }
    }

    // 3. Draw Lines / Area for each group
    for (int g = 0; g < groups.length; g++) {
      final groupName = groups[g];
      final groupColor = palette[g % palette.length];
      final groupData =
          data.where((d) => (d.group ?? 'Default') == groupName).toList();

      // Sort group data by label order
      groupData.sort((a, b) =>
          xLabels.indexOf(a.label).compareTo(xLabels.indexOf(b.label)));

      if (groupData.isEmpty) continue;

      final Path path = Path();
      final double xStep =
          xLabels.length > 1 ? chartWidth / (xLabels.length - 1) : chartWidth;

      bool isFirst = true;
      Offset firstOffset = Offset.zero;
      Offset lastOffset = Offset.zero;

      for (final d in groupData) {
        final int idx = xLabels.indexOf(d.label);
        if (idx == -1) continue;

        final double xPos = paddingLeft + idx * xStep;
        final double yRatio =
            targetMaxY > 0 ? (d.value - minY) / (targetMaxY - minY) : 0.0;
        final double yPos = paddingTop + chartHeight * (1 - yRatio);

        if (isFirst) {
          path.moveTo(xPos, yPos);
          firstOffset = Offset(xPos, yPos);
          isFirst = false;
        } else {
          path.lineTo(xPos, yPos);
        }
        lastOffset = Offset(xPos, yPos);

        // Draw dots at points
        final dotPaint = Paint()
          ..color = groupColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(xPos, yPos), 4.0, dotPaint);

        final dotStrokePaint = Paint()
          ..color = colorScheme.background
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(xPos, yPos), 4.0, dotStrokePaint);
      }

      // Draw path line
      final linePaint = Paint()
        ..color = groupColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      // Draw gradient area if enabled
      if (fillArea && !isFirst) {
        final areaPath = Path.from(path)
          ..lineTo(lastOffset.dx, size.height - paddingBottom)
          ..lineTo(firstOffset.dx, size.height - paddingBottom)
          ..close();

        final areaPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              groupColor.withOpacity(0.25),
              groupColor.withOpacity(0.01),
            ],
          ).createShader(Rect.fromLTRB(
            firstOffset.dx,
            paddingTop,
            lastOffset.dx,
            size.height - paddingBottom,
          ))
          ..style = PaintingStyle.fill;

        canvas.drawPath(areaPath, areaPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.fillArea != fillArea;
  }
}

// --- BAR CHART PAINTER ---
class BarChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final ColorScheme colorScheme;

  BarChartPainter({required this.data, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final groups = data.map((d) => d.group ?? 'Default').toSet().toList();
    final xLabels = data.map((d) => d.label).toSet().toList()..sort();
    final double maxY =
        data.map((d) => d.value).reduce((a, b) => math.max(a, b));
    final double minY = 0.0;
    final double targetMaxY = maxY * 1.15; // Give 15% top margin

    const double paddingLeft = 60.0;
    const double paddingRight = 20.0;
    const double paddingTop = 25.0;
    const double paddingBottom = 40.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final gridPaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final borderPaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal grids
    const int horizontalSegments = 4;
    for (int i = 0; i <= horizontalSegments; i++) {
      final double yRatio = i / horizontalSegments;
      final double yPos = paddingTop + chartHeight * (1 - yRatio);

      if (i > 0 && i < horizontalSegments) {
        drawDashedLine(
          canvas,
          Offset(paddingLeft, yPos),
          Offset(size.width - paddingRight, yPos),
          gridPaint,
          4,
          4,
        );
      } else {
        canvas.drawLine(
          Offset(paddingLeft, yPos),
          Offset(size.width - paddingRight, yPos),
          borderPaint,
        );
      }

      // Y Labels
      final double yVal = minY + (targetMaxY - minY) * yRatio;
      textPainter.text = TextSpan(
        text: '\$${yVal.toStringAsFixed(0)}',
        style: TextStyle(
          color: colorScheme.onBackground.withOpacity(0.6),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
            paddingLeft - textPainter.width - 8, yPos - textPainter.height / 2),
      );
    }

    // X Axis line
    canvas.drawLine(
      Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, size.height - paddingBottom),
      borderPaint,
    );

    if (xLabels.isEmpty) return;

    final double groupWidth = chartWidth / xLabels.length;
    final double innerPaddingRatio = 0.2; // space between groups
    final double barPaddingRatio = 0.1; // space between bars in same group

    final double activeGroupWidth = groupWidth * (1 - innerPaddingRatio);
    final double barWidth = activeGroupWidth / groups.length;
    final palette = getPalette(colorScheme);

    // Draw bars
    for (int i = 0; i < xLabels.length; i++) {
      final label = xLabels[i];
      final double groupStart =
          paddingLeft + i * groupWidth + (groupWidth * innerPaddingRatio / 2);

      // Draw grid category label
      textPainter.text = TextSpan(
        text: label.length > 8 ? '${label.substring(0, 7)}..' : label,
        style: TextStyle(
          color: colorScheme.onBackground.withOpacity(0.6),
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(groupStart + activeGroupWidth / 2 - textPainter.width / 2,
            size.height - paddingBottom + 8),
      );

      // Draw tick marks
      canvas.drawLine(
        Offset(groupStart + activeGroupWidth / 2, size.height - paddingBottom),
        Offset(
            groupStart + activeGroupWidth / 2, size.height - paddingBottom + 4),
        borderPaint,
      );

      // Draw individual bars for groups
      for (int g = 0; g < groups.length; g++) {
        final gName = groups[g];
        final gColor = palette[g % palette.length];

        // Find matching data point
        final pt = data.firstWhere(
          (d) => d.label == label && (d.group ?? 'Default') == gName,
          orElse: () => ChartDataPoint(label: label, value: 0.0, group: gName),
        );

        final double barLeft =
            groupStart + g * barWidth + (barWidth * barPaddingRatio / 2);
        final double barRight = barLeft + barWidth * (1 - barPaddingRatio);

        final double yRatio =
            targetMaxY > 0 ? (pt.value - minY) / (targetMaxY - minY) : 0.0;
        final double barTop =
            size.height - paddingBottom - chartHeight * yRatio;
        final double barBottom = size.height - paddingBottom;

        if (barTop < barBottom) {
          final barPaint = Paint()
            ..color = gColor
            ..style = PaintingStyle.fill;

          final rrect = RRect.fromRectAndCorners(
            Rect.fromLTRB(barLeft, barTop, barRight, barBottom),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          );
          canvas.drawRRect(rrect, barPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.colorScheme != colorScheme;
  }
}

// --- PIE CHART PAINTER ---
class PieChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final ColorScheme colorScheme;

  PieChartPainter({required this.data, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double total = data.fold<double>(0.0, (sum, d) => sum + d.value);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;
    final palette = getPalette(colorScheme);

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final sliceColor = palette[i % palette.length];
      final sweepAngle = (d.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = sliceColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // White borders separating slices
      final strokePaint = Paint()
        ..color = colorScheme.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        strokePaint,
      );

      startAngle += sweepAngle;
    }

    // Draw inner circle for a sleek donut look
    final donutPaint = Paint()
      ..color = colorScheme.background
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.55, donutPaint);

    // Draw center text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: 'Total\n\$${total.toStringAsFixed(0)}',
      style: TextStyle(
        color: colorScheme.onBackground,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.colorScheme != colorScheme;
  }
}

// --- WIDGET WRAPPERS ---
class CustomLineChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final bool fillArea;
  final double height;

  const CustomLineChart({
    super.key,
    required this.data,
    this.fillArea = true,
    this.height = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = data.map((d) => d.group ?? 'Default').toSet().toList();
    final palette = getPalette(theme.colorScheme);

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: LineChartPainter(
              data: data,
              colorScheme: theme.colorScheme,
              fillArea: fillArea,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend row
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(groups.length, (idx) {
            final groupColor = palette[idx % palette.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: groupColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  groups[idx],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class CustomBarChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final double height;

  const CustomBarChart({
    super.key,
    required this.data,
    this.height = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = data.map((d) => d.group ?? 'Default').toSet().toList();
    final palette = getPalette(theme.colorScheme);

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: BarChartPainter(
              data: data,
              colorScheme: theme.colorScheme,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend row (if multiple groups)
        if (groups.length > 1 || (groups.isNotEmpty && groups[0] != 'Default'))
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(groups.length, (idx) {
              final groupColor = palette[idx % palette.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: groupColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    groups[idx],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }),
          ),
      ],
    );
  }
}

class CustomPieChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final double height;

  const CustomPieChart({
    super.key,
    required this.data,
    this.height = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = getPalette(theme.colorScheme);
    final total = data.fold<double>(0.0, (sum, d) => sum + d.value);

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: PieChartPainter(
              data: data,
              colorScheme: theme.colorScheme,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Custom Legend with values and percentages
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(data.length, (idx) {
            final d = data[idx];
            final sliceColor = palette[idx % palette.length];
            final percent = total > 0 ? (d.value / total) * 100 : 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: sliceColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${d.label} (${percent.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
