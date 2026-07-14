import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DonutChart extends StatelessWidget {
  final String midText;
  final int pending;
  final int approved;
  final int rejected;
  final int progress;
  final int autoApproved;
  final int locked;

  const DonutChart({
    Key? key,
    required this.midText,
    this.pending = 0,
    this.approved = 0,
    this.rejected = 0,
    this.progress = 0,
    this.autoApproved = 0,
    this.locked = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = pending + approved + rejected + progress + autoApproved + locked;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            centerSpaceRadius: 60,
            sectionsSpace: 2,
            sections: total == 0
                ? [
                    PieChartSectionData(
                      value: 1,
                      color: Colors.grey.shade200,
                      showTitle: false,
                      radius: 40,
                    ),
                  ]
                : [
                    if (pending > 0)
                      PieChartSectionData(
                        value: pending.toDouble(),
                        color: Colors.green,
                        showTitle: false,
                        radius: 40,
                      ),
                    if (approved > 0)
                      PieChartSectionData(
                        value: approved.toDouble(),
                        color: Colors.orange,
                        showTitle: false,
                        radius: 40,
                      ),
                    if (rejected > 0)
                      PieChartSectionData(
                        value: rejected.toDouble(),
                        color: Colors.purple,
                        showTitle: false,
                        radius: 40,
                      ),
                    if (progress > 0)
                      PieChartSectionData(
                        value: progress.toDouble(),
                        color: Colors.blue,
                        showTitle: false,
                        radius: 40,
                      ),
                    if (autoApproved > 0)
                      PieChartSectionData(
                        value: autoApproved.toDouble(),
                        color: Colors.grey,
                        showTitle: false,
                        radius: 40,
                      ),
                    if (locked > 0)
                      PieChartSectionData(
                        value: locked.toDouble(),
                        color: Colors.red,
                        showTitle: false,
                        radius: 40,
                      ),
                  ],
          ),
        ),


        Column(
          mainAxisSize: MainAxisSize.min,
          children:  [
            Text(
              textAlign: TextAlign.center,
              midText,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}