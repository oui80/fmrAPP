import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'Data.dart';

class StatPage extends StatelessWidget {
  final List<Player> players;

  StatPage(this.players);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 15.0, top: 50, right: 15, bottom: 15),
        child: SfCartesianChart(
          primaryXAxis: NumericAxis(), // Change to NumericAxis
          primaryYAxis: NumericAxis(
            interval: 0.5, // Adjust the interval for fewer labels
          ),
          title: ChartTitle(text: 'Scores'),
          legend: Legend(
            isVisible: true,
            position: LegendPosition.bottom,
            overflowMode: LegendItemOverflowMode.scroll,
          ),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: _getPlayerScoreSeries(),
        ),
      ),
    );
  }

  List<LineSeries<Score, num>> _getPlayerScoreSeries() {
    return players.map((player) {
      num cumulativeSum = 0;
      return LineSeries<Score, num>(
        name: player.name,
        dataSource: player.scores,
        xValueMapper: (Score score, int index) {
          cumulativeSum += score.scoreValue;
          return cumulativeSum;
        },
        yValueMapper: (Score score, _) => score.scoreValue,
        dataLabelSettings: DataLabelSettings(isVisible: false), // Disable data labels
      );
    }).toList();
  }
}