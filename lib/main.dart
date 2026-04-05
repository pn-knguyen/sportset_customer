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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SportsetApp());
}

class SportsetApp extends StatelessWidget {
  const SportsetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sportset Customer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF9800),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9800),
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFFF44336),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F6),
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
                ? const Color(0xFFFF9800)
                : const Color(0xFF1A237E).withValues(alpha: 0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFFFF9800)
                  : const Color(0xFF1A237E).withValues(alpha: 0.6),
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
      backgroundColor: const Color(0xFFFF9800),
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
                    Color(0xFFFF9800),
                    Color(0xFFF44336),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
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
