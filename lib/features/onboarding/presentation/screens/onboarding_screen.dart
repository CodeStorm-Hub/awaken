import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-run onboarding: permissions pitch + squat demo + first alarm CTA.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const prefsKey = 'awaken_onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _pages = [
    (
      title: 'WAKE UP TAX',
      body:
          'Your alarm will not stop until you complete real squats — verified on-device by the camera. No math. No shake.',
      icon: Icons.fitness_center_rounded,
    ),
    (
      title: 'CAMERA + ALARMS',
      body:
          'Allow camera for squat verification and exact alarms so the wake-up rings on time — even from a locked screen.',
      icon: Icons.videocam_rounded,
    ),
    (
      title: 'CLAIM TERRITORY',
      body:
          'Run closed loops on the map to capture land, defend it, and climb the leaderboard.',
      icon: Icons.map_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingScreen.markComplete();
    if (!mounted) return;
    context.go(AppRoutes.alarmSetup);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH,
            vertical: AppConstants.screenPaddingV,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('SKIP'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(page.icon, size: 72, color: AppColors.primary)
                              .animate(key: ValueKey('icon_$i'))
                              .scale(duration: 450.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 32),
                          Text('AWAKEN', style: tt.eyebrow),
                          const SizedBox(height: 12),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontFamily: 'SpaceGrotesk',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.mutedForeground,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ).animate(key: ValueKey('page_$i')).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? AppColors.primary
                          : AppColors.mutedForeground.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _pageController.nextPage(
                        duration: AppConstants.mediumAnim,
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? 'SET FIRST ALARM' : 'NEXT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
