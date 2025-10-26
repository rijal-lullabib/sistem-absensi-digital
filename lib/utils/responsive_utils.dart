import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints yang lebih detail
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1200;
  static const double smallMobileMaxWidth = 360;

  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < smallMobileMaxWidth;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width >= smallMobileMaxWidth &&
      MediaQuery.of(context).size.width < mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMaxWidth &&
      MediaQuery.of(context).size.width < tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  static bool isMobileOrSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static Size getScreenSize(BuildContext context) =>
      MediaQuery.of(context).size;

  static double getFontSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    if (width < smallMobileMaxWidth) return baseSize * 0.75;
    if (width < mobileMaxWidth) return baseSize * 0.9;
    if (width < tabletMaxWidth) return baseSize * 1.1;
    return baseSize * 1.3;
  }

  static double getTitleFontSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    if (width < smallMobileMaxWidth) return baseSize * 0.8;
    if (width < mobileMaxWidth) return baseSize;
    if (width < tabletMaxWidth) return baseSize * 1.2;
    return baseSize * 1.4;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isSmallMobile(context)) {
      return const EdgeInsets.all(8.0);
    } else if (isMobile(context)) {
      return const EdgeInsets.all(12.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  static double getCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileMaxWidth) return width * 0.9;
    if (width < tabletMaxWidth) return width * 0.45;
    return width * 0.3;
  }

  static double getDialogWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileMaxWidth) return width * 0.95;
    if (width < tabletMaxWidth) return width * 0.8;
    return width * 0.6;
  }

  static double getDialogHeight(BuildContext context) {
    final height = getScreenHeight(context);
    if (height < 600) return height * 0.8;
    if (height < 800) return height * 0.7;
    return height * 0.6;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < mobileMaxWidth) return 1;
    if (width < tabletMaxWidth) return 2;
    return 3;
  }

  static double getIconSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    if (width < smallMobileMaxWidth) return baseSize * 0.8;
    if (width < mobileMaxWidth) return baseSize;
    if (width < tabletMaxWidth) return baseSize * 1.2;
    return baseSize * 1.4;
  }

  static double getButtonHeight(BuildContext context) {
    if (isSmallMobile(context)) return 44.0;
    if (isMobile(context)) return 48.0;
    if (isTablet(context)) return 52.0;
    return 56.0;
  }

  static double getAppBarHeight(BuildContext context) {
    if (isSmallMobile(context)) return 56.0;
    if (isMobile(context)) return 64.0;
    return 72.0;
  }

  static BorderRadius getBorderRadius(BuildContext context) {
    if (isSmallMobile(context)) {
      return BorderRadius.circular(12.0);
    } else if (isMobile(context)) {
      return BorderRadius.circular(16.0);
    } else if (isTablet(context)) {
      return BorderRadius.circular(20.0);
    } else {
      return BorderRadius.circular(24.0);
    }
  }

  static double getSpacing(BuildContext context, double baseSpacing) {
    final width = getScreenWidth(context);
    if (width < smallMobileMaxWidth) return baseSpacing * 0.75;
    if (width < mobileMaxWidth) return baseSpacing * 0.9;
    if (width < tabletMaxWidth) return baseSpacing;
    return baseSpacing * 1.2;
  }
}
