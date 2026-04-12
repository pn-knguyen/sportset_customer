import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _activityNotifications = [
    {
      'icon': Icons.event_available,
      'title': 'Xác nhận đặt sân thành công',
      'description': 'Sân Cầu Lông A1 đã được đặt cho bạn vào lúc 18:00 tối nay.',
      'time': '5 phút trước',
      'isUnread': true,
    },
    {
      'icon': Icons.featured_play_list,
      'title': 'Kết quả trận đấu',
      'description': 'Trận đấu Tennis ngày 15/10 đã được cập nhật kết quả. Xem ngay!',
      'time': '1 giờ trước',
      'isUnread': false,
    },
    {
      'icon': Icons.card_giftcard,
      'title': 'Voucher mới tặng bạn',
      'description': 'Chúc mừng! Bạn nhận được Voucher giảm 20% cho lần đặt sân tiếp theo.',
      'time': '3 giờ trước',
      'isUnread': true,
    },
    {
      'icon': Icons.history,
      'title': 'Hoàn tất thanh toán',
      'description': 'Giao dịch nạp ví 200.000đ đã được xử lý thành công.',
      'time': 'Hôm qua',
      'isUnread': false,
    },
    {
      'icon': Icons.celebration,
      'title': 'Thăng hạng thành viên',
      'description': 'Tuyệt vời! Bạn đã chính thức đạt hạng THÀNH VIÊN BẠC.',
      'time': '2 ngày trước',
      'isUnread': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 128),
              itemCount: _activityNotifications.length + 1,
              itemBuilder: (context, index) {
                if (index == _activityNotifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'BẠN ĐÃ XEM HẾT THÔNG BÁO',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFD1D5DB),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildNotificationCard(_activityNotifications[index]),
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
        color: Color(0xFFE8F5E9),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 24, color: Color(0xFF1A237E)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              const Text(
                'Thông Báo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab == 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    'Hoạt động',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 0 ? const Color(0xFF1A237E) : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = 1;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab == 1 ? const Color(0xFF4CAF50) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    'Khuyến mãi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                      color: _selectedTab == 1 ? const Color(0xFF1A237E) : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = notification['isUnread'] as bool;
    
    return Container(
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? const Color(0xFFFFE0B2).withValues(alpha: 0.3) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8EAF6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notification['icon'],
                    color: const Color(0xFF1A237E),
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
                              notification['title'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 16),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4500),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
