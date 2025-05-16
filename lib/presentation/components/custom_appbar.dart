import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class InvisibleAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  // final VoidCallback? onBackPressed;  // Tambahkan parameter untuk custom action
  final bool? isBackButtonVisible;
  const InvisibleAppbar({this.title, this.isBackButtonVisible, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool showBackButton =
        isBackButtonVisible ?? true; // Default true jika null

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading:
          showBackButton
              ? Container(
                margin: EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.shade200,
                ),
                child: IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: Icon(Icons.arrow_back),
                  iconSize: 24,
                  padding: EdgeInsets.all(12),
                  color: Colors.black,
                ),
              )
              : null,
      title:
          title != null && title!.isNotEmpty
              ? Text(title!, style: AppFonts.semiBold(18))
              : null,
      centerTitle: true,
    );
  }
}
