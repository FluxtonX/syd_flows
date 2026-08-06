import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';

class SplashLogoCard extends StatelessWidget {
  const SplashLogoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logo,
      height: 240.0,
      width: 240.0,
      fit: BoxFit.contain,
    );
  }
}
