import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Alignment> _beginAlignment;
  late final Animation<Alignment> _endAlignment;
  late final Animation<double> _animationVal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _beginAlignment = AlignmentTween(
      begin: const Alignment(-1.5, -1.2),
      end: const Alignment(1.5, -0.8),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _endAlignment = AlignmentTween(
      begin: const Alignment(1.5, 1.2),
      end: const Alignment(-1.5, 0.8),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _animationVal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        final val = _animationVal.value;

        // 3-stop gradient colors from Figma design
        final peach = AppColors.wellnessGradient[0]; // #EEC9A4
        final cream = AppColors.wellnessGradient[1]; // #FBF7F2
        final pink  = AppColors.wellnessGradient[2]; // #FFB3D0

        // Subtle color breathing — each stop shifts slightly toward its neighbor
        final color1 = Color.lerp(peach, cream, val * 0.18)!;
        final color2 = Color.lerp(cream, peach, val * 0.10)!;
        final color3 = Color.lerp(pink, cream, val * 0.18)!;

        // Stops breathe gently
        final stop1 = 0.0 + (val * 0.05);           // 0.00 → 0.05
        final stop2 = 0.50 - (val * 0.04);           // 0.50 → 0.46
        final stop3 = 1.0 - (val * 0.05);            // 1.00 → 0.95

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2, color3],
              stops: [stop1, stop2, stop3],
              begin: _beginAlignment.value,
              end: _endAlignment.value,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

