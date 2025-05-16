import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isLoading = true;
  final _auth = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      extendBodyBehindAppBar: true,
      appBar: InvisibleAppbar(title: "Pengaturan"),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 45, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Akun",
                  style: AppFonts.semiBold(
                    16,
                  ).copyWith(color: AppColors.neutral.shade500),
                ),
                SizedBox(height: 8),
                Column(
                  children: [
                    CustomSettingsTile(
                      title: "Profil",
                      isTop: true,
                      onTap: () {
                        context.push(
                          '${AppRoutes.settings}/${AppRoutes.profileSettings}',
                        );
                      },
                    ),
                    CustomSettingsTile(
                      title: "Preferensi",
                      onTap: () {
                        context.push(
                          '${AppRoutes.settings}/${AppRoutes.preferenceSettings}',
                        );
                      },
                    ),
                    CustomSettingsTile(
                      title: "Koneksi",
                      isBottom: true,
                      onTap: () {
                        context.push(
                          '${AppRoutes.settings}/${AppRoutes.connectionsSettings}',
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),
                RedMainButton(
                  text: "Sign Out",
                  onPressed: () async {
                    await _auth.signout();
                    await GoogleSignIn().signOut();
                    context.go(AppRoutes.login);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomSettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isTop;
  final bool isBottom;

  const CustomSettingsTile({
    super.key,
    required this.title,
    this.onTap,
    this.isTop = false,
    this.isBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.shade300;

    BorderSide side = BorderSide(color: borderColor);

    Border border;
    if (isTop && isBottom) {
      border = Border.all(color: borderColor); // cuma 1 tile
    } else if (isTop) {
      border = Border(top: side, left: side, right: side);
    } else if (isBottom) {
      border = Border(bottom: side, left: side, right: side);
    } else {
      // Tengah: tetap punya kiri-kanan juga
      border = Border(left: side, right: side, top: side, bottom: side);
    }

    BorderRadius radius = BorderRadius.only(
      topLeft: isTop ? Radius.circular(8) : Radius.zero,
      topRight: isTop ? Radius.circular(8) : Radius.zero,
      bottomLeft: isBottom ? Radius.circular(8) : Radius.zero,
      bottomRight: isBottom ? Radius.circular(8) : Radius.zero,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: border, borderRadius: radius),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          IconButton(onPressed: onTap, icon: Icon(Icons.arrow_right_sharp)),
        ],
      ),
    );
  }
}
