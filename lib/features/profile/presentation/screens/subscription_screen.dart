import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_success_banner.dart';
import '../../../../core/widgets/gradient_background.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int _selectedPlanIndex = 0;
  bool _showSuccessBanner = false;
  bool _isRequestingSubscription = false;
  String _bannerMessage = '';
  Timer? _bannerTimer;

  void _showBanner(String message) {
    setState(() {
      _bannerMessage = message;
      _showSuccessBanner = true;
    });
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSuccessBanner = false);
    });
  }

  Future<void> _requestSubscription(List<SubscriptionPlanModel> plans) async {
    if (_isRequestingSubscription) return;
    setState(() => _isRequestingSubscription = true);
    final selectedPlan = _selectedPlanIndex < plans.length
        ? plans[_selectedPlanIndex]
        : (plans.isNotEmpty ? plans.first : null);
    final planId = selectedPlan?.id ?? (_selectedPlanIndex == 0 ? 'annual' : 'monthly');

    try {
      await SubscriptionService.instance.requestSubscription(
        planId: planId,
      );
      if (mounted) {
        _showBanner('Subscription request submitted. Awaiting admin approval.');
      }
    } catch (error) {
      if (mounted) {
        _showBanner(error is StateError ? error.message : 'Unable to start subscription. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isRequestingSubscription = false);
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: StreamBuilder<UserSubscriptionStatus>(
            stream: SubscriptionService.instance.streamUserSubscriptionStatus(),
            builder: (context, statusSnapshot) {
              final userStatus = statusSnapshot.data ?? UserSubscriptionStatus.inactive;

              return StreamBuilder<SubscriptionPlansConfigModel>(
                stream: SubscriptionService.instance.streamSubscriptionPlans(),
                builder: (context, plansSnapshot) {
                  final config = plansSnapshot.data ?? SubscriptionPlansConfigModel.defaults;
                  final plans = config.plans.isNotEmpty ? config.plans : SubscriptionPlansConfigModel.defaults.plans;
                  final safeSelectedIndex = _selectedPlanIndex < plans.length ? _selectedPlanIndex : 0;
                  final activePlan = plans[safeSelectedIndex];
                  final hasTrial = activePlan.trialDays > 0;

                  return Stack(children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _buildHeader(context, isPremium: userStatus.isPremium),
                        const SizedBox(height: 24),

                        // If user is ALREADY APPROVED (Premium Member), show the VIP Unlocked View
                        if (userStatus.isPremium) ...[
                          _buildActivePremiumCard(userStatus),
                          const SizedBox(height: 24),
                          _sectionLabel('YOUR UNLOCKED PRIVILEGES'),
                          const SizedBox(height: 10),
                          _buildBenefits(isPremium: true),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop(true);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.wellnessBrown,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.play_circle_fill_rounded, size: 22, color: AppColors.wellnessPinkText),
                                const SizedBox(width: 10),
                                Text(
                                  'Explore Workout Studio',
                                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ]),
                            ),
                          ),
                        ] else ...[
                          // Normal Purchase / Subscription Flow
                          _buildHero(config),
                          const SizedBox(height: 24),

                          // If user has a pending request, show glowing pending indicator
                          if (userStatus.status == 'pending') ...[
                            _buildPendingApprovalCard(),
                            const SizedBox(height: 20),
                          ],

                          _sectionLabel('WHAT YOU GET'),
                          const SizedBox(height: 10),
                          _buildBenefits(isPremium: false),
                          const SizedBox(height: 24),
                          _sectionLabel('CHOOSE YOUR PLAN'),
                          const SizedBox(height: 10),
                          ...List.generate(plans.length, (index) {
                            final plan = plans[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: index == plans.length - 1 ? 0 : 12),
                              child: _buildPlanCard(
                                index: index,
                                title: plan.title,
                                subtitle: plan.subtitle,
                                price: plan.price,
                                period: plan.period,
                                detail: plan.detail,
                                badge: plan.badge.isNotEmpty ? plan.badge : null,
                              ),
                            );
                          }),
                          const SizedBox(height: 20),

                          Column(children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: userStatus.status == 'pending' || _isRequestingSubscription
                                    ? null
                                    : () => _requestSubscription(plans),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.wellnessBrown,
                                  foregroundColor: AppColors.white,
                                  disabledBackgroundColor: AppColors.wellnessBrown.withValues(alpha: 0.55),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  if (_isRequestingSubscription)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  else
                                    Icon(userStatus.status == 'pending' ? Icons.hourglass_top_rounded : Icons.lock_outline_rounded, size: 19),
                                  const SizedBox(width: 9),
                                  Text(
                                    _isRequestingSubscription
                                        ? 'Submitting request…'
                                        : userStatus.status == 'pending'
                                            ? 'Request Submitted (Pending Approval)'
                                            : hasTrial
                                                ? 'Start ${activePlan.trialDays}-day free trial'
                                                : 'Continue with ${activePlan.title}',
                                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
                                  ),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _showBanner('Your purchases will be restored after verification.'),
                              child: Text('Restore purchase', style: AppTextStyles.labelMedium.copyWith(color: AppColors.wellnessBrown, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          Text(
                            'Cancel anytime. Request is verified by administrator. By continuing, you agree to our Terms of Service.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.wellnessBrown.withValues(alpha: 0.58), height: 1.45),
                          ),
                        ],
                      ]),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic,
                      top: _showSuccessBanner ? 14 : -100, left: 16, right: 16,
                      child: Center(child: AppSuccessBanner(message: _bannerMessage)),
                    ),
                  ]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isPremium}) => Row(children: [
    Material(
      color: AppColors.white.withValues(alpha: 0.82), borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(14),
        child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back_rounded, color: AppColors.wellnessBrown)),
      ),
    ),
    const SizedBox(width: 14),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        isPremium ? 'VIP MEMBERSHIP' : 'SYD FLOWS PREMIUM',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.wellnessPinkText, fontWeight: FontWeight.w800, letterSpacing: 1.1),
      ),
      Text(
        isPremium ? 'Premium Active' : 'Upgrade your flow',
        style: AppTextStyles.titleLarge.copyWith(color: AppColors.wellnessBrown, fontWeight: FontWeight.w700),
      ),
    ]),
  ]);

  Widget _buildActivePremiumCard(UserSubscriptionStatus status) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFF8FA), Color(0xFFFBD4E1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.wellnessPinkBorder, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.wellnessBrown.withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.wellnessPinkBorder),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.stars_rounded, color: AppColors.wellnessPinkText, size: 15),
            const SizedBox(width: 5),
            Text(
              'ACTIVE MEMBER',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.wellnessPinkText,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text(
              'UNLOCKED',
              style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'You have full VIP Access',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.wellnessBrown,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All paid workout studios, cycle phase guides, and tailored programs are fully unlocked for your account.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.wellnessBrown.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        SvgPicture.asset(AppAssets.premiumBadge, width: 68, height: 68),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.wellnessPinkBorder.withValues(alpha: 0.6)),
        ),
        child: Row(children: [
          const Icon(Icons.verified_rounded, color: AppColors.wellnessPinkText, size: 18),
          const SizedBox(width: 8),
          Text(
            'Plan: ${status.planTitle}',
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.wellnessBrown, fontWeight: FontWeight.w800),
          ),
        ]),
      ),
    ]),
  );

  Widget _buildPendingApprovalCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
    ),
    child: Row(children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'Request Submitted (Pending Approval)',
            style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            'Your subscription request has been received. Features unlock automatically once verified!',
            style: TextStyle(color: const Color(0xFFB45309).withValues(alpha: 0.85), fontSize: 11, height: 1.35),
          ),
        ]),
      ),
    ]),
  );

  Widget _buildHero(SubscriptionPlansConfigModel config) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFFFF8FA), Color(0xFFFBD4E1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.wellnessPinkBorder),
      boxShadow: [BoxShadow(color: AppColors.wellnessBrown.withValues(alpha: 0.07), blurRadius: 22, offset: const Offset(0, 10))],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(99)),
          child: Text(
            config.heroTagline.isNotEmpty ? config.heroTagline : 'PERSONALISED WELLNESS',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.wellnessPinkText, fontWeight: FontWeight.w800, fontSize: 9.5, letterSpacing: 0.8),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          config.heroTitle.isNotEmpty ? config.heroTitle : 'Feel supported\nin every phase.',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.wellnessBrown, fontWeight: FontWeight.w800, height: 1.12),
        ),
        const SizedBox(height: 8),
        Text(
          config.heroSubtitle.isNotEmpty ? config.heroSubtitle : 'Unlock the complete workout library and deeper cycle guidance.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.wellnessBrown.withValues(alpha: 0.72), height: 1.45),
        ),
      ])),
      const SizedBox(width: 12),
      SvgPicture.asset(AppAssets.premiumBadge, width: 72, height: 72),
    ]),
  );

  Widget _sectionLabel(String label) => Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.wellnessBrown.withValues(alpha: 0.58), fontWeight: FontWeight.w800, letterSpacing: 1));

  Widget _buildBenefits({required bool isPremium}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.84), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.wellnessBrown.withValues(alpha: 0.08))),
    child: Column(children: [
      _BenefitRow(
        icon: isPremium ? Icons.check_circle_rounded : Icons.lock_open_rounded,
        title: 'Every premium workout',
        detail: 'Move with the full studio library, whenever you need it.',
      ),
      const Divider(height: 24),
      _BenefitRow(
        icon: isPremium ? Icons.check_circle_rounded : Icons.insights_rounded,
        title: 'Deeper cycle insights',
        detail: 'Understand patterns and plan your movement with confidence.',
      ),
      const Divider(height: 24),
      _BenefitRow(
        icon: isPremium ? Icons.check_circle_rounded : Icons.favorite_outline_rounded,
        title: 'Made for your rhythm',
        detail: 'Supportive content for each stage of your cycle.',
      ),
    ]),
  );

  Widget _buildPlanCard({required int index, required String title, required String subtitle, required String price, required String period, required String detail, String? badge}) {
    final isSelected = _selectedPlanIndex == index;
    return Semantics(
      button: true, selected: isSelected, label: '$title plan, $price $period',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPlanIndex = index), borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF7FA) : AppColors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isSelected ? AppColors.wellnessPinkText : AppColors.wellnessBrown.withValues(alpha: 0.12), width: isSelected ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppColors.wellnessPinkText : Colors.transparent, border: Border.all(color: isSelected ? AppColors.wellnessPinkText : AppColors.wellnessBrown.withValues(alpha: 0.28), width: 1.5)),
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 15) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium.copyWith(color: AppColors.wellnessBrown, fontWeight: FontWeight.w800)),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.wellnessPinkBg, borderRadius: BorderRadius.circular(99)),
                        child: Text(badge, style: AppTextStyles.labelSmall.copyWith(color: AppColors.wellnessPinkText, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.wellnessBrown.withValues(alpha: 0.63))),
                const SizedBox(height: 10),
                Text(detail, style: AppTextStyles.labelSmall.copyWith(color: AppColors.wellnessBrown.withValues(alpha: 0.53), fontWeight: FontWeight.w500)),
              ])),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(price, style: AppTextStyles.titleLarge.copyWith(color: AppColors.wellnessBrown, fontWeight: FontWeight.w800)),
                Text(period, style: AppTextStyles.labelSmall.copyWith(color: AppColors.wellnessBrown.withValues(alpha: 0.58))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _BenefitRow({required this.icon, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.wellnessPinkBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.wellnessPinkText, size: 20)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.wellnessBrown, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text(detail, style: AppTextStyles.bodySmall.copyWith(color: AppColors.wellnessBrown.withValues(alpha: 0.66), height: 1.35)),
    ])),
  ]);
}
