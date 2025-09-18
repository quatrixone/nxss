import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/session.dart';
import '../services/api.dart';
import 'settings_screen.dart';

class SyncFolder {
  final String id;
  final String name;
  final String path;
  final String serverFolderName; // Name of folder on server
  final bool isPaired; // Whether this is a paired folder
  final bool isSyncing;
  final DateTime? lastSync;
  final String? status;

  SyncFolder({
    required this.id,
    required this.name,
    required this.path,
    required this.serverFolderName,
    this.isPaired = false,
    this.isSyncing = false,
    this.lastSync,
    this.status,
  });

  SyncFolder copyWith({
    String? id,
    String? name,
    String? path,
    String? serverFolderName,
    bool? isPaired,
    bool? isSyncing,
    DateTime? lastSync,
    String? status,
  }) {
    return SyncFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      serverFolderName: serverFolderName ?? this.serverFolderName,
      isPaired: isPaired ?? this.isPaired,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSync: lastSync ?? this.lastSync,
      status: status ?? this.status,
    );
  }
}

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  List<SyncFolder> _folders = [];
  bool _isLoading = false;
  String? _error;
  String? _serverUrl;
  bool _debugMode = false;
  bool _debugConsoleVisible = false;
  List<String> _debugLogs = [];

  Future<NxssApi> _api() async {
    final baseUrl = _serverUrl ?? 'http://127.0.0.1:8080';
    return NxssApi(baseUrl: baseUrl);
  }

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
    _loadFolders();
    _loadDebugMode();
  }

  Future<void> _loadServerUrl() async {
    final url = await SessionStore.getBaseUrl();
    setState(() {
      _serverUrl = url ?? 'http://127.0.0.1:8080';
    });
  }

  Future<void> _loadFolders() async {
    _addDebugLog('Loading saved folders...');
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getString('sync_folders');
    if (foldersJson != null) {
      final List<dynamic> foldersList = jsonDecode(foldersJson);
      setState(() {
        _folders = foldersList.map((f) => SyncFolder(
          id: f['id'],
          name: f['name'],
          path: f['path'],
          serverFolderName: f['serverFolderName'] ?? f['name'], // Fallback for old data
          isPaired: f['isPaired'] ?? false,
          isSyncing: false,
          lastSync: f['lastSync'] != null ? DateTime.fromMillisecondsSinceEpoch(f['lastSync']) : null,
          status: f['status'],
        )).toList();
      });
      _addDebugLog('Loaded ${_folders.length} folders');
    } else {
      _addDebugLog('No saved folders found');
    }
  }

  Future<void> _addFolder() async {
    _addDebugLog('Opening folder picker...');
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) {
        _addDebugLog('Folder selection cancelled');
        return;
      }
      _addDebugLog('Selected folder: $result');

      final localFolderName = result.split(Platform.pathSeparator).last;
      
      // Show dialog to choose sync type
      final syncType = await _showSyncTypeDialog();
      if (syncType == null) return;

      String serverFolderName = localFolderName;
      bool isPaired = false;

      if (syncType == 'paired') {
        // Show dialog to enter server folder name
        final serverName = await _showServerFolderDialog(localFolderName);
        if (serverName == null) return;
        serverFolderName = serverName;
        isPaired = true;
      }

      final folder = SyncFolder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: localFolderName,
        path: result,
        serverFolderName: serverFolderName,
        isPaired: isPaired,
      );

      setState(() {
        _folders = [..._folders, folder];
      });

      // Save folders to local storage
      await _saveFolders();
    } catch (e) {
      _showError('Failed to add folder: $e');
    }
  }

  Future<String?> _showSyncTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Sync Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Normal Sync'),
              subtitle: const Text('Sync with same folder name on server'),
              onTap: () => Navigator.pop(context, 'normal'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Paired Sync'),
              subtitle: const Text('Sync with different folder name on server'),
              onTap: () => Navigator.pop(context, 'paired'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showServerFolderDialog(String localFolderName) async {
    return showDialog<String>(
      context: context,
      builder: (context) => ServerFolderSelectorDialog(
        localFolderName: localFolderName,
        api: _api,
      ),
    );
  }

  Future<void> _removeFolder(String id) async {
    setState(() {
      _folders = _folders.where((f) => f.id != id).toList();
    });
    await _saveFolders();
  }

  Future<void> _editFolder(SyncFolder folder) async {
    final serverName = await _showServerFolderDialog(folder.name);
    if (serverName == null) return;

    setState(() {
      _folders = _folders.map((f) => 
        f.id == folder.id ? f.copyWith(
          serverFolderName: serverName,
          isPaired: serverName != folder.name,
        ) : f
      ).toList();
    });
    await _saveFolders();
  }

  Future<void> _startSync(String folderId) async {
    _addDebugLog('Starting sync for folder: $folderId');
    setState(() {
      _folders = _folders.map((f) => 
        f.id == folderId ? f.copyWith(isSyncing: true, status: 'Starting sync...') : f
      ).toList();
    });

    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      _addDebugLog('Syncing folder: ${folder.name} -> ${folder.serverFolderName}');
      final api = await _api();
      
      // Call the actual sync API with server folder name
      await api.syncFolder(folder.path, folder.serverFolderName);
      
      _addDebugLog('Sync completed successfully for: ${folder.name}');
      setState(() {
        _folders = _folders.map((f) => 
          f.id == folderId ? f.copyWith(
            isSyncing: false, 
            lastSync: DateTime.now(),
            status: 'Sync completed'
          ) : f
        ).toList();
      });
    } catch (e) {
      _addDebugLog('Sync failed for folder $folderId: $e');
      String errorMessage = 'Sync failed: $e';
      if (e.toString().contains('Connection refused')) {
        errorMessage = 'Sync failed: Cannot connect to server. Check server URL in settings.';
      } else if (e.toString().contains('ENOENT')) {
        errorMessage = 'Sync failed: Folder not found or inaccessible.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Sync failed: Request timeout. Check your connection.';
      }
      
      setState(() {
        _folders = _folders.map((f) => 
          f.id == folderId ? f.copyWith(
            isSyncing: false, 
            status: errorMessage
          ) : f
        ).toList();
      });
    }
  }

  Future<void> _stopSync(String folderId) async {
    setState(() {
      _folders = _folders.map((f) => 
        f.id == folderId ? f.copyWith(isSyncing: false, status: 'Sync stopped') : f
      ).toList();
    });
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = jsonEncode(_folders.map((f) => {
      'id': f.id,
      'name': f.name,
      'path': f.path,
      'serverFolderName': f.serverFolderName,
      'isPaired': f.isPaired,
      'lastSync': f.lastSync?.millisecondsSinceEpoch,
      'status': f.status,
    }).toList());
    await prefs.setString('sync_folders', foldersJson);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _loadDebugMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _debugMode = prefs.getBool('debug_mode') ?? false;
    });
  }

  void _addDebugLog(String message) {
    if (_debugMode) {
      setState(() {
        _debugLogs.add('${DateTime.now().toString().substring(11, 19)}: $message');
        if (_debugLogs.length > 100) {
          _debugLogs.removeAt(0); // Keep only last 100 logs
        }
      });
    }
  }

  void _toggleDebugConsole() {
    setState(() {
      _debugConsoleVisible = !_debugConsoleVisible;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
            // App title
            const Expanded(
              child: Text(
                'NXSS: Cross-Platform File Sync System',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          
          // Folders list
          Expanded(
        child: _folders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sync,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'NXSS: Cross-Platform File Sync System',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No folders added yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add a folder to sync',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
                : ListView.builder(
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Icon(
                            folder.isSyncing ? Icons.sync : (folder.isPaired ? Icons.link : Icons.folder),
                            color: folder.isSyncing ? Colors.blue : (folder.isPaired ? Colors.purple : Colors.grey[600]),
                          ),
                          title: Row(
                            children: [
                              Text(folder.name),
                              if (folder.isPaired) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'Paired',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(folder.path, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              if (folder.isPaired)
                                Text(
                                  'Server: ${folder.serverFolderName}',
                                  style: TextStyle(fontSize: 12, color: Colors.purple[600]),
                                ),
                              if (folder.status != null)
                                Text(
                                  folder.status!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: folder.status!.contains('failed') ? Colors.red : Colors.green,
                                  ),
                                ),
                              if (folder.lastSync != null)
                                Text(
                                  'Last sync: ${_formatDateTime(folder.lastSync!)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editFolder(folder),
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Edit Folder',
                              ),
                              if (folder.isSyncing)
                                IconButton(
                                  onPressed: () => _stopSync(folder.id),
                                  icon: const Icon(Icons.stop, color: Colors.red),
                                  tooltip: 'Stop Sync',
                                )
                              else
                                IconButton(
                                  onPressed: () => _startSync(folder.id),
                                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                                  tooltip: 'Start Sync',
                                ),
                              IconButton(
                                onPressed: () => _removeFolder(folder.id),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Remove Folder',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFolder,
        child: const Icon(Icons.add),
        tooltip: 'Add Folder',
      ),
        ),
        // Debug Console Overlay
        if (_debugMode && _debugConsoleVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Debug Console Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Debug Console',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _toggleDebugConsole,
                          icon: const Icon(Icons.close, color: Colors.white),
                          tooltip: 'Close Debug Console',
                        ),
                      ],
                    ),
                  ),
                  // Debug Logs
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: _debugLogs.isEmpty
                          ? const Center(
                              child: Text(
                                'No debug logs yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _debugLogs.length,
                              itemBuilder: (context, index) {
                                final log = _debugLogs[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    log,
                                    style: const TextStyle(
                                      color: Colors.green,
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
            ),
          ),
        // Debug Console Toggle Button
        if (_debugMode && !_debugConsoleVisible)
          Positioned(
            bottom: 16,
            right: 80,
            child: FloatingActionButton.small(
              onPressed: _toggleDebugConsole,
              backgroundColor: Colors.green,
              child: const Icon(Icons.bug_report, color: Colors.white),
              tooltip: 'Open Debug Console',
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ServerFolderSelectorDialog extends StatefulWidget {
  final String localFolderName;
  final Future<NxssApi> Function() api;

  const ServerFolderSelectorDialog({
    super.key,
    required this.localFolderName,
    required this.api,
  });

  @override
  State<ServerFolderSelectorDialog> createState() => _ServerFolderSelectorDialogState();
}

class _ServerFolderSelectorDialogState extends State<ServerFolderSelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  List<dynamic> _serverFolders = [];
  List<dynamic> _filteredFolders = [];
  bool _isLoading = true;
  String? _error;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _customNameController.text = widget.localFolderName;
    _loadServerFolders();
    _searchController.addListener(_filterFolders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  Future<void> _loadServerFolders() async {
    try {
      final api = await widget.api();
      final folders = await api.getServerFolders();
      setState(() {
        _serverFolders = folders;
        _filteredFolders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterFolders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFolders = _serverFolders.where((folder) {
        return folder['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectFolder(String folderName) {
    Navigator.pop(context, folderName);
  }

  void _toggleCustomInput() {
    setState(() {
      _showCustomInput = !_showCustomInput;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_open, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Select Server Folder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local folder: ${widget.localFolderName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search server folders...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle between list and custom input
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleCustomInput,
                    icon: Icon(_showCustomInput ? Icons.list : Icons.edit),
                    label: Text(_showCustomInput ? 'Browse Folders' : 'Custom Name'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showCustomInput ? Colors.grey[200] : Colors.indigo,
                      foregroundColor: _showCustomInput ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content area
            Expanded(
              child: _showCustomInput ? _buildCustomInput() : _buildFolderList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (_showCustomInput)
          ElevatedButton(
            onPressed: () {
              final name = _customNameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Use Custom Name'),
          ),
      ],
    );
  }

  Widget _buildCustomInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter custom folder name:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customNameController,
          decoration: const InputDecoration(
            labelText: 'Server folder name',
            hintText: 'Enter folder name for server',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will create a new folder on the server with the specified name.',
                  style: TextStyle(color: Colors.blue[700], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFolderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load server folders',
              style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadServerFolders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredFolders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, color: Colors.grey[400], size: 48),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                  ? 'No server folders found'
                  : 'No folders match your search',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'Create a custom folder name instead'
                  : 'Try a different search term',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredFolders.length,
      itemBuilder: (context, index) {
        final folder = _filteredFolders[index];
        final fileCount = folder['fileCount'] as int;
        final lastModified = folder['lastModified'] as int?;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.indigo[100],
            child: Icon(Icons.folder, color: Colors.indigo[700]),
          ),
          title: Text(
            folder['name'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$fileCount file${fileCount != 1 ? 's' : ''}'),
              if (lastModified != null && lastModified > 0)
                Text(
                  'Modified: ${_formatDateTime(DateTime.fromMillisecondsSinceEpoch(lastModified))}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _selectFolder(folder['name']),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
