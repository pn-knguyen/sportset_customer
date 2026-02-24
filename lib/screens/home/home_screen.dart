import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildBanner(),
                  _buildFieldSection('SÂN BÓNG ĐÁ GỢI Ý', _footballFields),
                  _buildFieldSection('SÂN CẦU LÔNG GỢI Ý', _badmintonFields),
                  _buildFieldSection('SÂN TENNIS GỢI Ý', _tennisFields),
                  _buildFieldSection('SÂN BÓNG RỔ GỢI Ý', _basketballFields),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_volleyball,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SPORTSET',
                  style: TextStyle(
                    color: Color(0xFF1A237E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
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
                        color: Colors.black.withOpacity(0.08),
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
              color: Colors.black.withOpacity(0.04),
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
            BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 12),
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

  Widget _buildFieldSection(String title, List<Map<String, dynamic>> fields) {
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
        Navigator.pushNamed(context, '/field-detail');
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
              color: Colors.black.withOpacity(0.04),
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
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
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

  // Data
  final List<Map<String, dynamic>> _footballFields = [
    {
      'name': 'Sân bóng Chảo Lửa',
      'address': '30 Phan Thúc Duyện, Tân Bình',
      'rating': 4.8,
      'distance': '1.2 km',
      'price': '300K/H',
      'image':
          'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
    },
    {
      'name': 'Sân bóng Thành Đồng',
      'address': '19 Sầm Sơn, Tân Bình',
      'rating': 4.7,
      'distance': '2.5 km',
      'price': '280K/H',
      'image':
          'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
    },
    {
      'name': 'Sân mini Tao Đàn',
      'address': '1 Huyền Trân Công Chúa, Q.1',
      'rating': 4.5,
      'distance': '0.8 km',
      'price': '350K/H',
      'image':
          'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
    },
    {
      'name': 'Sân cỏ nhân tạo D36',
      'address': '36 Hoàng Hoa Thám, Tân Bình',
      'rating': 4.9,
      'distance': '3.1 km',
      'price': '320K/H',
      'image':
          'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
    },
  ];

  final List<Map<String, dynamic>> _badmintonFields = [
    {
      'name': 'Sân cầu lông Bình Thới',
      'address': '220 Lãnh Binh Thăng, Q.11',
      'rating': 4.9,
      'distance': '1.5 km',
      'price': '120K/H',
      'image':
          'https://688corp.com/wp-content/uploads/2023/06/san-the-thao-cau-long.webp',
    },
    {
      'name': 'Sân cầu lông Thống Nhất',
      'address': '138 Đào Duy Từ, Q.10',
      'rating': 4.7,
      'distance': '2.2 km',
      'price': '150K/H',
      'image':
          'https://688corp.com/wp-content/uploads/2023/06/san-the-thao-cau-long.webp',
    },
    {
      'name': 'Sân cầu lông Hải Yến',
      'address': '151/1 Nguyễn Trãi, Q.5',
      'rating': 4.6,
      'distance': '1.8 km',
      'price': '100K/H',
      'image':
          'https://688corp.com/wp-content/uploads/2023/06/san-the-thao-cau-long.webp',
    },
  ];

  final List<Map<String, dynamic>> _tennisFields = [
    {
      'name': 'Sân Tennis Lan Anh',
      'address': '291 Cách Mạng Tháng 8, Q.10',
      'rating': 4.8,
      'distance': '1.5 km',
      'price': '550K/H',
      'image':
          'https://img.meta.com.vn/Data/image/2021/03/15/kich-thuoc-san-tennis-7.jpg',
    },
    {
      'name': 'Sân Tennis Kỳ Hòa',
      'address': '238 Ba Tháng Hai, Q.10',
      'rating': 4.7,
      'distance': '2.8 km',
      'price': '480K/H',
      'image':
          'https://img.meta.com.vn/Data/image/2021/03/15/kich-thuoc-san-tennis-7.jpg',
    },
    {
      'name': 'Sân Tennis Phú Thọ',
      'address': '215A Lý Thường Kiệt, Q.11',
      'rating': 4.6,
      'distance': '3.2 km',
      'price': '500K/H',
      'image':
          'https://img.meta.com.vn/Data/image/2021/03/15/kich-thuoc-san-tennis-7.jpg',
    },
  ];

  final List<Map<String, dynamic>> _basketballFields = [
    {
      'name': 'Sân rổ Phan Đình Phùng',
      'address': '8 Võ Văn Tần, Q.3',
      'rating': 4.7,
      'distance': '0.8 km',
      'price': '250K/H',
      'image':
          'https://th.bing.com/th/id/R.e8161a12d899f85d1b06980a2ae105fa?rik=qptbfe%2bJ%2beMk2Q&pid=ImgRaw&r=0',
    },
    {
      'name': 'NTĐ Hồ Xuân Hương',
      'address': '2 Hồ Xuân Hương, Q.3',
      'rating': 4.6,
      'distance': '1.7 km',
      'price': '200K/H',
      'image':
          'https://th.bing.com/th/id/R.e8161a12d899f85d1b06980a2ae105fa?rik=qptbfe%2bJ%2beMk2Q&pid=ImgRaw&r=0',
    },
    {
      'name': 'Nhà thi đấu Phú Thọ',
      'address': '219 Lý Thường Kiệt, Q.11',
      'rating': 4.8,
      'distance': '0.6 km',
      'price': '300K/H',
      'image':
          'https://th.bing.com/th/id/R.e8161a12d899f85d1b06980a2ae105fa?rik=qptbfe%2bJ%2beMk2Q&pid=ImgRaw&r=0',
    },
  ];
}
