import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionUtil {
  EncryptionUtil._();

  static encrypt.Key _deriveKey(String userToken) {
    final hash = sha256.convert(utf8.encode(userToken));
    return encrypt.Key.fromBase64(base64.encode(hash.bytes));
  }

  static String encryptData(String plaintext, String userToken) {
    final key = _deriveKey(userToken);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptData(String ciphertext, String userToken) {
    final key = _deriveKey(userToken);
    final parts = ciphertext.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
