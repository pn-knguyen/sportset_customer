import 'dart:ui';
import 'package:flutter/material.dart';

class EmailVerifiedScreen extends StatelessWidget {
  const EmailVerifiedScreen({super.key});

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
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Check icon
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9800).withOpacity(0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'Xác thực thành công!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text:
                          'Email của bạn đã được xác thực. Hãy bắt đầu hành trình chinh phục sân cỏ cùng ',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        height: 1.65,
                      ),
                      children: [
                        TextSpan(
                          text: 'SPORTSET',
                          style: TextStyle(
                            color: Color(0xFFFF9800),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' ngay bây giờ.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 44),
                  // Go to main button
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
                        'Vào Trang Chủ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Phiên bản 2.4.0 • Chào mừng bạn trở lại',
                    style: TextStyle(
                      color: Color(0xFFB0BEC5),
                      fontSize: 12,
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
}
