import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/api.dart';
import 'login_screen.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<dynamic> _files = const [];
  bool _loading = true;
  String? _error;

  Future<NxssApi> _api() async {
    final baseUrl = await SessionStore.getBaseUrl() ?? '';
    final token = await SessionStore.getToken();
    return NxssApi(baseUrl: baseUrl, token: token);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = await _api();
      final list = await api.listFiles();
      setState(() { _files = list; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final res = await FilePicker.platform.pickFiles(withData: false);
      if (res == null || res.files.isEmpty) return;
      final path = res.files.single.path;
      if (path == null) return;
      final api = await _api();
      await api.uploadFile(File(path));
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _logout() async {
    await SessionStore.setToken(null);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your files'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, i) {
                      final f = _files[i] as Map<String, dynamic>;
                      final name = f['relPath'] as String? ?? 'unknown';
                      final size = f['size']?.toString() ?? '';
                      return ListTile(title: Text(name), subtitle: Text('$size bytes'));
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUpload,
        child: const Icon(Icons.upload),
      ),
    );
  }
}


