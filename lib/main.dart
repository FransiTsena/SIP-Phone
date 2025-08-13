import 'package:fe/screens/sip_phone_page.dart';
import 'package:fe/api/config.dart';
import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'services/call_overlay_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIP Phone',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      navigatorKey: CallOverlayService.instance.navigatorKey,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (loggedIn) {
      final username = prefs.getString('username') ?? '';
      final accessToken = prefs.getString('access_token') ?? '';
      if (accessToken.isEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }
      final sipPassword = accessToken.substring(0, 16);
      // print("sipPassword" + sipPassword);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              SipPhonePage(username: username, password: sipPassword),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withOpacity(.08),
              ),
              child: Icon(Icons.phone_in_talk, size: 78, color: scheme.primary),
            ),
            const SizedBox(height: 34),
            Text(
              'SIP Phone',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black87,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Secure • Fast • Reliable',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                fontSize: 15,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

// Removed decorative blurred circles for a clean Material 3 white splash.
