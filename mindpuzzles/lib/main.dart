import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/sudoku_screen.dart';
import 'screens/patches_screen.dart';
import 'screens/zip_screen.dart';
import 'screens/subscription_screen.dart';
import 'utils/game_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameState.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MindPuzzlesApp());
}

class MindPuzzlesApp extends StatelessWidget {
  const MindPuzzlesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindPuzzles India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          primary: const Color(0xFF1565C0),
          secondary: const Color(0xFF42A5F5),
          surface: Colors.white,
          background: const Color(0xFFF8FAFF),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFF),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1565C0),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            color: const Color(0xFF1565C0),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      routes: {
        '/': (ctx) => const HomeScreen(),
        '/sudoku': (ctx) => const SudokuScreen(),
        '/patches': (ctx) => const PatchesScreen(),
        '/zip': (ctx) => const ZipScreen(),
        '/subscription': (ctx) => const SubscriptionScreen(),
      },
      initialRoute: '/',
    );
  }
}
