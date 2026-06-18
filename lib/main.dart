import 'package:flutter/material.dart';
import 'package:works_app/services/storage_service.dart';
import 'package:works_app/config/theme.dart';
import 'package:works_app/screens/main_screen.dart';
import 'package:works_app/models/user_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const WorksApp());
}

class WorksApp extends StatelessWidget {
  const WorksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Works',
      debugShowCheckedModeBanner: false,
      theme: getTheme(false),
      darkTheme: getTheme(true),
      themeMode: ThemeMode.system,
      home: const SplashLoader(),
    );
  }
}

class SplashLoader extends StatefulWidget {
  const SplashLoader({super.key});

  @override
  State<SplashLoader> createState() => _SplashLoaderState();
}

class _SplashLoaderState extends State<SplashLoader> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await StorageService().loadUserData();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(userData: data ?? UserData()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
