import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
            icon: const Icon(Icons.arrow_back, color: Color(0xFF006E1C)),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Äiá»u khoáº£n sá»­ dá»¥ng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006E1C),
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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last updated
          const Text(
            'Cáº¬P NHáº¬T Láº¦N CUá»I',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Color(0xFF006E1C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '24 thÃ¡ng 05, 2024',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3F4A3C),
            ),
          ),
          const SizedBox(height: 32),

          _buildSection(
            number: '1',
            title: 'Cháº¥p nháº­n Ä‘iá»u khoáº£n',
            child: _buildParagraph(
              'Báº±ng viá»‡c truy cáº­p hoáº·c sá»­ dá»¥ng á»©ng dá»¥ng SPORTSET, báº¡n Ä‘á»“ng Ã½ chá»‹u sá»± rÃ ng buá»™c bá»Ÿi cÃ¡c Äiá»u khoáº£n sá»­ dá»¥ng nÃ y. Náº¿u báº¡n khÃ´ng Ä‘á»“ng Ã½ vá»›i báº¥t ká»³ pháº§n nÃ o cá»§a cÃ¡c Ä‘iá»u khoáº£n, báº¡n khÃ´ng Ä‘Æ°á»£c phÃ©p truy cáº­p á»©ng dá»¥ng. ChÃºng tÃ´i cÃ³ quyá»n thay Ä‘á»•i cÃ¡c Ä‘iá»u khoáº£n nÃ y báº¥t cá»© lÃºc nÃ o mÃ  khÃ´ng cáº§n thÃ´ng bÃ¡o trÆ°á»›c.',
            ),
          ),

          _buildSection(
            number: '2',
            title: 'Quyá»n vÃ  nghÄ©a vá»¥ ngÆ°á»i dÃ¹ng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParagraph(
                  'NgÆ°á»i dÃ¹ng cam káº¿t cung cáº¥p thÃ´ng tin chÃ­nh xÃ¡c khi Ä‘Äƒng kÃ½ tÃ i khoáº£n vÃ  chá»‹u trÃ¡ch nhiá»‡m báº£o máº­t thÃ´ng tin Ä‘Äƒng nháº­p cá»§a mÃ¬nh.',
                ),
                const SizedBox(height: 8),
                _buildBullet('KhÃ´ng sá»­ dá»¥ng á»©ng dá»¥ng cho báº¥t ká»³ má»¥c Ä‘Ã­ch báº¥t há»£p phÃ¡p nÃ o.'),
                _buildBullet('KhÃ´ng gÃ¢y cáº£n trá»Ÿ hoáº·c lÃ m giÃ¡n Ä‘oáº¡n hoáº¡t Ä‘á»™ng cá»§a há»‡ thá»‘ng.'),
                _buildBullet('TÃ´n trá»ng cÃ¡c quy Ä‘á»‹nh chung táº¡i cÃ¡c sÃ¢n thá»ƒ thao thuá»™c há»‡ thá»‘ng liÃªn káº¿t.'),
              ],
            ),
          ),

          _buildSection(
            number: '3',
            title: 'Quy Ä‘á»‹nh Ä‘áº·t vÃ  há»§y sÃ¢n',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuote(
                  '"Má»i giao dá»‹ch Ä‘áº·t sÃ¢n pháº£i Ä‘Æ°á»£c xÃ¡c nháº­n thÃ´ng qua há»‡ thá»‘ng thanh toÃ¡n tÃ­ch há»£p cá»§a SPORTSET."',
                ),
                const SizedBox(height: 12),
                _buildParagraph(
                  'Há»§y sÃ¢n: Viá»‡c há»§y sÃ¢n pháº£i Ä‘Æ°á»£c thá»±c hiá»‡n Ã­t nháº¥t 12 giá» trÆ°á»›c giá» báº¯t Ä‘áº§u Ä‘á»ƒ nháº­n láº¡i 100% tiá»n cá»c. Há»§y sÃ¢n dÆ°á»›i 12 giá» sáº½ khÃ´ng Ä‘Æ°á»£c hoÃ n tráº£ phÃ­ dá»‹ch vá»¥ theo quy Ä‘á»‹nh cá»§a tá»«ng chá»§ sÃ¢n cá»¥ thá»ƒ.',
                ),
              ],
            ),
          ),

          _buildSection(
            number: '4',
            title: 'Giá»›i háº¡n trÃ¡ch nhiá»‡m',
            child: _buildParagraph(
              'SPORTSET lÃ  ná»n táº£ng káº¿t ná»‘i ngÆ°á»i dÃ¹ng vÃ  chá»§ sÃ¢n. ChÃºng tÃ´i khÃ´ng chá»‹u trÃ¡ch nhiá»‡m cho báº¥t ká»³ cháº¥n thÆ°Æ¡ng, máº¥t mÃ¡t tÃ i sáº£n hoáº·c tranh cháº¥p phÃ¡t sinh giá»¯a ngÆ°á»i dÃ¹ng vÃ  cÆ¡ sá»Ÿ váº­n hÃ nh sÃ¢n bÃ£i trong quÃ¡ trÃ¬nh sá»­ dá»¥ng dá»‹ch vá»¥ thá»±c táº¿ táº¡i sÃ¢n.',
            ),
          ),

          _buildSection(
            number: '5',
            title: 'LiÃªn há»‡',
            isLast: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildParagraph(
                  'Má»i tháº¯c máº¯c hoáº·c khiáº¿u náº¡i vá» Äiá»u khoáº£n sá»­ dá»¥ng, vui lÃ²ng liÃªn há»‡ vá»›i bá»™ pháº­n há»— trá»£ khÃ¡ch hÃ ng cá»§a chÃºng tÃ´i táº¡i:',
                ),
                const SizedBox(height: 12),
                _buildContactRow(Icons.mail_outline_rounded, 'support@sportset.vn'),
                const SizedBox(height: 8),
                _buildContactRow(Icons.call_outlined, '1900 1234 (8:00 - 22:00)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required Widget child,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF006E1C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF3F4A3C),
        height: 1.65,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                fontSize: 13,
                color: Color(0xFF3F4A3C),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuote(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        border: const Border(
          left: BorderSide(color: Color(0xFF006E1C), width: 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
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

  Widget _buildContactRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Color(0xFF006E1C)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF006E1C),
          ),
        ),
      ],
    );
  }
}

