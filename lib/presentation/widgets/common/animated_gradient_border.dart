import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'dart:math' as math;

/// A widget that displays an animated rotating gradient border
/// Useful for profile avatars and other circular elements
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double size;
  final double borderWidth;
  final List<Color>? gradientColors;
  final Duration animationDuration;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.size = 100,
    this.borderWidth = 3,
    this.gradientColors,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default gradient colors - vibrant rainbow gradient
    final colors =
        widget.gradientColors ??
        [
          theme.colorScheme.primary,
          const Color(0xFF8B5CF6), // Purple
          const Color(0xFFEC4899), // Pink
          const Color(0xFFF97316), // Orange
          const Color(0xFF10B981), // Emerald
          const Color(0xFF3B82F6), // Blue
          theme.colorScheme.primary,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size + widget.borderWidth * 2,
          height: widget.size + widget.borderWidth * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: 2 * math.pi,
              colors: colors,
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: Center(
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.background,
              ),
              child: ClipOval(child: widget.child),
            ),
          ),
        );
      },
    );
  }
}

/// A simpler animated gradient border with conic gradient effect
class AnimatedConicGradientBorder extends StatefulWidget {
  final Widget child;
  final double size;
  final double borderWidth;
  final List<Color>? gradientColors;
  final Duration animationDuration;

  const AnimatedConicGradientBorder({
    super.key,
    required this.child,
    this.size = 100,
    this.borderWidth = 3,
    this.gradientColors,
    this.animationDuration = const Duration(seconds: 2),
  });

  @override
  State<AnimatedConicGradientBorder> createState() =>
      _AnimatedConicGradientBorderState();
}

class _AnimatedConicGradientBorderState
    extends State<AnimatedConicGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default gradient colors - subtle professional gradient
    final colors =
        widget.gradientColors ??
        [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.7),
          const Color(0xFF8B5CF6), // Purple
          const Color(0xFFEC4899), // Pink
          theme.colorScheme.primary,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            rotation: _controller.value * 2 * math.pi,
            colors: colors,
            borderWidth: widget.borderWidth,
          ),
          child: Container(
            width: widget.size + widget.borderWidth * 2,
            height: widget.size + widget.borderWidth * 2,
            padding: EdgeInsets.all(widget.borderWidth),
            child: ClipOval(child: widget.child),
          ),
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double rotation;
  final List<Color> colors;
  final double borderWidth;

  _GradientBorderPainter({
    required this.rotation,
    required this.colors,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(
      colors: colors,
      transform: GradientRotation(rotation),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - borderWidth) / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}
