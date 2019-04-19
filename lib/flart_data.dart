import 'dart:collection';

import 'package:flarts/flart_axis.dart';
import 'package:flutter/material.dart';

/// T is the object type which holds the data to be charted.
/// D is the domain type of the data (e.g., dates, days, numbers, etc)
/// R is the range type of the data (e.g., prices, numbers, etc.)
typedef DomainFn<T, D> = D Function(T, int);
typedef RangeFn<T, R> = R Function(T, int);

// todo: consider adding a ColorFn rather than using a single color per data.
// typedef ColorFn<T> = Color Function(T, int);

/// A function that returns the measurable distance between any two instances
/// of type [T].
///
/// For [num]s, the distance is the difference between the two values.
/// For [DateTime]s, the distance is the milliseconds between the two times.
typedef DistanceFn<T> = double Function(T, T);

/// Returns a function that returns the distance between two given instances
/// of type [type].
DistanceFn distanceFnForType<T>(Type type) {
  Map<Type, DistanceFn> distanceFnMap = {
    DateTime: (a, b) => a.difference(b).inMilliseconds.toDouble(),
    int: (a, b) => (a - b).toDouble(),
    double: (a, b) => (a - b).toDouble(),
  };

  if (distanceFnMap.containsKey(type)) return distanceFnMap[type];

  return (a, b) => a.compareTo(b).toDouble();
}

/// A function that returns the measurement of a given instance of type [T].
///
/// For numbers, their measurement is simply their value.
/// For dates, their measurement is milliseconds since the Unix Epoch.
typedef MeasureFn<T> = double Function(T);

/// Returns a function that returns the measurement of a given type [T].
MeasureFn measureFnForType(Type type) {
  Map<Type, MeasureFn> measureFnMap = {
    DateTime: (date) => date.millisecondsSinceEpoch.toDouble(),
    int: (val) => val.toDouble(),
    double: (val) => val,
  };

  if (measureFnMap.containsKey(type)) return measureFnMap[type];

  print('Asked to measure unknown type: $type, defaulting to cast to double');
  return (val) => val as double;
}

/// A function that returns the minimum possible non-negative value of [T].
///
/// For example, for [num]s, this is 0. And for [DateTime]s, it is 0
/// milliseconds past the Unix Epoch.
typedef MinValueFn<T> = T Function();

/// Returns a function that returns the minimum possible non-negative value of
/// an instance of type [type].
MinValueFn minValueOfType(Type type) {
  Map<Type, MinValueFn> valueFnMap = {
    DateTime: () => DateTime.fromMillisecondsSinceEpoch(0),
    int: () => 0,
    double: () => 0.0,
  };

  if (valueFnMap.containsKey(type)) return valueFnMap[type];

  print('Asked for minValueFn of unknown type: $type, defaulting to () => 0.0');
  return () => 0.0;
}

Comparable interpolate<T extends Comparable>(T t,
    {T other, double skew = 0.5}) {
  final double aUnits = measureFnForType(t.runtimeType)(t);
  final double bUnits =
      other == null ? 0 : measureFnForType(other.runtimeType)(other);

  final T smaller = aUnits < bUnits ? t : other;
  final units = (aUnits - bUnits).abs() * skew;

  if (t is DateTime) {
    return (smaller as DateTime).add(Duration(milliseconds: units.toInt()));
  } else if (t is num) {
    return (smaller as num) + units;
  } else {
    throw UnimplementedError('interpolation not implemented for type $T');
  }
}

enum PlotType {
  line,
  bar,
}

/// A data set of type [T] with a domain of type [D] and a range of type [R].
///
/// [domainFn] and [rangeFn] should accept an instance of type [T], and return
/// an instance of type [D] and [R], respectively.
///
/// Example:
///   Given a class representing the price of a stock on a specific date:
///
/// ```
/// class StockPrice {
///   DateTime date;
///   double price;
/// }
/// ```
///
/// The type of data is [StockPrice], (which will be [T]).
/// The domain type ([D]) is [DateTime], and the range type ([R]) is [double].
///
/// Defining the [domainFn] and [rangeFn] is trivial in this case:
///
///   `domainFn: (StockPrice stockPrice) => stockPrice.date`
///   `rangeFn: (StockPrice stockPrice) => stockPrice.price`
class FlartData<T, D extends Comparable, R extends Comparable> {
  final PlotType plotType;
  final List<T> rawData;
  final int layer;

  final List<D> computedDomain = [];
  final List<R> computedRange = [];

  final DomainFn<T, D> domainFn;
  final RangeFn<T, R> rangeFn;

  final String domainAxisId;
  final String rangeAxisId;

  final SplayTreeMap<D, ComputedFlartDatum<D, R>> computedData;

  FlartAxis domainAxis;
  FlartAxis rangeAxis;

