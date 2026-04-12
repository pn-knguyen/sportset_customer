import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _countdown = 0;
  Timer? _timer;
  String? _errorMessage;
  late String _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = (ModalRoute.of(context)?.settings.arguments as String?) ?? '';
    if (_countdown == 0) _startCountdown();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  String get _enteredOtp =>
      _controllers.map((c) => c.text).join();

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_errorMessage != null) setState(() => _errorMessage = null);
    // Auto-verify when all 6 digits entered
    if (_enteredOtp.length == 6) _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    final enteredCode = _enteredOtp;
    if (enteredCode.length < 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đủ 6 chữ số');
      return;
    }
    setState(() { _isVerifying = true; _errorMessage = null; });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(_email)
          .get();
      if (!doc.exists) {
        setState(() => _errorMessage = 'Mã OTP không hợp lệ hoặc đã hết hạn');
        return;
      }
      final data = doc.data()!;
      final storedOtp = data['otp'] as String? ?? '';
      final expiresAt = data['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        setState(() => _errorMessage = 'Mã OTP đã hết hạn. Vui lòng gửi lại.');
        return;
      }
      if (enteredCode != storedOtp) {
        setState(() => _errorMessage = 'Mã OTP không chính xác');
        return;
      }
      // Mark as verified
      await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(_email)
          .update({'verified': true});
      if (!mounted) return;
      Navigator.pushNamed(context, '/reset-password', arguments: {'email': _email});
    } catch (_) {
      setState(() => _errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      await FirebaseFirestore.instance
          .collection('password_reset_otps')
          .doc(_email)
          .set({
        'otp': otp,
        'email': _email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 10))),
        'verified': false,
      });
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://sportset-d345c.firebaseapp.com',
          handleCodeInApp: true,
          androidPackageName: 'com.example.sportset_customer',
          androidMinimumVersion: '21',
        ),
      );
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP mới đã được gửi đến email của bạn'),
          backgroundColor: Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi lại. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
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
                          children: [
                            _buildLogo(),
                            const SizedBox(height: 32),
                            _buildTitle(),
                            const SizedBox(height: 40),
                            _buildOtpInputs(),
                            const SizedBox(height: 12),
                            // Error message
                            if (_errorMessage != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFF44336),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            _buildConfirmButton(),
                            const SizedBox(height: 32),
                            _buildResendSection(),
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
    return Column(
      children: [
        const Text(
          'Nhập Mã OTP',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Mã xác thực đã được gửi đến\n'),
                TextSpan(
                  text: _email,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: EdgeInsets.symmetric(horizontal: index == 0 || index == 5 ? 0 : 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _errorMessage != null
                  ? const Color(0xFFF44336)
                  : _controllers[index].text.isNotEmpty
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE2E8F0),
              width: 2,
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
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {});
              _onChanged(value, index);
            },
            onTap: () {
              if (_controllers[index].text.isNotEmpty) {
                _controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[index].text.length,
                );
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
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
        onPressed: _isVerifying ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Xác nhận',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        const Text(
          'Bạn không nhận được mã?',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (_countdown > 0)
          Text(
            'Gửi lại sau ${_countdown}s',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
            ),
          )
        else
          GestureDetector(
            onTap: _isResending ? null : _resendOtp,
            child: _isResending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : const Text(
                    'Gửi lại mã',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
      ],
    );
  }
}
