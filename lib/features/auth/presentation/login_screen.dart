import 'package:cursor_hack/features/auth/controllers/auth_provider.dart';
import 'package:cursor_hack/global-widgets/box.dart';
import 'package:cursor_hack/global-widgets/custom_button.dart';
import 'package:cursor_hack/global-widgets/custom_icon_button.dart';
import 'package:cursor_hack/global-widgets/custom_textfield.dart';
import 'package:cursor_hack/utils/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Consumer<AuthProvider>(
          builder: (context, prov, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                boxh50,
                CustomIconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.titleText,
                    size: 20,
                  ),
                  onPressed: () => context.pop(),
                ),
                boxh50,
                const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleText,
                  ),
                ),
                boxh30,
                CustomTextField(
                  hintText: 'Email',
                  editingController: _emailController,
                  textInputType: TextInputType.emailAddress,
                ),
                boxh10,
                CustomTextField(
                  hintText: 'Password',
                  editingController: _passwordController,
                  obscureText: prov.isPasswordVisible,
                  maxLines: 1,
                  textInputType: TextInputType.visiblePassword,
                  suffixIcon: GestureDetector(
                    onTap: () => prov.togglePassword(),
                    child: Icon(
                      (prov.isPasswordVisible)
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20.w,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                boxh30,
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    isLoading: prov.isLoading,
                    buttonText: 'Login',
                    radius: 10.r,
                    function: () => prov.login(
                      context,
                      email: _emailController.text,
                      password: _passwordController.text,
                    ),
                    buttonTextStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                boxh50,

                _GoogleSignInButton(
                  isLoading: prov.isGoogleLoading,
                  onPressed: () => prov.signInWithGoogle(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        elevation: 0.6,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFF4285F4).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF4285F4).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey<String>('loader'),
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4285F4),
                        ),
                      ),
                    )
                  : Row(
                      key: const ValueKey<String>('content'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 22,
                          width: 22,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Color(0xFF4285F4),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3C4043),
                            letterSpacing: 0.15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
