import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  final String fieldId;
  final String fieldName;
  final String fieldImage;
  final String playDate;

  const RatingScreen({
    super.key,
    required this.bookingId,
    required this.fieldId,
    required this.fieldName,
    required this.fieldImage,
    required this.playDate,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1440,
    );
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung đánh giá'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Chưa đăng nhập');

      // Fetch user display name and photo from customers collection
      final customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .get();
      final customerData = customerDoc.data() ?? {};
      final userName = (customerData['fullName'] ??
              FirebaseAuth.instance.currentUser?.displayName ??
              '')
          .toString();
      final userAvatar = (customerData['photoUrl'] ??
              customerData['photoURL'] ??
              FirebaseAuth.instance.currentUser?.photoURL ??
              '')
          .toString();

      // Upload images to Firebase Storage
      final List<String> imageUrls = [];
      for (int i = 0; i < _images.length; i++) {
        final bytes = await _images[i].readAsBytes();
        if (bytes.isEmpty) continue;
        final fileName =
            'review_images/$uid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child(fileName);
        final UploadTask uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        // Dùng snapshotEvents.last thay vì await trực tiếp để tránh task bị treo
        final TaskSnapshot taskSnapshot = await uploadTask.snapshotEvents
            .lastWhere((s) =>
                s.state == TaskState.success || s.state == TaskState.error)
            .timeout(const Duration(seconds: 60));
        if (taskSnapshot.state == TaskState.error) {
          throw Exception('Upload ảnh thất bại');
        }
        final String url = await taskSnapshot.ref.getDownloadURL();
        imageUrls.add(url);
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Save review to 'reviews' collection
      final reviewRef = firestore.collection('reviews').doc();
      batch.set(reviewRef, {
        'userId': uid,
        'userName': userName,
        'userAvatar': userAvatar,
        'fieldId': widget.fieldId,
        'bookingId': widget.bookingId,
        'fieldName': widget.fieldName,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'images': imageUrls,
        'replied': false,
        'reply': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark booking as reviewed
      if (widget.bookingId.isNotEmpty) {
        final bookingRef = firestore.collection('bookings').doc(widget.bookingId);
        batch.update(bookingRef, {'hasReview': true});
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã đánh giá!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi đánh giá thất bại: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
          child: Column(
            children: [
              // App Bar
              Container(
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xF0E8F5E9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(bottom: BorderSide(color: Color(0x1A4CAF50))),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF006E1C)),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Đánh Giá Sân',
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
              ),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Court Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F8E9)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.fieldImage,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 80,
                                  height: 80,
                                  color: const Color(0xFFE8F5E9),
                                  child: const Icon(Icons.sports_tennis,
                                      color: Color(0xFF4CAF50)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.fieldName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1C1C),
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ngày chơi: ${widget.playDate}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6F7A6B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF006E1C)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'HOÀN THÀNH',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006E1C),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Rating Stars
                      Column(
                        children: [
                          const Text(
                            'Bạn thấy chất lượng sân thế nào?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3F4A3C),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rating = index + 1;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    index < _rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: index < _rating
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFFD1D5DB),
                                    size: 40,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Review Text Field
                      TextField(
                        controller: _reviewController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Hãy chia sẻ cảm nhận của bạn...',
                          hintStyle: TextStyle(
                            color: const Color(0xFF6F7A6B).withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFFBECAB9), width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFF006E1C), width: 1.5),
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1A1C1C)),
                      ),
                      const SizedBox(height: 16),

                      // Image Grid
                      LayoutBuilder(builder: (context, constraints) {
                        final itemSize =
                            (constraints.maxWidth - 32) / 3;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            // Add Image Button
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: itemSize,
                                height: itemSize,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFBECAB9),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_a_photo_outlined,
                                        size: 28, color: Color(0xFF6F7A6B)),
                                    SizedBox(height: 6),
                                    Text(
                                      'Thêm ảnh',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6F7A6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Selected images
                            ..._images.asMap().entries.map((entry) {
                              final index = entry.key;
                              final image = entry.value;
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      image,
                                      width: itemSize,
                                      height: itemSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        );
                      }),
                      const SizedBox(height: 40),

                      // Submit Button
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submitReview,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _isSubmitting
                                ? LinearGradient(colors: [
                                    Colors.grey.shade400,
                                    Colors.grey.shade500
                                  ])
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF006E1C),
                                      Color(0xFF4CAF50)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isSubmitting
                                ? null
                                : [
                                    BoxShadow(
                                      color: const Color(0xFF006E1C)
                                          .withValues(alpha: 0.2),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: _isSubmitting
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Gửi Đánh Giá',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.send_rounded,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
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
}
