import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class PhotoService {
  static final _picker = ImagePicker();
  static final _storage = FirebaseStorage.instance;

  static Future<String?> captureAndUpload(String issueId) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (picked == null) return null;
      final file = File(picked.path);
      final name = 'issues/$issueId/photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final ref = _storage.ref().child(name);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) { return null; }
  }

  static Future<String?> chooseAndUpload(String issueId) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked == null) return null;
      final file = File(picked.path);
      final name = 'issues/$issueId/photo_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final ref = _storage.ref().child(name);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) { return null; }
  }
}
