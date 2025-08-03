import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedGradientCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final Duration animationDuration;

  const AnimatedGradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.gradient,
    this.shadows,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedGradientCard> createState() => _AnimatedGradientCardState();
}

class _AnimatedGradientCardState extends State<AnimatedGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin ?? const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              gradient: widget.gradient ?? AppTheme.primaryGradient,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
              boxShadow: widget.shadows ?? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  offset: Offset(0, _elevationAnimation.value / 2),
                  blurRadius: _elevationAnimation.value * 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: (widget.borderRadius ?? BorderRadius.circular(20)) as BorderRadius,
                child: Padding(
                  padding: widget.padding ?? const EdgeInsets.all(16.0),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
