import 'package:flutter/material.dart';

class CTSBottomBar extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const CTSBottomBar({
    super.key,
    required this.currentStep,
    required this.isSubmitting,
    required this.onBack,
    required this.onCancel,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (currentStep > 0)
              OutlinedButton.icon(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 40),
                ),
                icon: const Icon(Icons.arrow_back_outlined, size: 18),
                label: const Text(
                  'Back',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.blue, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                minimumSize: const Size(0, 40),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
            if (currentStep < 3)
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Next', style: TextStyle(fontSize: 14)),
              )
            else
              ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSubmitting ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Submitting...', style: TextStyle(fontSize: 14)),
                        ],
                      )
                    : const Text('Submit', style: TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}
