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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFF9F9F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _buildSuccessIcon(),
                const SizedBox(height: 8),
                Expanded(child: _buildQRCodeSection()),
                const SizedBox(height: 8),
                _buildBookingDetails(),
                const SizedBox(height: 8),
                _buildActionButtons(context),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF006E1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF006E1C).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.check,
            size: 38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'THÀNH CÔNG!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF006E1C),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Cảm ơn bạn đã tin dùng dịch vụ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3F4A3C),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    final imageUrl = _court['imageUrl']?.toString() ?? _court['image']?.toString() ?? '';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E1C).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 80,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFC8E6C9),
                          child: const Icon(
                            Icons.sports_soccer,
                            color: Color(0xFF4CAF50),
                            size: 48,
                          ),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFC8E6C9),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Color(0xFF4CAF50),
                          size: 48,
                        ),
                      ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0x99000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Text(
                    _courtName(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFBECAB9),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      QrImageView(
                        data: _qrData(),
                        version: QrVersions.auto,
                        size: 110,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1A1C1C),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1A1C1C),
                        ),
                      ),
                      Positioned(top: 0, left: 0, child: _buildCorner(top: true, left: true)),
                      Positioned(top: 0, right: 0, child: _buildCorner(top: true, left: false)),
                      Positioned(bottom: 0, left: 0, child: _buildCorner(top: false, left: true)),
                      Positioned(bottom: 0, right: 0, child: _buildCorner(top: false, left: false)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vui lòng đưa mã QR này cho nhân viên quản lý sân để nhận sân.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3F4A3C),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Color(0xFF4CAF50), width: 2) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Color(0xFF4CAF50), width: 2) : BorderSide.none,
          left: left ? const BorderSide(color: Color(0xFF4CAF50), width: 2) : BorderSide.none,
          right: !left ? const BorderSide(color: Color(0xFF4CAF50), width: 2) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006E1C).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'THÔNG TIN ĐƠN HÀNG',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6F7A6B),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                _bookingCode(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF3F3F3), height: 1),
          const SizedBox(height: 10),
          _buildDetailRow(
            icon: Icons.stadium,
            label: 'TÊN SÂN',
            value: _courtName(),
            subtitle: (_selectedSubCourt ?? '').trim().isNotEmpty ? _selectedSubCourt : null,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.schedule,
            label: 'THỜI GIAN',
            value: _timeLabel(),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'NGÀY',
            value: _dateLabel(),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF3F3F3), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thanh toán ($_paymentMethodLabel)',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6F7A6B),
                ),
              ),
              Text(
                _formatCurrency(_totalPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006E1C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: const Color(0xFF4CAF50), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6F7A6B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1C),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6F7A6B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/main',
                  (route) => false,
                  arguments: {'initialIndex': 3},
                );
              },
              borderRadius: BorderRadius.circular(14),
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
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
              borderRadius: BorderRadius.circular(14),
              child: const Center(
                child: Text(
                  'Về trang chủ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
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
