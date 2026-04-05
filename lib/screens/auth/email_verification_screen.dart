import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _resent = false;
  bool _isSending = false;
  bool _showSuccessBanner = false;
  int _countdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkEmailVerified();
    }
  }

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/email-verified');
    }
  }

  Future<void> _resendEmail() async {
    if (_countdown > 0 || _isSending) return;
    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      _startCountdown();
      setState(() {
        _resent = true;
        _showSuccessBanner = true;
        _isSending = false;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showSuccessBanner = false);
      });
    } catch (_) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi lại thất bại. Vui lòng thử lại.'),
            backgroundColor: Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startCountdown() {
    _countdown = 59;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _openEmailApp() async {
    final uri = Uri.parse('mailto:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Stack(
        children: [
          // Background decoration
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
            bottom: 80,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF44336).withOpacity(0.04),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(),
              ),
            ),
          ),
          // Success banner (animated)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: _showSuccessBanner ? 0 : -100,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Đã gửi lại email xác thực thành công!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 72),
                  _buildEnvelopeIcon(),
                  const SizedBox(height: 36),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _resent ? 'Đã gửi lại thư!' : 'Đăng ký thành công!',
                      key: ValueKey(_resent),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _resent
                          ? 'Vui lòng kiểm tra hộp thư của bạn một lần nữa để kích hoạt tài khoản.'
                          : 'Chúng tôi đã gửi một liên kết xác thực đến email của bạn. Vui lòng kiểm tra hộp thư (và cả hộp thư spam) để kích hoạt tài khoản trước khi bắt đầu.',
                      key: ValueKey(_resent),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Open email button
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
                    child: ElevatedButton.icon(
                      onPressed: _openEmailApp,
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Mở ứng dụng Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Resend / countdown
                  if (_countdown > 0)
                    Text(
                      'Gửi lại sau ${_countdown}s',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _isSending ? null : _resendEmail,
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF44336),
                              ),
                            )
                          : RichText(
                              text: const TextSpan(
                                text: 'Tôi chưa nhận được mail. ',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Gửi lại',
                                    style: TextStyle(
                                      color: Color(0xFFF44336),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvelopeIcon() {
    return SizedBox(
      width: 130,
      height: 115,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // White card (paper) underneath
          Positioned(
            bottom: 0,
            child: Container(
              width: 96,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          // Orange gradient envelope card
          Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.mail_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}
