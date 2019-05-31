import 'package:flutter/material.dart';

import 'package:flarts/flart.dart';
import 'package:flarts/flart_axis.dart';
import 'package:flarts/flart_data.dart';

import 'example_data.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flart Examples',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: FlartExamplePage(),
    );
  }
}

@immutable
class FlartExamplePage extends StatefulWidget {
  final Map<String, Widget> examples = {
    'Simple Data': SimpleDataExample(),
    'Large Spark': LargeSparkExample(),
    'Sparks': SparkExample(),
    'Multi Data': MultiDataExample(),
  };

  @override
  State<FlartExamplePage> createState() => FlartExamplePageState();
}

class SimpleDataExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) => Flart(
              constraints.biggest,
              [
                flartDataFromIterables(
                  simplyCount,
                  simplyDoubles,
                  rangeAxis: FlartAxis(
                    direction: Axis.vertical,
                    minValue:  -25, // min value on range axis.
                    maxValue:  25, // max value on range axis.
                    labelConfig: AxisLabelConfig(
                      frequency: AxisLabelFrequency.perGridline,
                      text: AxisLabelTextSource.interpolateFromDataType,
                    ),
                    numGridlines: 4,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class LargeSparkExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) => Flart.spark(
              constraints.biggest,
              [
                FlartData<StockQuote, DateTime, double>(
                  // This was an easy way to put the first n days on the
                  // first spark, the next n on the next spark, and so on.
                  spyQuotes,
                  rangeFn: (price, i) => price.price,
                  domainFn: (price, i) => price.timestamp,
                  plotType: PlotType.line,
                ),
              ],
            ),
      ),
    );
  }
}

class SparkExample extends StatelessWidget {
  final sparkCharts = <Widget>[];
  final sparkLength = 40;
  final numSparkCharts = 4;

  SparkExample() {
    for (var i = 0; i < numSparkCharts; i++) {
      sparkCharts.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (context, constraints) => Flart.spark(
                    constraints.biggest,
                    [
                      FlartData<StockQuote, DateTime, double>(
                        // This was an easy way to put the first n days on the
                        // first spark, the next n on the next spark, and so on.
                        spyQuotes.sublist(
                            i * sparkLength, (i + 1) * sparkLength),
                        rangeFn: (price, i) => price.price,
                        domainFn: (price, i) => price.timestamp,
                        plotType: PlotType.line,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: sparkCharts,
      ),
    );
  }
}

class MultiDataExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) => Flart(
              constraints.biggest,
              [
                // DJI prices
                FlartData<StockQuote, DateTime, double>(
                  dowQuotes,
                  customColor: Colors.green,
                  rangeFn: (quote, i) => quote.price,
                  domainFn: (quote, i) => quote.timestamp,
                  domainAxisId: 'dates',
                  rangeAxis: FlartAxis(
                    direction: Axis.vertical,
                    minValue: dowPricesData.minRange,
                    maxValue: dowPricesData.maxRange,
                    side: Side.left,
                    labelConfig: AxisLabelConfig(
                      frequency: AxisLabelFrequency.none,
                    ),
                    numGridlines: 0,
                  ),
                ),
                // SPY prices
                FlartData<StockQuote, DateTime, double>(
                  spyQuotes,
                  customColor: Colors.redAccent,
                  rangeFn: (price, i) => price.price,
                  domainFn: (price, i) => price.timestamp,
                  domainAxisId: 'dates',
                  rangeAxis: FlartAxis(
                    direction: Axis.vertical,
                    minValue: spyPriceData.minRange,
                    maxValue: spyPriceData.maxRange,
                    labelConfig: AxisLabelConfig(
                      frequency: AxisLabelFrequency.perGridline,
                      text: AxisLabelTextSource.interpolateFromDataType,
                    ),
                    numGridlines: 6,
                  ),
                ),
                // SPY volume
                FlartData<StockQuote, DateTime, int>(
                  spyQuotes,
                  layer: 0,
                  plotType: PlotType.bar,
                  customColor: Color(0xAA4488aa),
                  rangeFn: (price, i) => price.volume,
                  domainFn: (price, i) => price.timestamp,
                  domainAxisId: 'dates',
                  rangeAxis: FlartAxis(
                    direction: Axis.vertical,
                    minValue: spyVolumeData.minRange,
                    maxValue: spyVolumeData.maxRange,
                    side: Side.left,
                    labelConfig: AxisLabelConfig(
                      frequency: AxisLabelFrequency.perGridline,
                      text: AxisLabelTextSource.interpolateFromDataType,
                    ),
                    numGridlines: 6,
                  ),
                ),
              ],
              sharedAxes: [
                FlartAxis(
                  direction: Axis.horizontal,
                  minValue: spyPriceData.minDomain,
                  maxValue: spyPriceData.maxDomain,
                  id: 'dates',
                  labelConfig: AxisLabelConfig(
                    frequency: AxisLabelFrequency.perGridline,
                    text: AxisLabelTextSource.interpolateFromDataType,
                  ),
                  numGridlines: 8,
                ),
              ],
            ),
      ),
    );
  }
}

class FlartExamplePageState extends State<FlartExamplePage> {
  String selectedExample;
  bool rowMode;

  @override
  void initState() {
    selectedExample = widget.examples.keys.first;
    rowMode = false;

    super.initState();
  }

  void onSelectExample(String example) {
    setState(() => selectedExample = example);
  }

  void onUiButtonPress() {
    setState(() => rowMode = !rowMode);
  }

  @override
  Widget build(BuildContext context) {
    final controls = <Widget>[
      DropdownButton<String>(
        value: selectedExample,
        items: widget.examples.keys
            .map<DropdownMenuItem<String>>((key) => DropdownMenuItem<String>(
                  value: key,
                  child: Text(key),
                ))
            .toList(),
        onChanged: onSelectExample,
      ),
      RaisedButton(
        child: Text('ui side'),
        onPressed: onUiButtonPress,
      ),
    ];

    final contents = [
      Container(
        child: rowMode
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: controls,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: controls,
              ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: selectedExample != null
              ? widget.examples[selectedExample]
              : Container(),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Flart Examples', style: Theme.of(context).textTheme.title),
      ),
      body: Container(
        child: rowMode
            ? Column(
                children: contents,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: contents,
              ),
      ),
    );
  }
}
