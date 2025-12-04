/// Glass morphism box widget
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Reusable glass-styled container with blur effect
class GlassBox extends StatelessWidget {
  final Widget child;

  const GlassBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.defaultBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppConstants.glassBlurSigma,
          sigmaY: AppConstants.glassBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.defaultPadding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(AppConstants.glassOpacity),
            borderRadius:
                BorderRadius.circular(AppDimensions.defaultBorderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
