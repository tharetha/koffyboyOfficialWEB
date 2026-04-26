import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const KoffyboyArtistApp());
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class KoffyboyArtistApp extends StatelessWidget {
  const KoffyboyArtistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Koffyboy Official',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFFFF9900),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF9900),
              secondary: Color(0xFF00E676),
              surface: Colors.white,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
            ),
            fontFamily: 'Outfit',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            primaryColor: const Color(0xFFFF9900),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFF9900),
              secondary: Color(0xFF00E676),
              surface: Color(0xFF1E1E1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0A0A0A),
              elevation: 0,
              centerTitle: false,
            ),
            fontFamily: 'Outfit',
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
