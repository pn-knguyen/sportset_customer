import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookedSlots());
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

  List<TimeOfDay> get _timeSlots {
    final startMin = _toMinutes(_operatingStart);
    final endMin = _toMinutes(_operatingEnd);
    final slots = <TimeOfDay>[];
    for (int m = startMin; m < endMin; m += 30) {
      slots.add(TimeOfDay(hour: m ~/ 60, minute: m % 60));
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
            return d['date']?.toString() == selectedDate['date']?.toString() &&
                d['month']?.toString() == selectedDate['month']?.toString();
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
      backgroundColor: const Color(0xFFFFF8F6),
      body: Stack(
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
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 380,
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
                    height: 380,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 128,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFFFF8F6),
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
            bottom: 24,
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
                        ? const Color(0xFFf4ab25)
                        : Colors.white.withValues(alpha: 0.6),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: color ?? const Color(0xFF1c170d),
              size: 24,
            ),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
          ),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          courtName,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
            letterSpacing: -0.5,
          ),
        ),
        if (facilityName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            facilityName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFf4ab25),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 14,
              color: Color(0xFF9c7f49),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9c7f49),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFe8dfce), width: 1),
              bottom: BorderSide(color: Color(0xFFe8dfce), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFf4ab25).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: Color(0xFFf4ab25),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1c170d),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '(đánh giá cộng đồng)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9c7f49),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _isAvailableStatus(status)
                      ? 'Đang nhận đặt lịch'
                      : 'Tạm ngưng nhận đặt',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isAvailableStatus(status) ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    final amenitiesSource = _court['amenities'];
    final amenities = <String>[];
    if (amenitiesSource is List) {
      for (final item in amenitiesSource) {
        final text = item?.toString() ?? '';
        if (text.isNotEmpty) {
          amenities.add(text);
        }
      }
    }
    if (amenities.isEmpty) {
      amenities.addAll(['Wifi', 'Nước uống', 'Gửi xe']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích sân',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: amenities.map((amenity) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFe8dfce),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _amenityIcon(amenity),
                        color: const Color(0xFFf4ab25),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 76,
                      child: Text(
                        amenity,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1c170d).withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFf4ab25)
                      : (isAvailable ? Colors.white : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFf4ab25)
                        : const Color(0xFFe8dfce),
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
                          : (isAvailable ? Colors.green : Colors.red),
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
                                ? const Color(0xFF1c170d)
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
                color: Color(0xFF1c170d),
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
              final isWeekend = date['isWeekend'] as bool;

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
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: const Color(0xFFe8dfce),
                            width: 1,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFf4ab25).withValues(alpha: 0.3),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isWeekend
                                  ? Colors.red
                                  : const Color(0xFF1c170d).withValues(alpha: 0.6)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date['date'] as String,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isWeekend ? Colors.red : const Color(0xFF1c170d)),
                        ),
                      ),
                      Text(
                        '/${date['month']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF9c7f49),
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
                color: Color(0xFF1c170d),
              ),
            ),
            const Spacer(),
            if (_isLoadingBookings)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFf4ab25)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Legend
        Row(
          children: [
            _buildLegendChip(Colors.white, const Color(0xFFe8dfce), 'Còn trống'),
            const SizedBox(width: 10),
            _buildLegendChip(
                const Color(0xFFf4ab25).withValues(alpha: 0.2),
                const Color(0xFFf4ab25),
                'Đã chọn'),
            const SizedBox(width: 10),
            _buildLegendChip(
                Colors.red.shade50, Colors.red.shade200, 'Đã đặt'),
          ],
        ),
        const SizedBox(height: 20),

        // ── Start time ────────────────────────────────────────────────────
        const Text(
          'GIỜ BẮT ĐẦU',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9c7f49),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Hiện chưa có khung giờ khả dụng cho ngày này.',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9c7f49),
                  fontWeight: FontWeight.w600),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((t) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isBooked
                        ? Colors.red.shade50
                        : (inRange
                            ? const Color(0xFFFFE0B2)
                            : (isSelected ? null : Colors.white)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isBooked
                          ? Colors.red.shade200
                          : (isSelected
                              ? Colors.transparent
                              : (inRange
                                  ? const Color(0xFFf4ab25)
                                  : const Color(0xFFe8dfce))),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFf4ab25)
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    _timeLabel(t),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isBooked
                          ? Colors.red.shade300
                          : (isSelected
                              ? Colors.white
                              : const Color(0xFF1c170d)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        // ── End time (shown after start is selected) ──────────────────────
        if (_startTime != null) ...[
          const SizedBox(height: 24),
          const Text(
            'GIỜ KẾT THÚC',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9c7f49),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final endTs = _validEndTimes(_startTime!);
            if (endTs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Không có giờ kết thúc khả dụng từ giờ này.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9c7f49)),
                ),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: endTs.map((t) {
                final isSelected = _endTime != null &&
                    _toMinutes(_endTime!) == _toMinutes(t);
                return GestureDetector(
                  onTap: () => setState(() => _endTime = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : const Color(0xFFe8dfce),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFf4ab25)
                                    .withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      _timeLabel(t),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1c170d),
                      ),
                    ),
                  ),
                );
              }).toList(),
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

  Widget _buildLegendChip(Color bg, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFf4ab25).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range + duration badge
          Row(
            children: [
              const Icon(Icons.schedule,
                  color: Color(0xFFf4ab25), size: 18),
              const SizedBox(width: 8),
              Text(
                '${_timeLabel(_startTime!)}  →  ${_timeLabel(_endTime!)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1c170d),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFf4ab25).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFff4d00),
                  ),
                ),
              ),
            ],
          ),
          // Price breakdown (only when multiple pricing slots are crossed)
          if (breakdown.length > 1) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFFFE0B2)),
            const SizedBox(height: 8),
            ...breakdown.map((item) {
              final h = (item['mins'] as int) ~/ 60;
              final m = (item['mins'] as int) % 60;
              final timeStr =
                  '${h > 0 ? "${h}h " : ""}${m > 0 ? "${m}ph" : ""}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(item['label'] as String,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 6),
                    Text('($timeStr)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500])),
                    const Spacer(),
                    Text(
                      _formatCurrency(item['amount'] as int),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 1, color: Color(0xFFFFE0B2)),
            const SizedBox(height: 6),
          ] else
            const SizedBox(height: 10),
          // Total
          Row(
            children: [
              const Text(
                'Tổng cộng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1c170d),
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFff4d00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá thực tế',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFe8dfce),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1c170d),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < 4 ? Icons.star : Icons.star_half,
                        color: const Color(0xFFf4ab25),
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '120 reviews',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1c170d).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.75),
                    const SizedBox(height: 8),
                    _buildRatingBar(4, 0.15),
                    const SizedBox(height: 8),
                    _buildRatingBar(3, 0.05),
                    const SizedBox(height: 8),
                    _buildRatingBar(2, 0.03),
                    const SizedBox(height: 8),
                    _buildRatingBar(1, 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
              color: Color(0xFF1c170d),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFe8dfce),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFf4ab25),
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
              color: Color(0xFF9c7f49),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 36),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
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
                        color: const Color(0xFF1c170d).withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_totalPrice),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1c170d),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFf4ab25).withValues(alpha: 0.35),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
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
                        borderRadius: BorderRadius.circular(28),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _canBook ? 'Đặt sân ngay' : 'Không thể đặt',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _canBook ? Icons.bolt : Icons.block,
                              color: Colors.white,
                              size: 20,
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
      ),
    );
  }
}
