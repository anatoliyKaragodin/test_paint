import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pointsProvider = StateProvider<List<Offset>>((ref) => []);
final linesColorsProvider = StateProvider<List<Color>>((ref) => []);

abstract class IAppPainterWidgetModel {
  void onPanStart(WidgetRef ref, Offset offset);
  void onPanUpdate(WidgetRef ref, Offset offset);
  void onPanEnd(WidgetRef ref);
  void redo(WidgetRef ref);
  void undo(WidgetRef ref);
}

class AppPainterWidgetModel extends IAppPainterWidgetModel {
  static const _magnetPointThreshold = 30;

  static bool _canAddPoints = true;
  static final List<Offset> _pointsHistory = [];
  static final List<List<Offset>> _pointsHistoryList = [[]];
  static final List<List<Color>> _linesColorsHistoryList = [[]];
  static int _historyIndex = 0;

  @override
  onPanStart(WidgetRef ref, Offset offset) {
    if (_canAddPoints) {
      final List<Offset> currentPoints = ref.read(pointsProvider);
      final List<Offset> updatedPoints = List.from(currentPoints)..add(offset);

      _addLineColor(ref, currentPoints);

      // _recordHistory(updatedPoints, ref.read(linesColorsProvider));

      ref.read(pointsProvider.notifier).update((state) => updatedPoints);
    }
  }

  @override
  void onPanUpdate(WidgetRef ref, Offset offset) {
    final List<Offset> currentPoints = ref.read(pointsProvider);

    if (_canAddPoints) {
      final List<Offset> updatedPoints = List.from(currentPoints)
        ..last = offset;

      _checkLinesIntersection(ref, updatedPoints);

      ref.read(pointsProvider.notifier).update((state) => updatedPoints);
    } else {
      final int index = _findPointToMove(currentPoints, offset);

      if (index != -1) {
        final List<Offset> updatedPoints = List.from(currentPoints);
        updatedPoints[index] = offset;
        if (index == 0) {
          updatedPoints.last = offset;
        } else if (index == updatedPoints.length - 1) {
          updatedPoints.first = offset;
        }

        ref.read(pointsProvider.notifier).update((state) => updatedPoints);
        _updateLinesColors(ref, updatedPoints);
      }
    }
  }

  @override
  void onPanEnd(WidgetRef ref) {
    if (_canAddPoints) {
      final List<Offset> currentPoints = ref.read(pointsProvider);

      _pointsMagnet(currentPoints, ref);

      _addPointToHistory(currentPoints.last);

      _recordHistory(ref);

      _checkFigureComplete(ref);
    }
  }

  @override
  void undo(WidgetRef ref) {
    // dev.log('undo: _pointsHistoryList: $_pointsHistoryList');
    // dev.log('undo: _historyIndex: $_historyIndex');
    // dev.log('undo: _pointsHistory: $_pointsHistory');

    if (_historyIndex > 0) {
      _historyIndex--;
      ref
          .read(pointsProvider.notifier)
          .update((state) => _pointsHistoryList[_historyIndex]);
      ref
          .read(linesColorsProvider.notifier)
          .update((state) => _linesColorsHistoryList[_historyIndex]);

      _checkFigureComplete(ref);
    }
  }

  @override
  void redo(WidgetRef ref) {
    // dev.log('redo');

    if (_historyIndex < _pointsHistoryList.length - 1) {
      _historyIndex++;
      ref
          .read(pointsProvider.notifier)
          .update((state) => _pointsHistoryList[_historyIndex]);
      ref
          .read(linesColorsProvider.notifier)
          .update((state) => _linesColorsHistoryList[_historyIndex]);

      _checkFigureComplete(ref);
    }
  }

  // Приватные методы
  void _addPointToHistory(Offset offset) {
    _pointsHistory.add(offset);
  }

  void _pointsMagnet(List<Offset> currentPoints, WidgetRef ref) {
    if (_pointsHistory.isNotEmpty) {
      final double distance =
          (currentPoints.last - currentPoints.first).distance;
      if (distance < _magnetPointThreshold) {
        final List<Offset> updatedPoints = List.from(currentPoints)
          ..last = currentPoints.first;
        ref.read(pointsProvider.notifier).update((state) => updatedPoints);
      }
    }
  }

  void _checkFigureComplete(WidgetRef ref) {
    final List<Offset> currentPoints = ref.read(pointsProvider);
    if (currentPoints.length > 1 && currentPoints.last == currentPoints.first) {
      _canAddPoints = false;
    } else {
      _canAddPoints = true;
    }
  }

