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
        padding:
            const EdgeInsets.only(left: 15.0, top: 30, right: 15, bottom: 15),
        child: SfCartesianChart(
          primaryXAxis: DateTimeAxis(),
          primaryYAxis: NumericAxis(),
          title: ChartTitle(text: 'Scores'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: _getPlayerScoreSeries(),
        ),
      ),
    );
  }

  List<LineSeries<Score, DateTime>> _getPlayerScoreSeries() {
    return players.map((player) {
      return LineSeries<Score, DateTime>(
        name: player.name,
        dataSource: player.scores,
        xValueMapper: (Score score, _) => DateTime.parse(score.date),
        yValueMapper: (Score score, _) => score.scoreValue,
        dataLabelSettings: DataLabelSettings(isVisible: true),
      );
    }).toList();
  }
}
