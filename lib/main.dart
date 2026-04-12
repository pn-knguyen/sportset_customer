import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

// Intro screen
import 'screens/intro/intro_screen.dart';

// Auth screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/reset_password_success_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/email_verified_screen.dart';

// Home and navigation
import 'screens/home/home_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'screens/booking_history/booking_history_screen.dart';
import 'screens/profile/profile_screen.dart';

// Field and booking
import 'screens/field_detail/field_detail_screen.dart';
import 'screens/explore/venue_detail_screen.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/booking/booking_confirmation_screen.dart';
import 'screens/booking/voucher_selection_screen.dart';
import 'screens/booking/booking_success_screen.dart';

// Rating
import 'screens/booking_history/rating_screen.dart';

// Profile sections
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/profile/notifications_screen.dart';
import 'screens/profile/terms_screen.dart';
import 'screens/profile/privacy_policy_screen.dart';
import 'screens/profile/vouchers_screen.dart';

// Payment
import 'screens/payment_screen.dart';
import 'screens/payment_result_screen.dart';

// Deep link
import 'dart:async';
import 'package:app_links/app_links.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SportsetApp());
}

class SportsetApp extends StatefulWidget {
  const SportsetApp({super.key});

  @override
  State<SportsetApp> createState() => _SportsetAppState();
}

class _SportsetAppState extends State<SportsetApp> {
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _linkSub = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // MoMo payment result
    if (uri.scheme == 'yourapp' && uri.host == 'payment-result') {
      _navigatorKey.currentState?.pushNamed(
        '/payment-result',
        arguments: {
          'resultCode': uri.queryParameters['resultCode'] ?? '',
          'orderId': uri.queryParameters['orderId'] ?? '',
          'message': uri.queryParameters['message'] ?? '',
        },
      );
      return;
    }
    // Firebase password reset App Link
    if (uri.scheme == 'https' &&
        uri.host == 'sportset-d345c.firebaseapp.com') {
      final mode = uri.queryParameters['mode'];
      final oobCode = uri.queryParameters['oobCode'];
      if (mode == 'resetPassword' && oobCode != null) {
        _navigatorKey.currentState?.pushNamed(
          '/reset-password',
          arguments: {'oobCode': oobCode},
        );
      }
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Sportset Customer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2E7D32),
        ),
        scaffoldBackgroundColor: const Color(0xFFE8F5E9),
        useMaterial3: true,
        fontFamily: 'Lexend',
      ),
      initialRoute: '/',
      routes: {
        // Initial route - check if intro was completed
        '/': (context) => const SplashScreen(),
        
        // Intro route
        '/intro': (context) => const IntroScreen(),
        
        // Auth routes
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/otp-verification': (context) => const OtpVerificationScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/reset-password-success': (context) => const ResetPasswordSuccessScreen(),
        '/email-verification': (context) => const EmailVerificationScreen(),
        '/email-verified': (context) => const EmailVerifiedScreen(),
        
        // Main app with bottom navigation
        '/main': (context) => const MainNavigationScreen(),
        
        // Individual screens (accessible from main navigation)
        '/home': (context) => const HomeScreen(),
        '/explore': (context) => const ExploreScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/booking-history': (context) => const BookingHistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
        
        // Field and booking flow
        '/venue-detail': (context) => const VenueDetailScreen(),
        '/field-detail': (context) => const FieldDetailScreen(),
        '/booking': (context) => const BookingScreen(),
        '/booking-confirmation': (context) => const BookingConfirmationScreen(),
        '/voucher-selection': (context) => const VoucherSelectionScreen(),
        '/booking-success': (context) => const BookingSuccessScreen(),
        
        // Rating
        '/rating': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return RatingScreen(
            bookingId: args?['bookingId'] ?? '',
            fieldId: args?['fieldId'] ?? '',
            fieldName: args?['fieldName'] ?? '',
            fieldImage: args?['fieldImage'] ?? '',
            playDate: args?['playDate'] ?? '',
          );
        },
        
        // Profile sections
        '/edit-profile': (context) => const EditProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        '/vouchers': (context) => const VouchersScreen(),

        // Payment
        '/payment': (context) => const PaymentScreen(),
        '/payment-result': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return PaymentResultScreen(
            resultCode: args?['resultCode'] ?? '',
            orderId: args?['orderId'] ?? '',
            message: args?['message'] ?? '',
          );
        },
      },
    );
  }
}

// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _didInitIndex = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitIndex) return;
    _didInitIndex = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['initialIndex'] is int) {
      _currentIndex = args['initialIndex'] as int;
    }
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const FavoritesScreen(),
    const BookingHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Trang chủ', 0),
                _buildNavItem(Icons.explore, 'Khám phá', 1),
                _buildNavItem(Icons.favorite, 'Yêu thích', 2),
                _buildNavItem(Icons.calendar_today, 'Lịch đặt', 3),
                _buildNavItem(Icons.person, 'Tài khoản', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? const Color(0xFF4CAF50)
                : const Color(0xFF9E9E9E),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF9E9E9E),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Splash screen to check if intro was completed
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkIntroStatus();
  }

  Future<void> _checkIntroStatus() async {
    // Wait a moment to show splash
    await Future.delayed(const Duration(milliseconds: 500));
    
    final prefs = await SharedPreferences.getInstance();
    final introCompleted = prefs.getBool('intro_completed') ?? false;
    
    if (mounted) {
      if (introCompleted) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/intro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF2E7D32),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 70,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SPORTSET',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
