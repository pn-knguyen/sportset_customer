import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VoucherSelectionScreen extends StatefulWidget {
  const VoucherSelectionScreen({super.key});

  @override
  State<VoucherSelectionScreen> createState() => _VoucherSelectionScreenState();
}

class _VoucherSelectionScreenState extends State<VoucherSelectionScreen> {
  final TextEditingController _voucherCodeController = TextEditingController();
  bool _didInitArgs = false;
  int _selectedFilterIndex = 0;
  String? _selectedVoucherId;
  String? _facilityId;
  int _orderValue = 0;
  Set<String> _usedVoucherIds = {};

  final List<String> _filters = const ['Có thể dùng', 'Sắp hết hạn', 'Tất cả'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitArgs) {
      return;
    }
    _didInitArgs = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      return;
    }

    _facilityId = args['facilityId']?.toString();
    _orderValue = _toInt(args['orderValue']);
    _selectedVoucherId = args['selectedVoucherId']?.toString();
    _loadUsedVoucherIds();
  }

  Future<void> _loadUsedVoucherIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .get();
      final usedIds = <String>{};
      for (final doc in snapshot.docs) {
        final voucherId = doc.data()['voucherId']?.toString() ?? '';
        if (voucherId.isNotEmpty) {
          usedIds.add(voucherId);
        }
      }
      if (mounted) {
        setState(() => _usedVoucherIds = usedIds);
      }
    } catch (_) {
      // silently ignore — user simply won't have usage data loaded
    }
  }

  @override
  void dispose() {
    _voucherCodeController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  bool _isVoucherInDateRange(Map<String, dynamic> voucher, DateTime now) {
    final startDate = _toDateTime(voucher['startDate']);
    final endDate = _toDateTime(voucher['endDate']);
    if (startDate != null && now.isBefore(startDate)) {
      return false;
    }
    if (endDate != null && now.isAfter(endDate)) {
      return false;
    }
    return true;
  }

  int _remainingQuantity(Map<String, dynamic> voucher) {
    final totalQuantity = _toInt(voucher['totalQuantity']);
    return totalQuantity;
  }

  bool _hasUserUsedVoucher(Map<String, dynamic> voucher) {
    final voucherId = voucher['id']?.toString() ?? '';
    if (voucherId.isEmpty) return false;
    final maxPerUser = _toInt(voucher['maxPerUser'], fallback: 1);
    if (maxPerUser <= 0) return false;
    return _usedVoucherIds.contains(voucherId);
  }

  bool _canApplyVoucher(Map<String, dynamic> voucher, DateTime now) {
    final isActive = voucher['isActive'] == true;
    if (!isActive) {
      return false;
    }

    if (!_isVoucherInDateRange(voucher, now)) {
      return false;
    }

    if (_remainingQuantity(voucher) <= 0) {
      return false;
    }

    final minOrderValue = _toInt(voucher['minOrderValue']);
    if (_orderValue < minOrderValue) {
      return false;
    }

    if (_hasUserUsedVoucher(voucher)) {
      return false;
    }

    return true;
  }

  int _computeDiscountAmount(Map<String, dynamic> voucher, int orderValue) {
    final discountType = voucher['discountType']?.toString().toLowerCase() ?? '';
    final discountValue = (voucher['discountValue'] as num?)?.toDouble() ?? 0;

    if (discountType == 'percent') {
      final amount = (orderValue * discountValue / 100).round();
      return amount.clamp(0, orderValue);
    }

    final amount = discountValue.round();
    return amount.clamp(0, orderValue);
  }

  String _formatCurrency(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '--';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _discountLabel(Map<String, dynamic> voucher) {
    final discountType = voucher['discountType']?.toString().toLowerCase() ?? '';
    final value = (voucher['discountValue'] as num?)?.toDouble() ?? 0;
    if (discountType == 'percent') {
      return 'Giảm ${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
    }
    return 'Giảm ${_formatCurrency(value.round())}';
  }

  List<Map<String, dynamic>> _filterVouchers(List<Map<String, dynamic>> vouchers) {
    final now = DateTime.now();
    final query = _voucherCodeController.text.trim().toLowerCase();

    final filtered = vouchers.where((voucher) {
      if (_facilityId != null && _facilityId!.isNotEmpty) {
        final voucherFacilityId = voucher['facilityId']?.toString() ?? '';
        if (voucherFacilityId != _facilityId) {
          return false;
        }
      }

      if (_selectedFilterIndex == 0 && !_canApplyVoucher(voucher, now)) {
        return false;
      }

      if (_selectedFilterIndex == 1) {
        final endDate = _toDateTime(voucher['endDate']);
        if (endDate == null) {
          return false;
        }
        final difference = endDate.difference(now).inDays;
        if (difference < 0 || difference > 7) {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final code = voucher['code']?.toString().toLowerCase() ?? '';
        final title = voucher['title']?.toString().toLowerCase() ?? '';
        if (!code.contains(query) && !title.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      final aEnd = _toDateTime(a['endDate']) ?? DateTime(2099);
      final bEnd = _toDateTime(b['endDate']) ?? DateTime(2099);
      return aEnd.compareTo(bEnd);
    });

    return filtered;
  }

  void _applyCodeFromInput(List<Map<String, dynamic>> vouchers) {
    final query = _voucherCodeController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return;
    }

    final match = vouchers.where((voucher) {
      final code = voucher['code']?.toString().toLowerCase() ?? '';
      return code == query;
    }).toList();

    if (match.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy mã voucher này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final voucher = match.first;
    if (!_canApplyVoucher(voucher, now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher chưa đủ điều kiện áp dụng cho đơn này.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedVoucherId = voucher['id']?.toString();
    });
  }

  void _confirmSelection(List<Map<String, dynamic>> vouchers) {
    if (_selectedVoucherId == null) {
      Navigator.pop(context, null);
      return;
    }

    final selected = vouchers.firstWhere(
      (voucher) => voucher['id']?.toString() == _selectedVoucherId,
      orElse: () => {},
    );

    if (selected.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    final now = DateTime.now();
    if (!_canApplyVoucher(selected, now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voucher đã hết điều kiện sử dụng.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'id': selected['id']?.toString() ?? '',
      'code': selected['code']?.toString() ?? '',
      'title': selected['title']?.toString() ?? '',
      'discountType': selected['discountType']?.toString() ?? 'fixed',
      'discountValue': (selected['discountValue'] as num?)?.toDouble() ?? 0,
      'minOrderValue': _toInt(selected['minOrderValue']),
      'facilityId': selected['facilityId']?.toString() ?? '',
      'facilityName': selected['facilityName']?.toString() ?? '',
      'startDate': selected['startDate'],
      'endDate': selected['endDate'],
      'discountAmount': _computeDiscountAmount(selected, _orderValue),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 112),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('vouchers')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Không tải được danh sách voucher. Vui lòng thử lại.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final vouchers = (snapshot.data?.docs ?? [])
                        .map((doc) => <String, dynamic>{
                              'id': doc.id,
                              ...doc.data(),
                            })
                        .toList();
                    final filtered = _filterVouchers(vouchers);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: 120,
                      ),
                      child: Column(
                        children: [
                          _buildVoucherCodeInput(vouchers),
                          const SizedBox(height: 24),
                          _buildFilterTabs(),
                          const SizedBox(height: 24),
                          _buildVoucherList(filtered),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          _buildHeader(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('vouchers')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final vouchers = (snapshot.data?.docs ?? [])
                    .map((doc) => <String, dynamic>{
                          'id': doc.id,
                          ...doc.data(),
                        })
                    .toList();
                return _buildBottomBar(vouchers);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 48,
          bottom: 16,
        ),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1A1C1C),
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
                  color: Color(0xFF1A1C1C),
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCodeInput(List<Map<String, dynamic>> vouchers) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              decoration: InputDecoration(
                hintText: 'Nhập mã giảm giá...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF6F7A6B)),
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                  color: Color(0xFF6F7A6B),
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _applyCodeFromInput(vouchers),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(22),
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
                color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF3F4A3C),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVoucherList(List<Map<String, dynamic>> vouchers) {
    if (vouchers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: const Text(
          'Không có voucher phù hợp.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6F7A6B)),
        ),
      );
    }

    return Column(
      children: vouchers
          .map(
            (voucher) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildVoucherCard(voucher),
            ),
          )
          .toList(),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final now = DateTime.now();
    final isSelected = voucher['id']?.toString() == _selectedVoucherId;
    final alreadyUsed = _hasUserUsedVoucher(voucher);
    final canApply = _canApplyVoucher(voucher, now);
    final endDate = _toDateTime(voucher['endDate']);
    final minOrder = _toInt(voucher['minOrderValue']);
    final discountAmount = _computeDiscountAmount(voucher, _orderValue);

    final String statusText;
    final Color statusColor;
    if (alreadyUsed) {
      statusText = 'Bạn đã sử dụng voucher này';
      statusColor = const Color(0xFF6F7A6B);
    } else if (canApply) {
      statusText = 'Tiết kiệm ${_formatCurrency(discountAmount)}';
      statusColor = const Color(0xFF4CAF50);
    } else {
      statusText = 'Chưa đủ điều kiện áp dụng';
      statusColor = const Color(0xFFBA1A1A);
    }

    return GestureDetector(
      onTap: canApply
          ? () {
              setState(() {
                _selectedVoucherId = voucher['id']?.toString();
              });
            }
          : null,
      child: Opacity(
        opacity: canApply ? 1 : 0.6,
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.4)
                  : const Color(0xFFBECAB9).withValues(alpha: 0.4),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
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
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: canApply
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                              : Colors.grey[100],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.confirmation_number,
                              color: canApply
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey[400],
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voucher['code']?.toString() ?? '--',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: canApply
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey[400],
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 1,
                        child: CustomPaint(painter: DashedLinePainter()),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                voucher['title']?.toString() ?? 'Voucher',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1C1C),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hạn dùng: ${_formatDate(endDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_discountLabel(voucher)} | Tối thiểu ${_formatCurrency(minOrder)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: canApply
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[500],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (alreadyUsed)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F7A6B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Đã sử dụng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (isSelected)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
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
      ),
    );
  }

  Widget _buildBottomBar(List<Map<String, dynamic>> vouchers) {
    return Container(
      padding: const EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context, null),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, color: Color(0xFF6F7A6B), size: 20),
                    SizedBox(height: 2),
                    Text(
                      'Hủy',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6F7A6B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Confirm
          Expanded(
            flex: 2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _confirmSelection(vouchers),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(height: 2),
                      Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
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
      ..color = const Color(0xFFBECAB9)
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
