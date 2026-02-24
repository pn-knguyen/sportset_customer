import 'dart:ui';
import 'package:flutter/material.dart';

class VoucherSelectionScreen extends StatefulWidget {
  const VoucherSelectionScreen({super.key});

  @override
  State<VoucherSelectionScreen> createState() => _VoucherSelectionScreenState();
}

class _VoucherSelectionScreenState extends State<VoucherSelectionScreen> {
  final TextEditingController _voucherCodeController = TextEditingController();
  int _selectedFilterIndex = 0;
  String? _selectedVoucherId;

  final List<String> _filters = ['Tất cả', 'Sân bóng', 'Mới nhất'];

  final List<Map<String, dynamic>> _vouchers = [
    {
      'id': '1',
      'code': 'SPORTSET',
      'title': 'Giảm 50K',
      'expiryDate': '31/12/2023',
      'description': 'Áp dụng cho mọi loại sân',
      'isHighlighted': true,
    },
    {
      'id': '2',
      'code': 'DISCOUNT',
      'title': 'Giảm 10%',
      'expiryDate': '25/11/2023',
      'description': 'Đơn tối thiểu 300K',
      'isHighlighted': false,
    },
    {
      'id': '3',
      'code': 'WEEKEND',
      'title': 'Giảm 20K',
      'expiryDate': '20/11/2023',
      'description': 'Áp dụng cuối tuần',
      'isHighlighted': false,
    },
    {
      'id': '4',
      'code': 'NEWUSER',
      'title': 'Giảm 30K',
      'expiryDate': '15/12/2023',
      'description': 'Dành cho khách hàng mới',
      'isHighlighted': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedVoucherId = _vouchers[0]['id'];
  }

  @override
  void dispose() {
    _voucherCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 120,
                  ),
                  child: Column(
                    children: [
                      _buildVoucherCodeInput(),
                      const SizedBox(height: 24),
                      _buildFilterTabs(),
                      const SizedBox(height: 24),
                      _buildVoucherList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 48,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F6).withValues(alpha: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF1c170d),
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Chọn Voucher',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1c170d),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherCodeInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _voucherCodeController,
              decoration: const InputDecoration(
                hintText: 'Nhập mã giảm giá...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Áp dụng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF9800) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                        width: 1,
                      ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVoucherList() {
    return Column(
      children: _vouchers.map((voucher) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildVoucherCard(voucher),
        );
      }).toList(),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final isSelected = voucher['id'] == _selectedVoucherId;
    final isHighlighted = voucher['isHighlighted'] as bool;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVoucherId = voucher['id'];
        });
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9800)
                : const Color(0xFFFF9800).withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFF9800).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                Row(
                  children: [
                    // Left side with icon and code
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? const Color(0xFFFF9800).withValues(alpha: 0.1)
                            : Colors.grey[50],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            color: isHighlighted
                                ? const Color(0xFFFF9800)
                                : Colors.grey[400],
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            voucher['code'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isHighlighted
                                  ? const Color(0xFFFF9800)
                                  : Colors.grey[400],
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dashed line separator
                    Container(
                      width: 1,
                      child: CustomPaint(painter: DashedLinePainter()),
                    ),
                    // Right side with details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              voucher['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1c170d),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hạn dùng: ${voucher['expiryDate']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              voucher['description'],
                              style: TextStyle(
                                fontSize: 10,
                                color: isHighlighted
                                    ? const Color(0xFFFF9800)
                                    : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Semi-circle cutouts at top and bottom
                Positioned(
                  left: 90,
                  top: -5,
                  child: Container(
                    width: 20,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F6),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 90,
                  bottom: -5,
                  child: Container(
                    width: 20,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                // Selected check icon
                if (isSelected)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
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

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 32,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F6),
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context, _selectedVoucherId);
              },
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Text(
                  'Xác nhận',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 10;

    while (startY < size.height - 10) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
