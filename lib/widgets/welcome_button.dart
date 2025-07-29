import 'package:flutter/material.dart';

class WelcomeButton extends StatefulWidget {
  const WelcomeButton({
    super.key,
    this.buttonText,
    this.onTap,
    this.color,
    this.textColor,
  });

  final String? buttonText;
  final Widget? onTap;
  final Color? color;
  final Color? textColor;

  @override
  State<WelcomeButton> createState() => _WelcomeButtonState();
}

class _WelcomeButtonState extends State<WelcomeButton> {
  double _backgroundOpacity = 0.2;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _backgroundOpacity = 0.5;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _backgroundOpacity = 0.2;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => widget.onTap!,
      ),
    );
  }

  void _handleTapCancel() {
    setState(() {
      _backgroundOpacity = 0.2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Container(
        margin: const EdgeInsets.all(12), // Space between buttons
        padding: const EdgeInsets.all(20.0),       // Padding around all sides
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.color!.withOpacity(_backgroundOpacity),
          borderRadius: BorderRadius.circular(8),  // Rectangle with slight rounding
        ),
        child: Text(
          widget.buttonText!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold,
            color: widget.textColor!,              // 100% opacity text
          ),
        ),
      ),
    );
  }
}
