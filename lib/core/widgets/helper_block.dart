import 'package:flutter/material.dart';
import 'package:dosifi_flutter/core/widgets/compact_card.dart';

enum HelperBlockType { info, warning, error }

class HelperBlock extends StatelessWidget {
  final String message;
  final HelperBlockType type;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const HelperBlock.info(
    this.message, {
    super.key,
    this.icon,
    this.padding = const EdgeInsets.all(12),
  }) : type = HelperBlockType.info;
  const HelperBlock.warning(
    this.message, {
    super.key,
    this.icon,
    this.padding = const EdgeInsets.all(12),
  }) : type = HelperBlockType.warning;
  const HelperBlock.error(
    this.message, {
    super.key,
    this.icon,
    this.padding = const EdgeInsets.all(12),
  }) : type = HelperBlockType.error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg;
    Color fg;
    IconData leadingIcon;

    switch (type) {
      case HelperBlockType.warning:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber[800]!;
        leadingIcon = Icons.warning_amber_rounded;
        break;
      case HelperBlockType.error:
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red[800]!;
        leadingIcon = Icons.error_outline;
        break;
      case HelperBlockType.info:
        bg = theme.colorScheme.primary.withValues(alpha: 0.08);
        fg = theme.colorScheme.primary;
        leadingIcon = Icons.info_outline;
        break;
    }

    return CompactCard(
      outlined: true,
      padding: padding,
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? leadingIcon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
