import 'package:flutter/material.dart';

class ScanningIndicator extends StatefulWidget {
  const ScanningIndicator({super.key});

  @override
  State<ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<ScanningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // continuous movement
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scanPosition =
            _controller.value * MediaQuery.of(context).size.height;

        return Stack(
          children: [
            // Dimmed background overlay
            Container(color: Colors.black.withOpacity(0.25)),

            // Moving scanner line
            Positioned(
              top: scanPosition,
              left: 0,
              right: 0,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.greenAccent.withOpacity(0.9),
                      Colors.greenAccent,
                      Colors.greenAccent.withOpacity(0.9),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Text hint
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Scanning...",
                  style: TextStyle(
                    color: Colors.greenAccent.shade100,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.greenAccent.withOpacity(0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
