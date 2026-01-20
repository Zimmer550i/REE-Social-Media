import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/style.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.color,
    this.textStyle,
    this.padding = EdgeInsets.zero,
    required this.onTap,
    required this.text,
    this.loading = false,
    this.width = double.infinity,
    this.height = 52,
  });

  final Function() onTap;
  final String text;
  final bool loading;
  final double? height;
  final double? width;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      child: Padding(
        padding: padding,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: color ?? AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  )
                : Text(
                    text,
                    style:
                        textStyle ??
                        AppStyles.h3(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
