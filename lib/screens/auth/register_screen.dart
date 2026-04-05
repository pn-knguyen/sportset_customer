import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  String? _fullNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  Future<void> _register() async {
    setState(() {
      _fullNameError = null;
      _phoneError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    bool hasError = false;
    if (fullName.isEmpty) {
      setState(() => _fullNameError = 'Vui lòng nhập họ và tên.');
      hasError = true;
    }
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Vui lòng nhập số điện thoại.');
      hasError = true;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập email.');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Vui lòng nhập mật khẩu.');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Mật khẩu phải có ít nhất 6 ký tự.');
      hasError = true;
    }
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Vui lòng nhập lại mật khẩu.');
      hasError = true;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = 'Mật khẩu nhập lại không khớp.');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(fullName);

      await FirebaseFirestore.instance
          .collection('customers')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await credential.user?.sendEmailVerification();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/email-verification');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          setState(() => _emailError = 'Email này đã được sử dụng.');
          break;
        case 'invalid-email':
          setState(() => _emailError = 'Email không hợp lệ.');
          break;
        case 'weak-password':
          setState(() => _passwordError = 'Mật khẩu quá yếu.');
          break;
        default:
          _showSnackBar('Đăng ký thất bại. Vui lòng thử lại.');
      }
    } catch (_) {
      _showSnackBar('Đã có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;

      final docRef = FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
          e.message ?? 'Đăng nhập Google thất bại. Vui lòng thử lại.');
    } catch (_) {
      _showSnackBar('Đăng nhập Google thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isFacebookLoading = true);
    try {
      final loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.cancelled) return;
      if (loginResult.status != LoginStatus.success) {
        _showSnackBar('Đăng nhập Facebook thất bại. Vui lòng thử lại.');
        return;
      }

      final accessToken = loginResult.accessToken!;
      final credential =
          FacebookAuthProvider.credential(accessToken.tokenString);

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;

      final docRef =
          FirebaseFirestore.instance.collection('customers').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final userData = await FacebookAuth.instance.getUserData(
          fields: 'name,email,picture.width(200)',
        );
        await docRef.set({
          'uid': user.uid,
          'fullName': userData['name'] ?? user.displayName ?? '',
          'email': userData['email'] ?? user.email ?? '',
          'phone': '',
          'photoUrl': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
          e.message ?? 'Đăng nhập Facebook thất bại. Vui lòng thử lại.');
    } catch (_) {
      _showSnackBar('Đăng nhập Facebook thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Stack(
        children: [
          // Background gradient effects
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
                            const SizedBox(height: 12),
                            _buildLogo(),
                            const SizedBox(height: 8),
                            _buildTitle(),
                            const SizedBox(height: 12),
                            _buildForm(),
                            const SizedBox(height: 12),
                            _buildDivider(),
                            const SizedBox(height: 12),
                            _buildSocialButtons(),
                            const Spacer(),
                            _buildLoginLink(),
                            const SizedBox(height: 16),
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
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
            ).createShader(bounds),
            child: const Icon(
              Icons.sports_soccer,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'SPORTSET',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Tạo tài khoản',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tham gia cộng đồng thể thao SPORTSET',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full name input
        _buildInputField(
          label: 'Họ và tên',
          hint: 'Nhập họ và tên của bạn',
          controller: _fullNameController,
          errorText: _fullNameError,
        ),
        const SizedBox(height: 10),
        // Phone input
        _buildInputField(
          label: 'Số điện thoại',
          hint: 'Nhập số điện thoại',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          errorText: _phoneError,
        ),
        const SizedBox(height: 10),
        // Email input
        _buildInputField(
          label: 'Email',
          hint: 'Nhập email của bạn',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          errorText: _emailError,
        ),
        const SizedBox(height: 10),
        // Password input
        _buildPasswordField(
          label: 'Mật khẩu',
          hint: 'Tạo mật khẩu',
          controller: _passwordController,
          isVisible: _isPasswordVisible,
          errorText: _passwordError,
          onToggle: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 10),
        // Confirm password input
        _buildPasswordField(
          label: 'Nhập lại mật khẩu',
          hint: 'Nhập lại mật khẩu',
          controller: _confirmPasswordController,
          isVisible: _isConfirmPasswordVisible,
          errorText: _confirmPasswordError,
          onToggle: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 16),
        // Register button
        Container(
          width: double.infinity,
          height: 48,
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
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Đăng ký',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
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
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFF44336)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
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
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Color(0xFFF44336),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
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
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFF44336)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF64748B),
                ),
                onPressed: onToggle,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Color(0xFFF44336),
                fontSize: 12,
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
            color: Colors.grey.shade200,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Hoặc đăng ký bằng',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        // Google button
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isGoogleLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: _isGoogleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFFF9800),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGoogleLogo(),
                        const SizedBox(width: 8),
                        const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Facebook button
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isFacebookLoading ? null : _signInWithFacebook,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: _isFacebookLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.facebook,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Facebook',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Đã có tài khoản?',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Đăng nhập ngay',
            style: TextStyle(
              color: Color(0xFFF44336),
              fontSize: 13,
              fontWeight: FontWeight.bold,
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
