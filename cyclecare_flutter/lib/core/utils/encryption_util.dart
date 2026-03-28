import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionUtil {
  EncryptionUtil._();

  /// Simple XOR-based encryption for local backup data.
  /// For production, use a proper AES library.
  static String encryptData(String plaintext, String userToken) {
    final key = sha256.convert(utf8.encode(userToken)).bytes;
    final input = utf8.encode(plaintext);
    final output = List<int>.generate(
      input.length,
      (i) => input[i] ^ key[i % key.length],
    );
    return base64.encode(output);
  }

  static String decryptData(String ciphertext, String userToken) {
    final key = sha256.convert(utf8.encode(userToken)).bytes;
    final input = base64.decode(ciphertext);
    final output = List<int>.generate(
      input.length,
      (i) => input[i] ^ key[i % key.length],
    );
    return utf8.decode(output);
  }

  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }
}
