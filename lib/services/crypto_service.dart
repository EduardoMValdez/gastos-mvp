import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  CryptoService._();
  static final CryptoService instance = CryptoService._();

  static const _keyName = 'aes_key_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late enc.Encrypter _encrypter;

  Future<void> init() async {
    var b64 = await _storage.read(key: _keyName);
    if (b64 == null) {
      final rnd = Random.secure();
      b64 = base64Encode(List<int>.generate(32, (_) => rnd.nextInt(256)));
      await _storage.write(key: _keyName, value: b64);
    }
    _encrypter = enc.Encrypter(
      enc.AES(enc.Key(base64Decode(b64)), mode: enc.AESMode.gcm),
    );
  }

  String encrypt(String plain) {
    if (plain.isEmpty) return '';
    final iv = enc.IV.fromSecureRandom(12);
    return '${iv.base64}:${_encrypter.encrypt(plain, iv: iv).base64}';
  }

  String decrypt(String stored) {
    if (stored.isEmpty) return '';
    try {
      final parts = stored.split(':');
      return _encrypter.decrypt(
        enc.Encrypted.fromBase64(parts[1]),
        iv: enc.IV.fromBase64(parts[0]),
      );
    } catch (_) {
      return '';
    }
  }
}