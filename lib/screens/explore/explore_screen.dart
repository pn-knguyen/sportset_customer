import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);
  static const double _nearbyRadiusKm = 15.0;

  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController =
      PageController(viewportFraction: 0.88);

  GoogleMapController? _mapController;
  LatLng? _userLocation;
  bool _isLocating = false;
  int _selectedIndex = -1;

  // Ratings computed from reviews grouped by facilityId
  Map<String, String> _courtFacilityMap = {}; // courtId → facilityId
  Map<String, double> _facilityRatings = {};
  Map<String, int> _facilityReviewCounts = {};
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _reviewDocs = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _courtSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reviewSub;

  // ── Helpers ──────────────────────────────────────────────────────────────

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> _facilityFromDoc(
      Map<String, dynamic> data, String docId) {
    return {
      'id': docId,
      'name': data['name']?.toString() ?? 'Chưa có tên cơ sở',
      'image': data['imageUrl']?.toString() ??
          data['image']?.toString() ??
          'https://images.unsplash.com/photo-1577223625816-7546f13df25d?auto=format&fit=crop&w=1200&q=80',
      'rating': _toDouble(data['rating'], fallback: 0),
      'address': data['address']?.toString() ?? 'Chưa cập nhật địa chỉ',
      'openTime': data['openTime']?.toString() ?? '',
      'closeTime': data['closeTime']?.toString() ?? '',
      'latitude': (data['latitude'] as num?)?.toDouble(),
      'longitude': (data['longitude'] as num?)?.toDouble(),
      'detailData': Map<String, dynamic>.from(data)..['id'] = docId,
    };
  }

  double _distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final sinDLat = sin(dLat / 2);
    final sinDLng = sin(dLng / 2);
    final c = 2 *
        asin(sqrt(sinDLat * sinDLat +
            cos(a.latitude * pi / 180) *
                cos(b.latitude * pi / 180) *
                sinDLng *
                sinDLng));
    return r * c;
  }

  String _distanceLabel(LatLng? from, double? lat, double? lng) {
    if (from == null || lat == null || lng == null) return '';
    final km = _distanceKm(from, LatLng(lat, lng));
    return km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
  }

  List<Map<String, dynamic>> _filteredVenues(List<Map<String, dynamic>> all) {
    final query = _searchController.text.trim().toLowerCase();
    return all.where((v) {
      if (query.isNotEmpty) {
        final text = '${v['name']} ${v['address']}'.toLowerCase();
        if (!text.contains(query)) return false;
      }
      final lat = v['latitude'] as double?;
      final lng = v['longitude'] as double?;
      if (_userLocation != null && lat != null && lng != null) {
        final d = _distanceKm(_userLocation!, LatLng(lat, lng));
        if (d > _nearbyRadiusKm) return false;
      }
      return true;
    }).toList();
  }

  // ── Location ─────────────────────────────────────────────────────────────

  Future<void> _getUserLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _isLocating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = ll;
        _isLocating = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: ll, zoom: 13)),
      );
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onMarkerTap(int index, LatLng pos) {
    setState(() => _selectedIndex = index);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 15)),
    );
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index, List<Map<String, dynamic>> venues) {
    setState(() => _selectedIndex = index);
    final lat = venues[index]['latitude'] as double?;
    final lng = venues[index]['longitude'] as double?;
    if (lat != null && lng != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15),
        ),
      );
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void _subscribeCourtsAndReviews() {
    _courtSub = FirebaseFirestore.instance
        .collection('courts')
        .snapshots()
        .listen((snap) {
      _courtFacilityMap = {
        for (final doc in snap.docs)
          doc.id: doc.data()['facilityId']?.toString() ?? ''
      };
      _recomputeFacilityRatings();
    });

    _reviewSub = FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snap) {
      _reviewDocs = snap.docs;
      _recomputeFacilityRatings();
    });
  }

  void _recomputeFacilityRatings() {
    final buckets = <String, List<double>>{};
    for (final doc in _reviewDocs) {
      final data = doc.data();
      final courtId = data['fieldId']?.toString() ?? '';
      final facilityId = _courtFacilityMap[courtId] ?? '';
      final r = (data['rating'] as num?)?.toDouble();
      if (facilityId.isNotEmpty && r != null) {
        buckets.putIfAbsent(facilityId, () => []).add(r);
      }
    }
    if (!mounted) return;
    setState(() {
      _facilityRatings.clear();
      _facilityReviewCounts.clear();
      for (final entry in buckets.entries) {
        _facilityReviewCounts[entry.key] = entry.value.length;
        _facilityRatings[entry.key] =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _getUserLocation());
    _subscribeCourtsAndReviews();
  }

  @override
  void dispose() {
    _courtSub?.cancel();
    _reviewSub?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('facilities')
            .snapshots(),
        builder: (context, snap) {
          final all = snap.data?.docs
                  .map((d) => _facilityFromDoc(d.data(), d.id))
                  .toList() ??
              [];
          final venues = _filteredVenues(all);

          return Stack(
            children: [
              _buildMap(venues),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopPanel(venues.length),
              ),
              Positioned(
                right: 16,
                bottom: venues.isEmpty ? 24 : 200,
                child: _buildGpsButton(),
              ),
              if (venues.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomCards(venues),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap(List<Map<String, dynamic>> venues) {
    final markers = <Marker>{};
    for (var i = 0; i < venues.length; i++) {
      final v = venues[i];
      final lat = v['latitude'] as double?;
      final lng = v['longitude'] as double?;
      if (lat == null || lng == null) continue;
      final isSelected = i == _selectedIndex;
      markers.add(Marker(
        markerId: MarkerId(v['id'] as String),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen,
        ),
        zIndex: isSelected ? 1 : 0,
        onTap: () => _onMarkerTap(i, LatLng(lat, lng)),
      ));
    }

    final circles = <Circle>{};
    if (_userLocation != null) {
      circles.add(Circle(
        circleId: const CircleId('radius'),
        center: _userLocation!,
        radius: _nearbyRadiusKm * 1000,
        strokeColor: const Color(0xFF4CAF50),
        strokeWidth: 1,
        fillColor: const Color(0xFF4CAF50).withValues(alpha: 0.06),
      ));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _userLocation ?? _defaultCenter,
        zoom: 12,
      ),
      onMapCreated: (c) => _mapController = c,
      markers: markers,
      circles: circles,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onTap: (_) => setState(() => _selectedIndex = -1),
    );
  }

  // ── Top panel ─────────────────────────────────────────────────────────────

  Widget _buildTopPanel(int count) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _selectedIndex = -1),
                  decoration: InputDecoration(
                    hintText: 'Tìm cơ sở, khu vực...',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1A237E)),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _selectedIndex = -1);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child:
                        Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1C46),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me,
                        size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '$count cơ sở',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GPS button ─────────────────────────────────────────────────────────────

  Widget _buildGpsButton() {
    return FloatingActionButton.small(
      onPressed: _isLocating ? null : _getUserLocation,
      backgroundColor: Colors.white,
      elevation: 4,
      child: _isLocating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0C1C46),
              ),
            )
          : const Icon(Icons.my_location,
              color: Color(0xFF0C1C46), size: 20),
    );
  }

  // ── Bottom cards ──────────────────────────────────────────────────────────

  Widget _buildBottomCards(List<Map<String, dynamic>> venues) {
    return Container(
      height: 180,
      padding: const EdgeInsets.only(bottom: 12),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => _onPageChanged(i, venues),
        itemCount: venues.length,
        itemBuilder: (ctx, i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _buildVenueCard(venues[i], i == _selectedIndex),
          );
        },
      ),
    );
  }

  Widget _buildVenueCard(Map<String, dynamic> v, bool isSelected) {
    final distLabel = _distanceLabel(
      _userLocation,
      v['latitude'] as double?,
      v['longitude'] as double?,
    );
    final open = v['openTime'] as String;
    final close = v['closeTime'] as String;
    final hours =
        open.isNotEmpty && close.isNotEmpty ? '$open - $close' : 'Liên hệ';
    final facilityId = v['id'] as String? ?? '';
    final avgRating = _facilityRatings[facilityId];
    final reviewCount = _facilityReviewCounts[facilityId] ?? 0;
    final hasRating = avgRating != null && reviewCount > 0;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/venue-detail',
        arguments: v['id'] as String,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF4CAF50), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Image.network(
                v['image'] as String? ?? '',
                width: 110,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image,
                      color: Colors.grey, size: 32),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v['name'] as String? ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            v['address'] as String? ?? '',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 3),
                        Text(
                          hours,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 12, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          hasRating
                              ? avgRating.toStringAsFixed(1)
                              : 'Chưa có',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A237E)),
                        ),
                        if (hasRating) ...[
                          const SizedBox(width: 3),
                          Text(
                            '($reviewCount)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        if (distLabel.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.near_me,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(distLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500])),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(Icons.chevron_right,
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[400],
                  size: 22),
            ),
          ],
        ),
      ),
    );
  }
}