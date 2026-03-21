import 'package:cursor_hack/utils/colors/colors.dart';
import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? iconText;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.iconText,
    this.onPressed,
    this.textStyle,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: borderRadius ?? BorderRadius.circular(14),
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.inputBackground,
          borderRadius: borderRadius ?? BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (iconText != null) ...[
              const SizedBox(width: 8),
              Text(
                iconText!,
                style:
                    textStyle ??
                    const TextStyle(
                      color: AppColors.titleText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
