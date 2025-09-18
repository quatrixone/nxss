import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/session.dart';
import '../services/api.dart';
import 'files_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _defaultBaseUrl() {
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://127.0.0.1:8080';
  }
  late final TextEditingController _serverCtrl = TextEditingController(text: _defaultBaseUrl());
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    SessionStore.getBaseUrl().then((v) {
      if (v != null) _serverCtrl.text = v;
      setState(() {});
    });
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      final baseUrl = _serverCtrl.text.trim();
      if (baseUrl.isEmpty) throw Exception('Server URL required');
      await SessionStore.setBaseUrl(baseUrl);
      final api = NxssApi(baseUrl: baseUrl);
      final token = await api.loginOrRegister(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      await SessionStore.setToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const FilesScreen()));
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to NXSS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _serverCtrl, decoration: const InputDecoration(labelText: 'Server URL', hintText: 'http://host:8080')),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator() : const Text('Continue')),
          ],
        ),
      ),
    );
  }
}


