import 'package:flutter/material.dart';

import 'package:flarts/flart_data.dart';
import 'package:flarts/label_formatter.dart';

class Gridline {
  final double normalizedDistanceAlongAxis;

  Gridline(this.normalizedDistanceAlongAxis);
}

class AxisLabel {
  final double normalizedDistanceAlongAxis;
  final String text;
  final TextStyle style;

  AxisLabel(this.normalizedDistanceAlongAxis, this.text, {this.style});
}

enum AxisLabelFrequency {
  perGridline,
  everyOtherGridline,
  none,
}

enum AxisLabelTextSource {
  interpolateFromDataType,
  useLabelIndex,
}

class AxisLabelConfig {
  AxisLabelFrequency frequency;
  AxisLabelTextSource text;

  AxisLabelConfig({this.frequency, this.text});
}

enum Side { left, top, right, bottom }

/// An axis spanning [min] to [max], with an orientation of [direction].
class FlartAxis<T extends Comparable> {
  final Axis direction;
  final Side side;

  final double range;
  final T min;
  final T max;

  final List<Gridline> gridlines = [];
  final List<AxisLabel> labels = [];

  final String id;

  FlartAxis(
    this.direction,
    this.min,
    this.max, {
    this.id,
    Side side,
    AxisLabelConfig labelConfig,
    int numGridlines = 0,
    Map<T, String> customLabels,
    List<double> additionalCustomGridLines,
  })  : this.side = side != null
            ? side
            : direction == Axis.vertical ? Side.right : Side.bottom,
        range = distanceFnForType(min.runtimeType)(min, max).abs() {
    final labelToString = LabelFormatter.labelToStringForType(min.runtimeType);
    int numLabels;

    if (labelConfig.frequency == AxisLabelFrequency.perGridline) {
      numLabels = numGridlines;
    } else if (labelConfig.frequency == AxisLabelFrequency.everyOtherGridline) {
      numLabels = (numGridlines / 2).floor();
    } else if (labelConfig.frequency == AxisLabelFrequency.none) {
      numLabels = 0;
    } else {
      numLabels = 0;
    }

    if (additionalCustomGridLines != null) {
      additionalCustomGridLines.forEach((position) {
        final norm = position / range;
        gridlines.add(Gridline(norm));
      });
    }

    // todo: Use better splits for labels so they make more sense.
    if (numGridlines > 0) {
      final spacingPerLine = range / (numGridlines + 1);
      for (var i = 1; i < numGridlines + 1; i++) {
        final distance = i * spacingPerLine;
        final normDistance = distance / range;
        gridlines.add(Gridline(normDistance));
      }
    }

    if (numLabels > 0) {
      for (var i = 1; i < numLabels + 1; i++) {
        final normDistance = i / (numLabels + 1);
        final label = labelConfig.text ==
                AxisLabelTextSource.interpolateFromDataType
            ? labelToString(interpolate(min, other: max, skew: normDistance))
            : '$i';

        labels.add(AxisLabel(normDistance, label));
      }
    }
  }
}