  DistanceFn<D> domainDistanceFn;
  DistanceFn<R> rangeDistanceFn;

  List<double> normalizedDomain;
  List<double> normalizedRange;

  double minRangeDistance = 0;
  double maxRangeDistance = 0;
  double maxDomainDistance = 0;

  D maxDomain;
  D minDomain;
  R maxRange;
  R minRange;

  static List<Color> _colors = [
    Colors.blue,
    Colors.redAccent,
    Colors.green,
  ];

  static int _nextColorIndex = 0;

  Color customColor;
  Color _color;

  Color get color {
    if (_color == null) {
      _color = customColor ?? _colors[_nextColorIndex++ % _colors.length];
    }

    return _color;
  }

  // todo: lazily compute the data similar to Flutter's TextPainter.layout?
  FlartData(
    this.rawData, {
    this.layer = 1,
    this.plotType = PlotType.line,
    this.domainFn,
    this.rangeFn,
    this.domainAxisId,
    this.rangeAxisId,
    this.domainAxis,
    this.rangeAxis,
    this.customColor,
  }) : computedData = SplayTreeMap() {
    final firstDomain = domainFn(rawData.first, 0);
    final firstRange = rangeFn(rawData.first, 0);
    maxRange = minRange = firstRange;
    maxDomain = minDomain = firstDomain;
    computedDomain.add(firstDomain);
    computedRange.add(firstRange);

    domainDistanceFn =
        distanceFnForType(domainFn(rawData.first, 0).runtimeType);
    rangeDistanceFn = distanceFnForType(rangeFn(rawData.first, 0).runtimeType);

    for (var i = 1; i < rawData.length; i++) {
      final domain = domainFn(rawData[i], i);
      final range = rangeFn(rawData[i], i);
      computedDomain.add(domain);
      computedRange.add(range);

      final rangeDistance = rangeDistanceFn(range, minRange);
      final rangeDistanceToMin = rangeDistanceFn(range, minRange);
      final domainDistance = domainDistanceFn(domain, minDomain);

      if (rangeDistanceToMin < 0) {
        minRangeDistance = rangeDistance;
        maxRangeDistance = rangeDistanceFn(maxRange, range);
        minRange = range;
      } else if (rangeDistance > maxRangeDistance) {
        maxRangeDistance = rangeDistance;
        maxRange = range;
      }

      if (domainDistance < 0) {
        maxDomainDistance = domainDistanceFn(domain, maxDomain);
        minDomain = domain;
      } else if (domainDistance > maxDomainDistance) {
        maxDomainDistance = domainDistance;
        maxDomain = domain;
      }
    }

    normalizedDomain = normalizeComparable(computedDomain);
    normalizedRange = normalizeComparable(computedRange);

    for (var i = 0; i < rawData.length; i++) {
      computedData.putIfAbsent(
        computedDomain[i],
        () => ComputedFlartDatum(computedDomain[i], computedRange[i],
            normalizedDomain[i], normalizedRange[i]),
      );
    }
  }

  static List<double> normalizeComparable<T extends Comparable>(List<T> data) {
    final compareFn = distanceFnForType(data.first.runtimeType);
    final normalizedDistances = <double>[];

    double lowestLow = 0;
    double highestHigh = 0;
    int indexOfLowest = 0;

    for (var i = 1; i < data.length; i++) {
      final distance = compareFn(data[i], data.first);

      if (distance < lowestLow) {
        lowestLow = distance;
        indexOfLowest = i;
      }

      if (distance > highestHigh) highestHigh = distance;
    }

    final range = (highestHigh - lowestLow);

    for (var i = 0; i < data.length; i++) {
      final distance = compareFn(data[i], data[indexOfLowest]);
      normalizedDistances.add(distance / range);
    }

    return normalizedDistances;
  }
}

class ComputedFlartDatum<D, R> {
  final D domain;
  final R range;
  final double normalizedDomain;
  final double normalizedRange;

  ComputedFlartDatum(
    this.domain,
    this.range,
    this.normalizedDomain,
    this.normalizedRange,
  );
}

FlartData<MapEntry<D, R>, D, R>
    flartDataFromIterables<D extends Comparable, R extends Comparable>(
  List<D> domain,
  List<R> range, {
  String domainAxisId,
  String rangeAxisId,
  FlartAxis<D> domainAxis,
  FlartAxis<R> rangeAxis,
}) {
  final Map<D, R> data = Map.fromIterables(domain, range);

  return FlartData<MapEntry<D, R>, D, R>(
    data.entries.toList(),
    rangeFn: (e, i) => e.value,
    domainFn: (e, i) => e.key,
    domainAxis: domainAxis,
    rangeAxis: rangeAxis,
    domainAxisId: domainAxisId,
    rangeAxisId: rangeAxisId,
  );
}
