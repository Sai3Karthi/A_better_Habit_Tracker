import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/habit.dart';
import 'providers.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters - CRITICAL: Register HabitTypeAdapter first!
  Hive.registerAdapter(HabitTypeAdapter());
  Hive.registerAdapter(HabitAdapter());

  // Open Hive box
  final habitBox = await Hive.openBox<Habit>('habits');

  runApp(
    ProviderScope(
      overrides: [habitBoxProvider.overrideWithValue(habitBox)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elysian Goals',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}
