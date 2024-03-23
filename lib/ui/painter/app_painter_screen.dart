import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_paint/ui/painter/app_painter_wm.dart';

class AppPainterScreen extends StatelessWidget {
  const AppPainterScreen({super.key, required this.wm});

  final IAppPainterWidgetModel wm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _PaintWidget(
              wm: wm,
            ),
            const _ButtonsWidget()
          ],
        ),
      ),
    );
  }
}

class _BackgroundWidget extends StatelessWidget {
  const _BackgroundWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
    );
  }
}

class _ButtonsWidget extends ConsumerWidget {
  const _ButtonsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          child: Row(
            children: [
              IconButton(
                  onPressed: () {
                    AppPainterWidgetModel().undo(ref);
                  },
                  icon: const Icon(Icons.settings_backup_restore_rounded)),
              Transform.flip(
                flipX: true,
                child: IconButton(
                    onPressed: () {
                      AppPainterWidgetModel().redo(ref);
                    },
                    icon: const Icon(Icons.settings_backup_restore_rounded)),
              ),
            ],
          ),
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.add_box_rounded))
      ],
    );
  }
}

class _PaintWidget extends ConsumerWidget {
  const _PaintWidget({Key? key, required this.wm}) : super(key: key);

  final IAppPainterWidgetModel wm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(pointsProvider);
    final linesColors = ref.watch(linesColorsProvider);
    dev.log(points.toString());

    return GestureDetector(
      onPanStart: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        wm.onPanStart(ref, renderBox.globalToLocal(details.globalPosition));
      },
      onPanUpdate: (details) {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        wm.onPanUpdate(ref, renderBox.globalToLocal(details.globalPosition));
      },
      onPanEnd: (details) {
        wm.onPanEnd(ref);
      },
      child: CustomPaint(
        painter: _AppPainter(points, linesColors),
        child: const _BackgroundWidget(),
      ),
    );
  }
}

class _AppPainter extends CustomPainter {
  final List<Offset> points;
  final List<Color> linesColors;

  _AppPainter(this.points, this.linesColors);

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final circlePaintInside = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      final color = linesColors[i];
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    for (final point in points) {
      canvas.drawCircle(point, 8.0, circlePaintInside);
    }

    for (final point in points) {
      canvas.drawCircle(point, 8.0, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
