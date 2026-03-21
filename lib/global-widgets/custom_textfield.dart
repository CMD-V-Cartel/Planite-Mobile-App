import 'package:cursor_hack/utils/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatefulWidget {
  final String? label;
  final bool obscureText;
  final TextEditingController editingController;
  final String? hintText;
  final AutovalidateMode autovalidateMode;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType textInputType;
  final int? maxLines;
  final Widget? suffixIcon;
  final TextCapitalization? textCapitalization;
  final Function(String)? onChanged;
  final Widget? hintIcon;
  final FormFieldValidator? formValidator;
  final FormFieldSetter? onFieldSubmitted;
  final FormFieldSetter? onTapOutside;
  final Color? enabledBorderColor;
  final int? maxLength;
  final int? minLines;
  final bool enabled;
  final Function()? onTap;
  final bool readOnly;
  final Widget? suffix;
  final double? borderRadius;
  final Widget? prefixIcon;
  final bool autofocus;
  final bool isPassword;
  final String? suffixText;
  final bool isFilled;
  final bool isBorder;

  const CustomTextField({
    super.key,
    this.label,
    this.enabled = true,
    this.isPassword = false,
    this.maxLines,
    this.obscureText = false,
    this.inputFormatters,
    this.onChanged,
    this.borderRadius,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    required this.editingController,
    this.textCapitalization,
    this.hintText,
    required this.textInputType,
    this.hintIcon,
    this.suffixIcon,
    this.formValidator,
    this.onFieldSubmitted,
    this.onTapOutside,
    this.enabledBorderColor,
    this.maxLength,
    this.onTap,
    this.minLines,
    this.readOnly = false,
    this.suffix,
    this.prefixIcon,
    this.autofocus = false,
    this.suffixText,
    this.isFilled = true,
    this.isBorder = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool passwordVisible = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      minLines: widget.minLines,
      textAlign: TextAlign.left,
      maxLength: widget.maxLength,
      obscureText: widget.obscureText,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textCapitalization: widget.textCapitalization ?? TextCapitalization.none,
      autovalidateMode: widget.autovalidateMode,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: AppColors.primary,
      inputFormatters: widget.inputFormatters,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.titleText),
      controller: widget.editingController,
      keyboardType: widget.textInputType,
      decoration: InputDecoration(
        suffixStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.primaryText),
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xffA1A1A1),
          height: 1.4,
        ),
        labelText: widget.label,
        alignLabelWithHint: true,
        suffix: widget.suffix,
        errorStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
        hintText: widget.hintText,
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[500], height: 1.4),
        prefixIcon: widget.prefixIcon,
        filled: widget.isFilled,
        fillColor: widget.enabled
            ? AppColors.primaryText
            : Colors.grey.shade100,
        suffixIcon:
            widget.suffixIcon ??
            (widget.isPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        passwordVisible = !passwordVisible;
                      });
                    },
                    icon: passwordVisible
                        ? const Icon(Icons.visibility_off)
                        : const Icon(Icons.visibility),
                  )
                : null),
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        border: widget.isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? 10.r,
                ),
                borderSide: const BorderSide(color: AppColors.primary),
              )
            : InputBorder.none,
        errorBorder: widget.isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? 10.r,
                ),
                borderSide: const BorderSide(color: AppColors.primary),
              )
            : InputBorder.none,
        errorMaxLines: 2,
        disabledBorder: widget.isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? 10.r,
                ),
                borderSide: BorderSide(color: Colors.grey.shade200),
              )
            : InputBorder.none,
        focusedBorder: widget.isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? 10.r,
                ),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              )
            : InputBorder.none,
        enabledBorder: widget.isBorder
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? 10.r,
                ),
                borderSide: BorderSide(
                  color: widget.enabledBorderColor ?? Colors.grey.shade300,
                ),
              )
            : InputBorder.none,
      ),
      validator: widget.formValidator,
      onFieldSubmitted: widget.onFieldSubmitted,
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }
}
