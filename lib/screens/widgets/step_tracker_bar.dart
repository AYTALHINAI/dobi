import 'package:flutter/material.dart';

class StepTrackerBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const StepTrackerBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1A237E); // Deep Indigo
    // ignore: unused_local_variable
    const inactiveColor = Color(0xFFE0E0E0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            // STEP CIRCLE
            int stepIndex = index ~/ 2;
            int stepNumber = stepIndex + 1;
            bool isActive = stepNumber == currentStep;
            bool isCompleted = stepNumber < currentStep;

            return Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 40 : 32,
                    height: isActive ? 40 : 32,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive ? activeColor : Colors.white,
                      border: Border.all(
                        color: isCompleted || isActive ? activeColor : Colors.grey.shade400,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: activeColor.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '$stepNumber',
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: isActive ? 16 : 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stepIndex < stepLabels.length ? stepLabels[stepIndex] : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? activeColor : Colors.grey.shade600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // CONNECTING LINE
            int stepIndex = (index - 1) ~/ 2;
            bool isLineActive = stepIndex + 1 < currentStep;

            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24), // Increased to align with larger circles + labels
                height: 3,
                decoration: BoxDecoration(
                  color: isLineActive ? activeColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
