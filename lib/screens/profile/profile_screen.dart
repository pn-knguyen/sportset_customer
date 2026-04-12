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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 32),
                // Group 1
                _buildMenuGroup([
                  _buildMenuItem(
                    iconData: Icons.manage_accounts_outlined,
                    title: 'Chỉnh sửa thông tin',
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                    showDivider: true,
                  ),
                  _buildMenuItem(
                    iconData: Icons.confirmation_number_outlined,
                    title: 'Kho Voucher',
                    onTap: () => Navigator.pushNamed(context, '/vouchers'),
                    showDivider: false,
                  ),
                ]),
                const SizedBox(height: 24),
                // Group 2
                _buildMenuGroup([
                  _buildMenuItem(
                    iconData: Icons.history_rounded,
                    title: 'Lịch sử đặt sân',
                    onTap: () => Navigator.pushNamed(context, '/booking-history'),
                    showDivider: true,
                  ),
                  _buildMenuItem(
                    iconData: Icons.sports_soccer_outlined,
                    title: 'Sân đã chơi',
                    onTap: () {},
                    showDivider: true,
                  ),
                  _buildMenuItem(
                    iconData: Icons.favorite_outline_rounded,
                    title: 'Sân yêu thích',
                    onTap: () {},
                    showDivider: false,
                  ),
                ]),
                const SizedBox(height: 24),
                // Group 3
                _buildMenuGroup([
                  _buildMenuItem(
                    iconData: Icons.notifications_outlined,
                    title: 'Thông báo',
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    showDivider: true,
                    showBadge: true,
                  ),
                  _buildMenuItem(
                    iconData: Icons.settings_outlined,
                    title: 'Cài đặt ứng dụng',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    showDivider: true,
                  ),
                  _buildMenuItem(
                    iconData: Icons.gavel_outlined,
                    title: 'Điều khoản & Chính sách',
                    onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
                    showDivider: true,
                  ),
                  _buildMenuItem(
                    iconData: Icons.support_agent_outlined,
                    title: 'Liên hệ hỗ trợ',
                    onTap: () {},
                    showDivider: false,
                  ),
                ]),
                const SizedBox(height: 24),
                // Logout button
                GestureDetector(
                  onTap: () => _showLogoutDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFBA1A1A), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'SPORTSET v2.4.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Made for Athletes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final initials = _displayName.isNotEmpty
        ? _displayName.trim()[0].toUpperCase()
        : '?';

    return Row(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _isLoading
                    ? Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFFE8F5E9),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      )
                    : (_photoUrl.isNotEmpty
                        ? Image.network(
                            _photoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildInitialsAvatar(initials),
                          )
                        : _buildInitialsAvatar(initials)),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.verified, size: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLoading ? '' : _displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1C),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isLoading
                    ? ''
                    : (_phoneNumber.isNotEmpty ? _phoneNumber : _email),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3F4A3C),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HẠNG VÀNG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFF4CAF50),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F3F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData iconData,
    required String title,
    required VoidCallback onTap,
    required bool showDivider,
    bool showBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF8F8F8)),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF18A5A7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: const Color(0xFF18A5A7), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1C1C),
                ),
              ),
            ),
            if (showBadge) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4500),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, color: Color(0xFFBECAB9), size: 22),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1C),
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?',
          style: TextStyle(fontSize: 14, color: Color(0xFF6F7A6B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6F7A6B),
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
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFFBA1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
