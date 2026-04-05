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
      backgroundColor: const Color(0xFFFFF8F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _bookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF9800),
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

    return {
      'id': doc.id,
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
      'statusRaw': statusRaw,
      'status': _statusLabel(statusRaw),
      'paymentStatus': (data['paymentStatus'] ?? 'pending').toString(),
      'totalPrice': _toInt(data['totalPrice']),
      'hasReview': data['hasReview'] == true,
    };
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

  bool _isUpcomingBooking(Map<String, dynamic> booking) {
    final status = (booking['statusRaw'] ?? '').toString();
    if (status == 'cancelled' || status == 'completed') {
      return false;
    }

    final playDateTime = booking['dateTime'] as DateTime?;
    if (playDateTime == null) {
      return false;
    }

    return playDateTime.isAfter(DateTime.now());
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
            Icon(
              Icons.event_busy_rounded,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
        color: Color(0xFFFFF8F6),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFFF9800),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Text(
                'LỊCH ĐẶT CỦA TÔI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? const Color(0xFFFF9800)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Sắp tới',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedTab == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedTab == 0
                              ? const Color(0xFFFF9800)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? const Color(0xFFFF9800)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Lịch sử',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedTab == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedTab == 1
                              ? const Color(0xFFFF9800)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              booking['image'] ?? '',
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 96,
                height: 96,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPending
                            ? const Color(0xFFFF9800).withValues(alpha: 0.12)
                            : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPending
                              ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        (booking['status'] ?? 'Đã xác nhận').toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPending ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      (booking['time'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      (booking['date'] ?? '').toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatMoney(_toInt(booking['totalPrice']))} • ${(booking['paymentStatus'] ?? 'pending').toString().toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      final selectedDate =
                          (booking['selectedDate'] is Map)
                              ? Map<String, dynamic>.from(
                                  booking['selectedDate'] as Map,
                                )
                              : <String, dynamic>{};

                      final selectedSlot =
                          (booking['selectedSlot'] is Map)
                              ? Map<String, dynamic>.from(
                                  booking['selectedSlot'] as Map,
                                )
                              : <String, dynamic>{};

                      _showQRBottomSheet(context, booking);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Xem mã QR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
            // drag handle
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
                    color: Color(0xFF1A237E),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
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
                border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                  color: Color(0xFF1A237E),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
              textAlign: TextAlign.center,
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            if (time.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            if (bookingId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mã đặt: $bookingId',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isCancelled ? 0.9 : 1.0,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColorFiltered(
                colorFilter: isCancelled
                    ? ColorFilter.mode(
                        Colors.grey.withValues(alpha: 0.3),
                        BlendMode.saturation,
                      )
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: Image.network(
                  booking['image'] ?? '',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 96,
                    height: 96,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? const Color(0xFFF44336).withValues(alpha: 0.1)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCancelled
                                ? const Color(0xFFF44336).withValues(alpha: 0.2)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          (booking['status'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCancelled ? const Color(0xFFF44336) : const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isCancelled ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (booking['time'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isCancelled ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: isCancelled ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (booking['date'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isCancelled ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatMoney(_toInt(booking['totalPrice']))} • ${(booking['paymentStatus'] ?? 'pending').toString().toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isCancelled ? Colors.grey[400] : const Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        if (!hasReview && !isCancelled) {
                          Navigator.pushNamed(
                            context,
                            '/rating',
                            arguments: {
                              'fieldId': booking['id'],
                              'fieldName': booking['name'],
                              'fieldImage': booking['image'],
                              'playDate': booking['date'],
                            },
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          (!hasReview && !isCancelled) ? 'Đánh giá' : 'Đặt lại',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
