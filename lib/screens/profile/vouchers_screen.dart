import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({super.key});

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  int _selectedTab = 0;

  DateTime? _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Stream<List<Map<String, dynamic>>> _voucherStream() {
    return FirebaseFirestore.instance
        .collection('vouchers')
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final docs = snap.docs
          .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
          .toList();
      switch (_selectedTab) {
        case 1:
          docs.sort((a, b) {
            final dtA = _toDateTime(a['createdAt']) ?? DateTime(2000);
            final dtB = _toDateTime(b['createdAt']) ?? DateTime(2000);
            return dtB.compareTo(dtA);
          });
        case 2:
          docs.removeWhere((v) {
            final end = _toDateTime(v['endDate']);
            return end != null && now.isAfter(end);
          });
          docs.sort((a, b) {
            final dtA = _toDateTime(a['endDate']) ?? DateTime(2100);
            final dtB = _toDateTime(b['endDate']) ?? DateTime(2100);
            return dtA.compareTo(dtB);
          });
        default:
          break;
      }
      return docs;
    });
  }

  String _formatEndDate(dynamic endDate) {
    final dt = _toDateTime(endDate);
    if (dt == null) return '';
    return 'HSD: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  bool _isExpired(dynamic endDate) {
    final dt = _toDateTime(endDate);
    if (dt == null) return false;
    return DateTime.now().isAfter(dt);
  }

  String _discountLabel(Map<String, dynamic> v) {
    final type = v['discountType']?.toString() ?? '';
    final value = v['discountValue'];
    if (type == 'percent') return 'Giảm $value%';
    if (type == 'fixed') {
      final amount = (value is num) ? value.toInt() : int.tryParse(value.toString()) ?? 0;
      if (amount >= 1000) return 'Giảm ${amount ~/ 1000}K';
      return 'Giảm ${amount}đ';
    }
    return v['code']?.toString() ?? 'Voucher';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              _buildAppBar(),
              _buildTabBar(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Kho Voucher',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Tất cả', 'Mới nhất', 'Sắp hết hạn'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final selected = _selectedTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
                        : [],
                  ),
                  child: Text(
                    tabs[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? const Color(0xFF2E7D32) : const Color(0xFF6F7A6B),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _voucherStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)));
        }
        if (snap.hasError) {
          return Center(child: Text('Lỗi: ${snap.error}', style: const TextStyle(color: Color(0xFFBA1A1A))));
        }
        final vouchers = snap.data ?? [];
        if (vouchers.isEmpty) return _buildEmpty();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          itemCount: vouchers.length,
          separatorBuilder: (_, e) => const SizedBox(height: 14),
          itemBuilder: (ctx, i) => _buildVoucherCard(vouchers[i]),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.card_giftcard_rounded, size: 40, color: Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 16),
          const Text('Không có voucher nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C))),
          const SizedBox(height: 6),
          const Text('Hãy quay lại sau để nhận ưu đãi mới', style: TextStyle(fontSize: 13, color: Color(0xFF6F7A6B))),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final imageUrl = voucher['imageUrl']?.toString() ?? '';
    final title = voucher['title']?.toString() ?? voucher['name']?.toString() ?? '';
    final expiredStr = _formatEndDate(voucher['endDate']);
    final expired = _isExpired(voucher['endDate']);
    final discount = _discountLabel(voucher);

    return Opacity(
      opacity: expired ? 0.55 : 1.0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F3F3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: Stack(fit: StackFit.expand, children: [
                      imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, e, s) => _imageFallback())
                          : _imageFallback(),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x33000000)],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C), height: 1.3)),
                            if (expiredStr.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(expiredStr,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                                      color: expired ? const Color(0xFFBA1A1A) : const Color(0xFF6F7A6B))),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(discount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                            if (!expired)
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/voucher-selection'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                                  ),
                                  child: const Text('Dùng ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(20)),
                                child: const Text('Hết hạn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E))),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 120, top: 0, bottom: 0,
              child: CustomPaint(size: const Size(1, double.infinity), painter: _DashedLinePainter()),
            ),
            Positioned(left: 111, top: -10, child: _cutout()),
            Positioned(left: 111, bottom: -10, child: _cutout()),
          ],
        ),
      ),
    );
  }

  Widget _cutout() => Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9), shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF3F3F3)),
        ),
      );

  Widget _imageFallback() => Container(
        color: const Color(0xFFE8F5E9),
        child: const Center(child: Icon(Icons.card_giftcard_rounded, size: 36, color: Color(0xFF4CAF50))),
      );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBECAB9)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dashH = 5.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashH), paint);
      y += dashH + gap;
    }
  }

  @override
  bool shouldRepaint(CustomPainter _) => false;
}
