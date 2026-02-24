import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 128),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8F6),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
                'Chính sách bảo mật',
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

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cập nhật lần cuối: 24 tháng 5, 2024',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          _buildParagraph(
            'Chào mừng bạn đến với SPORTSET. Chúng tôi cam kết bảo vệ quyền riêng tư và dữ liệu cá nhân của người dùng một cách tuyệt đối. Chính sách này mô tả cách chúng tôi xử lý thông tin của bạn.',
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('1. Thu thập thông tin'),
          _buildParagraph(
            'Chúng tôi thu thập các thông tin cần thiết để cung cấp dịch vụ đặt sân tốt nhất cho bạn, bao gồm:',
          ),
          const SizedBox(height: 8),
          _buildBulletPoint('Thông tin cá nhân: Họ tên, số điện thoại, email khi đăng ký tài khoản.'),
          _buildBulletPoint('Dữ liệu vị trí: Để giúp bạn tìm kiếm các sân thể thao gần nhất một cách thuận tiện.'),
          _buildBulletPoint('Lịch sử đặt sân: Các thông tin về thời gian, địa điểm và loại sân bạn đã sử dụng.'),
          const SizedBox(height: 24),
          _buildSectionTitle('2. Mục đích sử dụng dữ liệu'),
          _buildParagraph(
            'Thông tin của người dùng được sử dụng cho các mục đích chính đáng sau:',
          ),
          const SizedBox(height: 8),
          _buildParagraph('• Xác nhận và quản lý các đơn đặt sân của bạn một cách chính xác.'),
          _buildParagraph('• Gửi thông báo nhắc lịch, ưu đãi đặc biệt và cập nhật trạng thái sân bãi.'),
          _buildParagraph('• Cải thiện trải nghiệm người dùng và chất lượng dịch vụ trên ứng dụng SPORTSET.'),
          _buildParagraph('• Giải quyết các khiếu nại hoặc vấn đề phát sinh trong quá trình sử dụng dịch vụ.'),
          const SizedBox(height: 24),
          _buildSectionTitle('3. Bảo mật thông tin khách hàng'),
          _buildParagraph(
            'Bảo mật dữ liệu là ưu tiên hàng đầu của chúng tôi:',
          ),
          const SizedBox(height: 8),
          _buildParagraph(
            'Chúng tôi áp dụng các biện pháp mã hóa SSL tiên tiến nhất để bảo vệ dữ liệu truyền tải. Mọi thông tin thanh toán đều được xử lý qua các cổng thanh toán uy tín và không lưu trữ thông tin thẻ trực tiếp trên hệ thống của chúng tôi.',
          ),
          const SizedBox(height: 8),
          _buildParagraph(
            'SPORTSET cam kết không bán, trao đổi hoặc chia sẻ thông tin cá nhân của bạn cho bất kỳ bên thứ ba nào vì mục đích thương mại mà không có sự đồng ý của bạn.',
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Nếu bạn có bất kỳ câu hỏi nào về chính sách này, vui lòng liên hệ bộ phận hỗ trợ trong mục "Tài khoản".',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF5722),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
