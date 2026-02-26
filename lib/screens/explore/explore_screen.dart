import 'package:flutter/material.dart';
import 'dart:ui';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = 'Bóng đá';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Bóng đá',
    'Cầu lông',
    'Tennis',
    'Bóng rổ',
    'Bơi lội',
  ];

  final List<Map<String, dynamic>> _venues = [
    {
      'name': 'Sân bóng Chảo Lửa',
      'image':
          'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
      'rating': 4.8,
      'price': '300k',
      'address': '30 Phan Thúc Duyện, Tân Bình',
      'distance': '1.2 km',
      'info': '6:00 - 22:00',
      'infoIcon': Icons.schedule,
    },
    {
      'name': 'Sân bóng Thành Đồng',
      'image':
          'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
      'rating': 4.7,
      'price': '280k',
      'address': '19 Sầm Sơn, Tân Bình',
      'distance': '2.5 km',
      'info': 'Cỏ nhân tạo',
      'infoIcon': Icons.sports_soccer,
    },
    {
      'name': 'Sân Cầu Lông Bình Thới',
      'image':
          'https://688corp.com/wp-content/uploads/2023/06/san-the-thao-cau-long.webp',
      'price': '120k',
      'address': '220 Lãnh Binh Thăng, Q.11',
      'distance': '1.5 km',
      'info': 'Thảm chuyên dụng',
      'infoIcon': Icons.layers,
    },
    {
      'name': 'Sân Tennis Lan Anh',
      'image':
          'https://img.meta.com.vn/Data/image/2021/03/15/kich-thuoc-san-tennis-7.jpg',
      'rating': 4.8,
      'price': '550k',
      'address': '291 Cách Mạng Tháng 8, Q.10',
      'distance': '1.5 km',
      'info': 'Có mái che',
      'infoIcon': Icons.wb_sunny,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: _venues.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildVenueCard(_venues[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
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
        Navigator.pushNamed(context, '/field-detail');
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
                          Navigator.pushNamed(context, '/field-detail');
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
