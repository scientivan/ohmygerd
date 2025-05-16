import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:dotted_border/dotted_border.dart';

class MainButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const MainButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 37,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary.shade200,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.neutral.shade900, width: 1),
          ),
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neutral.shade900,
                    ),
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  text,
                  style: AppFonts.semiBold(
                    14,
                  ).copyWith(color: AppColors.neutral.shade900),
                ),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.neutral.shade900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: SizedBox(
        width: double.infinity,
        child:
            isLoading
                ? Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.neutral.shade900,
                      ),
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/google_icon.png'),
                    const SizedBox(width: 10),
                    Text(
                      'Lanjut dengan Google',
                      style: AppFonts.medium(
                        14,
                      ).copyWith(color: AppColors.neutral.shade900),
                    ),
                  ],
                ),
      ),
    );
  }
}

class DashedMainButton extends StatelessWidget {
  final String text;
  final String? icon;
  final VoidCallback onPressed;
  final bool isLoading;

  const DashedMainButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: Radius.circular(8),
      color: AppColors.neutral.shade900,
      dashPattern: [6, 3],
      strokeWidth: 1,
      child:
          isLoading
              ? Container(
                width: double.infinity,
                height: 37,
                alignment: Alignment.center,
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.neutral.shade900,
                    ),
                  ),
                ),
              )
              : SizedBox(
                width: double.infinity,
                height: 37,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neutral.shade0,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child:
                      icon != null
                          ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(icon!),
                              SizedBox(width: 8),
                              Text(
                                text,
                                style: AppFonts.semiBold(
                                  14,
                                ).copyWith(color: AppColors.neutral.shade900),
                              ),
                            ],
                          )
                          : Text(
                            text,
                            style: AppFonts.semiBold(
                              14,
                            ).copyWith(color: AppColors.neutral.shade900),
                          ),
                ),
              ),
    );
  }
}

class RedMainButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const RedMainButton({Key? key, required this.text, required this.onPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 37,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger.shade100,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.danger.shade300, width: 1),
          ),
        ),
        child: Text(
          text,
          style: AppFonts.semiBold(
            14,
          ).copyWith(color: AppColors.neutral.shade900),
        ),
      ),
    );
  }
}
