import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? AppColors.darkSurface : Colors.white;
    
    // Pink border color from the mockup image
    final borderColor = isDark 
        ? AppColors.darkBorder 
        : const Color(0xFFF5B5CD); // Solid pink border
        
    final activeTextColor = isDark ? Colors.white : AppColors.wellnessBrown;
    final inactiveTextColor = isDark 
        ? AppColors.darkTextTertiary 
        : AppColors.wellnessBrown.withValues(alpha: 0.6); // Muted brown for inactive

    final items = [
      _BottomNavItem(
        svgPath: AppAssets.navToday,
        label: 'Today',
      ),
      _BottomNavItem(
        svgPath: AppAssets.navCycle,
        label: 'Cycle',
      ),
      _BottomNavItem(
        svgPath: AppAssets.navWorkouts,
        label: 'Workouts',
      ),
      _BottomNavItem(
        svgPath: AppAssets.navProgress,
        label: 'Progress',
      ),
      _BottomNavItem(
        svgPath: AppAssets.navProfile,
        label: 'Profile',
      ),
    ];

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomPadding > 0 ? bottomPadding : 8.0;

    return Container(
      margin: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, bottomMargin),
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.4) 
                : AppColors.wellnessBrown.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / items.length;

          return Stack(
            children: [
              // Sliding active tab background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                left: currentIndex * tabWidth + (tabWidth - 64.0) / 2,
                top: 8.0,
                height: 60.0,
                width: 64.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.primary.withValues(alpha: 0.3),
                              AppColors.secondary.withValues(alpha: 0.2),
                            ]
                          : const [
                              Color(0xFFFFD1DF), // Warm pink left
                              Color(0xFFFFF0F5), // Soft lavender pink right
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              // Interactive Row of items
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(items.length, (index) {
                    final isSelected = currentIndex == index;
                    final item = items[index];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              item.svgPath,
                              width: 22,
                              height: 22,
                              colorFilter: ColorFilter.mode(
                                isSelected ? activeTextColor : inactiveTextColor,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              item.label,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isSelected ? activeTextColor : inactiveTextColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomNavItem {
  final String svgPath;
  final String label;

  _BottomNavItem({
    required this.svgPath,
    required this.label,
  });
}