  void _addLineColor(WidgetRef ref, List<Offset> currentPoints) {
    if (currentPoints.isNotEmpty) {
      final List<Color> currentLinesColors = ref.read(linesColorsProvider);
      final List<Color> updatedLinesColors = List.from(currentLinesColors)
        ..add(Colors.black);
      ref
          .read(linesColorsProvider.notifier)
          .update((state) => updatedLinesColors);
    }
  }

  void _checkLinesIntersection(WidgetRef ref, List<Offset> currentPoints) {
    final List<Color> currentLinesColors = ref.read(linesColorsProvider);
    final List<Offset> points =
        currentPoints.sublist(0, currentPoints.length - 1);
    final int pointsLength = points.length;
    final List<bool> intersections = List.filled(pointsLength, false);

    for (int i = 0; i < pointsLength - 1; i++) {
      for (int j = i + 1; j < pointsLength; j++) {
        final bool intersect = _doIntersect(
            points[i],
            points[(i + 1) % pointsLength],
            points[j],
            points[(j + 1) % pointsLength]);
        if (intersect) {
          intersections[i] = true;
          intersections[j] = true;
        }
      }
    }

    final List<Color> updatedLinesColors = List.from(currentLinesColors);
    for (int i = 0; i < pointsLength - 1; i++) {
      updatedLinesColors[i] = intersections[i] ? Colors.red : Colors.black;
    }

    ref
        .read(linesColorsProvider.notifier)
        .update((state) => updatedLinesColors);
  }

  bool _doIntersect(Offset p1, Offset q1, Offset p2, Offset q2) {
    int o1 = _orientation(p1, q1, p2);
    int o2 = _orientation(p1, q1, q2);
    int o3 = _orientation(p2, q2, p1);
    int o4 = _orientation(p2, q2, q1);

    // Общая вершина и не пересекаются
    if (o1 == 0 && _onSegment(p1, p2, q1)) return false;
    if (o2 == 0 && _onSegment(p1, q2, q1)) return false;
    if (o3 == 0 && _onSegment(p2, p1, q2)) return false;
    if (o4 == 0 && _onSegment(p2, q1, q2)) return false;

    if (o1 != o2 && o3 != o4) {
      return true;
    }

    return false;
  }

  int _orientation(Offset p, Offset q, Offset r) {
    double val = (q.dy - p.dy) * (r.dx - q.dx) - (q.dx - p.dx) * (r.dy - q.dy);
    if (val == 0) return 0; // колинеарные
    return (val > 0) ? 1 : 2; // по часовой или против часовой стрелки
  }

  bool _onSegment(Offset p, Offset q, Offset r) {
    if (q.dx <= max(p.dx, r.dx) &&
        q.dx >= min(p.dx, r.dx) &&
        q.dy <= max(p.dy, r.dy) &&
        q.dy >= min(p.dy, r.dy)) {
      return true;
    }
    return false;
  }

  int _findPointToMove(List<Offset> points, Offset touchPoint) {
    for (int i = 0; i < points.length; i++) {
      final double distance = (points[i] - touchPoint).distance;
      if (distance < _magnetPointThreshold) {
        return i;
      }
    }
    return -1;
  }

  void _updateLinesColors(WidgetRef ref, List<Offset> points) {
    final List<Color> currentLinesColors = ref.read(linesColorsProvider);
    final List<bool> intersections = _findIntersections(points);

    final List<Color> updatedLinesColors = List.from(currentLinesColors);
    for (int i = 0; i < points.length - 1; i++) {
      updatedLinesColors[i] = intersections[i] ? Colors.red : Colors.black;
    }

    ref
        .read(linesColorsProvider.notifier)
        .update((state) => updatedLinesColors);
  }

  List<bool> _findIntersections(List<Offset> points) {
    final List<bool> intersections = List.filled(points.length - 1, false);

    for (int i = 0; i < points.length - 1; i++) {
      for (int j = i + 1; j < points.length - 1; j++) {
        final bool intersect = _doIntersect(
            points[i],
            points[(i + 1) % points.length],
            points[j],
            points[(j + 1) % points.length]);
        if (intersect) {
          intersections[i] = true;
          intersections[j] = true;
        }
      }
    }

    return intersections;
  }

  void _recordHistory(ref) {
    final List<Offset> points = ref.read(pointsProvider);
    final List<Color> colors = ref.read(linesColorsProvider);

    // dev.log('new history input: points $points colors $colors');

    _pointsHistoryList.add(points);
    _linesColorsHistoryList.add(List<Color>.from(colors));

    _historyIndex++;
    // dev.log(_historyIndex.toString());
  }
}
