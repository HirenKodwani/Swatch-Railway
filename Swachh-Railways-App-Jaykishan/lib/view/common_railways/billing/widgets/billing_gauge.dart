import 'package:crm_train/utills/app_colors.dart';
import 'package:flutter/material.dart';

class BillingGauge extends StatelessWidget {
  final double score;
  final double size;
  final String label;

  const BillingGauge({
    super.key,
    required this.score,
    this.size = 120,
    this.label = 'Score',
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 90 ? Colors.green : (score >= 80 ? Colors.blue : (score >= 70 ? Colors.orange : Colors.red));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.toInt()}%',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.2, color: color),
              ),
              Text(
                label,
                style: TextStyle(fontSize: size * 0.1, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
