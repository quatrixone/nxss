import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session.dart';
import '../services/api.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _serverUrlController;
  late TextEditingController _gdriveCredentialsController;
  bool _debugMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController();
    _gdriveCredentialsController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = await SessionStore.getBaseUrl() ?? _getDefaultServerUrl();
      final debugMode = prefs.getBool('debug_mode') ?? false;
      final gdriveCredentials = prefs.getString('gdrive_credentials') ?? '';
      
      setState(() {
        _serverUrlController.text = serverUrl;
        _debugMode = debugMode;
        _gdriveCredentialsController.text = gdriveCredentials;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getDefaultServerUrl() {
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://127.0.0.1:8080';
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = _serverUrlController.text.trim();
      
      // Save server URL
      await SessionStore.setBaseUrl(serverUrl);
      
      // Save debug mode
      await prefs.setBool('debug_mode', _debugMode);
      
      // Save Google Drive credentials
      await prefs.setString('gdrive_credentials', _gdriveCredentialsController.text.trim());
      
      // Update server storage settings if Google Drive credentials are provided
      if (_gdriveCredentialsController.text.trim().isNotEmpty) {
        try {
          final api = NxssApi(baseUrl: serverUrl);
          await api.updateStorageSettings(
            provider: 'gdrive',
            credentials: _gdriveCredentialsController.text.trim(),
          );
        } catch (e) {
          // If server update fails, still save local settings
          print('Failed to update server storage settings: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDebugConsole() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DebugConsoleScreen(),
      ),
    );
  }

  Future<void> _resetPairing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reset Pairing'),
          ],
        ),
        content: const Text(
          'This will reset your device pairing and you will need to enter a new pairing code to reconnect to the server. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pairing_completed', false);
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.sync,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Settings'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Server Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _serverUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://host:8080',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the URL of your NXSS server',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Storage Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Storage Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _gdriveCredentialsController,
                    decoration: const InputDecoration(
                      labelText: 'Google Drive Credentials (JSON)',
                      hintText: 'Paste your Google Drive service account JSON here',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Optional: Configure Google Drive storage. Leave empty to use local storage.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Debug Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Debug Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Debug Mode'),
                    subtitle: const Text('Show debug console and detailed logging'),
                    value: _debugMode,
                    onChanged: (value) {
                      setState(() {
                        _debugMode = value;
                      });
                    },
                  ),
                  if (_debugMode) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showDebugConsole,
                      icon: const Icon(Icons.terminal),
                      label: const Text('Open Debug Console'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Pairing Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.devices, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Device Pairing',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Device Status'),
                    subtitle: const Text('Successfully paired with server'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _resetPairing,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Pairing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reset pairing to connect to a different server or re-authenticate.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'App Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.storage),
                    title: const Text('Storage Provider'),
                    subtitle: Text(_gdriveCredentialsController.text.trim().isEmpty 
                        ? 'Local Storage' 
                        : 'Google Drive'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text('Server URL'),
                    subtitle: Text(_serverUrlController.text.trim().isEmpty 
                        ? _getDefaultServerUrl() 
                        : _serverUrlController.text.trim()),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Debug Mode'),
                    subtitle: Text(_debugMode ? 'Enabled' : 'Disabled'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addLog('Debug console initialized');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _testConnection() async {
    _addLog('Testing server connection...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final serverUrl = await SessionStore.getBaseUrl() ?? 'http://127.0.0.1:8080';
      
      _addLog('Connecting to: $serverUrl');
      
      final api = NxssApi(baseUrl: serverUrl);
      final settings = await api.getSettings();
      
      _addLog('Connection successful!');
      _addLog('Storage Provider: ${settings['storageProvider']}');
      _addLog('Server URL: ${settings['serverUrl']}');
      _addLog('Google Drive: ${settings['features']['googleDrive']}');
      _addLog('Local Storage: ${settings['features']['localStorage']}');
      _addLog('Debug Mode: ${settings['features']['debugMode']}');
    } catch (e) {
      _addLog('Connection test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Console'),
        actions: [
          IconButton(
            onPressed: _testConnection,
            icon: const Icon(Icons.wifi),
            tooltip: 'Test Connection',
          ),
          IconButton(
            onPressed: _clearLogs,
            icon: const Icon(Icons.clear),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Debug controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _testConnection,
                  icon: const Icon(Icons.wifi),
                  label: const Text('Test Connection'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          
          // Logs display
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No debug logs yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
