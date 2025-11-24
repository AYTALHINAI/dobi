import 'package:flutter/material.dart';

class StepTrackerBar extends StatefulWidget {
  final int currentStep;
  final int totalSteps;

  const StepTrackerBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<StepTrackerBar> createState() => _StepTrackerBarState();
}

class _StepTrackerBarState extends State<StepTrackerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // pulse animation for current step
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: List.generate(widget.totalSteps * 2 - 1, (index) {
          if (index.isEven) {
            // Step circle
            int stepIndex = index ~/ 2;
            bool isActive = stepIndex == widget.currentStep - 1;
            bool isCompleted = stepIndex < widget.currentStep - 1;

            return Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double scale = isActive ? 1 + 0.1 * _controller.value : 1;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : isActive
                              ? Colors.black87
                              : Colors.grey.shade300,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isCompleted || isActive)
                              BoxShadow(
                                color: (isCompleted
                                    ? Colors.green
                                    : Colors.black87)
                                    .withOpacity(0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isCompleted || isActive
                                  ? Colors.white
                                  : Colors.black54,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            // Connecting line
            int leftStep = index ~/ 2;
            bool isActive = leftStep < widget.currentStep - 1;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey.shade300,
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
