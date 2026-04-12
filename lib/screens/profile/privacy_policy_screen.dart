import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4CAF50)),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Quy định bảo mật',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last updated
          Text(
            'CẬP NHẬT LẦN CUỐI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '24 tháng 12, 2023',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 28),

          // Section 1
          _buildSectionTitle('1. THU THẬP THÔNG TIN'),
          const SizedBox(height: 10),
          _buildParagraph(
            'Chúng tôi thu thập các thông tin cá nhân cần thiết để cung cấp dịch vụ quản lý sân cỏ tốt nhất cho bạn, bao gồm nhưng không giới hạn ở:',
          ),
          const SizedBox(height: 10),
          _buildBullet('Họ và tên, số điện thoại, địa chỉ email.'),
          _buildBullet('Thông tin cơ sở kinh doanh, vị trí sân cỏ.'),
          _buildBullet('Lịch sử giao dịch và dữ liệu đặt sân.'),
          const SizedBox(height: 24),

          // Section 2
          _buildSectionTitle('2. MỤC ĐÍCH SỬ DỤNG DỮ LIỆU'),
          const SizedBox(height: 10),
          _buildParagraph('Thông tin được thu thập sẽ được sử dụng vào các mục đích sau:'),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.verified_user_rounded,
            title: 'XÁC THỰC TÀI KHOẢN',
            body: 'Đảm bảo an toàn cho các giao dịch và quyền truy cập của chủ sân.',
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.bar_chart_rounded,
            title: 'TỐI ƯU HÓA DOANH THU',
            body: 'Phân tích xu hướng đặt sân để đề xuất các giải pháp kinh doanh hiệu quả.',
          ),
          const SizedBox(height: 24),

          // Section 3
          _buildSectionTitle('3. BẢO MẬT THÔNG TIN KHÁCH HÀNG'),
          const SizedBox(height: 10),
          _buildQuote(
            '"Chúng tôi cam kết không chia sẻ thông tin của bạn với bên thứ ba mà không có sự đồng ý rõ ràng từ bạn."',
          ),
          const SizedBox(height: 14),
          _buildParagraph(
            'Tất cả dữ liệu được mã hóa bằng công nghệ SSL tiên tiến và lưu trữ trên các máy chủ đám mây bảo mật cao. Hệ thống của chúng tôi thường xuyên được kiểm tra để ngăn chặn các truy cập trái phép.',
          ),
          const SizedBox(height: 8),
          _buildParagraph(
            'SPORTSET cam kết không bán, trao đổi hoặc chia sẻ thông tin cá nhân của bạn cho bất kỳ bên thứ ba nào vì mục đích thương mại mà không có sự đồng ý của bạn.',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBECAB9)),
            ),
            child: const Text(
              'Nếu bạn có bất kỳ câu hỏi nào về chính sách này, vui lòng liên hệ bộ phận hỗ trợ trong mục "Tài khoản".',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3F4A3C),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4CAF50),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF3F4A3C),
        height: 1.65,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1C1C),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4CAF50), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF1A1C1C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3F4A3C),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        border: Border(
          left: BorderSide(color: Color(0xFF4CAF50), width: 4),
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Color(0xFF3F4A3C),
          height: 1.6,
        ),
      ),
    );
  }
}
