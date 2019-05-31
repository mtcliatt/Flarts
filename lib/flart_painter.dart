import 'package:flutter/material.dart';

import 'package:flarts/flart_axis.dart';
import 'package:flarts/flart_data.dart';
import 'package:flarts/flart_theme.dart';

class FlartPainter extends CustomPainter {
  final List<FlartData> dataList;
  final List<FlartAxis> axes;
  final FlartStyle style;

  Size chartSize;
  Offset chartTopLeft;
  Offset chartBottomRight;

  Map<String, TextPainter> textPainterCache = {};

  FlartPainter({this.dataList, this.axes, FlartStyle style})
      : this.style = style ?? FlartStyle();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    _drawBackground(canvas, size);

    final labels = _calculateLabelAreas(axes, style.labelPadding);
    chartSize = Size(
        size.width - labels.horizontalArea, size.height - labels.verticalArea);
    chartTopLeft = Offset(labels.leftArea, labels.topArea);
    chartBottomRight =
        Offset(size.width - labels.rightArea, size.height - labels.bottomArea);

    _drawGridlines(canvas, axes);
    _drawData(canvas);
    _drawFlartBorder(canvas);
    _drawLabels(canvas, axes);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), style.backgroundPaint);
  }

  void _drawGridlines(Canvas canvas, List<FlartAxis> axes) {
    Set<double> horizontalLines = Set();
    Set<double> verticalLines = Set();

    axes.forEach((axis) {
      if (axis.direction == Axis.horizontal) {
        axis.gridlines.forEach((gridline) {
          horizontalLines
              .add(_axisToScreenX(axis, gridline.normalizedDistanceAlongAxis));
        });
      } else {
        axis.gridlines.forEach((gridline) {
          verticalLines
              .add(_axisToScreenY(axis, gridline.normalizedDistanceAlongAxis));
        });
      }
    });

    horizontalLines.forEach((x) => canvas.drawLine(
          Offset(x, chartTopLeft.dy),
          Offset(x, chartBottomRight.dy),
          style.gridlinePaint,
        ));

    verticalLines.forEach((y) => canvas.drawLine(
          Offset(chartTopLeft.dx, y),
          Offset(chartBottomRight.dx, y),
          style.gridlinePaint,
        ));
  }

  /// Draws the labels of each of the given [axes].
  void _drawLabels(Canvas canvas, List<FlartAxis> axes) {
    final visited = <Offset>[];

    void drawLabels(List<AxisLabel> labels, Function xFn, Function yFn) {
      labels.forEach((label) {
        final painter = _painterForText(label.text);
        final x = xFn(label, painter.width, painter.height);
        final y = yFn(label, painter.width, painter.height);

        if (visited.contains(Offset(x, y))) return;

        painter.paint(canvas, Offset(x, y));
      });
    }

    // The only thing that changes when labelling each side is determining the
    // x and y of the labels. We can just specify those functions to use the
    // method for drawing all labels.
    axes.forEach((axis) {
      Function xFn;
      Function yFn;

      if (axis.side == Side.left) {
        xFn = (_, width, __) => chartTopLeft.dx - style.labelPadding - width;
        yFn = (label, _, height) =>
            _axisToScreenY(axis, label.normalizedDistanceAlongAxis) -
            height / 2;
      } else if (axis.side == Side.right) {
        xFn = (_, width, __) => chartBottomRight.dx + style.labelPadding;
        yFn = (label, _, height) =>
            _axisToScreenY(axis, label.normalizedDistanceAlongAxis) -
            height / 2;
      } else if (axis.side == Side.top) {
        xFn = (label, width, _) =>
            _axisToScreenX(axis, label.normalizedDistanceAlongAxis) - width / 2;
        yFn =
            (label, _, height) => chartTopLeft.dy - style.labelPadding - height;
      } else {
        xFn = (label, width, _) =>
            _axisToScreenX(axis, label.normalizedDistanceAlongAxis) - width / 2;
        yFn = (label, _, __) => chartBottomRight.dy + style.labelPadding;
      }

      drawLabels(axis.labels, xFn, yFn);
    });
  }

  /// Paints a border around the chart area.
  void _drawFlartBorder(Canvas canvas) {
    final halfStroke = style.borderStyle.strokeWidth / 2;

    final path = Path()
      ..moveTo(chartTopLeft.dx + halfStroke, chartTopLeft.dy + halfStroke)
      ..lineTo(chartTopLeft.dx + halfStroke, chartBottomRight.dy - halfStroke)
      ..lineTo(chartBottomRight.dx, chartBottomRight.dy - halfStroke)
      ..lineTo(chartBottomRight.dx, chartTopLeft.dy + halfStroke)
      ..lineTo(chartTopLeft.dx + halfStroke, chartTopLeft.dy + halfStroke);

    canvas.drawPath(path, style.borderStyle);
  }

  /// Draws all data by sending each set to the appropriate drawing method
  /// for that data's [PlotType].
  void _drawData(Canvas canvas) {
    final Map<int, List<FlartData>> layerMap = {};
    dataList.forEach((data) {
      if (layerMap.containsKey(data.layer))
        layerMap[data.layer].add(data);
      else
        layerMap[data.layer] = [data];
    });

    final sortedKeys = layerMap.keys.toList()..sort();

    for (final key in sortedKeys) {
      final layer = layerMap[key];

      for (final data in layer) {
        switch (data.plotType) {
          case PlotType.line:
            _drawDataAsLine(canvas, data);
            break;
          case PlotType.bar:
            _drawDataAsBar(canvas, data);
            break;
        }
      }
    }
  }

  void _drawDataAsBar(Canvas canvas, FlartData data) {
    // todo: see about other/better ways to handle thin bars.
    var barWidth = chartSize.width / data.maxDomainDistance;
    barWidth = barWidth < 1.0 ? 1.0 : barWidth;
    final rangeDistanceFn = distanceFnForType(data.minRange.runtimeType);
    final domainDistanceFn = distanceFnForType(data.minDomain.runtimeType);

    final rects = <Rect>[];

    final dataKeys = data.computedData.keys.toList();

    for (var i = 0; i < dataKeys.length; i++) {
      final datum = data.computedData[dataKeys[i]];
      final rangeDistToMin =
          rangeDistanceFn(datum.range, data.rangeAxis.minValue);
      final domainDistToMin =
          domainDistanceFn(datum.domain, data.domainAxis.minValue);
      final normAxisDomain = domainDistToMin / data.domainAxis.range;
      final normAxisRange = rangeDistToMin / data.rangeAxis.range;
      final x = _axisToScreenX(data.domainAxis, normAxisDomain);
      final y = _axisToScreenY(data.rangeAxis, normAxisRange);

      rects.add(Rect.fromLTRB(x, y, x + barWidth, chartBottomRight.dy));
    }

    var paint = style.barPaint;

    if (data.color != null) {
      paint = Paint()
        ..color = data.color
        ..style = style.barPaint.style
        ..strokeWidth = style.barPaint.strokeWidth
        ..strokeJoin = style.barPaint.strokeJoin;
    }

    for (final rect in rects) {
      canvas.drawRect(rect, paint);
    }
  }

  void _drawDataAsLine(Canvas canvas, FlartData data) {
    final points = <Offset>[];
    final rangeDistanceFn = distanceFnForType(data.minRange.runtimeType);
    final domainDistanceFn = distanceFnForType(data.minDomain.runtimeType);

    for (final datumKey in data.computedData.keys) {
      final datum = data.computedData[datumKey];

      // todo: double check this late-night logic. is all this necessary?
      final rangeDistToMin =
          rangeDistanceFn(datum.range, data.rangeAxis.minValue);
      final domainDistToMin =
          domainDistanceFn(datum.domain, data.domainAxis.minValue);
      final normAxisDomain = domainDistToMin / data.domainAxis.range;
      final normAxisRange = rangeDistToMin / data.rangeAxis.range;

      final x = _axisToScreenX(data.domainAxis, normAxisDomain);
      final y = _axisToScreenY(data.rangeAxis, normAxisRange);

      if (data.domainAxis.direction == Axis.horizontal) {
        points.add(Offset(x, y));
      } else {
        final axisX =
            chartBottomRight.dx - _normToAxis(data.rangeAxis, normAxisRange);
        final axisY =
            chartBottomRight.dy - _normToAxis(data.domainAxis, normAxisDomain);

        points.add(Offset(axisX, axisY));
      }
    }

    _drawLine(canvas, points, data.color);
  }

  /// Draws the given [points] to the canvas in one path with the given [color].
  void _drawLine(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    var paint = style.linePaint;

    if (color != null) {
      paint = Paint()
        ..color = color
        ..style = style.linePaint.style
        ..strokeWidth = style.linePaint.strokeWidth
        ..strokeJoin = style.linePaint.strokeJoin;
    }

    canvas.drawPath(path, paint);
  }

  double _normToAxis(FlartAxis axis, double norm) =>
      axis.direction == Axis.horizontal
          ? norm * chartSize.width
          : norm * chartSize.height;

  double _axisToScreenX(FlartAxis axis, double normalizedX) =>
      chartTopLeft.dx + normalizedX * chartSize.width;

  double _axisToScreenY(FlartAxis axis, double normalizedY) =>
      chartBottomRight.dy - normalizedY * chartSize.height;

  /// Finds the required minimum size for the labels on each side of the chart.
  LabelAreaInfo _calculateLabelAreas(
      List<FlartAxis> axes, double labelPadding) {
    final Function max = (a, b) => a > b ? a : b;
    final areaInfo = LabelAreaInfo(padding: labelPadding);

    axes.forEach((axis) {
      axis.labels.forEach((label) {
        final painter = _painterForText(label.text, textStyle: label.style);

        if (axis.side == Side.top) {
          areaInfo.maxTop = max(painter.height, areaInfo.maxTop);
        } else if (axis.side == Side.left) {
          areaInfo.maxLeft = max(painter.width, areaInfo.maxLeft);
        } else if (axis.side == Side.right) {
          areaInfo.maxRight = max(painter.width, areaInfo.maxRight);
        } else {
          areaInfo.maxBottom = max(painter.height, areaInfo.maxBottom);
        }
      });
    });

    return areaInfo;
  }

  /// Returns a [TextPainter] for the provided [text].
  ///
  /// Also calls [layout()] on the painter before returning so that it's already
  /// done and the callers don't have to worry about that responsibility.
  TextPainter _painterForText(String text, {TextStyle textStyle}) {
    if (textPainterCache.containsKey(text)) return textPainterCache[text];

    final painter = TextPainter(
        text: TextSpan(text: text, style: textStyle ?? style.labelTextStyle),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr);
    painter.layout();

    textPainterCache[text] = painter;
    return painter;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Holds information about the size of the label areas around the chart.
class LabelAreaInfo {
  double maxTop;
  double maxLeft;
  double maxRight;
  double maxBottom;
  double padding;

  double padOrZero(n) => n == 0 ? 0 : n + 2 * padding;

  double get topArea => padOrZero(maxTop);
  double get leftArea => padOrZero(maxLeft);
  double get rightArea => padOrZero(maxRight);
  double get bottomArea => padOrZero(maxBottom);

  double get horizontalArea => leftArea + rightArea;
  double get verticalArea => topArea + bottomArea;

  LabelAreaInfo({
    this.padding = 0,
    this.maxTop = 0,
    this.maxLeft = 0,
    this.maxRight = 0,
    this.maxBottom = 0,
  });

  @override
  String toString() => 'left: $maxLeft, right: $maxRight '
      'top: $maxTop, bottom: $maxBottom';
}
