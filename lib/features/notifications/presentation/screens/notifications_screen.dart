import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Filter state: 'All' or 'Unread'
  String _activeTab = 'All';

  void _markAllAsRead() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      UserService.instance.markAllNotificationsAsRead(user.uid);
    }
  }

  void _toggleReadStatus(String id) {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      UserService.instance.markNotificationAsRead(user.uid, id);
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getCategoryHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'TODAY';
    } else if (itemDate == yesterday) {
      return 'YESTERDAY';
    } else {
      return 'EARLIER';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'welcome':
        return Icons.auto_awesome_rounded;
      case 'cycle':
        return Icons.calendar_today_rounded;
      case 'workout':
        return Icons.fitness_center_rounded;
      case 'insight':
        return Icons.trending_up_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getCategoryBg(String category) {
    switch (category.toLowerCase()) {
      case 'welcome':
      case 'cycle':
      case 'insight':
        return AppColors.wellnessPinkBg;
      case 'workout':
        return AppColors.wellnessOrangeBg;
      default:
        return AppColors.systemNotificationBg;
    }
  }

  Color _getCategoryIconColor(String category) {
    switch (category.toLowerCase()) {
      case 'welcome':
      case 'cycle':
      case 'insight':
        return AppColors.wellnessPinkText;
      case 'workout':
        return AppColors.wellnessOrangeText;
      default:
        return AppColors.systemNotificationIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSpacing.h16,
              _buildAppBar(),
              AppSpacing.h24,
              _buildFilterToggle(),
              AppSpacing.h16,

              // Notifications Stream from Firestore
              Expanded(
                child: user == null
                    ? _buildEmptyState()
                    : StreamBuilder<List<NotificationModel>>(
                        stream: UserService.instance.getNotificationsStream(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.wellnessPinkText,
                              ),
                            );
                          }

                          final allNotifications = snapshot.data ?? [];

                          // Filter list based on active tab
                          final filteredList = _activeTab == 'All'
                              ? allNotifications
                              : allNotifications.where((n) => !n.isRead).toList();

                          if (filteredList.isEmpty) {
                            return _buildEmptyState();
                          }

                          // Group filtered items by date category ('TODAY', 'YESTERDAY', 'EARLIER')
                          final Map<String, List<NotificationModel>> groupedItems = {};
                          for (var item in filteredList) {
                            final categoryHeader = _getCategoryHeader(item.createdAt);
                            groupedItems.putIfAbsent(categoryHeader, () => []).add(item);
                          }

                          final categories = ['TODAY', 'YESTERDAY', 'EARLIER'];

                          return ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.l,
                              vertical: AppSpacing.s,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, catIndex) {
                              final category = categories[catIndex];
                              final items = groupedItems[category];
                              if (items == null || items.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Category Header
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 16.0,
                                      bottom: 8.0,
                                    ),
                                    child: Text(
                                      category,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.wellnessGray,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                  // Items list for this category
                                  ...items.map(
                                    (item) => _buildNotificationCard(item),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- App Bar ---
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Custom Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.r12,
                border: Border.all(
                  color: AppColors.wellnessBrown.withValues(alpha: 0.1),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.wellnessBrown,
                size: 26,
              ),
            ),
          ),

          Text(
            'Notifications',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Mark all as read button
          GestureDetector(
            onTap: _markAllAsRead,
            child: Text(
              'Mark all as read',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Filter Toggle ---
  Widget _buildFilterToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(3.0),
        decoration: BoxDecoration(
          color: AppColors.wellnessBeigeCardBg,
          borderRadius: AppRadius.rCircular,
        ),
        child: Row(
          children: [
            Expanded(child: _buildToggleTab('All')),
            Expanded(child: _buildToggleTab('Unread')),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTab(String tabName) {
    final isSelected = _activeTab == tabName;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : AppColors.transparent,
          borderRadius: AppRadius.rCircular,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.wellnessBrown.withValues(alpha: 0.05),
                    blurRadius: 5.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          tabName,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.wellnessBrown : AppColors.wellnessGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  // --- Notification Card ---
  Widget _buildNotificationCard(NotificationModel item) {
    final icon = _getCategoryIcon(item.category);
    final iconBg = _getCategoryBg(item.category);
    final iconColor = _getCategoryIconColor(item.category);
    final timeAgo = _getTimeAgo(item.createdAt);

    return GestureDetector(
      onTap: () => _toggleReadStatus(item.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.r16,
          boxShadow: [
            BoxShadow(
              color: AppColors.wellnessBrown.withValues(alpha: 0.03),
              blurRadius: 12.0,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.wellnessBeige.withValues(alpha: 0.06),
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Category Badge
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppRadius.r12,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            AppSpacing.w16,

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.wellnessBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.wellnessGray,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h4,
                  Text(
                    item.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.wellnessGray,
                      fontSize: 13.0,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Unread pink dot
            if (!item.isRead) ...[
              AppSpacing.w8,
              Container(
                margin: const EdgeInsets.only(top: 5.0),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.wellnessPinkText,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: AppColors.wellnessPink.withValues(alpha: 0.8),
          ),
          AppSpacing.h16,
          Text(
            'No notifications yet',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.wellnessBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.h8,
          Text(
            "You're all caught up with your flow insights!",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.wellnessGray,
            ),
          ),
        ],
      ),
    );
  }
}
