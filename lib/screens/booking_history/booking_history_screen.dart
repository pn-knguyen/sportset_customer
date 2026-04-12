import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  int _selectedTab = 0; // 0: Sắp tới, 1: Lịch sử

  Stream<QuerySnapshot<Map<String, dynamic>>> get _bookingsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Không tải được lịch đặt. Vui lòng thử lại sau.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                final bookings = (snapshot.data?.docs ?? [])
                    .map(_mapBooking)
                    .toList()
                  ..sort((a, b) {
                    final aTime = (a['dateTime'] as DateTime?);
                    final bTime = (b['dateTime'] as DateTime?);
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                final upcomingBookings = bookings
                    .where(_isUpcomingBooking)
                    .toList();
                final historyBookings = bookings
                    .where((booking) => !_isUpcomingBooking(booking))
                    .toList();

                final tabBookings = _selectedTab == 0
                    ? upcomingBookings
                    : historyBookings;

                if (tabBookings.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 0,
                  ),
                  itemCount: tabBookings.length,
                  itemBuilder: (context, index) {
                    final booking = tabBookings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _selectedTab == 0
                          ? _buildUpcomingBookingCard(booking)
                          : _buildHistoryBookingCard(booking),
                    );
                  },
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }

  Map<String, dynamic> _mapBooking(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final selectedDateRaw = data['selectedDate'];
    final selectedSlotRaw = data['selectedSlot'];
    final selectedDate = selectedDateRaw is Map
        ? Map<String, dynamic>.from(selectedDateRaw)
        : <String, dynamic>{};
    final selectedSlot = selectedSlotRaw is Map
        ? Map<String, dynamic>.from(selectedSlotRaw)
        : <String, dynamic>{};

    final dateTime = _extractDateTime(selectedDate['dateTime']);
    final statusRaw = _normalizeStatus((data['status'] ?? '').toString());
    final startTimeStr = (selectedSlot['startTime'] ?? '').toString();
    final startDateTime = _combineDateTime(dateTime, startTimeStr);

    return {
      'id': doc.id,
      'courtId': (data['courtId'] ?? '').toString(),
      'name': (data['courtName'] ?? 'Sân thể thao').toString(),
      'image': (data['courtImageUrl'] ?? '').toString(),
      'sportType': (data['sportType'] ?? '').toString(),
      'selectedDate': selectedDate,
      'selectedSlot': selectedSlot,
      'subCourtName': (data['subCourtName'] ?? '').toString(),
      'duration': (data['duration'] ?? '').toString(),
      'paymentMethodLabel': (data['paymentMethodLabel'] ?? 'Chưa chọn').toString(),
      'time': _buildTimeText(selectedSlot),
      'date': _buildDateText(selectedDate, dateTime),
      'dateTime': dateTime,
      'startDateTime': startDateTime,
      'statusRaw': statusRaw,
      'status': _statusLabel(statusRaw),
      'paymentStatus': (data['paymentStatus'] ?? 'pending').toString(),
      'totalPrice': _toInt(data['totalPrice']),
      'hasReview': data['hasReview'] == true,
    };
  }

  DateTime? _combineDateTime(DateTime? date, String startTime) {
    if (date == null) return null;
    final parts = startTime.split(':');
    if (parts.length < 2) return date;
    final hour = int.tryParse(parts[0].trim()) ?? 0;
    final minute = int.tryParse(parts[1].trim()) ?? 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  DateTime? _extractDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  String _buildDateText(Map<String, dynamic> selectedDate, DateTime? dateTime) {
    final day = (selectedDate['day'] ?? '').toString();
    final date = (selectedDate['date'] ?? '').toString();
    final month = (selectedDate['month'] ?? '').toString();

    if (day.isNotEmpty && date.isNotEmpty && month.isNotEmpty) {
      return '$day, $date/$month';
    }
    if (date.isNotEmpty && month.isNotEmpty) {
      return '$date/$month';
    }

    if (dateTime != null) {
      final dd = dateTime.day.toString().padLeft(2, '0');
      final mm = dateTime.month.toString().padLeft(2, '0');
      final yyyy = dateTime.year.toString();
      return '$dd/$mm/$yyyy';
    }

    return 'Chưa có ngày';
  }

  String _buildTimeText(Map<String, dynamic> selectedSlot) {
    final start = (selectedSlot['startTime'] ?? '').toString();
    final end = (selectedSlot['endTime'] ?? '').toString();

    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    }
    if (start.isNotEmpty) {
      return start;
    }

    return 'Chưa có khung giờ';
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    return 0;
  }

  String _normalizeStatus(String status) => status.trim().toLowerCase();

  Future<void> _navigateToBooking(String courtId) async {
    if (courtId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('courts')
          .doc(courtId)
          .get();
      if (!mounted) return;
      final Map<String, dynamic> courtData = doc.exists && doc.data() != null
          ? Map<String, dynamic>.from(doc.data()!)
          : {};
      courtData['id'] = courtId;
      Navigator.pushNamed(context, '/booking', arguments: {'court': courtData});
    } catch (_) {
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/booking',
        arguments: {'court': <String, dynamic>{'id': courtId}},
      );
    }
  }

  bool _isUpcomingBooking(Map<String, dynamic> booking) {
    final status = (booking['statusRaw'] ?? '').toString();
    if (status == 'cancelled' || status == 'completed') {
      return false;
    }

    final startDateTime = booking['startDateTime'] as DateTime?;
    if (startDateTime == null) {
      return false;
    }

    return startDateTime.isAfter(DateTime.now());
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      case 'completed':
        return 'Đã hoàn thành';
      case 'pending':
        return 'Đang chờ';
      default:
        return status.isEmpty ? 'Không xác định' : status;
    }
  }

  String _formatMoney(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }

  Widget _buildEmptyState() {
    final title = _selectedTab == 0
        ? 'Chưa có lịch đặt sắp tới'
        : 'Chưa có lịch sử đặt sân';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                size: 36,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF6F7A6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFE8F5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFBECAB9), width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Text(
                      'Lịch đặt của tôi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Sắp tới',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w600,
                              color: _selectedTab == 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF6F7A6B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Lịch sử',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w600,
                              color: _selectedTab == 1
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF6F7A6B),
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
      ),
    );
  }

  Widget _buildUpcomingBookingCard(Map<String, dynamic> booking) {
    final statusRaw = (booking['statusRaw'] ?? '').toString();
    final isPending = statusRaw == 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // circular image
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    booking['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFC8E6C9),
                      child: const Icon(Icons.sports_soccer, color: Color(0xFF4CAF50), size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (booking['name'] ?? '').toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C1C),
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFF9C4)
                                : const Color(0xFF94F990).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (booking['status'] ?? 'Đã xác nhận').toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isPending ? const Color(0xFF994700) : const Color(0xFF005313),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if ((booking['sportType'] ?? '').toString().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.sports, size: 14, color: Color(0xFF6F7A6B)),
                          const SizedBox(width: 5),
                          Text(
                            (booking['sportType'] ?? '').toString(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF00696B)),
                        const SizedBox(width: 5),
                        Text(
                          '${(booking['time'] ?? '')} | ${(booking['date'] ?? '')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00696B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE8F5E9), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TỔNG THANH TOÁN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6F7A6B),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatMoney(_toInt(booking['totalPrice'])),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToBooking((booking['courtId'] ?? '').toString()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF4CAF50)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Đặt lại',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _showQRBottomSheet(context, booking),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Xem mã QR',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
  void _showQRBottomSheet(BuildContext context, Map<String, dynamic> booking) {
    final bookingId = (booking['id'] ?? '').toString();
    final name = (booking['name'] ?? 'Sân thể thao').toString();
    final date = (booking['date'] ?? '').toString();
    final time = (booking['time'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mã QR đặt sân',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBECAB9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: bookingId.isNotEmpty ? bookingId : 'SPORTSET-BOOKING',
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF2E7D32),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1C),
              ),
              textAlign: TextAlign.center,
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6F7A6B)),
                textAlign: TextAlign.center,
              ),
            ],
            if (time.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6F7A6B)),
                textAlign: TextAlign.center,
              ),
            ],
            if (bookingId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mã đặt: $bookingId',
                style: const TextStyle(fontSize: 11, color: Color(0xFFBECAB9)),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBookingCard(Map<String, dynamic> booking) {
    final isCancelled = (booking['statusRaw'] ?? '').toString() == 'cancelled';
    final hasReview = booking['hasReview'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular image
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: ColorFiltered(
                      colorFilter: isCancelled
                          ? const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ])
                          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                      child: Image.network(
                        booking['image'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFE8F5E9),
                          alignment: Alignment.center,
                          child: const Icon(Icons.sports_tennis, color: Color(0xFF4CAF50), size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              (booking['name'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1C1C),
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? const Color(0xFFBA1A1A).withValues(alpha: 0.1)
                                  : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (booking['status'] ?? '').toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isCancelled
                                    ? const Color(0xFFBA1A1A)
                                    : const Color(0xFF4CAF50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined, size: 13, color: Color(0xFF6F7A6B)),
                          const SizedBox(width: 4),
                          Text(
                            (booking['time'] ?? '').toString(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF6F7A6B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (booking['date'] ?? '').toString(),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider + price + action
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE8F5E9))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatMoney(_toInt(booking['totalPrice'])),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (!hasReview && !isCancelled) {
                      Navigator.pushNamed(
                        context,
                        '/rating',
                        arguments: {
                          'bookingId': booking['id'],
                          'fieldId': booking['courtId'],
                          'fieldName': booking['name'],
                          'fieldImage': booking['image'],
                          'playDate': booking['date'],
                        },
                      );
                    } else {
                      _navigateToBooking((booking['courtId'] ?? '').toString());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: (!hasReview && !isCancelled)
                          ? const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      (!hasReview && !isCancelled) ? 'Đánh giá' : 'Đặt lại',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
