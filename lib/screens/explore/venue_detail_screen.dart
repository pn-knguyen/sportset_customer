import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({super.key});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  static const String _fallbackImage =
      'https://images.unsplash.com/photo-1577223625816-7546f13df25d?auto=format&fit=crop&w=1200&q=80';

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? fallback;
    return fallback;
  }

  String _priceLabel(dynamic value) {
    if (value is num) {
      if (value >= 1000) return '${(value / 1000).round()}K/h';
      return '${value.round()}/h';
    }
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Liên hệ' : text;
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'maintenance':
        return Colors.green;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _normalizeText(String input) {
    final lower = input.toLowerCase().trim();
    const replacements = {
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'đ': 'd',
    };
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }

  IconData _amenityIconFor(String label) {
    final n = _normalizeText(label);
    if (n.contains('wifi') || n.contains('wi-fi')) return Icons.wifi;
    if (n.contains('gui xe') || n.contains('bai xe') || n.contains('parking')) return Icons.local_parking;
    if (n.contains('nuoc') || n.contains('giai khat') || n.contains('drink')) return Icons.local_drink;
    if (n.contains('tam') || n.contains('shower')) return Icons.shower;
    if (n.contains('thay do') || n.contains('locker')) return Icons.checkroom;
    if (n.contains('ve sinh') || n.contains('wc') || n.contains('toilet')) return Icons.wc;
    if (n.contains('den') || n.contains('lighting')) return Icons.lightbulb;
    if (n.contains('huan luyen') || n.contains('coach') || n.contains('trong tai')) return Icons.groups;
    if (n.contains('dung cu') || n.contains('vot') || n.contains('bong') || n.contains('thue')) return Icons.sports;
    if (n.contains('bao ho') || n.contains('y te')) return Icons.health_and_safety;
    return Icons.check_circle;
  }

  List<Map<String, dynamic>> _resolveAmenities(dynamic raw) {
    if (raw is List) {
      final list = raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .map((e) => <String, dynamic>{'icon': _amenityIconFor(e), 'label': e})
          .toList();
      if (list.isNotEmpty) return list;
    }
    return const [];
  }

  IconData _sportIcon(String sportType) {
    final s = sportType.toLowerCase();
    if (s.contains('bóng đá') || s.contains('bong da') || s.contains('football') || s.contains('soccer')) {
      return Icons.sports_soccer;
    }
    if (s.contains('cầu lông') || s.contains('cau long') || s.contains('badminton')) {
      return Icons.sports_tennis;
    }
    if (s.contains('bóng rổ') || s.contains('bong ro') || s.contains('basketball')) {
      return Icons.sports_basketball;
    }
    if (s.contains('tennis')) {
      return Icons.sports_tennis;
    }
    if (s.contains('bóng chuyền') || s.contains('bong chuyen') || s.contains('volleyball')) {
      return Icons.sports_volleyball;
    }
    if (s.contains('bơi') || s.contains('swimming') || s.contains('pool')) {
      return Icons.pool;
    }
    if (s.contains('gym') || s.contains('fitness') || s.contains('thể hình')) {
      return Icons.fitness_center;
    }
    return Icons.sports;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final venueId = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('facilities')
            .doc(venueId)
            .snapshots(),
        builder: (context, venueSnap) {
          if (venueSnap.connectionState == ConnectionState.waiting &&
              !venueSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final venueData = venueSnap.data?.data() ?? {};
          final name = venueData['name']?.toString() ?? 'Cơ sở thể thao';
          final imageUrl = venueData['imageUrl']?.toString() ??
              venueData['image']?.toString() ??
              _fallbackImage;
          final address =
              venueData['address']?.toString() ?? 'Chưa cập nhật địa chỉ';
          final rating = _toDouble(venueData['rating']);
          final openTime = venueData['openTime']?.toString() ?? '';
          final closeTime = venueData['closeTime']?.toString() ?? '';
          final phone = venueData['phone']?.toString() ?? '';
          final description = venueData['description']?.toString() ?? '';
          final amenities = _resolveAmenities(venueData['amenities']);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildSliverHeader(imageUrl, name),
                  SliverToBoxAdapter(
                    child: _buildVenueInfo(
                      name: name,
                      address: address,
                      rating: rating,
                      openTime: openTime,
                      closeTime: closeTime,
                      phone: phone,
                      description: description,
                      amenities: amenities,
                    ),
                  ),
                  _buildCourtsSection(venueId),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
              _buildFloatingBack(),
            ],
          );
        },
      ),
    );
  }

  // ── Sliver header ─────────────────────────────────────────────────────────

  Widget _buildSliverHeader(String imageUrl, String name) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Floating back button ──────────────────────────────────────────────────

  Widget _buildFloatingBack() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
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
                      icon: const Icon(Icons.chevron_left,
                          color: Color(0xFF1A237E)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
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

  // ── Venue info block ──────────────────────────────────────────────────────

  Widget _buildVenueInfo({
    required String name,
    required String address,
    required double rating,
    required String openTime,
    required String closeTime,
    required String phone,
    required String description,
    required List<Map<String, dynamic>> amenities,
  }) {
    final hours =
        openTime.isNotEmpty && closeTime.isNotEmpty ? '$openTime - $closeTime' : 'Liên hệ';

    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + rating row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              if (rating > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Color(0xFF4CAF50), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Hours
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                hours,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: 20),
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
                    border: Border.all(color: const Color(0xFFC8E6C9)),
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
                        amenity['icon'] as IconData,
                        color: const Color(0xFF4CAF50),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amenity['label'] as String,
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
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFC8E6C9)),
        ],
      ),
    );
  }

  // ── Courts section ────────────────────────────────────────────────────────

  Widget _buildCourtsSection(String venueId) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Danh sách sân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('courts')
                  .where('facilityId', isEqualTo: venueId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snap.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Không thể tải danh sách sân'),
                    ),
                  );
                }

                final courts = snap.data?.docs ?? [];

                if (courts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.sports, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          'Cơ sở chưa có sân nào',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: courts.map((doc) {
                    final data = Map<String, dynamic>.from(doc.data());
                    data['id'] = doc.id;
                    return _buildCourtCard(data);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Court card ────────────────────────────────────────────────────────────

  Widget _buildCourtCard(Map<String, dynamic> court) {
    final courtName = court['name']?.toString() ?? 'Sân thể thao';
    final sportType = court['sportType']?.toString() ?? '';
    final status = court['status']?.toString() ?? '';
    final price = _priceLabel(court['pricePerHour'] ?? court['price']);
    final imageUrl = court['imageUrl']?.toString() ??
        court['image']?.toString() ??
        _fallbackImage;
    final rating = _toDouble(court['rating']);
    final statusText = _statusLabel(status);
    final statusColor = _statusColor(status);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/field-detail',
        arguments: {'court': court},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: Image.network(
                imageUrl,
                width: 100,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 110,
                  color: Colors.grey[200],
                  child:
                      const Icon(Icons.image, color: Colors.grey, size: 28),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courtName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A237E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sportType.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(_sportIcon(sportType),
                              size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            sportType,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            price,
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (rating > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              size: 12, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 3),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right,
                  color: Colors.grey[400], size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
