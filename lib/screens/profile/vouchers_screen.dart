import 'package:flutter/material.dart';
import 'dart:ui';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  int _selectedTab = 0;

  final List<Map<String, String>> _vouchers = [
    {
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAE0Ow8trodeaiZiA9j7OQ5yUoAmvfR-jrBo5jX5EEYLvoPqyHQxrzErYK3r3QBnqgHIT0F-hEx5haE_l1qGrNw2z5W6I8-VfcrFzObw2W3MEFf-T81uI-M9O-62BcNrZOwp8AC5xqwUAmNceyrPu7gGzZSEYypZIUfg0IK7MpFX3_vjHiy5LUXoaxxKC6LKseTIclCizBPOU_iT8UO4vzkRMG18OIjwDwRKtAhmCAWG7laR_cYyPNdGzjDu5itAVjCkPt3wehOrzjW',
      'discount': 'Giảm 30K',
      'title': 'Ưu đãi sân cỏ nhân tạo',
      'expiry': 'HSD: 31/12/2023',
    },
    {
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCRGNq3X36u1jymukYIZY8LiOgBkxHBSzXeLuCslQ-Zm-wGlzq5PClP0KWBlLtV8d4i6PUh6sORRMbRU_nHbrF0iYk_nKfaYzN-AhZSyLdQh779vVREZVbeJqRbB_kK_Eh3MZB7FxO31C_PKUErp--sYVkpsYLrQrHNjOyONewoukrTKd_R-4shPj9Piyhnc6wHAn7Tdaq0Ffc1c3R-uRnij-Esvmm-jRoJeItZXz2mCtY82RrsYVhuww5vBW6_7jhAcGBlB0YFW63V',
      'discount': 'Giảm 15%',
      'title': 'Voucher Pickleball Sáng Sớm',
      'expiry': 'HSD: 15/01/2024',
    },
    {
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBe52yQY7pEQqrVXKT98lDpRty68pw10Nwx026a83f5K-QWRvr7NQse7pOaiTP9GffENoDj6zLZqxEEi6KBFaFA3V4-O8EunKLPPIK_b-e4mP874zC2Kk_IOzoXYggG6OOJuz2fp-rHtFJ9U6whgh1zvO_IUXF6unMps1qb84dlhz3YfKF99gN-Vn4Pv0MH-Mmt8kYqT5zYCn3HAVOb02S6aKh7ZY-qPGY13WIXgnoM86aL3haeZG_K669OBqF2OIWtd4Lh8ZBoqUtl',
      'discount': 'Giảm 50K',
      'title': 'Quà tặng Thành Viên Bạc',
      'expiry': 'HSD: 20/01/2024',
    },
    {
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBr_ZUO8rh-9K3KMn4nRrsQ3nv_6HyYZKOAJNaxwbrGsMUkA97t2QPgvN8ttdyoOt4m273UMu1J5c-tDyoUUoXwLNI1Toji6QuHrquZVbt_K_rFFUqYAwLl9vLDzd-xC-ZLF4GWhUrEGg_XS3LiPiS3PXNr9H5bN33BaufT_iaI_sgtMInklRXZ83SVwD-YTZp4Kk3MiuXBjzMqo5RaZU_3uvIxwOhok91X2Q6q1n5p8x7BlojhW4yZmsXomDtZmsUd6wzzjYBoCtMk',
      'discount': 'Giảm 20%',
      'title': 'Combo Đặt Sân + Nước Uống',
      'expiry': 'HSD: 10/01/2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 128),
              itemCount: _vouchers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                return _buildVoucherCard(_vouchers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF9FAFB)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A237E)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              const Text(
                'Kho Voucher',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabItem('Tất cả', 0),
          _buildTabItem('Mới nhất', 1),
          _buildTabItem('Sắp hết hạn', 2),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? const Color(0xFFFF9800) : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFFFF9800) : Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, String> voucher) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Left side - Image (35%)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35 - 24,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        voucher['image']!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
              ),
              // Right side - Content (65%)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            voucher['discount']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF44336),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            voucher['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A237E),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            voucher['expiry']!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                child: Text(
                                  'Dùng ngay',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Dashed divider line
          Positioned(
            left: MediaQuery.of(context).size.width * 0.35 - 24,
            top: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(2, double.infinity),
              painter: DashedLinePainter(),
            ),
          ),
          // Top cutout circle
          Positioned(
            left: MediaQuery.of(context).size.width * 0.35 - 24 - 10,
            top: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8F6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Bottom cutout circle
          Positioned(
            left: MediaQuery.of(context).size.width * 0.35 - 24 - 10,
            bottom: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8F6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F1F1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
