import 'dart:async';
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
            backgroundColor: Color(0xFFBA1A1A),
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
        child: Stack(
          children: [
            // Top-right blob
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                ),
              ),
            ),
            // Bottom-left blob
            Positioned(
              bottom: MediaQuery.sizeOf(context).height * 0.25,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.05),
                ),
              ),
            ),
            // Success banner
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: _showSuccessBanner ? 0 : -100,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(
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
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  // Logo: icon above, SPORTSET below (column layout)
                  Column(
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
                      const SizedBox(height: 4),
                      const Text(
                        'SPORTSET',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.8,
                        ),
                      ),
                    ],
                  ),
                  // Remaining space: content vertically centered
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildEnvelopeIllustration(),
                          const SizedBox(height: 24),
                          // Title
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _resent ? 'Đã gửi lại thư!' : 'Đăng ký thành công!',
                              key: ValueKey(_resent),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Subtitle
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _resent
                                  ? 'Vui lòng kiểm tra hộp thư của bạn một lần nữa để kích hoạt tài khoản.'
                                  : 'Chúng tôi đã gửi một liên kết xác thực đến email của bạn. Vui lòng kiểm tra hộp thư (và cả hòm thư spam) để kích hoạt tài khoản trước khi bắt đầu.',
                              key: ValueKey(_resent),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                height: 1.65,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // Open email button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _openEmailApp,
                                icon: const Icon(Icons.open_in_new_rounded,
                                    color: Colors.white, size: 20),
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
                          ),
                          const SizedBox(height: 20),
                          // Resend
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
                                        color: Color(0xFF4CAF50),
                                      ),
                                    )
                                  : RichText(
                                      text: const TextSpan(
                                        text: 'Tôi chưa nhận được mail. ',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Gửi lại',
                                            style: TextStyle(
                                              color: Color(0xFF4CAF50),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvelopeIllustration() {
    // White card: 192×128, Green card: 160×96, overlaps 48px above white card
    return SizedBox(
      width: 280,
      height: 176,
      child: Stack(
        children: [
          // Green blur background
          Positioned(
            top: 24,
            left: 40,
            child: Container(
              width: 200,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
              ),
            ),
          ),
          // White envelope card
          Positioned(
            bottom: 0,
            left: 44,
            child: Container(
              width: 192,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8F5E9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(painter: _EnvelopeLinesPainter()),
              ),
            ),
          ),
          // Green rotated card (-6 degrees)
          Positioned(
            top: 0,
            left: 60,
            child: Transform.rotate(
              angle: -0.10472,
              child: Container(
                width: 160,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnvelopeLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8F5E9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // V-fold lines
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height * 0.5)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);

    // Side diagonal lines
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width * 0.4, size.height * 0.45), paint);
    canvas.drawLine(
        Offset(size.width, size.height), Offset(size.width * 0.6, size.height * 0.45), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

