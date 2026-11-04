import 'dart:convert';
import 'package:cyclecare/features/partner/data/partner_sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('401 refreshes session once and retries with the new token', () async {
    final seen = <String>[];
    var rpcCalls = 0;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    Map<String, Object> session(String token) => {
      'access_token': token,
      'refresh_token': 'refresh-token',
      'expires_at': nowSeconds + 3600,
      'user': {'id': 'device-owner'},
    };
    final repo = PartnerSyncRepository(
      client: MockClient((request) async {
        expect(request.followRedirects, isFalse);
        seen.add(request.url.path);
        if (request.url.path == '/auth/v1/signup') {
          return http.Response(jsonEncode(session('first')), 200);
        }
        if (request.url.path == '/auth/v1/token') {
          expect(request.url.queryParameters['grant_type'], 'refresh_token');
          return http.Response(jsonEncode(session('second')), 200);
        }
        if (request.url.path == '/rest/v1/rpc/cc_partner_connections') {
          rpcCalls++;
          expect(
            request.headers['Authorization'],
            rpcCalls == 1 ? 'Bearer first' : 'Bearer second',
          );
        return rpcCalls == 1 ? http.Response('', 401) : http.Response('[]', 200);
        }
        fail('Unexpected endpoint ${request.url.path}');
      }),
    );
    addTearDown(repo.dispose);
    await repo.configure(
      const PartnerServerConfig(
        'https://project.example',
        'sb_publishable_example',
      ),
    );
    await repo.authenticate();
    expect(await repo.fetchConnections(), isEmpty);
    expect(rpcCalls, 2);
    expect(seen, [
      '/auth/v1/signup',
      '/rest/v1/rpc/cc_partner_connections',
      '/auth/v1/token',
      '/rest/v1/rpc/cc_partner_connections',
    ]);
  });

  test('switching servers cannot silently discard a device identity', () async {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final repo = PartnerSyncRepository(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'access_token': 'first',
            'refresh_token': 'refresh',
            'expires_at': nowSeconds + 3600,
            'user': {'id': 'owner'},
          }),
          200,
        ),
      ),
    );
    addTearDown(repo.dispose);
    await repo.configure(
      const PartnerServerConfig('https://one.example', 'sb_publishable_one'),
    );
    await repo.authenticate();
    await expectLater(
      repo.configure(
        const PartnerServerConfig('https://two.example', 'sb_publishable_two'),
      ),
      throwsA(isA<PartnerSyncException>()),
    );
    expect(repo.userId, 'owner');
    expect(repo.configuration!.url, 'https://one.example');
    await repo.configure(
      const PartnerServerConfig(
        'https://one.example/',
        'sb_publishable_rotated',
      ),
    );
    expect(repo.userId, 'owner');
  });
}
