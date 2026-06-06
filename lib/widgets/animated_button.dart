import 'package:flutter/material.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final Future<void> Function() onPressed;
  final bool loading;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _pressed = false;
  bool _running = false;

  Future<void> _handleTap() async {
    if (_running || widget.loading) return;

    setState(() {
      _pressed = true;
      _running = true;
    });

    await Future.delayed(const Duration(milliseconds: 120));

    setState(() => _pressed = false);

    try {
      await widget.onPressed();
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.92 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.loading ? Colors.grey : Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}