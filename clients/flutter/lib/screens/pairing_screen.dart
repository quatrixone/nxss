import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session.dart';
import '../services/api.dart';
import 'sync_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _serverUrl;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadServerUrl() async {
    final url = await SessionStore.getBaseUrl();
    setState(() {
      _serverUrl = url ?? 'http://127.0.0.1:8080';
      _serverUrlController.text = _serverUrl!;
    });
  }

  Future<void> _verifyPairingCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a pairing code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = NxssApi(baseUrl: _serverUrl!);
      final result = await api.verifyPairingCode(_codeController.text.trim().toUpperCase());
      
      // Save the server URL and pairing success
      await SessionStore.setBaseUrl(_serverUrl!);
      await _savePairingSuccess();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SyncScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePairingSuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pairing_completed', true);
  }

  void _openPairingPage() {
    final url = '$_serverUrl/pairing';
    // In a real app, you might want to use url_launcher
    // For now, we'll show a dialog with instructions
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Get Pairing Code'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To get a pairing code:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('1. Open your web browser'),
            const Text('2. Go to:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('3. Click "Generate Code"'),
            const Text('4. Copy the code and paste it below'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // App logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sync,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('NXSS Pairing'),
          ],
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const SizedBox(height: 40),
            Icon(
              Icons.devices,
              size: 80,
              color: Colors.indigo[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Pair Your Device',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the pairing code from your server to connect',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Server URL
            Text(
              'Server URL',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                hintText: 'http://127.0.0.1:8080',
                prefixIcon: const Icon(Icons.dns),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _serverUrl = value.trim();
                });
              },
            ),
            const SizedBox(height: 24),

            // Pairing Code
            Text(
              'Pairing Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Enter 6-character code',
                prefixIcon: const Icon(Icons.vpn_key),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (value) {
                setState(() {
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Get Pairing Code Button
            OutlinedButton.icon(
              onPressed: _openPairingPage,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Get Pairing Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Error Message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Pair Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyPairingCode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Pair Device',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),

            const Spacer(),

            // Help Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'How to pair:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Make sure your NXSS server is running\n'
                    '2. Open the pairing page in your browser\n'
                    '3. Generate a pairing code\n'
                    '4. Enter the code above to connect',
                    style: TextStyle(color: Colors.blue[700], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
