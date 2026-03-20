import 'package:flutter/material.dart';

/// A reusable dark-themed back button matching the app's design language.
/// Dark rounded container with a chevron-left icon.
/// Calls [Navigator.pop] when tapped unless [onPressed] is provided.
class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const CustomBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.chevron_left_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

