import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      'distance': data['distance']?.toString() ?? '-- km',
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
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFFFF8F6),
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Chào buổi sáng,',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
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
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuCKRmp4nEVBG-6uZ-8CWBD4oUrLxTb23Yg-C-i_07c59-76-Z848HbHMok4RKJY3bNQu34c_sal_V2_gKYpo_UVyKgjJ_wleR_H870lmfJZEwHox2Brd0o4fH4KSrJWIoR2hwWfRI1cNkU95hWSboXt_sjVL6TohZZ2O9SfKvxe0_Ej8hm_MWL6V_Y0-YFRZYimbOEoK60_5vS_Z3qdpbYV48_yQHyIMTxiBBeUx2NdjIPTde0xIxHMgef_w4piWWcxIVIKoBasGDoL',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person, color: Colors.white),
                        );
                      },
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            const Expanded(
              child: Text(
                'Tìm kiếm sân tập, địa điểm...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 20,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const Icon(Icons.tune, color: Color(0xFFFF9800), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.15),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
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
                      color: Color(0xFFFF9800),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFFF9800),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
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
                          Icons.star,
                          color: Color(0xFFFF9800),
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          field['rating'].toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          Text(
                            field['distance'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        field['price'],
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
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
