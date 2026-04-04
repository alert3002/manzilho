import 'package:flutter/material.dart';

/// Shimmer эффекти сабук барои skeleton-loading (популярный дизайн).
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1100),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = widget.baseColor ?? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE6E6E6));
    final hi = widget.highlightColor ?? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5));

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        // Аз -1 то +2 барои ҳаракати градиент аз чап ба рост.
        final dx = (t * 3) - 1;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 + dx, 0),
              end: Alignment(1 + dx, 0),
              colors: [base, hi, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.height,
    this.width,
    this.radius = 14,
    this.margin,
  });

  final double? height;
  final double? width;
  final double radius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        margin: margin,
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white, // муҳим: ранг барои ShaderMask
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

