import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatsPage extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  StatsPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 15.0, top: 30, right: 15, bottom: 15),
        child: SfCartesianChart(
          primaryXAxis: DateTimeAxis(
            intervalType: DateTimeIntervalType.seconds,
            interval: 1,
          ),
          title: ChartTitle(text: 'Scores des Joueurs'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: _getPlayerSeries(),
        ),
      ),
    );
  }

  List<LineSeries<Map<String, dynamic>, DateTime>> _getPlayerSeries() {
    return data.map((player) {
      List<Map<String, dynamic>> cumulativePoints = [];
      int cumulativeScore = 0;

      for (var point in player['points']) {
        cumulativeScore += point['score'] as int;
        cumulativePoints.add({
          'time': point['time'],
          'score': cumulativeScore,
        });
      }

      return LineSeries<Map<String, dynamic>, DateTime>(
        dataSource: cumulativePoints,
        xValueMapper: (point, _) => point['time'],
        yValueMapper: (point, _) => point['score'],
        name: player['nom'],
        dataLabelSettings: DataLabelSettings(isVisible: true),
      );
    }).toList();
  }
}