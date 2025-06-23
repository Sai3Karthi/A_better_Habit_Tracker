import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'providers.dart';
import 'screens/home_screen.dart';
import 'themes/habit_theme.dart';
import 'themes/color_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show splash immediately
  runApp(const SplashApp());

  // Initialize in background
  final habitBox = await _initializeApp();

  // Launch main app
  runApp(
    ProviderScope(
      overrides: [habitBoxProvider.overrideWithValue(habitBox)],
      child: const MyApp(),
    ),
  );
}

Future<Box<Habit>> _initializeApp() async {
  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters - CRITICAL: Register HabitTypeAdapter first!
  Hive.registerAdapter(HabitTypeAdapter());
  Hive.registerAdapter(HabitAdapter());

  // Open Hive box
  return await Hive.openBox<Habit>('habits');
}

// Lightweight splash screen
class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        color: const Color(0xFF121212), // Dark background
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Warm up shaders on first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      // This helps with first animation jank
    });
  }

  @override
  Widget build(BuildContext context) {
    // Create a clean dark theme with our HabitTheme extension
    final darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.dark,
      ),
      // Add our single clean dark theme extension
      extensions: [HabitTheme.darkTheme()],
    );

    return MaterialApp(
      title: 'Elysian Goals',
      theme: darkTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
