import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _darkMode = false;

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
          child: Column(
            children: [
              // AppBar
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF4CAF50)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Cài đặt ứng dụng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('THÔNG BÁO'),
                      _buildCard([
                        _buildToggleRow(
                          icon: Icons.notifications_outlined,
                          title: 'Thông báo đẩy',
                          value: _pushNotifications,
                          onChanged: (v) =>
                              setState(() => _pushNotifications = v),
                          showDivider: true,
                        ),
                        _buildToggleRow(
                          icon: Icons.mail_outline_rounded,
                          title: 'Thông báo qua Email',
                          value: _emailNotifications,
                          onChanged: (v) =>
                              setState(() => _emailNotifications = v),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionHeader('BẢO MẬT'),
                      _buildCard([
                        _buildNavRow(
                          icon: Icons.lock_outline_rounded,
                          title: 'Đổi mật khẩu',
                          onTap: () {},
                          showDivider: true,
                        ),
                        _buildNavRow(
                          icon: Icons.fingerprint_rounded,
                          title: 'Cài đặt Face ID/Vân tay',
                          onTap: () {},
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionHeader('HIỂN THỊ'),
                      _buildCard([
                        _buildToggleRow(
                          icon: Icons.dark_mode_outlined,
                          title: 'Chế độ tối (Dark Mode)',
                          value: _darkMode,
                          onChanged: (v) => setState(() => _darkMode = v),
                          showDivider: true,
                        ),
                        _buildNavRow(
                          icon: Icons.language_outlined,
                          title: 'Ngôn ngữ',
                          onTap: () {},
                          trailing: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tiếng Việt',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.expand_more_rounded,
                                  size: 18, color: Color(0xFF4CAF50)),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 32),
                      _buildSectionHeader('THÔNG TIN'),
                      _buildCard([
                        _buildNavRow(
                          icon: Icons.description_outlined,
                          title: 'Điều khoản sử dụng',
                          onTap: () =>
                              Navigator.pushNamed(context, '/terms'),
                          showDivider: true,
                          trailingIcon: Icons.open_in_new_rounded,
                        ),
                        _buildNavRow(
                          icon: Icons.policy_outlined,
                          title: 'Chính sách bảo mật',
                          onTap: () =>
                              Navigator.pushNamed(context, '/privacy-policy'),
                          showDivider: true,
                          trailingIcon: Icons.open_in_new_rounded,
                        ),
                        _buildNavRow(
                          icon: Icons.info_outline_rounded,
                          title: 'Phiên bản',
                          onTap: null,
                          trailing: const Text(
                            '2.4.0',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F4A3C),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3F4A3C),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = false,
  }) {
    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF3F3F3)),
              ),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _buildIconBox(icon),
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
            _buildSwitch(value, onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool showDivider = false,
    Widget? trailing,
    IconData trailingIcon = Icons.chevron_right,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: showDivider
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F3F3)),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _buildIconBox(icon),
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
                trailing ??
                    Icon(trailingIcon,
                        color: const Color(0xFFBECAB9), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF80F5F6).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF18A5A7), size: 22),
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? const Color(0xFF4CAF50) : const Color(0xFFE0E0E0),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
