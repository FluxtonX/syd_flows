import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/auth_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSpacing.h24,

                    // Logo Header matching Figma
                    Center(
                      child: Image.asset(
                        AppAssets.logo,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                    ),
                    AppSpacing.h24,

                    // Error banner
                    if (_viewModel.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: AppRadius.r12,
                          border: Border.all(color: const Color(0xFFF8B4B4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFE53E3E),
                              size: 20,
                            ),
                            AppSpacing.w12,
                            Expanded(
                              child: Text(
                                _viewModel.errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: const Color(0xFF9B1C1C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h16,
                    ],

                    // Main switched views with smooth cross-fade animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: _buildCurrentForm(_viewModel.currentState),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentForm(AuthState state) {
    switch (state) {
      case AuthState.signIn:
        return _buildSignInView();
      case AuthState.signUp:
        return _buildSignUpView();
      case AuthState.resetPassword:
        return _buildResetPasswordView();
    }
  }

  // --- SIGN IN VIEW ---
  Widget _buildSignInView() {
    return Column(
      key: const ValueKey('SignInView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Subtitle
        Text(
          'Welcome back',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.wellnessBrown,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        AppSpacing.h8,
        Text(
          'Move with intention again today.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.wellnessGray,
          ),
        ),
        AppSpacing.h24,

        // Google Sign In
        _buildGoogleButton(),
        AppSpacing.h16,

        // Divider
        _buildDivider(),
        AppSpacing.h16,

        // Email field
        AuthTextField(
          label: 'Email',
          hintText: 'you@sydflows.app',
          controller: _viewModel.emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.h16,

        // Password field
        AuthTextField(
          label: 'Password',
          hintText: '••••••••',
          controller: _viewModel.passwordController,
          obscureText: _viewModel.obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _viewModel.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.wellnessGray,
              size: 20.0,
            ),
            onPressed: _viewModel.togglePasswordVisibility,
          ),
        ),
        AppSpacing.h8,

        // Forgot password link (Figma color selection #F08AAE)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _viewModel.setAuthState(AuthState.resetPassword),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot password?',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.wellnessPinkCategory,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        AppSpacing.h24,

        // Sign In Button
        _buildPrimaryButton(
          text: 'Sign in',
          onPressed: () async {
            final success = await _viewModel.handleSignIn();
            if (success && mounted) {
              final nextRoute = await _viewModel.getNextRoute();
              NavigationService.pushNamedAndRemoveUntil(nextRoute);
            }
          },
        ),
        AppSpacing.h24,

        // Footer: New to Syd Flows? Create account
        _buildFooter(
          normalText: 'New to SYD FLOWS?',
          actionText: 'Create account',
          onTap: () => _viewModel.setAuthState(AuthState.signUp),
        ),
      ],
    );
  }

  // --- SIGN UP VIEW ---
  Widget _buildSignUpView() {
    return Column(
      key: const ValueKey('SignUpView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Subtitle
        Text(
          'Create your account',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.wellnessBrown,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        AppSpacing.h8,
        Text(
          'Start your cycle-aware journey.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.wellnessGray,
          ),
        ),
        AppSpacing.h24,

        // Google Sign In
        _buildGoogleButton(),
        AppSpacing.h16,

        // Divider
        _buildDivider(),
        AppSpacing.h16,

        // Full name field
        AuthTextField(
          label: 'Full name',
          hintText: 'Ava Hart',
          controller: _viewModel.nameController,
          keyboardType: TextInputType.name,
        ),
        AppSpacing.h16,

        // Email field
        AuthTextField(
          label: 'Email',
          hintText: 'you@sydflows.app',
          controller: _viewModel.emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.h16,

        // Password field
        AuthTextField(
          label: 'Password',
          hintText: '••••••••',
          controller: _viewModel.passwordController,
          obscureText: _viewModel.obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _viewModel.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.wellnessGray,
              size: 20.0,
            ),
            onPressed: _viewModel.togglePasswordVisibility,
          ),
        ),
        AppSpacing.h24,

        // Create Account Button
        _buildPrimaryButton(
          text: 'Create account',
          onPressed: () async {
            final success = await _viewModel.handleSignUp();
            if (success && mounted) {
              final nextRoute = await _viewModel.getNextRoute();
              NavigationService.pushNamedAndRemoveUntil(nextRoute);
            }
          },
        ),
        AppSpacing.h24,

        // Footer: Already have an account? Sign in
        _buildFooter(
          normalText: 'Already have an account? ',
          actionText: 'Sign in',
          onTap: () => _viewModel.setAuthState(AuthState.signIn),
        ),
      ],
    );
  }

  // --- RESET PASSWORD VIEW ---
  Widget _buildResetPasswordView() {
    return Column(
      key: const ValueKey('ResetPasswordView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title & Subtitle
        Text(
          'Reset password',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.wellnessBrown,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        AppSpacing.h8,
        Text(
          "We'll send you a recovery link.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.wellnessGray,
          ),
        ),
        AppSpacing.h32,

        // Email field
        AuthTextField(
          label: 'Email',
          hintText: 'you@sydflows.app',
          controller: _viewModel.emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        AppSpacing.h32,

        // Send Recovery Link Button
        _buildPrimaryButton(
          text: 'Send recovery link',
          onPressed: () async {
            final success = await _viewModel.handleResetPassword();
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recovery link sent to your email!'),
                  backgroundColor: AppColors.wellnessBrown,
                ),
              );
              _viewModel.setAuthState(AuthState.signIn);
            }
          },
        ),
        AppSpacing.h24,

        // Footer: Already have an account? Sign in
        _buildFooter(
          normalText: 'Already have an account? ',
          actionText: 'Sign in',
          onTap: () => _viewModel.setAuthState(AuthState.signIn),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENTS ---

  // Google Sign In Button
  Widget _buildGoogleButton() {
    final isAnyLoading = _viewModel.isLoading || _viewModel.isGoogleLoading;
    return SizedBox(
      height: 48.0,
      child: ElevatedButton(
        onPressed: isAnyLoading
            ? null
            : () async {
                final success = await _viewModel.handleGoogleSignIn();
                if (success && mounted) {
                  final nextRoute = await _viewModel.getNextRoute();
                  NavigationService.pushNamedAndRemoveUntil(nextRoute);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.wellnessBrown,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.r16,
            side: BorderSide(color: AppColors.wellnessBeige, width: 1.0),
          ),
        ),
        child: _viewModel.isGoogleLoading
            ? const SizedBox(
                height: 20.0,
                width: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.wellnessBrown,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.googleLogo, width: 18.0, height: 18.0),
                  AppSpacing.w8,
                  const Text(
                    'Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // "or with email" Divider
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.wellnessBeige.withValues(alpha: 0.4),
            thickness: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'or with email',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.wellnessGray.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.wellnessBeige.withValues(alpha: 0.4),
            thickness: 1.0,
          ),
        ),
      ],
    );
  }

  // Glowing Primary Action Button
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    final isAnyLoading = _viewModel.isLoading || _viewModel.isGoogleLoading;
    return Container(
      height: 48.0,
      decoration: BoxDecoration(
        borderRadius: AppRadius.r16,
        boxShadow: [
          // Soft premium glow matching the button's theme
          BoxShadow(
            color: AppColors.wellnessBrown.withValues(alpha: 0.25),
            blurRadius: 20.0,
            spreadRadius: 1.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isAnyLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.wellnessBrown,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.r16),
        ),
        child: _viewModel.isLoading
            ? const SizedBox(
                height: 20.0,
                width: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                text,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
      ),
    );
  }

  // Form Footer link
  Widget _buildFooter({
    required String normalText,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _viewModel.isLoading ? null : onTap,
      child: Center(
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(
              fontFamily: AppAssets.primaryFont,
              color: AppColors.wellnessGray,
            ),
            children: [
              TextSpan(text: normalText),
              TextSpan(
                text: actionText,
                style: const TextStyle(
                  color: AppColors.wellnessBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
