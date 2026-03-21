import 'package:cursor_hack/global-widgets/box.dart';
import 'package:cursor_hack/utils/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  final String buttonText;
  final bool isLoading;
  final VoidCallback? function;
  final Color? customButtonColor;
  final TextStyle? buttonTextStyle;
  final double? radius;
  final IconData? iconData;

  const CustomButton({
    super.key,
    this.customButtonColor,
    required this.buttonText,
    required this.function,
    this.isLoading = false,
    this.buttonTextStyle,
    this.iconData,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: function,
      child: Container(
        height: 45.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius ?? 8.r),
          color: customButtonColor ?? AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconData != null
                      ? Icon(iconData, size: 16, color: Colors.white)
                      : const SizedBox.shrink(),
                  iconData != null ? boxw10 : const SizedBox.shrink(),
                  Text(
                    buttonText,
                    textAlign: TextAlign.center,
                    style:
                        buttonTextStyle ??
                        TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
