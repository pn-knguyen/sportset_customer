import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = '';
  final TextEditingController _searchController = TextEditingController();

  String _normalizeText(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  String _toPrice(dynamic value) {
    if (value is num) {
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}k';
      }
      return value.toStringAsFixed(0);
    }
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? 'Liên hệ' : text;
  }

  String _formatOperatingHours(Map<String, dynamic> data) {
    final weekdayPricing = data['weekdayPricing'];
    if (weekdayPricing is List && weekdayPricing.isNotEmpty) {
      final firstSlot = weekdayPricing.first;
      if (firstSlot is Map<String, dynamic>) {
        final start = firstSlot['startTime']?.toString();
        final end = firstSlot['endTime']?.toString();
        if ((start ?? '').isNotEmpty && (end ?? '').isNotEmpty) {
          return '$start - $end';
        }
      }
    }
    return 'Giờ linh hoạt';
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
      'image':
          data['imageUrl'] ??
          data['image'] ??
          'https://images.unsplash.com/photo-1577223625816-7546f13df25d?auto=format&fit=crop&w=1200&q=80',
      'rating': _toDouble(data['rating'], fallback: 0),
      'price': _toPrice(data['pricePerHour'] ?? data['price']),
      'address': data['address'] ?? 'Chưa cập nhật địa chỉ',
      'distance': data['distance']?.toString() ?? '-- km',
      'info': data['facilityName'] ?? _formatOperatingHours(data),
      'infoIcon': Icons.business,
      'category': data['sportType']?.toString() ?? '',
      'detailData': detailData,
    };
  }

  List<String> _buildVisibleSports(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
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

  void _syncSelectedCategory(List<String> categories) {
    if (categories.isEmpty) {
      return;
    }
    if (categories.contains(_selectedCategory)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedCategory = categories.first;
      });
    });
  }

  List<Map<String, dynamic>> _buildFilteredVenues(
    List<Map<String, dynamic>> source,
    String selectedCategory,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return source.where((venue) {
      final venueCategory = _normalizeText(venue['category']?.toString());
      final categoryMatched =
          venueCategory == _normalizeText(selectedCategory);
      final text = '${venue['name'] ?? ''} ${venue['address'] ?? ''}'.toLowerCase();
      final searchMatched = query.isEmpty || text.contains(query);
      return categoryMatched && searchMatched;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
              child: Text('Chưa có danh mục nào đang hiển thị'),
            );
          }

          _syncSelectedCategory(categories);
          final selectedCategory = categories.contains(_selectedCategory)
              ? _selectedCategory
              : categories.first;

          return Column(
            children: [
              _buildHeader(categories),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('courts')
                      .where('sportType', isEqualTo: selectedCategory)
                      .snapshots(),
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

                    final filteredVenues = _buildFilteredVenues(
                            courtsSnapshot.data?.docs
                              .map((doc) => _courtFromFirestore(doc.data(), docId: doc.id))
                              .toList() ??
                          <Map<String, dynamic>>[],
                      selectedCategory,
                    );

                    if (filteredVenues.isEmpty) {
                      return Center(
                        child: Text(
                          'Không có sân cho danh mục $selectedCategory',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: filteredVenues.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildVenueCard(filteredVenues[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<String> categories) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Logo and user info
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                            colors: [Color(0xFFFF9800), Color(0xFFF44336)],
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
                          color: Color(0xFF0F172A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Chào buổi sáng,',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Nam!',
                            style: TextStyle(
                              color: Color(0xFF1c170d),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF9800),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAT3NjTa30NOo9uOXk0-MFXZAkedViXSrdcLCFJpX8nsF7Y5woFfmz2Caveo1jY78fJNKTNSfxVWGpJh4K59QbfmBIgwvF2ocouc_dAO1mKtpLe106atmLIc9q5JtaEfK_i0y-WfZsJ6hzOkWajGlfSr1Nkt5BgDUZdiA3omHtjJDaeuj5-4IeGSowbjkTA3pXGgAeluVpn_ITg6tTGjCCLhGQV01XecolYkA1OSaIrOk6ibaj4ZRfcGRGb82wscJcTQwlIVuRziSKu',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, 4),
                      blurRadius: 20,
                      spreadRadius: -10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(Icons.search, color: Colors.grey, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm sân, khu vực...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      height: 20,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.grey[200],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: IconButton(
                        icon: const Icon(
                          Icons.tune,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category filters
            SizedBox(
              height: 60,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF9800),
                                      Color(0xFFF44336),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey[100]!,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF9800,
                                      ).withValues(alpha: 0.2),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard(Map<String, dynamic> venue) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/field-detail',
          arguments: {'court': venue['detailData'] ?? venue},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey[100]!),
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
            // Image with rating and favorite button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: Image.network(
                    venue['image'],
                    height: 192,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFF9800),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              venue['rating'].toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Venue details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          venue['name'],
                          style: const TextStyle(
                            color: Color(0xFF1A237E),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue['price'],
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '/h',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
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
                          venue['address'],
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: Colors.grey[50], height: 1),
                  const SizedBox(height: 16),

                  // Distance, info and details button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.near_me,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                venue['distance'],
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Icon(
                                venue['infoIcon'],
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                venue['info'],
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/field-detail',
                            arguments: {'court': venue['detailData'] ?? venue},
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF9800,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Chi tiết',
                            style: TextStyle(
                              color: Color(0xFFFF9800),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
