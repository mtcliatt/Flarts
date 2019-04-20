import 'package:flutter/material.dart';

import 'package:flarts/flart_axis.dart';
import 'package:flarts/flart_data.dart';
import 'package:flarts/flart_paint.dart';
import 'package:flarts/flart_theme.dart';

// todo: cache everything that can be cached.
// todo: bevel the edges of the chart border.
// todo: use [canvas.clipRect()] to prevent drawing over the rest of the screen.
// todo: make sure repainting happens when/if it should.
// todo: customizable gridline styling.
// todo: customizable label styling.

class Flart extends StatelessWidget {
  final List<FlartData> _dataList;
  final List<FlartAxis> _axes;
  final FlartStyle _style;
  final Size _size;

  Flart(
    this._size,
    this._dataList, {
    List<FlartAxis> sharedAxes = const [],
    FlartStyle style,
  })  : _style = style ?? FlartStyle(),
        _axes = [] {
    final Map<String, FlartAxis> shared = {};

    sharedAxes.forEach((axis) => shared[axis.id] = axis);

    // Make sure all referenced axes were provided.
    _dataList.forEach((data) {
      if (data.domainAxisId != null && !shared.containsKey(data.domainAxisId)) {
        throw ArgumentError(
            'Axis for referenced ID not provided: ${data.domainAxisId}');
      }

      if (data.rangeAxisId != null && !shared.containsKey(data.rangeAxisId)) {
        throw ArgumentError(
            'Axis for referenced ID not provided: ${data.rangeAxisId}');
      }
    });

    _dataList.forEach((data) {
      if (data.domainAxisId != null) {
        data.domainAxis = shared[data.domainAxisId];
      } else {
        if (data.domainAxis == null) {
          // If no axis or ID was provided, make a simple one with no labels.
          data.domainAxis = FlartAxis(
            Axis.horizontal,
            data.minDomain,
            data.maxDomain,
            // todo: move defaults like these into the theme.
            labelConfig: AxisLabelConfig(
              frequency: AxisLabelFrequency.none,
            ),
            numGridlines: 4,
          );
        }

        _axes.add(data.domainAxis);
      }

      if (data.rangeAxisId != null) {
        data.rangeAxis = shared[data.rangeAxisId];
      } else {
        if (data.rangeAxis == null) {
          // If no axis or ID was provided, make a simple one with no labels.
          data.rangeAxis = FlartAxis(
            Axis.horizontal,
            data.minDomain,
            data.maxDomain,
            labelConfig: AxisLabelConfig(
              frequency: AxisLabelFrequency.none,
            ),
            numGridlines: 4,
          );
        }

        _axes.add(data.rangeAxis);
      }
    });

    shared.forEach((_, axis) => _axes.add(axis));
  }

  // A sleek line chart with no labels or gridlines.
  factory Flart.spark(Size size, List<FlartData> dataList) {
    final style = FlartStyle(
      borderStyle: Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke,
      backgroundPaint: Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.fill,
    );

    for (final data in dataList) {
      data.customColor = Colors.redAccent;

      data.domainAxis = FlartAxis(
        Axis.horizontal,
        dataList.first.minDomain,
        dataList.first.maxDomain,
        labelConfig: AxisLabelConfig(
          frequency: AxisLabelFrequency.none,
        ),
      );

      data.rangeAxis = FlartAxis(
        Axis.vertical,
        dataList.first.minRange,
        dataList.first.maxRange,
        labelConfig: AxisLabelConfig(
          frequency: AxisLabelFrequency.none,
        ),
      );
    }

    return Flart(
      size,
      dataList,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: _size,
      painter: FlartPainter(
        dataList: _dataList,
        style: _style,
        axes: _axes,
      ),
    );
  }
}
