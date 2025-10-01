import 'package:flutter/material.dart';

class ScalePressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scaleFactor;

  const ScalePressButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scaleFactor =
        0.95, // How much to scale down (e.g., 0.95 means 95% of original size)
  });

  @override
  State<ScalePressButton> createState() => _ScalePressButtonState();
}

class _ScalePressButtonState extends State<ScalePressButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          setState(() {
            _isPressed = true;
          });
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          setState(() {
            _isPressed = false;
          });
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) {
          setState(() {
            _isPressed = false;
          });
        }
      },
      onTap: widget.onPressed, // Execute the original onPressed callback
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
