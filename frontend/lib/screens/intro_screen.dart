import 'package:chat_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  bool onLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Main PageView content
            PageView(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  onLastPage = (index == 2);
                });
              },
              children: [
                _buildPage(
                  svgAsset: 'assets/images/welcome.svg',
                  title: 'WELCOME TO ENGINUITY!',
                  description:
                      'This app is designed for clients of EJSS Construction to help you stay updated on your project.',
                ),
                _buildPage(
                  svgAsset: 'assets/images/track.svg',
                  title: 'TRACK PROJECTS',
                  description:
                      "Keep an eye on your project's progress. Track activities, progress, and important updates, all in one place.",
                ),
                _buildPage(
                  svgAsset: 'assets/images/account.svg',
                  title: 'ACCOUNT LOG IN',
                  description:
                      'To log in, use the credentials sent to your email from EJSS Construction. You can change your password anytime in the app settings after you log in.',
                ),
              ],
            ),

            // Skip button (top right)
            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: _navigateToLogin,
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(65, 42, 213, 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Bottom section with indicators and Get Started button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicator
                    SmoothPageIndicator(
                      controller: _controller,
                      count: 3,
                      effect: const WormEffect(
                        dotHeight: 10,
                        dotWidth: 10,
                        activeDotColor: Color.fromRGBO(65, 42, 213, 1),
                        dotColor: Color.fromRGBO(65, 42, 213, 0.2),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Get Started button (only shows on last page)
                    AnimatedOpacity(
                      opacity: onLastPage ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: onLastPage ? 56 : 0,
                        child: onLastPage
                            ? SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _navigateToLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromRGBO(65, 42, 213, 1),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String svgAsset,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          
          // SVG illustration
          SvgPicture.asset(
            svgAsset,
            height: 280,
          ),
          
          const SizedBox(height: 60),
          
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}