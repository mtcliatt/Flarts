import 'package:flutter/material.dart';

Paint flartBackgroundPaint() => Paint()
  ..color = Colors.black26
  ..style = PaintingStyle.fill;

Paint flartGridLinePaint() => Paint()
  ..color = Colors.white30
  ..style = PaintingStyle.fill
  ..strokeWidth = 1;

Paint flartLabelPaint() => Paint()
  ..color = Colors.white70
  ..style = PaintingStyle.fill;

Paint flartLabelBorderPaint() => Paint()
  ..color = Colors.greenAccent
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1;

Paint lineStylePaint() => Paint()
  ..style = PaintingStyle.stroke
  ..color = Colors.blue
  ..strokeWidth = 2
  ..strokeJoin = StrokeJoin.bevel;

Paint barPaint() => Paint()
  ..style = PaintingStyle.fill
  ..color = Colors.grey
  ..strokeJoin = StrokeJoin.bevel;

TextStyle labelTextStyle() => TextStyle(fontSize: 14.0);

// todo: write a copyWith() to make life easier in other places.
// todo: add themes.
class FlartStyle {
  final Paint backgroundPaint;
  final Paint borderStyle;
  final Paint gridlinePaint;

  final double labelPadding;
  final TextStyle labelTextStyle;

  final Paint linePaint;
  final Paint barPaint;

  FlartStyle({
    Paint backgroundPaint,
    Paint borderStyle,
    Paint gridlinePaint,
    Paint labelPaint,
    Paint barPaint,
    Paint linePaint,
    TextStyle labelTextStyle,
    double labelPadding,
  })  : this.backgroundPaint = backgroundPaint ??
            (Paint()
              ..color = Colors.black26
              ..style = PaintingStyle.fill),
        this.borderStyle = borderStyle ??
            (Paint()
              ..color = Colors.greenAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1),
        this.gridlinePaint = gridlinePaint ??
            (Paint()
              ..color = Colors.white30
              ..style = PaintingStyle.fill
              ..strokeWidth = 1),
        this.linePaint = linePaint ??
            (Paint()
              ..style = PaintingStyle.stroke
              ..color = Colors.blue
              ..strokeWidth = 2
              ..strokeJoin = StrokeJoin.bevel),
        this.barPaint = linePaint ??
            (Paint()
              ..style = PaintingStyle.fill
              ..color = Colors.grey
              ..strokeJoin = StrokeJoin.bevel),
        this.labelTextStyle = labelTextStyle ?? TextStyle(fontSize: 14.0),
        this.labelPadding = labelPadding ?? 4.0;
}
