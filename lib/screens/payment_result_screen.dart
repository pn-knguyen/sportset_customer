import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentResultScreen extends StatefulWidget {
  final String resultCode;
  final String orderId;
  final String message;

  const PaymentResultScreen({
    super.key,
    required this.resultCode,
    required this.orderId,
    this.message = '',
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  bool _isUpdating = true;
  String? _updateError;

  bool get _isSuccess => widget.resultCode == '0';

  @override
  void initState() {
    super.initState();
    if (_isSuccess && widget.orderId.isNotEmpty) {
      _confirmBooking();
    } else {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmBooking() async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.orderId)
          .update({
        'status': 'confirmed',
        'paymentStatus': 'paid',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) setState(() => _updateError = e.toString());
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isUpdating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4CAF50)),
              SizedBox(height: 16),
              Text('Đang xác nhận thanh toán...',
                  style: TextStyle(color: Color(0xFF6F7A6B))),
            ],
          ),
        ),
      );
    }
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                        : const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 56,
                    color: _isSuccess
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFBA1A1A),
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                Text(
                  _isSuccess
                      ? 'Thanh toán thành công!'
                      : 'Thanh toán thất bại',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _isSuccess
                        ? const Color(0xFF006E1C)
                        : const Color(0xFFBA1A1A),
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  _isSuccess
                      ? (_updateError != null
                          ? 'Giao dịch thành công nhưng không thể cập nhật đơn hàng. Vui lòng liên hệ hỗ trợ.'
                          : 'Đơn hàng của bạn đã được xác nhận và đang được xử lý.')
                      : (widget.message.isNotEmpty
                          ? widget.message
                          : 'Giao dịch không thể hoàn tất. Vui lòng thử lại.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6F7A6B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Order ID card
                if (widget.orderId.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF3F3F3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            size: 18, color: Color(0xFF6F7A6B)),
                        const SizedBox(width: 10),
                        const Text(
                          'Mã đơn hàng:',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F7A6B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.orderId,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),

                // Back to home button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/main', (_) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Về trang chủ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (_isSuccess) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/main',
                          (_) => false,
                          arguments: {'initialIndex': 3},
                        );
                      },
                      icon: const Icon(Icons.calendar_today,
                          size: 18, color: Color(0xFF006E1C)),
                      label: const Text(
                        'Xem lịch đặt sân',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006E1C),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],

                if (!_isSuccess) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006E1C),
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
