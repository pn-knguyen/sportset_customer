import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  bool _didInitFromArgs = false;

  String _bookingId = '';
  Map<String, dynamic> _court = {};
  Map<String, dynamic>? _selectedDate;
  Map<String, dynamic>? _selectedSlot;
  String? _selectedSubCourt;
  String _duration = '1 tiếng 30 phút';
  int _totalPrice = 0;
  String _paymentMethodLabel = 'Chưa chọn';

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

    _bookingId = args['bookingId']?.toString() ?? '';

    final incomingCourt = args['court'];
    if (incomingCourt is Map) {
      _court = Map<String, dynamic>.from(incomingCourt);
    } else {
      _court = {
        'name': (args['courtName'] ?? args['name'] ?? 'Sân thể thao').toString(),
        'sportType': (args['sportType'] ?? '').toString(),
      };
    }

    final incomingDate = args['selectedDate'];
    if (incomingDate is Map) {
      _selectedDate = Map<String, dynamic>.from(incomingDate);
    } else {
      final fallbackDate = (args['date'] ?? '').toString();
      if (fallbackDate.isNotEmpty) {
        _selectedDate = {'day': '', 'date': fallbackDate, 'month': ''};
      }
    }

    final incomingSlot = args['selectedSlot'];
    if (incomingSlot is Map) {
      _selectedSlot = Map<String, dynamic>.from(incomingSlot);
    } else {
      final fallbackTime = (args['time'] ?? '').toString();
      if (fallbackTime.contains('-')) {
        final parts = fallbackTime.split('-');
        if (parts.length >= 2) {
          _selectedSlot = {
            'startTime': parts.first.trim(),
            'endTime': parts.last.trim(),
          };
        }
      }
    }

    _selectedSubCourt = args['selectedSubCourt']?.toString();
    _duration = args['duration']?.toString() ?? _duration;
    _totalPrice = _toInt(args['totalPrice']);
    _paymentMethodLabel = args['paymentMethodLabel']?.toString() ?? 'Chưa chọn';
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

  String _bookingCode() {
    if (_bookingId.isEmpty) {
      return '#SP-PENDING';
    }
    final trimmed = _bookingId.length > 8
        ? _bookingId.substring(0, 8)
        : _bookingId;
    return '#SP-${trimmed.toUpperCase()}';
  }

  String _courtName() {
    return _court['name']?.toString() ?? 'Sân thể thao';
  }

  String _sportType() {
    return _court['sportType']?.toString() ?? '';
  }

  String _timeLabel() {
    final slot = _selectedSlot;
    if (slot == null) {
      return 'Chưa xác định';
    }
    final start = slot['startTime']?.toString() ?? '';
    final end = slot['endTime']?.toString() ?? '';
    if (start.isEmpty || end.isEmpty) {
      return 'Chưa xác định';
    }
    return '$start - $end';
  }

  String _dateLabel() {
    final selectedDate = _selectedDate;
    if (selectedDate == null) {
      return 'Chưa xác định';
    }

    final day = selectedDate['day']?.toString() ?? '';
    final date = selectedDate['date']?.toString() ?? '';
    final month = selectedDate['month']?.toString() ?? '';

    if (date.isNotEmpty && month.isNotEmpty && day.isNotEmpty) {
      return '$day, $date/$month';
    }
    if (date.isNotEmpty && month.isNotEmpty) {
      return '$date/$month';
    }
    if (date.isNotEmpty) {
      return date;
    }
    return 'Chưa xác định';
  }

  String _qrData() {
    return '${_bookingCode()}|${_courtName()}|${_timeLabel()}|${_dateLabel()}';
  }

  IconData _sportIcon() {
    final sportType = _sportType().toLowerCase();
    if (sportType.contains('cầu lông')) {
      return Icons.sports_tennis;
    }
    if (sportType.contains('bóng rổ')) {
      return Icons.sports_basketball;
    }
    return Icons.sports_soccer;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSuccessIcon(),
                    _buildQRCodeSection(),
                    _buildBookingDetails(),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'THÀNH CÔNG!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: QrImageView(
              data: _qrData(),
              version: QrVersions.auto,
              size: 150,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1c170d),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1c170d),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vui lòng đưa mã QR này cho nhân viên quản lý sân.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFFFF3E0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MÃ ĐƠN HÀNG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _bookingCode(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _sportIcon(),
                color: const Color(0xFFFF9800),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tên sân',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _courtName(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1c170d),
                      ),
                    ),
                    if ((_selectedSubCourt ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _selectedSubCourt!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thời gian',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _timeLabel(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1c170d),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateLabel(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1c170d),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFFFF3E0), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thanh toán ($_paymentMethodLabel)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _formatCurrency(_totalPrice),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 48,
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
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/booking-history',
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Text(
                  'Xem lịch đặt của tôi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Text(
                  'Về trang chủ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
