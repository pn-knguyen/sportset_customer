import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = '';
  String _photoUrl = '';

  // Distance
  Position? _userPosition;
  // facilityId -> {lat, lng}
  final Map<String, Map<String, double>> _facilityCoords = {};

  // Ratings from reviews collection: courtId -> avgRating
  final Map<String, double> _courtRatings = {};
  final Map<String, int> _courtReviewCounts = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reviewSub;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _allCourts = [];
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _getUserLocation();
    _loadFacilityCoords();
    _loadAllCourts();
    _subscribeReviews();
    _searchFocus.addListener(_onFocusChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _reviewSub?.cancel();
    _removeOverlay();
    _searchFocus.removeListener(_onFocusChange);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _subscribeReviews() {
    _reviewSub = FirebaseFirestore.instance
        .collection('reviews')
        .snapshots()
        .listen((snapshot) {
      final ratings = <String, List<double>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fieldId = data['fieldId']?.toString() ?? '';
        final r = (data['rating'] as num?)?.toDouble();
        if (fieldId.isNotEmpty && r != null) {
          ratings.putIfAbsent(fieldId, () => []).add(r);
        }
      }
      if (mounted) {
        setState(() {
          _courtRatings.clear();
          _courtReviewCounts.clear();
          for (final entry in ratings.entries) {
            _courtReviewCounts[entry.key] = entry.value.length;
            _courtRatings[entry.key] =
                entry.value.reduce((a, b) => a + b) / entry.value.length;
          }
        });
      }
    });
  }

  Future<void> _loadAllCourts() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('courts').get();
      final courts = snap.docs
          .map((doc) => _courtFromFirestore(doc.data(), docId: doc.id))
          .where((c) {
        final status = c['status']?.toString() ?? '';
        return status.isEmpty || status == 'available';
      }).toList();
      if (mounted) setState(() => _allCourts = courts);
    } catch (_) {}
  }

  void _onFocusChange() {
    if (!_searchFocus.hasFocus) {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _removeOverlay();
      setState(() => _suggestions = []);
      return;
    }
    final results = _allCourts.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final address = (c['address'] ?? '').toString().toLowerCase();
      final category = (c['category'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          address.contains(query) ||
          category.contains(query);
    }).take(6).toList();
    setState(() => _suggestions = results);
    if (results.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (a, b) =>
                    const Divider(height: 1, color: Color(0xFFF1F8E9)),
                itemBuilder: (ctx, i) {
                  final court = _suggestions[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _removeOverlay();
                      _searchController.clear();
                      _searchFocus.unfocus();
                      Navigator.pushNamed(
                        context,
                        '/field-detail',
                        arguments: {
                          'court': court['detailData'] ?? court
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              court['image']?.toString() ?? '',
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx2, err, st) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.grey[200],
                                child: const Icon(Icons.sports,
                                    size: 20, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  court['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A237E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  court['address']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            court['price']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
      final snap = await FirebaseFirestore.instance
          .collection('facilities')
          .get();
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
    if (_userPosition == null || facilityId == null) return '';
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

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ưu tiên lấy từ Firestore
    final doc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();

    if (!mounted) return;
    final data = doc.data();
    setState(() {
      _displayName = (data?['fullName'] as String? ?? '').trim().isNotEmpty
          ? (data!['fullName'] as String).trim()
          : (user.displayName ?? '').trim();
      _photoUrl = (data?['photoUrl'] as String? ?? '').trim().isNotEmpty
          ? (data!['photoUrl'] as String).trim()
          : (user.photoURL ?? '');
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }
  String _normalizeText(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _toPrice(dynamic value) {
    if (value is num) {
      if (value >= 1000) {
        return '${(value / 1000).round()}K/H';
      }
      return '${value.round()}/H';
    }
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? 'Liên hệ' : text;
  }

  Map<String, dynamic> _courtFromFirestore(
    Map<String, dynamic> data, {
    required String docId,
  }) {
    final detailData = Map<String, dynamic>.from(data);
    detailData['id'] = docId;
    return {
      'id': docId,
      'name': data['name'] ?? 'Chưa có tên sân',
      'address': data['address'] ?? 'Chưa cập nhật địa chỉ',
      'rating': _toDouble(data['rating'], fallback: 0),
      'facilityId': data['facilityId']?.toString() ?? '',
      'price': _toPrice(data['pricePerHour'] ?? data['price']),
      'image':
          data['imageUrl'] ??
          data['image'] ??
          'https://images.unsplash.com/photo-1577223625816-7546f13df25d?auto=format&fit=crop&w=1200&q=80',
      'category': data['sportType']?.toString() ?? '',
      'status': data['status']?.toString() ?? '',
      'detailData': detailData,
    };
  }

  List<String> _buildVisibleSports(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sports = <String>[];
    for (final doc in docs) {
      final data = doc.data();
      if (data['isVisible'] != true) {
        continue;
      }
      final name = data['name']?.toString().trim() ?? '';
      if (name.isNotEmpty && !sports.contains(name)) {
        sports.add(name);
      }
    }
    return sports;
  }

  Map<String, List<Map<String, dynamic>>> _buildSuggestedByCategory({
    required List<String> categories,
    required List<Map<String, dynamic>> courts,
  }) {
    final normalizedCategories = {
      for (final category in categories) _normalizeText(category): category,
    };

    final grouped = <String, List<Map<String, dynamic>>>{
      for (final category in categories) category: <Map<String, dynamic>>[],
    };

    for (final court in courts) {
      final key = _normalizeText(court['category']?.toString());
      final category = normalizedCategories[key];
      if (category != null) {
        grouped[category]!.add(court);
      }
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final left = (a['rating'] as num?)?.toDouble() ?? 0;
        final right = (b['rating'] as num?)?.toDouble() ?? 0;
        return right.compareTo(left);
      });
      if (entry.value.length > 10) {
        entry.value.removeRange(10, entry.value.length);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('sports')
            .where('isVisible', isEqualTo: true)
            .snapshots(),
        builder: (context, sportsSnapshot) {
          if (sportsSnapshot.connectionState == ConnectionState.waiting &&
              !sportsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sportsSnapshot.hasError) {
            return const Center(
              child: Text('Không thể tải danh mục từ Firebase'),
            );
          }

          final categories = _buildVisibleSports(sportsSnapshot.data?.docs ?? []);
          if (categories.isEmpty) {
            return const Center(
              child: Text('Chưa có danh mục thể thao đang hiển thị'),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('courts').snapshots(),
            builder: (context, courtsSnapshot) {
              if (courtsSnapshot.connectionState == ConnectionState.waiting &&
                  !courtsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (courtsSnapshot.hasError) {
                return const Center(
                  child: Text('Không thể tải dữ liệu sân từ Firebase'),
                );
              }

              final courts = (courtsSnapshot.data?.docs ?? [])
                  .map((doc) => _courtFromFirestore(doc.data(), docId: doc.id))
                  .where((court) {
                    final status = (court['status'] ?? '').toString();
                    return status.isEmpty || status == 'available';
                  })
                  .toList();
              final suggestedByCategory = _buildSuggestedByCategory(
                categories: categories,
                courts: courts,
              );

              final visibleSections = categories
                  .where((category) =>
                      (suggestedByCategory[category] ?? <Map<String, dynamic>>[])
                          .isNotEmpty)
                  .toList();

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          _buildBanner(),
                          if (visibleSections.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('Chưa có sân phù hợp với danh mục'),
                            ),
                          for (final category in visibleSections)
                            _buildFieldSection(
                              category,
                              suggestedByCategory[category] ??
                                  <Map<String, dynamic>>[],
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.sports_soccer,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SPORTSET',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.2,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _displayName.isEmpty ? 'Bạn' : _displayName,
                          style: const TextStyle(
                            color: Color(0xFF1c170d),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _photoUrl.isNotEmpty
                        ? Image.network(
                            _photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade300,
                                child: const Icon(
                                    Icons.person,
                                    color: Colors.white),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF4CAF50),
                            child: Center(
                              child: Text(
                                _displayName.isNotEmpty
                                    ? _displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade400, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm sân tập, địa điểm...',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    _removeOverlay();
                    _searchFocus.unfocus();
                  },
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _removeOverlay();
                  },
                  child: Icon(Icons.close,
                      color: Colors.grey.shade400, size: 18),
                )
              else ...[  Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                const Icon(Icons.tune, color: Color(0xFF4CAF50), size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAM8-PvGAS_chH2u0nhLtsfRsqCUdPvjeA4FYhPPvr-0l9NGOm-PNNWYb1tyde2GnH4JpuUUNZV9C6K7Infqhwgkrjcwf7M0owPBR45qxsG_Ldg6EMK-4-HcUxiVuhRNzJz-GeF0b4Btqhv-iwmMig5wHaTyytm9zRU-HPnwOzpOMmcG4tfCAMMfBYHC5NPNj5rFXt6_wcURkr5_P3J0QMTu17XUVvOmV0I-tjAV4iFr0kqY_53KYWYEo4KlPMYub_qJ4b7TwhFefkK',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.grey.shade300);
                  },
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xB3000000),
                      Color(0x4D000000),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ƯU ĐÃI MỚI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Khám phá ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const SizedBox(
                      width: 200,
                      child: Text(
                        'Trải nghiệm sân tập chất lượng hàng đầu.',
                        style: TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Đặt sân ngay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildFieldSection(String category, List<Map<String, dynamic>> fields) {
    final title = 'SÂN ${category.toUpperCase()} GỢI Ý';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF4CAF50),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 245,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              return _buildFieldCard(fields[index]);
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/field-detail',
          arguments: {'court': field['detailData'] ?? field},
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    field['image'],
                    height: 144,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 144,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 48),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Builder(builder: (context) {
                    final courtId = field['id']?.toString() ?? '';
                    final avg = _courtRatings[courtId];
                    final count = _courtReviewCounts[courtId] ?? 0;
                    final hasRating = avg != null && count > 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            hasRating
                                ? avg.toStringAsFixed(1)
                                : '—',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C1C),
                            ),
                          ),
                          if (hasRating) ...[  const SizedBox(width: 3),
                            Text(
                              '($count)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field['name'],
                    style: const TextStyle(
                      color: Color(0xFF1c170d),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 10,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          field['address'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Builder(builder: (context) {
                            final label = _calcDistanceLabel(
                                field['facilityId'] as String?);
                            if (label.isEmpty) {
                              return _userPosition == null &&
                                      (field['facilityId'] as String? ?? '')
                                          .isNotEmpty
                                  ? const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : const Text(
                                      '--',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    );
                            }
                            return Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          }),
                        ],
                      ),
                      Text(
                        field['price'],
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
    );
  }

}
