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
                  hintText: 'Username',
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
                      username: _emailController.text,
                      password: _passwordController.text,
                    ),
                    buttonTextStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                boxh50,

                // const _SocialButton(
                //   iconWidget: Icon(
                //     Icons.g_mobiledata_rounded,
                //     color: Color(0xFF4285F4),
                //     size: 28,
                //   ),
                //   label: 'Sign in with google',
                // ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.iconWidget, required this.label});

  final Widget iconWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: CustomIconButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        icon: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[iconWidget, boxw10],
        ),
        iconText: label,
        textStyle: const TextStyle(color: AppColors.titleText, fontSize: 19),
      ),
    );
  }
}
