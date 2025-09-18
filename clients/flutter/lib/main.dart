import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/sync_screen.dart';
import 'screens/pairing_screen.dart';
import 'services/session.dart';

void main() {
  runApp(const NxssApp());
}

class NxssApp extends StatelessWidget {
  const NxssApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NXSS: Cross-Platform File Sync System',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const InitialScreen(),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _isPaired = false;

  @override
  void initState() {
    super.initState();
    _checkPairingStatus();
  }

  Future<void> _checkPairingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isPaired = prefs.getBool('pairing_completed') ?? false;
    
    setState(() {
      _isPaired = isPaired;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isPaired ? const SyncScreen() : const PairingScreen();
  }
}

