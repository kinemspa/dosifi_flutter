import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LabelChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const LabelChip({
    super.key,
    this.icon,
    required this.label,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipTheme = theme.chipTheme;

    // Use themed colors by default for readability; allow explicit color override
    final Color fg = color ?? (chipTheme.labelStyle?.color ?? theme.colorScheme.onSurface);
    final Color bg = color != null
        ? color!.withValues(alpha: 0.12)
        : (chipTheme.backgroundColor ?? theme.colorScheme.surface);
    final Color borderColor = color != null
        ? color!.withValues(alpha: 0.28)
        : (theme.colorScheme.onSurface.withValues(alpha: 0.15));

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
