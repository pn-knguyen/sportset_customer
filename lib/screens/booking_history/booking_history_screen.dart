import 'package:flutter/material.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  int _selectedTab = 0; // 0: Sắp tới, 1: Lịch sử

  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': '1',
      'name': 'Sân bóng Chảo Lửa',
      'image': 'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
      'time': '18:00 - 19:30',
      'date': '22/11/2023',
      'status': 'Đã xác nhận',
    },
    {
      'id': '2',
      'name': 'Sân cầu lông Bình Thới',
      'image': 'https://688corp.com/wp-content/uploads/2023/06/san-the-thao-cau-long.webp',
      'time': '19:30 - 21:00',
      'date': '24/11/2023',
      'status': 'Đã xác nhận',
    },
    {
      'id': '3',
      'name': 'Sân Tennis Lan Anh',
      'image': 'https://img.meta.com.vn/Data/image/2021/03/15/kich-thuoc-san-tennis-7.jpg',
      'time': '08:00 - 10:00',
      'date': '26/11/2023',
      'status': 'Đã xác nhận',
    },
    {
      'id': '4',
      'name': 'Sân rổ P.Đình Phùng',
      'image': 'https://th.bing.com/th/id/R.e8161a12d899f85d1b06980a2ae105fa?rik=qptbfe%2bJ%2beMk2Q&pid=ImgRaw&r=0',
      'time': '17:00 - 19:00',
      'date': '28/11/2023',
      'status': 'Đã xác nhận',
    },
    {
      'id': '9',
      'name': 'Sân bóng Thiên Long',
      'image': 'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
      'time': '20:00 - 21:30',
      'date': '29/11/2023',
      'status': 'Đã xác nhận',
    },
    {
      'id': '10',
      'name': 'Sân bơi Aqua Park',
      'image': 'https://688corp.com/wp-content/uploads/2023/06/san-the-thao-cau-long.webp',
      'time': '15:00 - 17:00',
      'date': '30/11/2023',
      'status': 'Đã xác nhận',
    },
  ];

  final List<Map<String, dynamic>> _historyBookings = [
    {
      'id': '5',
      'name': 'Sân bóng Chảo Lửa',
      'image': 'https://co-nhan-tao.com/wp-content/uploads/2021/08/san-bong-7-nguoi.jpg',
      'time': '18:00 - 19:30',
      'date': '15/11/2023',
      'status': 'Đã hoàn thành',
      'hasReview': false,
    },
    {
      'id': '6',
      'name': 'Sân cầu lông Bình Thới',
      'image': 'https://688corp.com/wp-content/uploads/2023/06/san-the-thao-cau-long.webp',
      'time': '19:30 - 21:00',
      'date': '12/11/2023',
      'status': 'Đã hoàn thành',
      'hasReview': true,
    },
    {
      'id': '7',
      'name': 'Sân Tennis Lan Anh',
      'image': 'https://img.meta.com.vn/Data/image/2021/03/15/kich-thuoc-san-tennis-7.jpg',
      'time': '08:00 - 10:00',
      'date': '10/11/2023',
      'status': 'Đã hủy',
      'hasReview': false,
    },
    {
      'id': '8',
      'name': 'Sân rổ P.Đình Phùng',
      'image': 'https://th.bing.com/th/id/R.e8161a12d899f85d1b06980a2ae105fa?rik=qptbfe%2bJ%2beMk2Q&pid=ImgRaw&r=0',
      'time': '17:00 - 19:00',
      'date': '05/11/2023',
      'status': 'Đã hoàn thành',
      'hasReview': false,
    },
    {
      'id': '11',
      'name': 'Sân bóng Thiên Long',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCX7Lh_IQkAB7irHwXOjGqcucR3-ziF5MGIKeOKwlN5CqQeA3M1FS7ePwCExMmueE6gohRnfnmdOWYWWMMumiIo9VXVdhJccNGDShWMdkTjRi90WYVxPFStYe2UxWD9kqiGbAFv7XOIPfU1t5rtEmj4jYvQ0vYWxiF6sHLNeTShjIXnVPdINu6J--dgqmZeQA_NvMhPewhLCrbpaAWZj6NJYwQcyXaMHhLnG6vBTdQFQei42MUoZG4nF5kTr27ccRO6K2ZE65AONmaC',
      'time': '20:00 - 21:30',
      'date': '03/11/2023',
      'status': 'Đã hoàn thành',
      'hasReview': true,
    },
    {
      'id': '12',
      'name': 'Sân bơi Aqua Park',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDBfH7HLUrf9SuNdxlN879jRfj5C85jXz7pRZmTFSjKa6TE5y6LkIHl_s5Us2AO8iv8pG8p1OMyNE2JGmobPsIthjYD_yQ4EL7iMJT9Zw_u2tIa05eapXqy9s--WoooraHsutYQAn0A-UNEn0RFQ8qV0SzwumPYUuUN3uKjiVbK0mJsfE27Og6DWlxMUTTq5NxjWRRzG5nrrumJlzFMubsEixbkQT4n6t3d0HJA8SwJkLWp5D87Ft4Pf0mFv4ukfg3y3mTIn3E1H74W',
      'time': '15:00 - 17:00',
      'date': '01/11/2023',
      'status': 'Đã hoàn thành',
      'hasReview': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 0,
              ),
              itemCount: _selectedTab == 0
                  ? _upcomingBookings.length
                  : _historyBookings.length,
              itemBuilder: (context, index) {
                final booking = _selectedTab == 0
                    ? _upcomingBookings[index]
                    : _historyBookings[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _selectedTab == 0
                      ? _buildUpcomingBookingCard(booking)
                      : _buildHistoryBookingCard(booking),
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
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F6),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFFF9800),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Text(
                'LỊCH ĐẶT CỦA TÔI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? const Color(0xFFFF9800)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Sắp tới',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedTab == 0
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedTab == 0
                              ? const Color(0xFFFF9800)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? const Color(0xFFFF9800)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Lịch sử',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedTab == 1
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: _selectedTab == 1
                              ? const Color(0xFFFF9800)
                              : Colors.grey,
                        ),
                      ),
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



  Widget _buildUpcomingBookingCard(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              booking['image'],
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking['name'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'Đã xác nhận',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking['time'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking['date'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/booking-success');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Xem mã QR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }

  Widget _buildHistoryBookingCard(Map<String, dynamic> booking) {
    final isCancelled = booking['status'] == 'Đã hủy';
    final hasReview = booking['hasReview'] as bool;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isCancelled ? 0.9 : 1.0,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColorFiltered(
                colorFilter: isCancelled
                    ? ColorFilter.mode(
                        Colors.grey.withValues(alpha: 0.3),
                        BlendMode.saturation,
                      )
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: Image.network(
                  booking['image'],
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          booking['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? const Color(0xFFF44336).withValues(alpha: 0.1)
                              : const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCancelled
                                ? const Color(0xFFF44336).withValues(alpha: 0.2)
                                : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          booking['status'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCancelled
                                ? const Color(0xFFF44336)
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isCancelled ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        booking['time'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isCancelled ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: isCancelled ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        booking['date'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isCancelled ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        if (!hasReview && !isCancelled) {
                          Navigator.pushNamed(
                            context,
                            '/rating',
                            arguments: {
                              'fieldId': booking['id'],
                              'fieldName': booking['name'],
                              'fieldImage': booking['image'],
                              'playDate': booking['date'],
                            },
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFF44336)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          (!hasReview && !isCancelled) ? 'Đánh giá' : 'Đặt lại',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
