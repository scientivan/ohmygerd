import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';

class OnboardingController extends StatefulWidget {
  const OnboardingController({super.key});

  @override
  State<OnboardingController> createState() => _OnboardingControllerState();
}

class _OnboardingControllerState extends State<OnboardingController> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Rekomendasi Makanan",
      description:
          "Aplikasi ini membantu penderita GERD untuk bisa menentukkan makanan mana yang aman, tempat menjualnya, dan cara membuatnya",
      assetImage: 'assets/images/onboarding_mockup_1.png',
    ),
    OnboardingPageData(
      title: "Scan Makanan",
      description:
          "Aplikasi ini membantu penderita GERD untuk bisa menentukkan mana komponen makanan yang discan yang dapat menyebabkan GERD",
      assetImage: 'assets/images/onboarding_mockup_2.png',
    ),
    OnboardingPageData(
      title: "Notifikasi",
      description:
          "Aplikasi ini membantu penderita GERD untuk bisa  mengingatkan jika lupa mencatat asupan air serta makan tepat waktu",
      assetImage: 'assets/images/onboarding_mockup_3.png',
    ),
    OnboardingPageData(
      title: "ChatBot",
      description:
          "Aplikasi ini membantu penderita GERD untuk bisa berkonsultasi dengan cepat dan gratis mengenai GERD",
      assetImage: 'assets/images/onboarding_mockup_4.png',
    ),
    OnboardingPageData(
      title: "Streak & Record",
      description:
          "Aplikasi ini membantu penderita GERD untuk bisa menjaga streak mereka dengan makan tepat waktu dan minum air yang cukup",
      assetImage: 'assets/images/onboarding_mockup_5.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
      );
    } else {
      // On last page, navigate to registration
      context.push(AppRoutes.register);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      body: PageView.builder(
        physics: const ClampingScrollPhysics(),
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final page = _pages[index];
          return OnboardingPage(
            pageData: page,
            buttonText: "Daftar",
            activeIndex: index,
            onButtonPressed: () {
              context.go(AppRoutes.register);
            },
            isFirstPage: index == 0,
          );
        },
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final String assetImage;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.assetImage,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingPageData pageData;
  final VoidCallback onButtonPressed;
  final String buttonText;
  final int activeIndex;
  final bool isFirstPage;

  const OnboardingPage({
    super.key,
    required this.pageData,
    required this.onButtonPressed,
    required this.buttonText,
    required this.activeIndex,
    this.isFirstPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Image.asset(
            pageData.assetImage,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              children: [
                Text(
                  pageData.title,
                  style: AppFonts.bold(28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  pageData.description,
                  style: AppFonts.regular(14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (index) => Padding(
                            padding: EdgeInsets.only(
                              right: index < 4 ? 10.25 : 0,
                            ),
                            child: Container(
                              width: index == activeIndex ? 46 : 10,
                              height: index == activeIndex ? 11 : 10,
                              decoration: BoxDecoration(
                                color:
                                    index == activeIndex
                                        ? AppColors.secondary.shade200
                                        : AppColors.neutral.shade200,
                                border: Border.all(
                                  color: AppColors.neutral.shade900,
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onButtonPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary.shade200,
                          foregroundColor: AppColors.neutral.shade900,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppColors.neutral.shade900,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Text(buttonText, style: AppFonts.semiBold(14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
