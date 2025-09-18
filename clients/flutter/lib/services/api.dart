import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class NxssApi {
  final String baseUrl;

  const NxssApi({required this.baseUrl});

  Future<Map<String, dynamic>> verifyPairingCode(String code) async {
    final uri = Uri.parse('$baseUrl/api/pairing/verify');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );
    
    if (r.statusCode == 200) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } else if (r.statusCode == 404) {
      throw HttpException('Invalid pairing code');
    } else if (r.statusCode == 410) {
      throw HttpException('Pairing code expired');
    } else {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      throw HttpException('Pairing failed: ${body['error'] ?? r.statusCode}');
    }
  }

  Future<List<dynamic>> listFiles() async {
    final uri = Uri.parse('$baseUrl/files');
    final r = await http.get(uri);
    if (r.statusCode != 200) throw HttpException('List failed: ${r.statusCode}');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<void> uploadFile(File file, {String? relPath}) async {
    final uri = Uri.parse('$baseUrl/files/upload');
    final req = http.MultipartRequest('POST', uri);
    final rp = relPath ?? p.basename(file.path);
    final lm = await file.lastModified();
    req.fields['relPath'] = rp;
    req.fields['lastModified'] = lm.millisecondsSinceEpoch.toString();
    req.fields['folderId'] = 'default'; // Use a default folder ID for now
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    if (streamed.statusCode != 200) {
      final body = await streamed.stream.bytesToString();
      throw HttpException('Upload failed: ${streamed.statusCode} $body');
    }
  }

  Future<void> syncFolder(String folderPath, String serverFolderName) async {
    final uri = Uri.parse('$baseUrl/sync/folder');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'folderPath': folderPath,
        'folderId': serverFolderName, // Use server folder name as folder ID
      }),
    );
    if (r.statusCode != 200) {
      throw HttpException('Sync failed: ${r.statusCode}');
    }
  }

  Future<List<dynamic>> getServerFolders() async {
    final uri = Uri.parse('$baseUrl/folders');
    final r = await http.get(uri);
    if (r.statusCode != 200) throw HttpException('List server folders failed: ${r.statusCode}');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<List<dynamic>> getFolderFiles(String folderId) async {
    final uri = Uri.parse('$baseUrl/folders/$folderId/files');
    final r = await http.get(uri);
    if (r.statusCode != 200) throw HttpException('List folder files failed: ${r.statusCode}');
    return jsonDecode(r.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> getSettings() async {
    final uri = Uri.parse('$baseUrl/settings');
    final r = await http.get(uri);
    if (r.statusCode != 200) throw HttpException('Get settings failed: ${r.statusCode}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStorageSettings({
    required String provider,
    String? credentials,
  }) async {
    final uri = Uri.parse('$baseUrl/settings/storage');
    final r = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'credentials': credentials,
      }),
    );
    if (r.statusCode != 200) {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      throw HttpException('Update storage settings failed: ${body['error'] ?? r.statusCode}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}


