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
  // controller to keep track of which page the user is on
  PageController _controller = PageController();

  // keep track if the user is on the last page
  bool onLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onLastPage = (index == 2);
              });
            },
            children: [
              // Page 1
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    SvgPicture.asset(
                      'assets/images/welcome.svg',
                      height: 300,
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'WELCOME TO ENGINUITY!',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This app is designed for clients of EJSS Construction to help you stay updated on your project.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Page 2
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    SvgPicture.asset(
                      'assets/images/track.svg',
                      height: 300,
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'TRACK PROJECTS',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Keep an eye on your project's progress. Track activities, progress, and important updates, all in one place.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Page 3
              Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    SvgPicture.asset(
                      'assets/images/account.svg',
                      height: 300,
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'ACCOUNT LOG IN',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'To log in, use the credentials sent to your email from EJSS Construction. You can change your password anytime in the app settings after you log in.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 60,
          right: 30,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginScreen();
                  },
                ),
              );
            },
            child: const Text('Skip'),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 80.0),
          alignment: Alignment(0, 0.75),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // page indicator
              SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: const WormEffect(
                  // Changed to WormEffect to prevent dot expansion
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: Color.fromRGBO(65, 42, 213, 1),
                ),
              ),

              const SizedBox(height: 20),

              // Back and Next/Done buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // go back to previous page
                    GestureDetector(
                      onTap: () {
                        _controller.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeIn,
                        );
                      },
                      child: const Text('Back'),
                    ),

                    // go to the next page
                    onLastPage
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return LoginScreen();
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25.0,
                                vertical: 10.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(65, 42, 213, 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 25.0,
                                vertical: 10.0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(65, 42, 213, 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
