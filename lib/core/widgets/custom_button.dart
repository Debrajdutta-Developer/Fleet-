import 'package:flutter/material.dart';
import 'loading_widget.dart';

enum ButtonType { primary, secondary, text }

/// Reusable production-ready button component supporting different states, shapes, and types.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon = officeIcon, // Default no icon placeholder
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50.0,
  });

  static const IconData officeIcon = IconData(0x0, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBgColor = type == ButtonType.primary
        ? theme.colorScheme.primary
        : Colors.transparent;

    final defaultTextColor = type == ButtonType.primary
        ? (isDark ? theme.colorScheme.onPrimary : Colors.white)
        : (type == ButtonType.secondary
            ? theme.colorScheme.primary
            : theme.colorScheme.primary);

    final finalBgColor = backgroundColor ?? defaultBgColor;
    final finalTextColor = textColor ?? defaultTextColor;

    final buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          LoadingWidget.small(color: finalTextColor),
          const SizedBox(width: 10),
        ] else if (icon != null && icon != officeIcon) ...[
          Icon(icon, size: 18, color: finalTextColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: onPressed == null
                ? theme.colorScheme.onSurface.withOpacity(0.38)
                : finalTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );

    Widget button;

    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: finalBgColor,
            disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(
              0.12,
            ),
            minimumSize: Size(width ?? double.infinity, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonContent,
        );
        break;

      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height),
            side: BorderSide(
              color: onPressed == null
                  ? theme.colorScheme.onSurface.withOpacity(0.12)
                  : (backgroundColor ?? theme.colorScheme.primary),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonContent,
        );
        break;

      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: buttonContent,
        );
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: button,
    );
  }
}
