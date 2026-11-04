import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/partner_share_code.dart';
import 'partner_sync_models.dart';

class PartnerSyncException implements Exception {
  const PartnerSyncException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PartnerServerConfig {
  const PartnerServerConfig(this.url, this.publicKey);
  final String url, publicKey;
  bool get valid {
    final u = Uri.tryParse(url);
    return u != null &&
        u.scheme == 'https' &&
        u.host.isNotEmpty &&
        u.userInfo.isEmpty &&
        (u.path.isEmpty || u.path == '/') &&
        !u.hasQuery &&
        !u.hasFragment &&
        publicKey.trim().isNotEmpty &&
        !publicKey.startsWith('sb_secret_') &&
        !_serviceRoleKey(publicKey);
  }

  static bool _serviceRoleKey(String key) {
    try {
      final parts = key.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map && payload['role'] == 'service_role';
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {'url': url, 'key': publicKey};
}

/// Authenticated Supabase REST/RPC transport. Never uses a service-role key.
/// No requests or anonymous identity creation occur merely by constructing it.
class PartnerSyncRepository {
  PartnerSyncRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
    Future<SharedPreferences> Function()? preferences,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferences.getInstance;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final Future<SharedPreferences> Function() _preferences;
  static const configKey = 'cc.partner.server.v1';
  static const _sessionKey = 'cc.partner.session.v1';
  static const _cacheKey = 'cc.partner.remote_cache.v1';
  PartnerServerConfig? _config;
  Map<String, dynamic>? _session;
  Future<void>? _authPending;
  String? get userId => (_session?['user'] as Map?)?['id'] as String?;
  PartnerServerConfig? get configuration => _config;
  bool get configured => _config?.valid ?? false;
  bool get signedIn => _session != null;

  Future<void> load() async {
    final prefs = await _preferences();
    final raw = prefs.getString(configKey);
    if (raw != null) {
      final j = jsonDecode(raw) as Map;
      _config = PartnerServerConfig(j['url'] as String, j['key'] as String);
    }
    if (raw == null) return;
    final session = await _storage.read(key: _sessionKey);
    if (session != null)
      _session = (jsonDecode(session) as Map).cast<String, dynamic>();
  }

  Future<void> configure(PartnerServerConfig config) async {
    if (!config.valid)
      throw const PartnerSyncException(
        'Use an HTTPS project URL and a publishable or anon key. Never enter a secret or service-role key.',
      );
    final previousUrl = _config?.url.replaceAll(RegExp(r'/$'), '');
    final nextUrl = config.url.replaceAll(RegExp(r'/$'), '');
    if (_session != null && previousUrl != null && previousUrl != nextUrl) {
      throw const PartnerSyncException(
        'Changing partner servers requires explicitly forgetting this device identity. Revoke existing connections first.',
      );
    }
    if (previousUrl != nextUrl) {
      await _storage.delete(key: _sessionKey);
      _session = null;
      await (await _preferences()).remove(_cacheKey);
    }
    final prefs = await _preferences();
    if (!await prefs.setString(configKey, jsonEncode(config.toJson())))
      throw const PartnerSyncException('Could not save server settings.');
    _config = config;
  }

  Future<void> authenticate({bool forceRefresh = false}) async {
    if (!configured)
      throw const PartnerSyncException('Set up the partner server first.');
    if (_authPending != null) return _authPending!;
    final operation = _authenticate(forceRefresh: forceRefresh);
    _authPending = operation;
    try {
      await operation;
    } finally {
      _authPending = null;
    }
  }

  Future<void> _authenticate({required bool forceRefresh}) async {
    if (!forceRefresh &&
        _session != null &&
        ((_session!['expires_at'] as num?)?.toInt() ?? 0) >
            DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60)
      return;
    final refresh = _session?['refresh_token'] as String?;
    if (_session != null && refresh == null) {
      throw const PartnerSyncException(
        'This device identity cannot be refreshed. Reauthorize it in partner settings.',
      );
    }
    final data = await _request(
      refresh == null
          ? '/auth/v1/signup'
          : '/auth/v1/token?grant_type=refresh_token',
      refresh == null ? {} : {'refresh_token': refresh},
      authenticated: false,
    );
    final session = (data as Map).cast<String, dynamic>();
    if (session['access_token'] is! String ||
        (session['user'] as Map?)?['id'] is! String) {
      throw const PartnerSyncException(
        'The server did not create a partner session. Enable anonymous sign-ins or reauthorize this device.',
      );
    }
    if (session['expires_at'] == null)
      session['expires_at'] =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 +
          (session['expires_in'] as num? ?? 3600).toInt();
    await _storage.write(key: _sessionKey, value: jsonEncode(session));
    _session = session;
  }

  Future<dynamic> _request(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = true,
    bool retryAuth = true,
  }) async {
    final config = _config;
    if (config == null || !config.valid)
      throw const PartnerSyncException('Partner sync is not configured.');
    if (authenticated) await authenticate();
    final token = _session?['access_token'] as String?;
    final headers = {
      'apikey': config.publicKey,
      'Content-Type': 'application/json',
      if (authenticated && token != null) 'Authorization': 'Bearer $token',
    };
    http.Response response;
    try {
      final request =
          http.Request(
              'POST',
              Uri.parse(config.url.replaceAll(RegExp(r'/$'), '') + path),
            )
            ..followRedirects = false
            ..headers.addAll(headers)
            ..body = jsonEncode(body);
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const PartnerSyncException(
        'Could not reach the partner server. Saved updates remain available offline.',
      );
    }
    if (response.statusCode == 401 && authenticated && retryAuth) {
      await authenticate(forceRefresh: true);
      return _request(path, body, authenticated: true, retryAuth: false);
    }
    dynamic parsed;
    try {
      parsed = jsonDecode(response.body);
    } catch (_) {
      throw const PartnerSyncException(
        'The partner server returned an unreadable response.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = parsed is Map ? parsed['code']?.toString() : null;
      if (response.statusCode == 401)
        throw const PartnerSyncException(
          'This device session needs reauthorization. Reconnect in partner settings.',
        );
      if (code == 'P0001' && parsed is Map)
        throw PartnerSyncException(
          parsed['message']?.toString() ?? 'Partner access was declined.',
        );
      throw const PartnerSyncException(
        'Partner sync failed. Check the server setup and your connection, then retry.',
      );
    }
    return parsed;
  }

  Future<PartnerInvite> createInvite(PartnerConsent consent) async {
    final result =
        (await _request('/rest/v1/rpc/cc_partner_create_invite', {
                  'p_consent': consent.toJson(),
                })
                as Map)
            .cast<String, dynamic>();
    return PartnerInvite(
      result['code'] as String,
      PartnerConnection.fromJson(
        (result['connection'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  Future<PartnerConnection> acceptInvite(String code) async =>
      PartnerConnection.fromJson(
        ((await _request('/rest/v1/rpc/cc_partner_accept_invite', {
                  'p_code': code.trim(),
                }))
                as Map)
            .cast<String, dynamic>(),
      );
  Future<List<PartnerConnection>> fetchConnections() async {
    final rows = await _request('/rest/v1/rpc/cc_partner_connections', {});
    final links = (rows as List)
        .map(
          (r) => PartnerConnection.fromJson((r as Map).cast<String, dynamic>()),
        )
        .toList();
    final prefs = await _preferences();
    final oldRaw = prefs.getString(_cacheKey);
    final dynamic old = oldRaw == null ? null : jsonDecode(oldRaw);
    final history = old is Map && old['history'] is Map
        ? Map<String, dynamic>.from(old['history'] as Map)
        : <String, dynamic>{};
    history.removeWhere((id, _) => !links.any((l) => l.id == id));
    for (final link in links) {
      if (link.revoked ||
          link.expiredAt(DateTime.now()) ||
          link.snapshot == null ||
          !link.consent.automaticUpdates) {
        history.remove(link.id);
        continue;
      }
      final previous = (history[link.id] as List? ?? [])
          .map(
            (s) => PartnerSnapshot.fromJson((s as Map).cast<String, dynamic>()),
          )
          .toList();
      final selected = previous
          .map(link.consent.filter)
          .where((s) => !s.isExpiredAt(DateTime.now()))
          .toList();
      if (selected.isEmpty ||
          selected.first.createdAt != link.snapshot!.createdAt)
        selected.insert(0, link.snapshot!);
      history[link.id] = selected.take(30).map((s) => s.toJson()).toList();
    }
    if (!await prefs.setString(
      _cacheKey,
      jsonEncode({
        'links': links.map((l) => l.toJson()).toList(),
        'history': history,
      }),
    ))
      throw const PartnerSyncException(
        'Could not keep the latest partner updates on this device.',
      );
    return links;
  }

  Future<List<PartnerConnection>> cachedConnections() async {
    final raw = (await _preferences()).getString(_cacheKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    final list = decoded is List ? decoded : (decoded as Map)['links'] as List;
    return list
        .map(
          (j) => PartnerConnection.fromJson((j as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<PartnerSnapshot>> cachedHistory(String id) async {
    final raw = (await _preferences()).getString(_cacheKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return [];
    final history = decoded['history'] as Map?;
    return (history?[id] as List? ?? [])
        .map(
          (j) => PartnerSnapshot.fromJson((j as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<void> publish(
    String id,
    PartnerSnapshot snapshot,
    PartnerConsent consent,
  ) async {
    // Defense in depth: private fields never enter the HTTP body at all.
    final selected =
        (consent.automaticUpdates ? consent : const PartnerConsent()).filter(
          snapshot,
        );
    await _request('/rest/v1/rpc/cc_partner_publish', {
      'p_link_id': id,
      'p_snapshot': selected.toJson(),
      'p_consent': consent.toJson(),
    });
  }

  Future<void> revoke(String id) async {
    await _request('/rest/v1/rpc/cc_partner_revoke', {'p_link_id': id});
  }

  Future<void> disconnect(String id) async {
    await _request('/rest/v1/rpc/cc_partner_disconnect', {'p_link_id': id});
  }

  Future<void> forgetLocalSession() async {
    await _storage.delete(key: _sessionKey);
    _session = null;
    await (await _preferences()).remove(_cacheKey);
  }

  void dispose() => _client.close();
}
