import 'package:agora_poc/controllers/auth_controller.dart';
import 'package:agora_poc/home.dart';
import 'package:agora_poc/theme.dart';
import 'package:agora_poc/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/meeting_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<MeetingService>(create: (_) => MeetingService()..initialize()),
      ],
      child: MaterialApp(
        title: 'Agora Voice Call App',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AppStartup(),
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.isLoggedIn();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      return const HomeScreen();
    }

    return const WelcomeScreen();
  }
}
