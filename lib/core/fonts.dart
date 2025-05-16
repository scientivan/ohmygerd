import 'package:flutter/material.dart';

class AppFonts {
  static const String outfit = 'Outfit';

  static TextStyle regular(double size) => TextStyle(
        fontFamily: outfit,
        fontWeight: FontWeight.w400,
        fontSize: size,
      );

  static TextStyle medium(double size) => TextStyle(
        fontFamily: outfit,
        fontWeight: FontWeight.w500,
        fontSize: size,
      );

  static TextStyle semiBold(double size) => TextStyle(
        fontFamily: outfit,
        fontWeight: FontWeight.w600,
        fontSize: size,
      );

  static TextStyle bold(double size) => TextStyle(
        fontFamily: outfit,
        fontWeight: FontWeight.w700,
        fontSize: size,
      );

  static TextStyle extraBold(double size) => TextStyle(
        fontFamily: outfit,
        fontWeight: FontWeight.w800,
        fontSize: size,
      );
}
