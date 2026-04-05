import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = '';
  String _phoneNumber = '';
  String _email = '';
  String _photoUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .get();
      if (mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _displayName = data['fullName']?.toString() ??
              user.displayName ??
              'Người dùng';
          _phoneNumber = data['phone']?.toString() ?? '';
          _email = data['email']?.toString() ?? user.email ?? '';
          _photoUrl = data['photoUrl']?.toString() ??
              user.photoURL ??
              '';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        setState(() {
          _displayName = user?.displayName ?? 'Người dùng';
          _email = user?.email ?? '';
          _photoUrl = user?.photoURL ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 32),
              _buildAccountSection(context),
              const SizedBox(height: 24),
              _buildSystemSection(context),
              const SizedBox(height: 32),
              const Text(
                'SPORTSET v2.5.0 • Minimalist Edition',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = _displayName.isNotEmpty
        ? _displayName.trim()[0].toUpperCase()
        : '?';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFF44336)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(48),
            ),
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: _isLoading
                  ? Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : (_photoUrl.isNotEmpty
                      ? Image.network(
                          _photoUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildInitialsAvatar(initials),
                        )
                      : _buildInitialsAvatar(initials)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _isLoading ? '' : _displayName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isLoading ? '' : (_phoneNumber.isNotEmpty ? _phoneNumber : _email),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFFF9800),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'TÀI KHOẢN',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline,
                iconColor: const Color(0xFF1A237E),
                backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                title: 'Chỉnh sửa thông tin',
                onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                showDivider: true,
              ),
              _buildMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: const Color(0xFF1A237E),
                backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                title: 'Ví tiền của tôi',
                onTap: () {},
                showDivider: true,
              ),
              _buildMenuItem(
                icon: Icons.confirmation_number_outlined,
                iconColor: const Color(0xFF1A237E),
                backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                title: 'Kho Voucher',
                onTap: () {
                  Navigator.pushNamed(context, '/voucher-selection');
                },
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'HỆ THỐNG',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFF1A237E),
                backgroundColor: Colors.grey.shade100,
                title: 'Thông báo',
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                showDivider: true,
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                iconColor: Colors.grey.shade600,
                backgroundColor: Colors.grey.shade100,
                title: 'Cài đặt ứng dụng',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                showDivider: true,
              ),
              _buildMenuItem(
                icon: Icons.support_agent,
                iconColor: Colors.grey.shade600,
                backgroundColor: Colors.grey.shade100,
                title: 'Liên hệ hỗ trợ',
                onTap: () {},
                showDivider: true,
              ),
              _buildMenuItem(
                icon: Icons.logout,
                iconColor: const Color(0xFFF44336),
                backgroundColor: const Color(0xFFF44336).withValues(alpha: 0.1),
                title: 'Đăng xuất',
                titleColor: const Color(0xFFF44336),
                titleFontWeight: FontWeight.bold,
                onTap: () {
                  _showLogoutDialog(context);
                },
                showDivider: false,
                showChevron: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    Color? titleColor,
    FontWeight? titleFontWeight,
    required VoidCallback onTap,
    required bool showDivider,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: titleFontWeight ?? FontWeight.w600,
                  color: titleColor ?? const Color(0xFF1A237E),
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade300,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF44336),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
