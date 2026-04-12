import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FieldDetailScreen extends StatefulWidget {
  const FieldDetailScreen({super.key});

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  static const String _fallbackImage =
      'https://images.unsplash.com/photo-1577223625816-7546f13df25d?auto=format&fit=crop&w=1200&q=80';

  // Live stats
  double? _avgRating;
  int _reviewCount = 0;
  String? _distance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reviewSub;
  bool _dependenciesLoaded = false;

  // Favorite
  bool _isFavorite = false;
  bool _favoriteLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesLoaded) {
      _dependenciesLoaded = true;
      final court = _readCourtData(context);
      _subscribeReviews(court['id']?.toString() ?? '');
      _fetchDistance(court);
      _loadFavoriteState(court['id']?.toString() ?? '');
    }
  }

  Future<void> _loadFavoriteState(String courtId) async {
    if (courtId.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('favorites')
        .doc(uid)
        .collection('courts')
        .doc(courtId)
        .get();
    if (mounted) setState(() => _isFavorite = doc.exists);
  }

  Future<void> _toggleFavorite(Map<String, dynamic> court) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final courtId = court['id']?.toString() ?? '';
    if (courtId.isEmpty) return;
    setState(() => _favoriteLoading = true);
    final ref = FirebaseFirestore.instance
        .collection('favorites')
        .doc(uid)
        .collection('courts')
        .doc(courtId);
    try {
      if (_isFavorite) {
        await ref.delete();
        if (mounted) setState(() => _isFavorite = false);
      } else {
        final image = (court['imageUrl'] ?? court['image'] ?? '').toString();
        final priceVal = court['pricePerHour'] ?? court['price'];
        String price = '';
        if (priceVal is num) {
          price = priceVal >= 1000
              ? '${(priceVal / 1000).round()}K/h'
              : '${priceVal.round()}/h';
        } else {
          price = priceVal?.toString() ?? '';
        }
        await ref.set({
          'courtId': courtId,
          'name': court['name']?.toString() ?? '',
          'image': image,
          'address': court['address']?.toString() ?? '',
          'rating': (court['rating'] as num?)?.toDouble() ?? 0.0,
          'price': price,
          'facilityId': court['facilityId']?.toString() ?? '',
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) setState(() => _isFavorite = true);
      }
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  void _subscribeReviews(String courtId) {
    if (courtId.isEmpty) return;
    _reviewSub?.cancel();
    _reviewSub = FirebaseFirestore.instance
        .collection('reviews')
        .where('fieldId', isEqualTo: courtId)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;
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
    });
  }

  Future<void> _fetchDistance(Map<String, dynamic> court) async {
    // Try lat/lng directly on court first, else fetch from parent facility
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

  double _distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final c = 2 *
        asin(sqrt(sinDLat * sinDLat +
            cos(lat1 * pi / 180) *
                cos(lat2 * pi / 180) *
                sinDLng *
                sinDLng));
    return r * c;
  }

  @override
  void dispose() {
    _reviewSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final court = _readCourtData(context);
    final images = _resolveImages(court);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E9), Colors.white],
        ),
      ),
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageCarousel(images),
                _buildContent(court),
                const SizedBox(height: 100),
              ],
            ),
          ),
          _buildFloatingHeader(),
          _buildBottomBar(),
        ],
      ),
    ));
  }

  Map<String, dynamic> _readCourtData(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final nested = args['court'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      return args;
    }
    return <String, dynamic>{};
  }

  List<String> _resolveImages(Map<String, dynamic> court) {
    final rawImages = court['images'];
    final output = <String>[];

    if (rawImages is List) {
      for (final item in rawImages) {
        final text = item?.toString() ?? '';
        if (text.isNotEmpty) {
          output.add(text);
        }
      }
    }

    final imageUrl = court['imageUrl']?.toString() ?? '';
    if (imageUrl.isNotEmpty && !output.contains(imageUrl)) {
      output.add(imageUrl);
    }

    final image = court['image']?.toString() ?? '';
    if (image.isNotEmpty && !output.contains(image)) {
      output.add(image);
    }

    if (output.isEmpty) {
      output.add(_fallbackImage);
    }

    if (_currentImageIndex >= output.length) {
      _currentImageIndex = 0;
    }

    return output;
  }

  List<Map<String, dynamic>> _resolveAmenities(Map<String, dynamic> court) {
    final raw = court['amenities'];
    if (raw is List) {
      final amenities = raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .map((item) => <String, dynamic>{
                'icon': _amenityIconFor(item),
                'label': item,
              })
          .toList();

      if (amenities.isNotEmpty) {
        return amenities;
      }
    }

    return [
      {'icon': Icons.local_parking, 'label': 'Bãi xe'},
      {'icon': Icons.wifi, 'label': 'Wifi'},
      {'icon': Icons.sports, 'label': 'Dụng cụ'},
      {'icon': Icons.support_agent, 'label': 'Hỗ trợ'},
    ];
  }

  IconData _amenityIconFor(String label) {
    final normalized = _normalizeText(label);

    if (normalized.contains('wifi') || normalized.contains('wi-fi')) {
      return Icons.wifi;
    }
    if (normalized.contains('gui xe') ||
        normalized.contains('bai xe') ||
        normalized.contains('parking')) {
      return Icons.local_parking;
    }
    if (normalized.contains('nuoc') ||
        normalized.contains('nuoc uong') ||
        normalized.contains('giai khat') ||
        normalized.contains('drink')) {
      return Icons.local_drink;
    }
    if (normalized.contains('tam') || normalized.contains('shower')) {
      return Icons.shower;
    }
    if (normalized.contains('phong thay do') ||
        normalized.contains('thay do') ||
        normalized.contains('locker')) {
      return Icons.checkroom;
    }
    if (normalized.contains('wc') ||
        normalized.contains('ve sinh') ||
        normalized.contains('toilet')) {
      return Icons.wc;
    }
    if (normalized.contains('nha ve sinh')) {
      return Icons.wc;
    }
    if (normalized.contains('den') || normalized.contains('lighting')) {
      return Icons.lightbulb;
    }
    if (normalized.contains('huan luyen') ||
        normalized.contains('coach') ||
        normalized.contains('trong tai')) {
      return Icons.groups;
    }
    if (normalized.contains('dung cu') ||
        normalized.contains('vot') ||
        normalized.contains('bong') ||
        normalized.contains('thue')) {
      return Icons.sports;
    }
    if (normalized.contains('bao ho') || normalized.contains('y te')) {
      return Icons.health_and_safety;
    }

    return Icons.check_circle;
  }

  String _normalizeText(String input) {
    final lower = input.toLowerCase().trim();
    const replacements = {
      'a': 'a',
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }

  String _statusLabel(Map<String, dynamic> court) {
    final status = (court['status'] ?? '').toString().trim().toLowerCase();
    switch (status) {
      case 'available':
        return 'Mở cửa';
      case 'maintenance':
        return 'Bảo trì';
      case 'closed':
        return 'Đóng cửa';
      default:
        return status.isEmpty ? 'Chưa rõ' : status;
    }
  }

  Color _statusColor(Map<String, dynamic> court) {
    final status = (court['status'] ?? '').toString().trim().toLowerCase();
    switch (status) {
      case 'available':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _description(Map<String, dynamic> court) {
    final description = (court['description'] ?? '').toString().trim();
    if (description.isNotEmpty) {
      return description;
    }
    final facilityName = (court['facilityName'] ?? '').toString().trim();
    if (facilityName.isNotEmpty) {
      return 'Sân thuộc $facilityName, hiện chưa có mô tả chi tiết.';
    }
    return 'Sân hiện chưa có mô tả chi tiết.';
  }

  String _priceLabel(Map<String, dynamic> court) {
    final value = court['pricePerHour'] ?? court['price'];
    if (value is num) {
      if (value >= 1000) {
        return '${(value / 1000).round()}K/h';
      }
      return '${value.round()}/h';
    }
    final text = value?.toString() ?? '';
    return text.isEmpty ? 'Liên hệ' : text;
  }

  List<Map<String, dynamic>> _normalizePricing(dynamic raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }

    return raw
        .whereType<Map>()
        .map((item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ))
        .toList();
  }

  String _formatMoney(dynamic value) {
    if (value is num) {
      return '${value.toStringAsFixed(0)} đ';
    }
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Liên hệ' : text;
  }

  String _pricingTimeRange(Map<String, dynamic> item) {
    final start = (item['startTime'] ?? '').toString().trim();
    final end = (item['endTime'] ?? '').toString().trim();
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    }
    if (start.isNotEmpty) {
      return 'Từ $start';
    }
    if (end.isNotEmpty) {
      return 'Đến $end';
    }
    return 'Khung giờ linh hoạt';
  }

  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: _favoriteLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red),
                          )
                        : IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              final court = _readCourtData(context);
                              _toggleFavorite(court);
                            },
                            padding: EdgeInsets.zero,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              if (_currentImageIndex != index) {
                setState(() {
                  _currentImageIndex = index;
                });
              }
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
              );
            },
          ),
          // Gradient overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(images.length, (index) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> court) {
    final name = (court['name'] ?? 'Chưa có tên sân').toString();
    final address = (court['address'] ?? 'Chưa cập nhật địa chỉ').toString();
    final facilityName = (court['facilityName'] ?? '').toString().trim();
    final sportType = (court['sportType'] ?? '').toString().trim();

    return Container(
      transform: Matrix4.translationValues(0, -16, 0),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1C),
              ),
            ),
            if (facilityName.isNotEmpty || sportType.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                [facilityName, sportType]
                    .where((item) => item.isNotEmpty)
                    .join(' • '),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatsRow(court),
            const SizedBox(height: 16),
            _buildIntroduction(court),
            const SizedBox(height: 20),
            _buildPricingSection(court),
            const SizedBox(height: 20),
            _buildAmenities(court),
            const SizedBox(height: 12),
            _buildReviews(court['id']?.toString() ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> court) {
    final ratingDisplay = _avgRating != null
        ? _avgRating!.toStringAsFixed(1)
        : (() {
            final v = court['rating'];
            return v is num ? v.toStringAsFixed(1) : (v?.toString() ?? '--');
          })();
    final reviewLabel = _reviewCount > 0 ? '($_reviewCount)' : '';
    final distance = _distance ?? (court['distance']?.toString() ?? '--');
    final statusText = _statusLabel(court);
    final statusColor = _statusColor(court);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFC8E6C9)),
          bottom: BorderSide(color: const Color(0xFFC8E6C9)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFF4CAF50), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      ratingDisplay,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reviewLabel.isNotEmpty) ...[                      const SizedBox(width: 2),
                      Text(
                        reviewLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ĐÁNH GIÁ',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFC8E6C9),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.near_me, color: Color(0xFF4CAF50), size: 18),
                    const SizedBox(width: 4),
                    _distance == null &&
                            ((court['latitude'] as num?) != null ||
                                (court['facilityId']?.toString() ?? '').isNotEmpty)
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF4CAF50),
                            ),
                          )
                        : Text(
                            distance,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'KHOẢNG CÁCH',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFC8E6C9),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: statusColor, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'TRẠNG THÁI',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroduction(Map<String, dynamic> court) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giới thiệu sân',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              left: BorderSide(color: Color(0xFF4CAF50), width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _description(court),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Giá tham khảo: ${_priceLabel(court)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4CAF50),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(Map<String, dynamic> court) {
    final amenities = _resolveAmenities(court);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích dịch vụ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1C),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3.0,
          children: amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18A5A7).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      amenity['icon'] as IconData,
                      color: const Color(0xFF18A5A7),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      amenity['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1C),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPricingSection(Map<String, dynamic> court) {
    final weekdayPricing = _normalizePricing(court['weekdayPricing']);
    final weekendPricing = _normalizePricing(court['weekendPricing']);
    final hasDetailPricing = weekdayPricing.isNotEmpty || weekendPricing.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bảng giá theo ngày',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1C),
          ),
        ),
        const SizedBox(height: 12),
        if (hasDetailPricing) ...[
          // Weekday header
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 20, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text(
                'BẢNG GIÁ NGÀY THƯỜNG',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPricingGroup(
            title: 'Giá ngày thường',
            items: weekdayPricing,
            emptyText: 'Chưa cập nhật giá ngày thường',
            isWeekend: false,
          ),
          const SizedBox(height: 16),
          // Weekend header
          Row(
            children: [
              const Icon(Icons.event_available, size: 20, color: Color(0xFFBA1A1A)),
              const SizedBox(width: 8),
              Text(
                'BẢNG GIÁ CUỐI TUẦN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPricingGroup(
            title: 'Giá cuối tuần',
            items: weekendPricing,
            emptyText: 'Chưa cập nhật giá cuối tuần',
            isWeekend: true,
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Text(
              'Giá tham khảo: ${_priceLabel(court)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPricingGroup({
    required String title,
    required List<Map<String, dynamic>> items,
    required String emptyText,
    bool isWeekend = false,
  }) {
    const weekendColor = Color(0xFFBA1A1A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
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
          if (items.isEmpty)
            Text(
              emptyText,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              Color itemColor;
              Color itemBg;
              Color itemBorder;
              IconData timeIcon;

              if (isWeekend) {
                itemColor = weekendColor;
                itemBg = weekendColor.withValues(alpha: 0.05);
                itemBorder = weekendColor.withValues(alpha: 0.1);
                timeIcon = Icons.wb_sunny;
              } else if (index == 0) {
                itemColor = const Color(0xFF4CAF50);
                itemBg = const Color(0xFF4CAF50).withValues(alpha: 0.05);
                itemBorder = const Color(0xFF4CAF50).withValues(alpha: 0.1);
                timeIcon = Icons.wb_sunny;
              } else if (index == items.length - 1) {
                itemColor = const Color(0xFF18A5A7);
                itemBg = const Color(0xFF18A5A7).withValues(alpha: 0.05);
                itemBorder = const Color(0xFF18A5A7).withValues(alpha: 0.1);
                timeIcon = Icons.dark_mode;
              } else {
                itemColor = const Color(0xFFF59E0B);
                itemBg = Colors.white.withValues(alpha: 0.5);
                itemBorder = const Color(0xFF6F7A6B).withValues(alpha: 0.1);
                timeIcon = Icons.light_mode;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: itemBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: itemBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(timeIcon, color: itemColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pricingTimeRange(item),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1C),
                          ),
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _formatMoney(item['price']),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: itemColor,
                              ),
                            ),
                            TextSpan(
                              text: '/giờ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
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

  Widget _buildReviews(String courtId) {
    if (courtId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('fieldId', isEqualTo: courtId)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Lỗi tải đánh giá: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }
        final docs = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final ta = a.data()['createdAt'];
            final tb = b.data()['createdAt'];
            if (ta is Timestamp && tb is Timestamp) {
              return tb.compareTo(ta);
            }
            return 0;
          });

        final avgRating = docs.isEmpty
            ? 0.0
            : docs.fold<double>(
                    0,
                    (acc, d) =>
                        acc + ((d.data()['rating'] as num?)?.toDouble() ?? 0)) /
                docs.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đánh giá cộng đồng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    if (docs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Color(0xFF4CAF50)),
                            const SizedBox(width: 4),
                            Text(
                              '${avgRating.toStringAsFixed(1)} (${docs.length} đánh giá)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Text(
                  'Chưa có đánh giá nào. Hãy là người đầu tiên!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data();
                final rawImages = data['images'];
                final images = rawImages is List
                    ? rawImages
                        .map((e) => e.toString())
                        .where((e) => e.isNotEmpty)
                        .toList()
                    : <String>[];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildReviewCard(
                    name: (data['userName'] ?? 'Ẩn danh').toString(),
                    avatar: (data['userAvatar'] ?? '').toString(),
                    rating: (data['rating'] as num?)?.toInt() ?? 0,
                    time: _timeAgo(data['createdAt'] is Timestamp ? data['createdAt'] as Timestamp : null),
                    content: (data['review'] ?? '').toString(),
                    images: images,
                    replied: data['replied'] == true,
                    reply: data['reply']?.toString(),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard({
    required String name,
    String? avatar,
    String? initials,
    required int rating,
    required String time,
    required String content,
    List<String>? images,
    bool replied = false,
    String? reply,
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => Container(
                                color: const Color(0xFFC8E6C9),
                                child: const Icon(Icons.person,
                                    size: 20, color: Color(0xFF4CAF50)),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC8E6C9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials ?? '',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 12,
                            color: index < rating
                                ? const Color(0xFFFFA726)
                                : Colors.grey[300],
                          );
                        }),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          if (replied && reply != null && reply.isNotEmpty) ...[  
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFF4CAF50), width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PHẢN HỒI CỦA CHỦ SÂN:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E7D32),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reply,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (images != null && images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/booking',
                  arguments: {
                    'court': _readCourtData(context),
                  },
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kiểm tra lịch & Đặt ngay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}
