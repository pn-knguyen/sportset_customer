import 'dart:ui';
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _currentImageIndex = 0;
  int _selectedDateIndex = 0;
  String? _selectedStartTime = '18:00';
  String _selectedDuration = '1 tiếng 30 phút';
  bool _isFavorite = false;

  final List<String> _fieldImages = [
    'https://htsport.vn/wp-content/uploads/2019/12/25-kich-thuoc-san-bong-7-nguoi-2.jpg',
    'https://www.aisedulaos.com/img/Sport-field-ais.jpg',
    'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
  ];

  final List<Map<String, dynamic>> _dates = [
    {'day': 'Th 4', 'date': '15', 'isWeekend': false},
    {'day': 'Th 5', 'date': '16', 'isWeekend': false},
    {'day': 'Th 6', 'date': '17', 'isWeekend': false},
    {'day': 'Th 7', 'date': '18', 'isWeekend': true},
    {'day': 'CN', 'date': '19', 'isWeekend': true},
  ];

  final List<String> _startTimes = [
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
    '20:00',
    '20:30',
    '21:00',
    '21:30',
    '22:00'
  ];

  final List<String> _durations = ['1 tiếng', '1 tiếng 30 phút', '2 tiếng'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildImageCarousel(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldInfo(),
                      const SizedBox(height: 24),
                      _buildAmenities(),
                      const SizedBox(height: 32),
                      _buildDateSelection(),
                      const SizedBox(height: 32),
                      _buildTimeSelection(),
                      const SizedBox(height: 40),
                      _buildReviews(),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildTopBar(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 380,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _fieldImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Image.network(
                    _fieldImages[index],
                    width: double.infinity,
                    height: 380,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 128,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFFFFF8F6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _fieldImages.length,
                (index) => Container(
                  width: index == _currentImageIndex ? 24 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: index == _currentImageIndex
                        ? const Color(0xFFf4ab25)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 48, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTopButton(
              icon: Icons.chevron_left,
              onPressed: () => Navigator.pop(context),
            ),
            Row(
              children: [
                _buildTopButton(
                  icon: Icons.share,
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                _buildTopButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                  isFilled: _isFavorite,
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    Color? color,
    bool isFilled = false,
    required VoidCallback onPressed,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: color ?? const Color(0xFF1c170d),
              size: 24,
            ),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sân bóng Chảo Lửa',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 14,
              color: Color(0xFF9c7f49),
            ),
            const SizedBox(width: 8),
            const Text(
              '30 Phan Thúc Duyện, Tân Bình • 2.5 km',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9c7f49),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFe8dfce), width: 1),
              bottom: BorderSide(color: Color(0xFFe8dfce), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFf4ab25).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 18,
                      color: Color(0xFFf4ab25),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '4.8',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1c170d),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '(120 reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9c7f49),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Đang mở cửa • Đến 23:00',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    final amenities = [
      {'icon': Icons.wifi, 'label': 'Wifi miễn phí'},
      {'icon': Icons.local_drink, 'label': 'Nước uống'},
      {'icon': Icons.local_parking, 'label': 'Bãi xe rộng'},
      {'icon': Icons.restaurant, 'label': 'Căn tin'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích sân',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: amenities.map((amenity) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFe8dfce),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        amenity['icon'] as IconData,
                        color: const Color(0xFFf4ab25),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        amenity['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1c170d).withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chọn ngày',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1c170d),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFf4ab25),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_dates.length, (index) {
              final date = _dates[index];
              final isSelected = index == _selectedDateIndex;
              final isWeekend = date['isWeekend'] as bool;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDateIndex = index;
                  });
                },
                child: Container(
                  width: 64,
                  height: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: const Color(0xFFe8dfce),
                            width: 1,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFf4ab25).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date['day'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isWeekend
                                  ? Colors.red
                                  : const Color(0xFF1c170d).withValues(alpha: 0.6)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date['date'] as String,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isWeekend ? Colors.red : const Color(0xFF1c170d)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đặt giờ linh hoạt',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'GIỜ BẮT ĐẦU',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9c7f49),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _startTimes.length,
          itemBuilder: (context, index) {
            final time = _startTimes[index];
            final isDisabled = index < 2;
            final isSelected = time == _selectedStartTime;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      setState(() {
                        _selectedStartTime = time;
                      });
                    },
              child: Container(
                decoration: BoxDecoration(
                  gradient: isSelected && !isDisabled
                      ? const LinearGradient(
                          colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isDisabled
                      ? Colors.grey[300]
                      : (isSelected ? null : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: !isSelected && !isDisabled
                      ? Border.all(
                          color: const Color(0xFFf4ab25).withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                  boxShadow: isSelected && !isDisabled
                      ? [
                          BoxShadow(
                            color: const Color(0xFFf4ab25).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isDisabled
                        ? Colors.grey[500]
                        : (isSelected ? Colors.white : const Color(0xFF1c170d)),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text(
          'THỜI LƯỢNG CHƠI',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9c7f49),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _durations.map((duration) {
              final isSelected = duration == _selectedDuration;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDuration = duration;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: const Color(0xFFf4ab25).withValues(alpha: 0.3),
                            width: 1,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFf4ab25).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    duration,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1c170d),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFf4ab25).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFf4ab25).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Color(0xFFf4ab25),
                size: 20,
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1c170d),
                  ),
                  children: [
                    TextSpan(text: 'Dự kiến kết thúc: '),
                    TextSpan(
                      text: '19:30',
                      style: TextStyle(
                        color: Color(0xFFff4d00),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đánh giá thực tế',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1c170d),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFe8dfce),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Text(
                    '4.8',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1c170d),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < 4 ? Icons.star : Icons.star_half,
                        color: const Color(0xFFf4ab25),
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '120 reviews',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1c170d).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.75),
                    const SizedBox(height: 8),
                    _buildRatingBar(4, 0.15),
                    const SizedBox(height: 8),
                    _buildRatingBar(3, 0.05),
                    const SizedBox(height: 8),
                    _buildRatingBar(2, 0.03),
                    const SizedBox(height: 8),
                    _buildRatingBar(1, 0.02),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$stars',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1c170d),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFe8dfce),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFf4ab25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9c7f49),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 36),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              border: Border(
                top: BorderSide(
                  color: Colors.black.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TỔNG THANH TOÁN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: const Color(0xFF1c170d).withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '375.000đ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1c170d),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf4ab25), Color(0xFFff4d00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFf4ab25).withValues(alpha: 0.35),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/booking-confirmation');
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Đặt sân ngay',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
