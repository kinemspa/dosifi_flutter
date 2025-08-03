import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AnimatedGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final bool loading;
  final TextStyle? textStyle;
  final Duration animationDuration;

  const AnimatedGradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.gradient,
    this.textColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.width,
    this.height,
    this.loading = false,
    this.textStyle,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.loading) {
      _pressController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  void _handleTap() {
    if (widget.onPressed != null && !widget.loading) {
      _rippleController.forward().then((_) {
        _rippleController.reset();
      });
      widget.onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveGradient = widget.gradient ?? AppTheme.primaryGradient;
    final effectiveTextColor = widget.textColor ?? Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_pressController, _rippleController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: effectiveGradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: Stack(
              children: [
                // Ripple effect
                if (_rippleAnimation.value > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: _rippleAnimation.value * 2,
                          colors: [
                            Colors.white.withValues(alpha: 0.3 * (1 - _rippleAnimation.value)),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                // Button content
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleTap,
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Container(
                      padding: widget.padding,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.loading)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                              ),
                            )
                          else if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: effectiveTextColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (!widget.loading)
                            Text(
                              widget.text,
                              style: widget.textStyle ??
                                  theme.textTheme.titleMedium?.copyWith(
                                    color: effectiveTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
