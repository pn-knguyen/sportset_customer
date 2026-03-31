import 'package:flutter/material.dart';
import 'dart:ui';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final court = _readCourtData(context);
    final images = _resolveImages(court);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
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
    );
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
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, color: Color(0xFF1A237E)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.share, color: Color(0xFF1A237E)),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                        ),
                      ),
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
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
        color: Color(0xFFFFF8F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
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
            _buildReviews(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> court) {
    final ratingValue = court['rating'];
    final rating = ratingValue is num
        ? ratingValue.toStringAsFixed(1)
        : (ratingValue?.toString() ?? '0.0');
    final distance = (court['distance'] ?? '-- km').toString();
    final statusText = _statusLabel(court);
    final statusColor = _statusColor(court);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFFFE0B2)),
          bottom: BorderSide(color: const Color(0xFFFFE0B2)),
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
                    const Icon(Icons.star, color: Color(0xFFFF9800), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            color: const Color(0xFFFFE0B2),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.near_me, color: Color(0xFF1A237E), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      distance,
                      style: TextStyle(
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
            color: const Color(0xFFFFE0B2),
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
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _description(court),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Giá tham khảo: ${_priceLabel(court)}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF9800),
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
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            return Container(
              constraints: const BoxConstraints(minHeight: 34, minWidth: 96),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE0B2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    amenity['icon'],
                    color: const Color(0xFFFF9800),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    amenity['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
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
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 12),
        if (hasDetailPricing) ...[
          _buildPricingGroup(
            title: 'Giá ngày thường',
            items: weekdayPricing,
            emptyText: 'Chưa cập nhật giá ngày thường',
          ),
          const SizedBox(height: 12),
          _buildPricingGroup(
            title: 'Giá cuối tuần',
            items: weekendPricing,
            emptyText: 'Chưa cập nhật giá cuối tuần',
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Text(
              'Giá tham khảo: ${_priceLabel(court)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF9800),
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0B2)),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            )
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pricingTimeRange(item),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatMoney(item['price']),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đánh giá cộng đồng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF9800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewCard(
          name: 'Hoàng Nam',
          avatar: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCKRmp4nEVBG-6uZ-8CWBD4oUrLxTb23Yg-C-i_07c59-76-Z848HbHMok4RKJY3bNQu34c_sal_V2_gKYpo_UVyKgjJ_wleR_H870lmfJZEwHox2Brd0o4fH4KSrJWIoR2hwWfRI1cNkU95hWSboXt_sjVL6TohZZ2O9SfKvxe0_Ej8hm_MWL6V_Y0-YFRZYimbOEoK60_5vS_Z3qdpbYV48_yQHyIMTxiBBeUx2NdjIPTde0xIxHMgef_w4piWWcxIVIKoBasGDoL',
          rating: 5,
          time: '2 ngày trước',
          content: 'Sân đẹp, cỏ mới đá rất êm chân. Nhân viên nhiệt tình, bãi giữ xe thoải mái không phải chờ đợi lâu.',
          images: [
            'https://htsport.vn/wp-content/uploads/2019/12/25-kich-thuoc-san-bong-7-nguoi-2.jpg',
            'https://www.aisedulaos.com/img/Sport-field-ais.jpg',
            'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
          ],
        ),
        const SizedBox(height: 24),
        _buildReviewCard(
          name: 'Minh Tuấn',
          initials: 'MT',
          rating: 4,
          time: '1 tuần trước',
          content: 'Đèn hơi chói một chút ở góc sân số 3, nhưng nhìn chung chất lượng sân rất tốt so với tầm giá.',
        ),
      ],
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE0B2)),
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
                  avatar != null
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFE0B2)),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              avatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE0B2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials ?? '',
                              style: const TextStyle(
                                color: Color(0xFFFF9800),
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
                                ? const Color(0xFFFF9800)
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
              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.4),
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
