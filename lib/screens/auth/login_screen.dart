import 'dart:ui';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF9800).withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF44336).withOpacity(0.05),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // Logo section
                            _buildLogo(),
                            const SizedBox(height: 8),
                            // Title section
                            _buildTitle(),
                            const SizedBox(height: 20),
                            // Form section
                            _buildForm(),
                            const SizedBox(height: 12),
                            // Divider
                            _buildDivider(),
                            const SizedBox(height: 12),
                            // Social buttons
                            _buildSocialButtons(),
                            const Spacer(),
                            // Sign up link
                            _buildSignUpLink(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
            ).createShader(bounds),
            child: const Icon(
              Icons.sports_soccer,
              size: 70,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'SPORTSET',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Đăng nhập',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email/Phone input
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            'Email hoặc Số điện thoại',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Nhập email hoặc số điện thoại',
              hintStyle: TextStyle(color: Color(0xFFA0A0A0)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Password input
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            'Mật khẩu',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
            ),
          ),
        ),
        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  color: Color(0xFFF44336),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        // Login button
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF44336).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // Navigate to main screen after login
              Navigator.pushReplacementNamed(context, '/main');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Đăng nhập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Hoặc',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        // Google button
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Handle Google login
              },
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    'Tiếp tục với Google',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Facebook button
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1877F2).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Handle Facebook login
              },
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.facebook,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tiếp tục với Facebook',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleLogo() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản?',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/register');
          },
          child: const Text(
            'Đăng ký ngay',
            style: TextStyle(
              color: Color(0xFFF44336),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Scale factor to fit the logo
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    // Blue path (top right)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path();
    bluePath.moveTo(22.56 * scaleX, 12.25 * scaleY);
    bluePath.cubicTo(
      22.56 * scaleX, 11.47 * scaleY,
      22.49 * scaleX, 10.72 * scaleY,
      22.36 * scaleX, 10.0 * scaleY,
    );
    bluePath.lineTo(12 * scaleX, 10.0 * scaleY);
    bluePath.lineTo(12 * scaleX, 14.26 * scaleY);
    bluePath.lineTo(17.92 * scaleX, 14.26 * scaleY);
    bluePath.cubicTo(
      17.66 * scaleX, 15.63 * scaleY,
      16.88 * scaleX, 16.79 * scaleY,
      15.71 * scaleX, 17.57 * scaleY,
    );
    bluePath.lineTo(15.71 * scaleX, 20.34 * scaleY);
    bluePath.lineTo(19.28 * scaleX, 20.34 * scaleY);
    bluePath.cubicTo(
      21.36 * scaleX, 18.42 * scaleY,
      22.56 * scaleX, 15.6 * scaleY,
      22.56 * scaleX, 12.25 * scaleY,
    );
    bluePath.close();
    canvas.drawPath(bluePath, paint);

    // Green path (bottom right)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path();
    greenPath.moveTo(12 * scaleX, 23 * scaleY);
    greenPath.cubicTo(
      14.97 * scaleX, 23 * scaleY,
      17.46 * scaleX, 22.02 * scaleY,
      19.28 * scaleX, 20.34 * scaleY,
    );
    greenPath.lineTo(15.71 * scaleX, 17.57 * scaleY);
    greenPath.cubicTo(
      14.73 * scaleX, 18.23 * scaleY,
      13.48 * scaleX, 18.63 * scaleY,
      12 * scaleX, 18.63 * scaleY,
    );
    greenPath.cubicTo(
      9.14 * scaleX, 18.63 * scaleY,
      6.71 * scaleX, 16.7 * scaleY,
      5.84 * scaleX, 14.1 * scaleY,
    );
    greenPath.lineTo(2.18 * scaleX, 14.1 * scaleY);
    greenPath.lineTo(2.18 * scaleX, 16.94 * scaleY);
    greenPath.cubicTo(
      3.99 * scaleX, 20.53 * scaleY,
      7.7 * scaleX, 23 * scaleY,
      12 * scaleX, 23 * scaleY,
    );
    greenPath.close();
    canvas.drawPath(greenPath, paint);

    // Yellow path (bottom left)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path();
    yellowPath.moveTo(5.84 * scaleX, 14.09 * scaleY);
    yellowPath.cubicTo(
      5.62 * scaleX, 13.43 * scaleY,
      5.49 * scaleX, 12.73 * scaleY,
      5.49 * scaleX, 12 * scaleY,
    );
    yellowPath.cubicTo(
      5.49 * scaleX, 11.27 * scaleY,
      5.62 * scaleX, 10.57 * scaleY,
      5.84 * scaleX, 9.91 * scaleY,
    );
    yellowPath.lineTo(5.84 * scaleX, 7.07 * scaleY);
    yellowPath.lineTo(2.18 * scaleX, 7.07 * scaleY);
    yellowPath.cubicTo(
      1.43 * scaleX, 8.55 * scaleY,
      1 * scaleX, 10.22 * scaleY,
      1 * scaleX, 12 * scaleY,
    );
    yellowPath.cubicTo(
      1 * scaleX, 13.78 * scaleY,
      1.43 * scaleX, 15.45 * scaleY,
      2.18 * scaleX, 16.93 * scaleY,
    );
    yellowPath.lineTo(5.03 * scaleX, 14.71 * scaleY);
    yellowPath.lineTo(5.84 * scaleX, 14.09 * scaleY);
    yellowPath.close();
    canvas.drawPath(yellowPath, paint);

    // Red path (top left)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path();
    redPath.moveTo(12 * scaleX, 5.38 * scaleY);
    redPath.cubicTo(
      13.62 * scaleX, 5.38 * scaleY,
      15.06 * scaleX, 5.94 * scaleY,
      16.21 * scaleX, 7.04 * scaleY,
    );
    redPath.lineTo(19.36 * scaleX, 3.89 * scaleY);
    redPath.cubicTo(
      17.45 * scaleX, 2.09 * scaleY,
      14.97 * scaleX, 1 * scaleY,
      12 * scaleX, 1 * scaleY,
    );
    redPath.cubicTo(
      7.7 * scaleX, 1 * scaleY,
      3.99 * scaleX, 3.47 * scaleY,
      2.18 * scaleX, 7.07 * scaleY,
    );
    redPath.lineTo(5.84 * scaleX, 9.91 * scaleY);
    redPath.cubicTo(
      6.71 * scaleX, 7.31 * scaleY,
      9.14 * scaleX, 5.38 * scaleY,
      12 * scaleX, 5.38 * scaleY,
    );
    redPath.close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
