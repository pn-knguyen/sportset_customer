import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
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
            // -- Background sport silhouettes --
            Positioned(
              top: size.height * 0.25,
              left: -64,
              child: _SportBlob(size: 192, icon: Icons.sports_soccer),
            ),
            Positioned(
              bottom: size.height * 0.33,
              left: -40,
              child: _SportBlob(size: 160, icon: Icons.sports_tennis),
            ),
            Positioned(
              top: size.height * 0.33,
              right: -48,
              child: _SportBlob(size: 224, icon: Icons.sports_baseball),
            ),
            Positioned(
              bottom: size.height * 0.25,
              right: -32,
              child: _SportBlob(size: 128, icon: Icons.fitness_center),
            ),

            // -- Main content --
            SafeArea(
              child: Column(
                children: [
                  // Logo section (flex:3, align bottom)
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Icon with double ring
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring
                              Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Inner ring
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50)
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              // Icon
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF4CAF50),
                                    Color(0xFF2E7D32)
                                  ],
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.sports_soccer,
                                  size: 96,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'SPORTSET',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0A1929),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Tagline + subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              color: Color(0xFF0A1929),
                            ),
                            children: [
                              TextSpan(text: 'Đặt sân dễ dàng\n'),
                              TextSpan(text: 'Nâng tầm đam mê'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kết nối cộng đồng thể thao, tìm sân nhanh chóng chỉ với một chạm.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Image grid + button (flex:4)
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 2-column masonry image grid
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column — top-aligned
                              Expanded(
                                child: _SportImageCard(
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400&h=300&fit=crop',
                                  fallbackIcon: Icons.sports_soccer,
                                  fallbackColor: const Color(0xFF4CAF50),
                                  height: 104,
                                  topOffset: 0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Right column — offset 24px down (masonry)
                              Expanded(
                                child: _SportImageCard(
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=400&h=300&fit=crop',
                                  fallbackIcon: Icons.sports_tennis,
                                  fallbackColor: const Color(0xFF2E7D32),
                                  height: 104,
                                  topOffset: 24,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // CTA button
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFF2E7D32),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _completeIntro,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Khám phá ngay',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
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
}

/// Faded sport icon blob — replaces remote images for background decorations
class _SportBlob extends StatelessWidget {
  const _SportBlob({required this.size, required this.icon});
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.05,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.6, color: Colors.black),
      ),
    );
  }
}

/// Sport image card with gradient overlay and fallback
class _SportImageCard extends StatelessWidget {
  const _SportImageCard({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.height,
    this.topOffset = 0,
  });
  final String imageUrl;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double height;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => ColoredBox(
                color: fallbackColor.withValues(alpha: 0.2),
                child: Icon(fallbackIcon,
                    size: height * 0.45, color: fallbackColor),
              ),
            ),
            // Gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return topOffset > 0
        ? Padding(
            padding: EdgeInsets.only(top: topOffset),
            child: card,
          )
        : card;
  }
}
