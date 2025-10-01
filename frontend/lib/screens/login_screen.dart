// lib/screens/login_screen.dart
import 'package:chat_app/screens/home_screen.dart'; // Make sure this is the correct path to your HomeScreen
import 'package:chat_app/screens/register_screen.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG image

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _errorMessage;
  bool _isLoading = false;

  void _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      await _authService.login(email, password);

      Fluttertoast.showToast(
        msg: 'Logged in successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      Fluttertoast.showToast(
        msg: _errorMessage!,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print('Login Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the primary color (your button color) for consistency
    const Color primaryColor = Color.fromRGBO(65, 42, 213, 1);

    return Scaffold(
      backgroundColor: Colors.white,
      // Changed background to match button color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                SvgPicture.asset(
                  'assets/images/enginuity_logo.svg',
                  height: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Login to continue",
                  style: TextStyle(
                      color: Colors.black87), // Text color changed to white
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white
                        .withOpacity(0.9), // Keep input background white
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.black87),
                    floatingLabelStyle: const TextStyle(
                      color: Colors.black,
                    ), // White label text when focused
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: const BorderSide(
                        color:
                            primaryColor, // Changed focused border to white for better contrast
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Colors.black26, // Keep enabled border distinct
                      ),
                    ),
                    prefixIcon: const Icon(Icons.email,
                        color: primaryColor), // Icon color matching theme
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white
                          .withOpacity(0.9), // Keep input background white
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black87),
                      floatingLabelStyle: const TextStyle(
                          color: Colors.black), // White label text when focused
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color:
                              primaryColor, // Changed focused border to white for better contrast
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                          color: Colors.black26, // Keep enabled border distinct
                        ),
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: primaryColor, // Icon color matching theme
                      )),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 25),
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white), // Loader white on dark background
                      )
                    : SizedBox(
                        // NEW: Use SizedBox to control button width
                        width: double.infinity, // Make it take full width
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 88,
                                vertical:
                                    15), // Horizontal padding might be overridden by width: double.infinity
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0)),
                            backgroundColor:
                                primaryColor, // Button background is white
                            foregroundColor:
                                primaryColor, // Text/icon color on button is primary color
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (Context) => const RegisterScreen()));
                    },
                    child: const Text(
                      'Do not have an account? Register',
                      style: TextStyle(
                          color: Colors
                              .white), // Register text color changed to white
                    )),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
