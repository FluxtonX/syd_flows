import 'package:flutter/material.dart';

import 'animated_gradient_background.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(child: child);
  }
}
