import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _newPasswordError;
  String? _confirmPasswordError;

  String? _email;
  String? _oobCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _email = args['email'] as String?;
      _oobCode = args['oobCode'] as String?;
    } else if (args is String) {
      _email = args;
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    bool hasError = false;
    if (newPassword.length < 6) {
      setState(() => _newPasswordError = 'Mật khẩu phải ít nhất 6 ký tự');
      hasError = true;
    } else {
      setState(() => _newPasswordError = null);
    }
    if (confirmPassword != newPassword) {
      setState(() => _confirmPasswordError = 'Mật khẩu xác nhận không khớp');
      hasError = true;
    } else {
      setState(() => _confirmPasswordError = null);
    }
    if (hasError) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance
          .confirmPasswordReset(code: _oobCode!, newPassword: newPassword);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/reset-password-success');
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'expired-action-code'
          ? 'Liên kết đặt lại đã hết hạn. Vui lòng yêu cầu lại từ đầu.'
          : e.code == 'invalid-action-code'
              ? 'Liên kết không hợp lệ. Vui lòng yêu cầu lại.'
              : e.message ?? 'Đặt lại mật khẩu thất bại.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oobCode = _oobCode;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF0F172A),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                _buildLogo(),
                const SizedBox(height: 32),
                if (oobCode != null) ...[
                  // Password form mode
                  _buildTitle(),
                  const SizedBox(height: 40),
                  _buildPasswordFields(),
                  const SizedBox(height: 32),
                  _buildLoginLink(),
                ] else ...[
                  // Waiting for email link mode
                  _buildWaitingContent(),
                ],
                const Spacer(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ).createShader(bounds),
          child: const Icon(
            Icons.sports_soccer,
            size: 80,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'SPORTSET',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Đặt lại mật khẩu',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Vui lòng thiết lập mật khẩu mới',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingContent() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.mark_email_unread_rounded,
            size: 48,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Kiểm tra email của bạn',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chúng tôi đã gửi liên kết đặt lại mật khẩu đến${_email != null ? '\n$_email' : ' email của bạn'}.\n\nNhấp vào liên kết trong email để đặt mật khẩu mới ngay trong ứng dụng.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 15,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 32),
        // Hint box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF4CAF50), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kiểm tra cả hòm thư spam nếu không thấy email.',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false),
          child: const Text(
            'Quay lại đăng nhập',
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        _buildPasswordField(
          label: 'Mật khẩu mới',
          hint: 'Nhập mật khẩu mới (ít nhất 6 ký tự)',
          controller: _newPasswordController,
          isVisible: _isNewPasswordVisible,
          errorText: _newPasswordError,
          onToggle: () =>
              setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: 'Xác nhận mật khẩu',
          hint: 'Nhập lại mật khẩu mới',
          controller: _confirmPasswordController,
          isVisible: _isConfirmPasswordVisible,
          errorText: _confirmPasswordError,
          onToggle: () => setState(
              () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Cập nhật mật khẩu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFF44336)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF64748B),
                ),
                onPressed: onToggle,
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Color(0xFFF44336),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Quay lại',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
