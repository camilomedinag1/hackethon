import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecognitionService {
  RecognitionService(this._prefs);

  static const String _kDbKey = 'face_db_v1';
  final SharedPreferences _prefs;

  Future<void> saveIdentity(String personId, List<double> embedding, {String? imagePath}) async {
    final Map<String, dynamic> db = await _readDb();
    db[personId] = <String, dynamic>{
      'embedding': embedding,
      'imagePath': imagePath,
    };
    await _prefs.setString(_kDbKey, jsonEncode(db));
  }

  Future<Map<String, dynamic>> _readDb() async {
    final String? json = _prefs.getString(_kDbKey);
    if (json == null) return <String, dynamic>{};
    return jsonDecode(json) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> readAll() async {
    return _readDb();
  }

  Future<void> deleteIdentity(String personId, {bool deleteImage = true}) async {
    final Map<String, dynamic> db = await _readDb();
    final dynamic val = db.remove(personId);
    await _prefs.setString(_kDbKey, jsonEncode(db));
    if (deleteImage) {
      try {
        if (val is Map && val['imagePath'] is String) {
          final String path = val['imagePath'] as String;
          final File f = File(path);
          if (await f.exists()) {
            await f.delete();
          }
        }
      } catch (_) {
        // Ignorar errores de borrado de archivo
      }
    }
  }

  Future<String?> identify(List<double> embedding, {double threshold = 1.05}) async {
    final Map<String, dynamic> db = await _readDb();
    String? bestId;
    double bestDist = double.infinity;
    for (final MapEntry<String, dynamic> e in db.entries) {
      final dynamic val = e.value;
      List<double>? vector;
      if (val is List) {
        // Compat: registros antiguos solo tenían lista de embedding
        vector = val.cast<double>();
      } else if (val is Map) {
        final List<dynamic>? emb = val['embedding'] as List<dynamic>?;
        if (emb != null) {
          vector = emb.cast<double>();
        }
      }
      if (vector == null) continue;
      final double dist = _euclidean(embedding, vector);
      if (dist < bestDist) {
        bestDist = dist;
        bestId = e.key;
      }
    }
    if (bestDist <= threshold) return bestId;
    return null;
  }

  double _euclidean(List<double> a, List<double> b) {
    final int n = a.length;
    double sum = 0;
    for (int i = 0; i < n; i++) {
      final double d = a[i] - b[i];
      sum += d * d;
    }
    return sum.sqrt();
  }
}

extension on double {
  double sqrt() => this <= 0 ? 0 : (this).toDouble()._sqrtNewton();
}

extension on double {
  double _sqrtNewton() {
    double x = this;
    double g = this / 2.0;
    for (int i = 0; i < 8; i++) {
      g = 0.5 * (g + x / g);
    }
    return g;
  }
}


