import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/auth_controller.dart';
import '../../constants/app_colors.dart';

/// A pulsing circle loader for a unique loading indicator
class PulsingCircleLoader extends StatefulWidget {
  final double size;
  final Color color;
  const PulsingCircleLoader({
    this.size = 48,
    this.color = AppColors.primary,
    Key? key,
  }) : super(key: key);

  @override
  _PulsingCircleLoaderState createState() => _PulsingCircleLoaderState();
}

class _PulsingCircleLoaderState extends State<PulsingCircleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.75,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  SignUpScreen({Key? key}) : super(key: key);

  final AuthController authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Image
              SizedBox(
                height: screenHeight * 0.6,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  child: Image.asset(
                    'assets/common/welcome.png',
                    width: double.infinity,
                    height: screenHeight * 0.65,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Bottom content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Welcome texts
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Welcome to Hisabi',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Your smart companion for tracking expenses and managing money with ease.',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Sign-in Button or loader + Guest Login
                      Obx(() {
                        if (authController.isLoading.value) {
                          return const PulsingCircleLoader(size: 56);
                        }
                        return Column(
                          children: [
                            // Google Sign-In
                            GestureDetector(
                              onTap: authController.signInWithGoogle,
                              child: Container(
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.black12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/common/google.png',
                                      height: 24,
                                      width: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Guest Login Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                minimumSize: const Size(double.infinity, 54),
                              ),
                              onPressed: () {
                                authController.continueAsGuest();
                              },

                              child: const Text(
                                'Continue as Guest',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Footer
              Column(
                children: [
                  const SizedBox(height: 6),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: 'By signing in, you agree to our ',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      children: [
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' & '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hisabi © 2025',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                  ),
                ],
              ),
            ],
          ),

          // Block touches when loading
          Obx(() {
            if (authController.isLoading.value) {
              return const ModalBarrier(
                dismissible: false,
                color: Colors.black45,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
