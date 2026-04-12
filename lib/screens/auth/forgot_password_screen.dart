import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập email');
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Email không hợp lệ');
      return;
    }
    setState(() { _isLoading = true; _emailError = null; });
    try {
      // Check email exists in customers collection
      final snap = await FirebaseFirestore.instance
          .collection('customers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        setState(() => _emailError = 'Email này chưa được đăng ký');
        return;
      }
      // Generate 6-digit OTP
      final otp = (100000 + Random().nextInt(900000)).toString();
      // Store OTP in Firestore with 10 min expiry
      await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(email)
          .set({
        'otp': otp,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 10))),
        'verified': false,
      });
      // Send Firebase password reset email (carries the reset link + oobCode)
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://sportset-d345c.firebaseapp.com',
          handleCodeInApp: true,
          androidPackageName: 'com.example.sportset_customer',
          androidMinimumVersion: '21',
        ),
      );
      if (!mounted) return;
      Navigator.pushNamed(context, '/otp-verification', arguments: email);
    } on FirebaseAuthException catch (e) {
      setState(() => _emailError = e.message ?? 'Đã có lỗi xảy ra');
    } catch (_) {
      setState(() => _emailError = 'Đã có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F5E9), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Back button (fixed, outside scroll)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(24),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            _buildLogo(),
                            const SizedBox(height: 32),
                            // Title
                            _buildTitle(),
                            const SizedBox(height: 40),
                            // Form
                            _buildForm(),
                            const SizedBox(height: 20),
                            if (_emailError != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  _emailError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFF44336),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Back to login
                            _buildBackToLogin(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ).createShader(bounds),
          child: const Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
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
          'Quên mật khẩu',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Nhập email hoặc số điện thoại để nhận mã xác thực',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
            fontWeight: FontWeight.normal,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // Email input
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _emailError != null
                  ? const Color(0xFFF44336)
                  : const Color(0xFFE2E8F0),
            ),
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
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            decoration: const InputDecoration(
              hintText: 'Địa chỉ email đã đăng ký',
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
        const SizedBox(height: 20),
        // Send button
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
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
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
                    'Gửi mã xác nhận',
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

  Widget _buildBackToLogin() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text(
        'Quay lại đăng nhập',
        style: TextStyle(
          color: Color(0xFF4CAF50),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
