import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/app_colors.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_page_1.dart';
import '../../widgets/onboarding_page_2.dart';
import '../../widgets/onboarding_page_3.dart';
import '../../widgets/onboarding_page_4.dart';
import '../../widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _numPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipOnboarding() {
    _pageController.animateToPage(
      _numPages - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onRegister() {
    context.go('/register');
  }

  void _onLogin() {
    context.go('/login');
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral0,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  OnboardingPage1(),
                  OnboardingPage2(),
                  OnboardingPage3(),
                  OnboardingPage4(
                    onRegister: _onRegister,
                    onLogin: _onLogin,
                    onBack: _previousPage,
                  ),
                ],
              ),
            ),
            if (_currentPage < _numPages - 1)
              _buildStandardBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          PageIndicator(
            currentPage: _currentPage,
            numPages: 3,
          ),
          const SizedBox(height: 48),
          OnboardingButton(
            isLastPage: _currentPage == 2,
            currentPage: _currentPage,
            onNext: _nextPage,
            onSkip: _skipOnboarding,
            onBack: _previousPage,
          ),
        ],
      ),
    );
  }
}