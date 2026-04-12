import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool hasError = false;
    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập email.');
      hasError = true;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Vui lòng nhập mật khẩu.');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (credential.user?.emailVerified != true) {
        await FirebaseAuth.instance.signOut();
        setState(() => _emailError =
            'Email chưa được xác thực. Vui lòng kiểm tra hộp thư và xác thực tài khoản.');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          setState(() => _emailError = 'Email hoặc mật khẩu không đúng.');
          break;
        case 'wrong-password':
          setState(() => _passwordError = 'Mật khẩu không đúng.');
          break;
        case 'invalid-email':
          setState(() => _emailError = 'Email không hợp lệ.');
          break;
        case 'user-disabled':
          setState(() => _emailError = 'Tài khoản này đã bị khóa.');
          break;
        default:
          setState(() => _emailError = 'Đăng nhập thất bại. Vui lòng thử lại.');
      }
    } catch (_) {
      setState(() => _emailError = 'Đã có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // force account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;

      // Create Firestore document if first time (new user).
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

  Future<void> _loginWithFacebook() async {
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildLogo(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTitle(),
                      _buildForm(),
                      Column(
                        children: [
                          _buildDivider(),
                          const SizedBox(height: 16),
                          _buildSocialButtons(),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildSignUpLink(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
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
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Đăng nhập để đặt sân ngay',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
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
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _emailError != null
                  ? const Color(0xFFF44336)
                  : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Nhập email hoặc số điện thoại',
              hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
            ),
          ),
        ),
        if (_emailError != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              _emailError!,
              style: const TextStyle(
                color: Color(0xFFF44336),
                fontSize: 12,
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
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _passwordError != null
                  ? const Color(0xFFF44336)
                  : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
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
              fontSize: 16,
            ),
          ),
        ),
        if (_passwordError != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              _passwordError!,
              style: const TextStyle(
                color: Color(0xFFF44336),
                fontSize: 12,
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
                  color: Color(0xFF4CAF50),
                  fontSize: 14,
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
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF4CAF50).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
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
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isGoogleLoading ? null : _loginWithGoogle,
              borderRadius: BorderRadius.circular(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isGoogleLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF4CAF50),
                      ),
                    )
                  else ...[
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
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Facebook button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1877F2).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isFacebookLoading ? null : _loginWithFacebook,
              borderRadius: BorderRadius.circular(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isFacebookLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    const Icon(Icons.facebook, color: Colors.white, size: 24),
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
              color: Color(0xFF4CAF50),
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
