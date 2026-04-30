import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Pastikan import ini ada

import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'ui/app_theme.dart';
import 'ui/glass.dart';
import 'auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // [TAMBAHAN BARU]: Load file .env di sini
  await dotenv.load(fileName: ".env");

  // On Web, FirebaseOptions must be provided (no native config files).
  // On mobile, options are typically read from google-services / plist.
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _prefsKeyThemeMode = 'alterego_theme_mode';
  ThemeMode themeMode = ThemeMode.system;
  bool isLoadingTheme = true;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKeyThemeMode);
    ThemeMode mode;
    switch (value) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      default:
        mode = ThemeMode.system;
    }
    if (!mounted) return;
    setState(() {
      themeMode = mode;
      isLoadingTheme = false;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_prefsKeyThemeMode, value);
    if (!mounted) return;
    setState(() {
      themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingTheme) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final signedIn = AppWrapper(
      themeMode: themeMode,
      onThemeModeChanged: _setThemeMode,
    );

    final home = Firebase.apps.isEmpty ? signedIn : AuthGate(signedIn: signedIn);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: home,
    );
  }
}

class AppWrapper extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const AppWrapper({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return GlassBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              width: 360,
              height: 720,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12)
                ],
              ),
              child: MainScreen(
                themeMode: themeMode,
                onThemeModeChanged: onThemeModeChanged,
              ),
            ),
          ),
        ),
      );
    } else {
      return MainScreen(
        themeMode: themeMode,
        onThemeModeChanged: onThemeModeChanged,
      );
    }
  }
}