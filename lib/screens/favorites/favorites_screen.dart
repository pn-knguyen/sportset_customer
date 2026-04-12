import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Position? _userPosition;
  final Map<String, Map<String, double>> _facilityCoords = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadFacilityCoords();
  }

  Future<void> _getUserLocation() async {
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
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<void> _loadFacilityCoords() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('facilities').get();
      final coords = <String, Map<String, double>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          coords[doc.id] = {'lat': lat, 'lng': lng};
        }
      }
      if (mounted) setState(() => _facilityCoords.addAll(coords));
    } catch (_) {}
  }

  String _calcDistanceLabel(String? facilityId) {
    if (_userPosition == null || facilityId == null || facilityId.isEmpty) {
      return '';
    }
    final coords = _facilityCoords[facilityId];
    if (coords == null) return '';
    final lat2 = coords['lat']!;
    final lng2 = coords['lng']!;
    const r = 6371.0;
    final dLat = (lat2 - _userPosition!.latitude) * pi / 180;
    final dLng = (lng2 - _userPosition!.longitude) * pi / 180;
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final c = 2 *
        asin(sqrt(sinDLat * sinDLat +
            cos(_userPosition!.latitude * pi / 180) *
                cos(lat2 * pi / 180) *
                sinDLng *
                sinDLng));
    final km = r * c;
    return km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
  }

  Future<void> _removeFavorite(String courtId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('favorites')
        .doc(uid)
        .collection('courts')
        .doc(courtId)
        .delete();
  }

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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: uid == null
                  ? const Center(child: Text('Vui lòng đăng nhập để xem yêu thích'))
                  : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('favorites')
                          .doc(uid)
                          .collection('courts')
                          .orderBy('savedAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF4CAF50)));
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Lỗi: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red)));
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return _buildEmptyState();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                'Bạn có ${docs.length} địa điểm đã lưu',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6D6E6D),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildFavoriteCard(data),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có sân yêu thích',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn ❤ trên trang chi tiết sân để lưu',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F5E9), Color(0xF2E8F5E9)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC8E6C9), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: const SizedBox(
          height: 56,
          child: Center(
            child: Text(
              'Sân Yêu Thích',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> venue) {
    final courtId = venue['courtId']?.toString() ?? '';
    final facilityId = venue['facilityId']?.toString() ?? '';
    final distLabel = _calcDistanceLabel(facilityId);

    return GestureDetector(
      onTap: () => _navigateToBooking(courtId),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF5F5F5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    venue['image']?.toString() ?? '',
                    height: 224,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      height: 224,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image,
                          size: 48, color: Colors.grey),
                    ),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: Color(0xFF4CAF50), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          ((venue['rating'] as num?)?.toStringAsFixed(1)) ??
                              '0.0',
                          style: const TextStyle(
                            color: Color(0xFF1A1C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Remove favorite button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => _removeFavorite(courtId),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.red, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            // Content area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venue['name']?.toString() ?? '',
                          style: const TextStyle(
                            color: Color(0xFF1A1C1C),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: venue['price']?.toString() ?? '',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location + distance
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue['address']?.toString() ?? '',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distLabel.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.near_me,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          distLabel,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Book button
                  GestureDetector(
                    onTap: () => _navigateToBooking(courtId),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF4CAF50).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Đặt ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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
