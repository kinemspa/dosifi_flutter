import 'package:flutter/material.dart';

class CompactCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry borderRadius;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool outlined;

  const CompactCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onTap,
    this.accentColor,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = (accentColor ?? theme.colorScheme.primary).withValues(
      alpha: 0.10,
    );
    // Apply margin outside the Material so the border hugs the content without an internal gap.
    return Container(
      margin: margin,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: borderRadius as BorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: borderRadius as BorderRadius,
          onTap: onTap,
          child: Container
            (
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: outlined ? Border.all(color: borderColor, width: 1) : null,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
