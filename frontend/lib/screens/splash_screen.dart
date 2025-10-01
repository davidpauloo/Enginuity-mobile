import 'package:chat_app/screens/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Still using GetX for navigation
import 'package:flutter_svg/flutter_svg.dart'; // Import the flutter_svg package

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToIntro();
  }

  _navigateToIntro() async {
    await Future.delayed(const Duration(seconds: 5));
    Get.offAll(() => const IntroScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF412ad5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SvgPicture.asset(
                'assets/Enginuity.svg',
                height: 120,
              ),
            )
          ],
        ),
      ),
    );
  }
}
