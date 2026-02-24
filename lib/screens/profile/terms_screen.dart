import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 128),
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
                'Điều khoản sử dụng',
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
        borderRadius: BorderRadius.circular(16),
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
            'Cập nhật lần cuối: 24 tháng 05, 2024',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          
          // Section 1
          _buildSection(
            title: '1. Chấp nhận điều khoản',
            paragraphs: [
              'Chào mừng bạn đến với SPORTSET. Bằng cách cài đặt và sử dụng ứng dụng, bạn đồng ý tuân thủ và chịu sự ràng buộc bởi các điều khoản và điều kiện dưới đây. Nếu bạn không đồng ý với bất kỳ phần nào của các điều khoản này, vui lòng không sử dụng dịch vụ của chúng tôi.',
              'Chúng tôi có quyền thay đổi, chỉnh sửa, thêm hoặc lược bỏ bất kỳ phần nào trong Điều khoản sử dụng này vào bất cứ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải trên ứng dụng mà không cần thông báo trước.',
            ],
          ),
          
          // Section 2
          _buildSection(
            title: '2. Quyền và nghĩa vụ người dùng',
            subsections: [
              {
                'subtitle': '2.1. Tài khoản người dùng',
                'content': 'Người dùng có trách nhiệm bảo mật thông tin tài khoản và mật khẩu của mình. Bạn hoàn toàn chịu trách nhiệm cho tất cả các hoạt động diễn ra dưới tài khoản của bạn.',
              },
              {
                'subtitle': '2.2. Hành vi bị nghiêm cấm',
                'bullets': [
                  'Sử dụng dịch vụ cho bất kỳ mục đích bất hợp pháp nào.',
                  'Gây cản trở hoặc làm gián đoạn hoạt động của ứng dụng.',
                  'Cung cấp thông tin giả mạo hoặc mạo danh cá nhân, tổ chức khác.',
                  'Sử dụng các công cụ tự động để can thiệp vào hệ thống đặt sân.',
                ],
              },
            ],
          ),
          
          // Section 3
          _buildSection(
            title: '3. Quy định đặt và hủy sân',
            subsections: [
              {
                'subtitle': '3.1. Quy trình đặt sân',
                'content': 'Việc đặt sân chỉ được xác nhận sau khi người dùng hoàn tất thanh toán hoặc nhận được thông báo xác nhận từ hệ thống. Giá thuê sân được hiển thị công khai và có thể thay đổi tùy theo khung giờ hoặc ngày lễ.',
              },
              {
                'subtitle': '3.2. Chính sách hủy sân',
                'paragraphs': [
                  'Hủy sân trước 24 giờ: Hoàn tiền 100% vào ví ứng dụng.',
                  'Hủy sân từ 12-24 giờ: Hoàn tiền 50%.',
                  'Hủy sân dưới 12 giờ: Không hỗ trợ hoàn tiền. Mọi trường hợp ngoại lệ sẽ do ban quản trị sân quyết định.',
                ],
              },
            ],
          ),
          
          // Section 4
          _buildSection(
            title: '4. Giới hạn trách nhiệm',
            paragraphs: [
              'SPORTSET đóng vai trò là nền tảng kết nối người chơi và chủ sân. Chúng tôi không chịu trách nhiệm về chất lượng cơ sở vật chất thực tế tại sân hoặc bất kỳ rủi ro chấn thương nào xảy ra trong quá trình sử dụng sân của người dùng.',
            ],
          ),
          
          // Section 5
          _buildSection(
            title: '5. Liên hệ',
            paragraphs: [
              'Nếu bạn có bất kỳ câu hỏi nào về Điều khoản sử dụng này, vui lòng liên hệ với chúng tôi qua email: support@sportset.vn hoặc hotline: 1900 xxxx.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    List<String>? paragraphs,
    List<Map<String, dynamic>>? subsections,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (paragraphs != null)
            ...paragraphs.map((para) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    para,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                )),
          if (subsections != null)
            ...subsections.map((sub) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sub.containsKey('subtitle'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          sub['subtitle'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                            height: 1.5,
                          ),
                        ),
                      ),
                    if (sub.containsKey('content'))
                      Text(
                        sub['content'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                    if (sub.containsKey('paragraphs'))
                      ...((sub['paragraphs'] as List<String>).map((para) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              para,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ))),
                    if (sub.containsKey('bullets'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: (sub['bullets'] as List<String>)
                              .map((bullet) => _buildBulletPoint(bullet))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
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
              color: Colors.grey[700],
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
