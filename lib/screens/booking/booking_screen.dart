import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentImageIndex = 0;
  int _selectedDateIndex = 0;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedSubCourt;
  bool _isFavorite = false;
  bool _didInitFromArgs = false;
  Map<String, dynamic> _court = {};

  List<String> _fieldImages = [
    'https://htsport.vn/wp-content/uploads/2019/12/25-kich-thuoc-san-bong-7-nguoi-2.jpg',
    'https://www.aisedulaos.com/img/Sport-field-ais.jpg',
    'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
  ];

  late final List<Map<String, dynamic>> _dates = _buildUpcomingDates();
  List<Map<String, dynamic>> _subCourts = [];
  List<Map<String, dynamic>> _activePricingSlots = [];
  List<Map<String, dynamic>> _bookedSlots = [];
  bool _isLoadingBookings = false;

  // Reviews & distance
  double? _avgRating;
  int _reviewCount = 0;
  String? _distance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromArgs) {
      return;
    }
    _didInitFromArgs = true;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final incomingCourt = args?['court'];
    if (incomingCourt is Map) {
      _court = Map<String, dynamic>.from(incomingCourt);
    }

    _fieldImages = _extractImages(_court);
    _subCourts = _extractSubCourts(_court);
    _selectedSubCourt = _subCourts
        .where((subCourt) => _isAvailableStatus(subCourt['status']))
        .map((subCourt) => subCourt['name']?.toString() ?? '')
        .firstWhere((name) => name.isNotEmpty, orElse: () => '');
    if (_selectedSubCourt?.isEmpty ?? true) {
      _selectedSubCourt = null;
    }
    _refreshPricingSlots();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookedSlots();
      _fetchDistance(_court);
      _loadReviews(_court['id']?.toString() ?? '');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Map<String, dynamic>> _buildUpcomingDates() {
    const dayNames = ['CN', 'Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7'];
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return {
        'day': dayNames[date.weekday % 7],
        'date': date.day.toString().padLeft(2, '0'),
        'month': date.month.toString().padLeft(2, '0'),
        'isWeekend': date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday,
        'dateTime': date,
      };
    });
  }

  List<String> _extractImages(Map<String, dynamic> court) {
    final imagesRaw = court['images'];
    final result = <String>[];
    if (imagesRaw is List) {
      for (final item in imagesRaw) {
        final value = item?.toString() ?? '';
        if (value.isNotEmpty) {
          result.add(value);
        }
      }
    }
    final imageUrl = court['imageUrl']?.toString() ?? court['image']?.toString() ?? '';
    if (imageUrl.isNotEmpty && !result.contains(imageUrl)) {
      result.insert(0, imageUrl);
    }
    if (result.isEmpty) {
      return [
        'https://htsport.vn/wp-content/uploads/2019/12/25-kich-thuoc-san-bong-7-nguoi-2.jpg',
      ];
    }
    return result;
  }

  List<Map<String, dynamic>> _extractSubCourts(Map<String, dynamic> court) {
    final source = court['subCourts'];
    if (source is! List) {
      return [];
    }
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  bool _isAvailableStatus(dynamic status) {
    return status?.toString().trim().toLowerCase() == 'available';
  }

  List<Map<String, dynamic>> _normalizePricingList(dynamic source) {
    if (source is! List) {
      return [];
    }
    final slots = <Map<String, dynamic>>[];
    for (final item in source) {
      if (item is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(item);
      final startTime = map['startTime']?.toString() ?? '';
      final endTime = map['endTime']?.toString() ?? '';
      final price = _toInt(map['price']);
      if (startTime.isEmpty || endTime.isEmpty) {
        continue;
      }
      slots.add({
        'startTime': startTime,
        'endTime': endTime,
        'price': price,
      });
    }
    return slots;
  }

  void _refreshPricingSlots() {
    final isWeekend = _dates[_selectedDateIndex]['isWeekend'] as bool;
    final weekendPricing = _normalizePricingList(_court['weekendPricing']);
    final weekdayPricing = _normalizePricingList(_court['weekdayPricing']);
    final selected = isWeekend ? weekendPricing : weekdayPricing;
    final fallbackPrice = _toInt(_court['pricePerHour'] ?? _court['price']);

    if (selected.isNotEmpty) {
      _activePricingSlots = selected;
    } else if (fallbackPrice > 0) {
      _activePricingSlots = [
        {'startTime': '05:00', 'endTime': '22:00', 'price': fallbackPrice},
      ];
    } else {
      _activePricingSlots = [];
    }
    _startTime = null;
    _endTime = null;
  }

  // ── Time helpers ──────────────────────────────────────────────────────────

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _timeLabel(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 0, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  TimeOfDay get _operatingStart {
    if (_activePricingSlots.isEmpty) return const TimeOfDay(hour: 5, minute: 0);
    return _activePricingSlots
        .map((s) => _parseTime(s['startTime']))
        .reduce((a, b) => _toMinutes(a) < _toMinutes(b) ? a : b);
  }

  TimeOfDay get _operatingEnd {
    if (_activePricingSlots.isEmpty) return const TimeOfDay(hour: 22, minute: 0);
    return _activePricingSlots
        .map((s) => _parseTime(s['endTime']))
        .reduce((a, b) => _toMinutes(a) > _toMinutes(b) ? a : b);
  }

  bool _isPastSlot(TimeOfDay t) {
    if (_selectedDateIndex != 0) return false;
    final now = TimeOfDay.now();
    return _toMinutes(t) <= _toMinutes(now);
  }

  List<TimeOfDay> get _timeSlots {
    final startMin = _toMinutes(_operatingStart);
    final endMin = _toMinutes(_operatingEnd);
    final slots = <TimeOfDay>[];
    for (int m = startMin; m < endMin; m += 30) {
      final slot = TimeOfDay(hour: m ~/ 60, minute: m % 60);
      if (!_isPastSlot(slot)) slots.add(slot);
    }
    return slots;
  }

  bool _isStartBooked(TimeOfDay t) {
    final tMin = _toMinutes(t);
    for (final b in _bookedSlots) {
      final bStart = _toMinutes(_parseTime(b['startTime'] as String));
      final bEnd = _toMinutes(_parseTime(b['endTime'] as String));
      if (tMin >= bStart && tMin < bEnd) return true;
    }
    return false;
  }

  List<TimeOfDay> _validEndTimes(TimeOfDay start) {
    final startMin = _toMinutes(start);
    final endMax = _toMinutes(_operatingEnd);
    int? nextBookingMin;
    for (final b in _bookedSlots) {
      final bStart = _toMinutes(_parseTime(b['startTime'] as String));
      if (bStart > startMin) {
        if (nextBookingMin == null || bStart < nextBookingMin) {
          nextBookingMin = bStart;
        }
      }
    }
    final ceiling = nextBookingMin ?? endMax;
    final slots = <TimeOfDay>[];
    for (int m = startMin + 30; m <= ceiling; m += 30) {
      slots.add(TimeOfDay(hour: m ~/ 60, minute: m % 60));
    }
    return slots;
  }

  int _calculatePrice(TimeOfDay start, TimeOfDay end) {
    final startMin = _toMinutes(start);
    final endMin = _toMinutes(end);
    int total = 0;
    for (final slot in _activePricingSlots) {
      final slotStart = _toMinutes(_parseTime(slot['startTime']));
      final slotEnd = _toMinutes(_parseTime(slot['endTime']));
      final price = _toInt(slot['price']);
      final overlapStart = startMin < slotStart ? slotStart : startMin;
      final overlapEnd = endMin > slotEnd ? slotEnd : endMin;
      if (overlapEnd > overlapStart) {
        total += (price * (overlapEnd - overlapStart) / 60).round();
      }
    }
    return total;
  }

  String _durationLabel(TimeOfDay start, TimeOfDay end) {
    final mins = _toMinutes(end) - _toMinutes(start);
    final hours = mins ~/ 60;
    final minutes = mins % 60;
    if (hours == 0) return '$minutes phút';
    if (minutes == 0) return '$hours giờ';
    return '$hours giờ $minutes phút';
  }

  Future<void> _loadBookedSlots() async {
    final courtId = _court['id']?.toString() ?? '';
    if (courtId.isEmpty) return;
    if (mounted) setState(() => _isLoadingBookings = true);
    final selectedDate = _dates[_selectedDateIndex];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('courtId', isEqualTo: courtId)
          .where('status', whereIn: ['confirmed', 'pending'])
          .get();
      final booked = snap.docs
          .where((doc) {
            final d = doc.data()['selectedDate'];
            if (d is! Map) return false;
            final dateMatch =
                d['date']?.toString() == selectedDate['date']?.toString() &&
                d['month']?.toString() == selectedDate['month']?.toString();
            if (!dateMatch) return false;
            // If this court has sub-courts, only block slots for the same sub-court
            if (_hasSubCourtData && _selectedSubCourt != null) {
              final bookedSub = doc.data()['subCourtName']?.toString() ?? '';
              return bookedSub == _selectedSubCourt;
            }
            return true;
          })
          .map((doc) {
            final slot = doc.data()['selectedSlot'];
            if (slot is Map) {
              return {
                'startTime': slot['startTime']?.toString() ?? '',
                'endTime': slot['endTime']?.toString() ?? '',
              };
            }
            return {'startTime': '', 'endTime': ''};
          })
          .where((b) => (b['startTime'] ?? '').isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _bookedSlots = booked;
          _isLoadingBookings = false;
          _startTime = null;
          _endTime = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBookings = false);
    }
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

  int get _totalPrice =>
      (_startTime != null && _endTime != null)
          ? _calculatePrice(_startTime!, _endTime!)
          : 0;

  bool get _isCourtAvailable => _isAvailableStatus(_court['status']);

  bool get _hasSubCourtData => _subCourts.isNotEmpty;

  bool get _hasAvailableSubCourt {
    if (!_hasSubCourtData) {
      return true;
    }
    return _subCourts.any((subCourt) => _isAvailableStatus(subCourt['status']));
  }

  bool get _canBook {
    if (!_isCourtAvailable || !_hasAvailableSubCourt) return false;
    if (_hasSubCourtData && _selectedSubCourt == null) return false;
    return _startTime != null && _endTime != null;
  }

  String get _bookBlockReason {
    if (!_isCourtAvailable) return 'Sân hiện không khả dụng để đặt.';
    if (!_hasAvailableSubCourt) return 'Tất cả sân con đã đầy. Vui lòng chọn sân khác.';
    if (_startTime == null) return 'Vui lòng chọn giờ bắt đầu.';
    if (_endTime == null) return 'Vui lòng chọn giờ kết thúc.';
    return 'Vui lòng kiểm tra lại thông tin đặt sân.';
  }

  IconData _amenityIcon(String label) {
    final value = label.toLowerCase();
    if (value.contains('wifi')) return Icons.wifi;
    if (value.contains('xe') || value.contains('parking')) return Icons.local_parking;
    if (value.contains('nước') || value.contains('drink')) return Icons.local_drink;
    if (value.contains('wc') || value.contains('toilet') || value.contains('vệ sinh')) {
      return Icons.wc;
    }
    if (value.contains('ăn') || value.contains('tin')) return Icons.restaurant;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F1),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F9F1), Color(0xFFF9F9F9), Color(0xFFE8F5E9)],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageCarousel(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldInfo(),
                        const SizedBox(height: 24),
                        _buildAmenities(),
                        const SizedBox(height: 24),
                        _buildSubCourtSelection(),
                        const SizedBox(height: 32),
                        _buildDateSelection(),
                        const SizedBox(height: 32),
                        _buildTimeSelection(),
                        const SizedBox(height: 40),
                        _buildReviews(),
                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildTopBar(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _fieldImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Image.network(
                    _fieldImages[index],
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFF9F9F9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _fieldImages.length,
                (index) => Container(
                  width: index == _currentImageIndex ? 24 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: index == _currentImageIndex
                        ? const Color(0xFF4CAF50)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTopButton(
              icon: Icons.chevron_left,
              onPressed: () => Navigator.pop(context),
            ),
            Row(
              children: [
                _buildTopButton(
                  icon: Icons.share,
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                _buildTopButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  isFilled: _isFavorite,
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    Color? color,
    bool isFilled = false,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: color ?? const Color(0xFF1A1C1C),
          size: 22,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFieldInfo() {
    final courtName = _court['name']?.toString() ?? 'Sân đang cập nhật';
    final address = _court['address']?.toString() ?? 'Chưa cập nhật địa chỉ';
    final distance = _court['distance']?.toString();
    final rating = _toDouble(_court['rating'], fallback: 4.8);
    final status = _court['status']?.toString() ?? 'unknown';
    final facilityName = _court['facilityName']?.toString() ?? '';
    final locationText =
        distance != null && distance.isNotEmpty ? '$address • $distance km' : address;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        Text(
          courtName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1C1C),
            letterSpacing: -0.5,
          ),
        ),
        if (facilityName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            facilityName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isAvailableStatus(status) ? 'Đang mở' : 'Đã đóng',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isAvailableStatus(status)
                      ? const Color(0xFF006E1C)
                      : const Color(0xFFBA1A1A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 14, color: Color(0xFF6F7A6B)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                locationText,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6F7A6B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x26BECAB9), width: 1)),
          ),
          child: Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    _avgRating != null
                        ? _avgRating!.toStringAsFixed(1)
                        : rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1C),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($_reviewCount đánh giá)',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
                  ),
                ],
              ),
              Container(
                width: 1, height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0x4DBECAB9),
              ),
              const Icon(Icons.map, size: 16, color: Color(0xFF6F7A6B)),
              const SizedBox(width: 4),
              Text(
                _distance ?? 'Đang xác định...',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6F7A6B)),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildAmenities() {
    final amenitiesSource = _court['amenities'];
    final amenities = <String>[];
    if (amenitiesSource is List) {
      for (final item in amenitiesSource) {
        final text = item?.toString() ?? '';
        if (text.isNotEmpty) amenities.add(text);
      }
    }
    if (amenities.isEmpty) {
      amenities.addAll(['Wifi', 'Nước uống', 'Gửi xe', 'Căn tin']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích sân',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1C),
          ),
        ),
        const SizedBox(height: 2),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 4,
          childAspectRatio: 0.9,
          children: amenities.map((amenity) {
            return Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18A5A7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _amenityIcon(amenity),
                    color: const Color(0xFF18A5A7),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amenity,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1C),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubCourtSelection() {
    if (_subCourts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn sân con',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _subCourts.map((subCourt) {
            final name = subCourt['name']?.toString() ?? 'Sân phụ';
            final isAvailable = _isAvailableStatus(subCourt['status']);
            final isSelected = _selectedSubCourt == name;
            return InkWell(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedSubCourt = name;
                        _startTime = null;
                        _endTime = null;
                      });
                      _loadBookedSlots();
                    }
                  : null,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : (isAvailable ? Colors.white : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFBECAB9),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAvailable ? Icons.check_circle : Icons.block,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isAvailable
                              ? const Color(0xFF4CAF50)
                              : Colors.red),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAvailable ? name : '$name (đã đầy)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isAvailable
                                ? const Color(0xFF1A1C1C)
                                : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (!_hasAvailableSubCourt) ...[
          const SizedBox(height: 10),
          const Text(
            'Tất cả sân con đã đầy, bạn chưa thể đặt khung giờ này.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chọn ngày',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_dates.length, (index) {
              final date = _dates[index];
              final isSelected = index == _selectedDateIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateIndex = index;
                    _refreshPricingSlots();
                  });
                  _loadBookedSlots();
                },
                child: Container(
                  width: 64,
                  height: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date['day'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF6F7A6B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date['date'] as String,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1A1C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    final slots = _timeSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Row(
          children: [
            const Text(
              'Chọn giờ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1C),
              ),
            ),
            const Spacer(),
            if (_isLoadingBookings)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF4CAF50)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _buildLegendChip(const Color(0xFFE8E8E8), const Color(0xFFE8E8E8), 'Giờ còn trống'),
            _buildLegendChip(const Color(0xFF4CAF50), const Color(0xFF4CAF50), 'Đã chọn'),
            _buildLegendChip(const Color(0xFFFFEBEB), const Color(0xFFBA1A1A), 'Đã đặt', crossOut: true),
          ],
        ),
        const SizedBox(height: 20),

        // ── Start time ────────────────────────────────────────────────────
        const Text(
          'GIỜ BẮT ĐẦU',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6F7A6B),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 10),
        if (slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Hiện chưa có khung giờ khả dụng cho ngày này.',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF006E1C),
                  fontWeight: FontWeight.w600),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 1.7,
            ),
            itemCount: slots.length,
            itemBuilder: (context, idx) {
              final t = slots[idx];
              final isBooked = _isStartBooked(t);
              final isSelected =
                  _startTime != null && _toMinutes(_startTime!) == _toMinutes(t);
              final inRange = _startTime != null &&
                  _endTime != null &&
                  _toMinutes(t) > _toMinutes(_startTime!) &&
                  _toMinutes(t) < _toMinutes(_endTime!);
              return GestureDetector(
                onTap: isBooked
                    ? null
                    : () => setState(() {
                          _startTime = t;
                          _endTime = null;
                        }),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isBooked
                        ? const Color(0xFFFFEBEB)
                        : (isSelected
                            ? const Color(0xFF4CAF50)
                            : (inRange
                                ? const Color(0xFFC8E6C9)
                                : const Color(0xFFE8E8E8))),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: isBooked
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              _timeLabel(t),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFBA1A1A),
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Color(0xFFBA1A1A),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _timeLabel(t),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1A1C1C),
                          ),
                        ),
                ),
              );
            },
          ),

        // ── End time (shown after start is selected) ──────────────────────
        if (_startTime != null) ...[
          const SizedBox(height: 24),
          const Text(
            'GIỜ KẾT THÚC',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6F7A6B),
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final endTs = _validEndTimes(_startTime!);
            if (endTs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Không có giờ kết thúc khả dụng từ giờ này.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF006E1C)),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.7,
              ),
              itemCount: endTs.length,
              itemBuilder: (context, idx) {
                final t = endTs[idx];
                final isSelected = _endTime != null &&
                    _toMinutes(_endTime!) == _toMinutes(t);
                return GestureDetector(
                  onTap: () => setState(() => _endTime = t),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      _timeLabel(t),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF1A1C1C),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],

        // ── Booking summary card ──────────────────────────────────────────
        if (_startTime != null && _endTime != null) ...[
          const SizedBox(height: 20),
          _buildBookingSummaryCard(),
        ],
      ],
    );
  }

  Widget _buildLegendChip(Color bg, Color border, String label, {bool crossOut = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6F7A6B)),
        ),
      ],
    );
  }

  Widget _buildBookingSummaryCard() {
    final duration = _durationLabel(_startTime!, _endTime!);
    final total = _totalPrice;
    final startMin = _toMinutes(_startTime!);
    final endMin = _toMinutes(_endTime!);

    // Build price breakdown per pricing slot
    final breakdown = <Map<String, dynamic>>[];
    for (final slot in _activePricingSlots) {
      final slotStart = _toMinutes(_parseTime(slot['startTime']));
      final slotEnd = _toMinutes(_parseTime(slot['endTime']));
      final price = _toInt(slot['price']);
      final overlapStart = startMin < slotStart ? slotStart : startMin;
      final overlapEnd = endMin > slotEnd ? slotEnd : endMin;
      if (overlapEnd > overlapStart) {
        final mins = overlapEnd - overlapStart;
        breakdown.add({
          'label': '${slot['startTime']} - ${slot['endTime']}',
          'mins': mins,
          'amount': (price * mins / 60).round(),
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBECAB9).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range + duration badge
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF4CAF50), size: 22),
              const SizedBox(width: 10),
              Text(
                '${_timeLabel(_startTime!)}  →  ${_timeLabel(_endTime!)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1C),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006E1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x4DBECAB9)),
          const SizedBox(height: 12),
          // Price breakdown (only when multiple pricing slots are crossed)
          if (breakdown.length > 1) ...[
            ...breakdown.map((item) {
              final h = (item['mins'] as int) ~/ 60;
              final m = (item['mins'] as int) % 60;
              final timeStr =
                  '${h > 0 ? "${h}h " : ""}${m > 0 ? "${m}ph" : ""}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(item['label'] as String,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700])),
                    const SizedBox(width: 6),
                    Text('($timeStr)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500])),
                    const Spacer(),
                    Text(
                      _formatCurrency(item['amount'] as int),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 1, color: Color(0x4DBECAB9)),
            const SizedBox(height: 10),
          ],
          // Total
          Row(
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1C),
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildReviews() {
    final courtId = _court['id']?.toString() ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: courtId.isEmpty
          ? null
          : FirebaseFirestore.instance
              .collection('reviews')
              .where('fieldId', isEqualTo: courtId)
              .limit(20)
              .snapshots(),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final ta = a.data()['createdAt'];
            final tb = b.data()['createdAt'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            return 0;
          });

        final avg = docs.isEmpty
            ? 0.0
            : docs.fold<double>(0,
                    (acc, d) =>
                        acc +
                        ((d.data()['rating'] as num?)?.toDouble() ?? 0)) /
                docs.length;

        // Compute rating distribution
        final counts = List<int>.filled(6, 0);
        for (final d in docs) {
          final r = ((d.data()['rating'] as num?)?.toInt() ?? 0).clamp(1, 5);
          counts[r]++;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đánh giá thực tế',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1C),
              ),
            ),
            const SizedBox(height: 16),

            // Rating summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        docs.isEmpty ? '—' : avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1C1C),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = i < avg.round();
                          return Icon(
                            filled ? Icons.star : Icons.star_border,
                            color: const Color(0xFFF59E0B),
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${docs.length} đánh giá',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6F7A6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: List.generate(5, (i) {
                        final star = 5 - i;
                        final pct = docs.isEmpty
                            ? 0.0
                            : counts[star] / docs.length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _buildRatingBar(star, pct),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Review cards
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Text(
                  'Chưa có đánh giá nào. Hãy là người đầu tiên!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReviewCard(
                    name: (data['userName'] ?? 'Ẩn danh').toString(),
                    avatar: data['userAvatar']?.toString(),
                    rating: (data['rating'] as num?)?.toInt() ?? 0,
                    time: _timeAgo(data['createdAt'] is Timestamp
                        ? data['createdAt'] as Timestamp
                        : null),
                    content: (data['review'] ?? '').toString(),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$stars',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1C1C),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6F7A6B),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _loadReviews(String courtId) async {
    if (courtId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('fieldId', isEqualTo: courtId)
          .get();
      final docs = snap.docs;
      final avg = docs.isEmpty
          ? 0.0
          : docs.fold<double>(
                  0,
                  (acc, d) =>
                      acc + ((d.data()['rating'] as num?)?.toDouble() ?? 0)) /
              docs.length;
      if (mounted) {
        setState(() {
          _avgRating = avg;
          _reviewCount = docs.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchDistance(Map<String, dynamic> court) async {
    double? lat = (court['latitude'] as num?)?.toDouble();
    double? lng = (court['longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      final facilityId = court['facilityId']?.toString() ?? '';
      if (facilityId.isEmpty) return;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('facilities')
            .doc(facilityId)
            .get();
        final data = doc.data();
        lat = (data?['latitude'] as num?)?.toDouble();
        lng = (data?['longitude'] as num?)?.toDouble();
      } catch (_) {
        return;
      }
    }

    if (lat == null || lng == null) return;

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final km = _distanceKm(pos.latitude, pos.longitude, lat, lng);
      final label = km < 1
          ? '${(km * 1000).round()} m'
          : '${km.toStringAsFixed(1)} km';
      if (mounted) setState(() => _distance = label);
    } catch (_) {}
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * asin(sqrt(a));
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _buildReviewCard({
    required String name,
    String? avatar,
    required int rating,
    required String time,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  (avatar != null && avatar.isNotEmpty)
                      ? Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => Container(
                                color: const Color(0xFFC8E6C9),
                                child: const Icon(Icons.person,
                                    size: 18, color: Color(0xFF4CAF50)),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC8E6C9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          Icons.star,
                          size: 12,
                          color: i < rating
                              ? const Color(0xFFFFA726)
                              : Colors.grey[300],
                        )),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TỔNG THANH TOÁN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF6F7A6B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrency(_totalPrice),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1C1C),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 52,
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
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!_canBook) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_bookBlockReason),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final selectedDate = _dates[_selectedDateIndex];
                          Navigator.pushNamed(
                            context,
                            '/booking-confirmation',
                            arguments: {
                              'court': _court,
                              'selectedSubCourt': _selectedSubCourt,
                              'selectedDate': selectedDate,
                              'selectedSlot': {
                                'startTime': _timeLabel(_startTime!),
                                'endTime': _timeLabel(_endTime!),
                                'price': _totalPrice,
                              },
                              'duration': _durationLabel(_startTime!, _endTime!),
                              'totalPrice': _totalPrice,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _canBook ? 'Đặt sân ngay' : 'Không thể đặt',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _canBook ? Icons.bolt : Icons.block,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
