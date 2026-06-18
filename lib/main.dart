import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:alterego/screens/main_screen.dart';
import 'ui/app_theme.dart';
import 'ui/glass.dart';
import 'auth/auth_gate.dart';
import 'view_models/chat_view_model.dart';
import 'view_models/reflection_view_model.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/profile_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatViewModel()), 
        ChangeNotifierProvider(create: (_) => ReflectionViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const MyApp(),
    ),
  );
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
      case 'light': mode = ThemeMode.light; break;
      case 'dark': mode = ThemeMode.dark; break;
      default: mode = ThemeMode.system;
    }
    if (!mounted) return;
    setState(() { themeMode = mode; isLoadingTheme = false; });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light ? 'light' : (mode == ThemeMode.dark ? 'dark' : 'system');
    await prefs.setString(_prefsKeyThemeMode, value);
    if (!mounted) return;
    setState(() => themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingTheme) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));

    final signedIn = AppWrapper(themeMode: themeMode, onThemeModeChanged: _setThemeMode);
    final home = Firebase.apps.isEmpty ? signedIn : AuthGate(signedIn: signedIn);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(), // Paksa Dark Mode untuk UI Glassmorphism
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      
      // 👇 INI KUNCINYA BRAY: Global Wrapper untuk Web 👇
      builder: (context, child) {
        if (kIsWeb) {
          // Bungkus seluruh navigasi aplikasi di dalam kontainer HP
          return Scaffold(
            backgroundColor: const Color(0xFF06152D), // Warna background luar HP
            body: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24), // Bikin sudut HP melengkung
                child: SizedBox(
                  width: 360,
                  height: 720,
                  // Tampilkan apapun halaman yang lagi aktif di dalam sini
                  child: child, 
                ),
              ),
            ),
          );
        }
        // Kalau di HP Android/iOS asli, lepas aja tanpa dibungkus
        return child!;
      },
      
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
    required this.onThemeModeChanged
  });

  @override
  Widget build(BuildContext context) {
    // AppWrapper sekarang murni nge-return MainScreen karena batasan Web udah pindah ke global
    return MainScreen(themeMode: themeMode, onThemeModeChanged: onThemeModeChanged);
  }
}