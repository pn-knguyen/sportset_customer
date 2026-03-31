import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  String _selectedPayment = 'momo';
  bool _isSubmitting = false;
  bool _didInitFromArgs = false;
  Map<String, dynamic> _court = {};
  Map<String, dynamic>? _selectedDate;
  Map<String, dynamic>? _selectedSlot;
  String? _selectedSubCourt;
  String _duration = '1 tiếng 30 phút';
  int _totalPrice = 0;
  Map<String, dynamic>? _selectedVoucher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromArgs) {
      return;
    }
    _didInitFromArgs = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      return;
    }

    final incomingCourt = args['court'];
    if (incomingCourt is Map) {
      _court = Map<String, dynamic>.from(incomingCourt);
    }

    final incomingDate = args['selectedDate'];
    if (incomingDate is Map) {
      _selectedDate = Map<String, dynamic>.from(incomingDate);
    }

    final incomingSlot = args['selectedSlot'];
    if (incomingSlot is Map) {
      _selectedSlot = Map<String, dynamic>.from(incomingSlot);
    }

    _selectedSubCourt = args['selectedSubCourt']?.toString();
    _duration = args['duration']?.toString() ?? _duration;
    _totalPrice = _toInt(args['totalPrice']);
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

  String _bookingTimeLabel() {
    final slot = _selectedSlot;
    final selectedDate = _selectedDate;
    if (slot == null || selectedDate == null) {
      return 'Chưa chọn lịch';
    }

    final start = slot['startTime']?.toString() ?? '';
    final end = slot['endTime']?.toString() ?? '';
    final day = selectedDate['day']?.toString() ?? '';
    final date = selectedDate['date']?.toString() ?? '';
    final month = selectedDate['month']?.toString() ?? '';

    if (start.isEmpty || end.isEmpty || day.isEmpty || date.isEmpty || month.isEmpty) {
      return 'Chưa chọn lịch';
    }
    return '$start - $end | $day, $date/$month';
  }

  String _subCourtLabel() {
    final subCourtName = _selectedSubCourt;
    if (subCourtName == null || subCourtName.trim().isEmpty) {
      return 'Sân tiêu chuẩn';
    }
    return subCourtName;
  }

  String _courtName() {
    return _court['name']?.toString() ?? 'Sân thể thao';
  }

  String _courtAddress() {
    return _court['address']?.toString() ?? 'Chưa có địa chỉ';
  }

  String _courtImage() {
    final imageUrl = _court['imageUrl']?.toString() ?? '';
    if (imageUrl.isNotEmpty) {
      return imageUrl;
    }
    return 'https://htsport.vn/wp-content/uploads/2019/12/25-kich-thuoc-san-bong-7-nguoi-2.jpg';
  }

  String _courtId() {
    return _court['id']?.toString() ?? _court['docId']?.toString() ?? '';
  }

  String _paymentMethodLabel() {
    switch (_selectedPayment) {
      case 'momo':
        return 'MoMo';
      case 'zalopay':
        return 'ZaloPay';
      case 'vnpay':
        return 'VNPAY';
      case 'banking':
        return 'ATM/Internet Banking';
      default:
        return _selectedPayment;
    }
  }

  int _voucherDiscountAmount() {
    final voucher = _selectedVoucher;
    if (voucher == null) {
      return 0;
    }

    final minOrderValue = _toInt(voucher['minOrderValue']);
    if (_totalPrice < minOrderValue) {
      return 0;
    }

    final discountType = voucher['discountType']?.toString().toLowerCase() ?? '';
    final discountValue = (voucher['discountValue'] as num?)?.toDouble() ?? 0;

    if (discountType == 'percent') {
      final amount = (_totalPrice * discountValue / 100).round();
      return amount.clamp(0, _totalPrice);
    }

    return discountValue.round().clamp(0, _totalPrice);
  }

  int _finalPayableAmount() {
    return (_totalPrice - _voucherDiscountAmount()).clamp(0, _totalPrice);
  }

  String _voucherTitle() {
    final voucher = _selectedVoucher;
    if (voucher == null) {
      return 'Chọn voucher';
    }
    final title = voucher['title']?.toString() ?? '';
    final code = voucher['code']?.toString() ?? '';
    if (title.isNotEmpty) {
      return title;
    }
    if (code.isNotEmpty) {
      return code;
    }
    return 'Voucher đã chọn';
  }

  String _voucherSubtitle() {
    final voucher = _selectedVoucher;
    if (voucher == null) {
      return '';
    }
    final code = voucher['code']?.toString() ?? '';
    final discountType = voucher['discountType']?.toString().toLowerCase() ?? '';
    final discountValue = (voucher['discountValue'] as num?)?.toDouble() ?? 0;
    final discountText = discountType == 'percent'
        ? 'Giảm ${discountValue.toStringAsFixed(discountValue % 1 == 0 ? 0 : 1)}%'
        : 'Giảm ${_formatCurrency(discountValue.round())}';
    if (code.isEmpty) {
      return discountText;
    }
    return '$code • $discountText';
  }

  Future<void> _openVoucherSelection() async {
    final result = await Navigator.pushNamed(
      context,
      '/voucher-selection',
      arguments: {
        'facilityId': _court['facilityId']?.toString() ?? '',
        'orderValue': _totalPrice,
        'selectedVoucherId': _selectedVoucher?['id']?.toString(),
      },
    );

    if (!mounted) {
      return;
    }

    if (result is Map) {
      setState(() {
        _selectedVoucher = Map<String, dynamic>.from(result);
      });
      return;
    }

    if (result == null) {
      return;
    }
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) {
      return;
    }

    final selectedDate = _selectedDate;
    final selectedSlot = _selectedSlot;
    final courtId = _courtId();

    if (selectedDate == null || selectedSlot == null || courtId.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thiếu dữ liệu đặt sân. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final discountAmount = _voucherDiscountAmount();
    final finalPayable = _finalPayableAmount();

    final bookingPayload = <String, dynamic>{
      'courtId': courtId,
      'courtName': _courtName(),
      'courtAddress': _courtAddress(),
      'courtImageUrl': _courtImage(),
      'facilityId': _court['facilityId']?.toString() ?? '',
      'facilityName': _court['facilityName']?.toString() ?? '',
      'sportType': _court['sportType']?.toString() ?? '',
      'subCourtName': _subCourtLabel(),
      'selectedDate': selectedDate,
      'selectedSlot': selectedSlot,
      'duration': _duration,
      'slotPrice': _toInt(selectedSlot['price']),
      'basePrice': _totalPrice,
      'discountAmount': discountAmount,
      'totalPrice': finalPayable,
      'voucherId': _selectedVoucher?['id']?.toString() ?? '',
      'voucherCode': _selectedVoucher?['code']?.toString() ?? '',
      'voucherTitle': _selectedVoucher?['title']?.toString() ?? '',
      'paymentMethod': _selectedPayment,
      'paymentMethodLabel': _paymentMethodLabel(),
      'status': 'confirmed',
      'paymentStatus': 'paid',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final firestore = FirebaseFirestore.instance;
      final bookingRef = firestore.collection('bookings').doc();
      final selectedVoucherId = _selectedVoucher?['id']?.toString() ?? '';

      await firestore.runTransaction((transaction) async {
        if (selectedVoucherId.isNotEmpty) {
          final voucherRef = firestore.collection('vouchers').doc(selectedVoucherId);
          final voucherSnapshot = await transaction.get(voucherRef);

          if (!voucherSnapshot.exists) {
            throw Exception('voucher_not_found');
          }

          final voucherData = voucherSnapshot.data() ?? <String, dynamic>{};
          final totalQuantity = _toInt(voucherData['totalQuantity']);
          final usedQuantity = _toInt(voucherData['usedQuantity']);

          if (totalQuantity <= 0) {
            throw Exception('voucher_out_of_quantity');
          }

          transaction.update(voucherRef, {
            'totalQuantity': totalQuantity - 1,
            'usedQuantity': usedQuantity + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.set(bookingRef, bookingPayload);
      });

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        '/booking-success',
        arguments: {
          'bookingId': bookingRef.id,
          'court': _court,
          'selectedDate': selectedDate,
          'selectedSlot': selectedSlot,
          'selectedSubCourt': _selectedSubCourt,
          'duration': _duration,
          'basePrice': _totalPrice,
          'discountAmount': discountAmount,
          'totalPrice': finalPayable,
          'selectedVoucher': _selectedVoucher,
          'paymentMethod': _selectedPayment,
          'paymentMethodLabel': _paymentMethodLabel(),
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể tạo đơn đặt sân. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldInfoCard(),
                          const SizedBox(height: 24),
                          _buildPaymentMethodSection(),
                          const SizedBox(height: 24),
                          _buildVoucherSection(),
                          const SizedBox(height: 24),
                          _buildPaymentDetailsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFixedHeader(),
          _buildFixedBottomButton(),
        ],
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F6).withValues(alpha: 0.8),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFFFE0CC), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF1c170d),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Xác Nhận Đặt Sân',
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

  Widget _buildFieldInfoCard() {
    final sportType = _court['sportType']?.toString().toLowerCase() ?? '';
    final sportIcon = sportType.contains('cầu lông')
        ? Icons.sports_tennis
        : Icons.sports_soccer;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0CC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _courtImage(),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _courtName(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1c170d),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _courtAddress(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Color(0xFFFF9800),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _bookingTimeLabel(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      sportIcon,
                      size: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _subCourtLabel(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1c170d),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE0CC)),
          ),
          child: Column(
            children: [
              _buildPaymentOption(
                'momo',
                'Ví MoMo',
                const Color(0xFFA50064),
                'MOMO',
              ),
              _buildDivider(),
              _buildPaymentOption(
                'zalopay',
                'ZaloPay',
                const Color(0xFF008FE5),
                'Zalo',
              ),
              _buildDivider(),
              _buildPaymentOption(
                'vnpay',
                'VNPAY',
                const Color(0xFF005BAA),
                'VNPAY',
              ),
              _buildDivider(),
              _buildPaymentOptionWithIcon(
                'banking',
                'Thẻ ATM / Internet Banking',
                Icons.credit_card,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String value,
    String label,
    Color bgColor,
    String text,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPayment = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1c170d),
                ),
              ),
            ),
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _selectedPayment,
              // ignore: deprecated_member_use
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPayment = newValue!;
                });
              },
              activeColor: const Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionWithIcon(String value, String label, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPayment = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1c170d),
                ),
              ),
            ),
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _selectedPayment,
              // ignore: deprecated_member_use
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPayment = newValue!;
                });
              },
              activeColor: const Color(0xFFFF9800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF9FAFB),
    );
  }

  Widget _buildVoucherSection() {
    return InkWell(
      onTap: _openVoucherSelection,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0CC)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.card_giftcard,
                color: Color(0xFFFF9800),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _voucherTitle(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedVoucher == null
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFFF57C00),
                    ),
                  ),
                  if (_selectedVoucher != null)
                    Text(
                      _voucherSubtitle(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              _selectedVoucher == null ? 'Chọn voucher' : 'Đổi voucher',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection() {
    final slotPrice = _toInt(_selectedSlot?['price']);
    final basePrice = slotPrice > 0 ? slotPrice : _totalPrice;
    final discountAmount = _voucherDiscountAmount();
    const serviceFee = 0;
    final grandTotal = (_totalPrice - discountAmount + serviceFee).clamp(0, _totalPrice + serviceFee);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0CC)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1c170d),
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Giá sân ($_duration)', _formatCurrency(basePrice)),
          if (_selectedVoucher != null) ...[
            const SizedBox(height: 12),
            _buildPriceRow(
              'Voucher (${_selectedVoucher?['code']?.toString() ?? 'N/A'})',
              '-${_formatCurrency(discountAmount)}',
            ),
          ],
          const SizedBox(height: 12),
          _buildPriceRow('Phí dịch vụ', _formatCurrency(serviceFee)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  _formatCurrency(grandTotal),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedBottomButton() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFF9FAFB),
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
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Thanh toán ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.verified_user,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
