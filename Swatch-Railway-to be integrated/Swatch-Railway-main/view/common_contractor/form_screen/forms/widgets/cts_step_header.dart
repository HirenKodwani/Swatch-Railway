import 'package:flutter/material.dart';

class CTSStepHeader extends StatelessWidget {
  final int currentStep;
  final List<String>? stepTitles;

  const CTSStepHeader({
    super.key,
    required this.currentStep,
    this.stepTitles,
  });

  @override
  Widget build(BuildContext context) {
    final titles = stepTitles ?? ['Basic', 'Attendance', 'Disposal', 'Submit'];

    return SizedBox(
      height: 60,
      child: Row(
        children: List.generate(
          titles.length * 2 - 1,
          (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final active = stepIndex == currentStep;
              final done = stepIndex < currentStep;

              return Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: done || active ? Colors.blue : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: active
                            ? Border.all(color: Colors.blue.shade700, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: done || active ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        titles[stepIndex],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active ? FontWeight.bold : FontWeight.w500,
                          color: done || active ? Colors.blue : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              final stepIndex = index ~/ 2;
              final done = currentStep > stepIndex;

              return Expanded(
                flex: 1,
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: done ? Colors.blue : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
