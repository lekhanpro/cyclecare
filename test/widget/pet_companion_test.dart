import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'package:cyclecare/core/theme/app_motion.dart';
import 'package:cyclecare/features/pet/pet_companion.dart';
import 'package:cyclecare/features/pet/pet_models.dart';
import 'package:cyclecare/features/pet/pet_screen.dart';
import '../shots/shot_harness.dart';

class _Films extends VideoPlayerPlatform {
  final sources = <DataSource>[];
  final calls = <String>[];
  final streams = <int, StreamController<VideoEvent>>{};
  bool fail = false;
  bool delay = false;
  bool failPlay = false;
  bool failPause = false;
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = sources.length;
    sources.add(options.dataSource);
    streams[id] = StreamController<VideoEvent>();
    if (!delay) initialize(id);
    return id;
  }

  void initialize(int id) {
    if (fail) {
      streams[id]!.addError(
        PlatformException(
          code: 'VideoError',
          message: 'Unavailable test decoder',
        ),
      );
    } else {
      streams[id]!.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          size: const Size(480, 510),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => streams[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose:$playerId');
  }

  @override
  Future<void> play(int playerId) async {
    calls.add('play:$playerId');
    if (failPlay)
      throw PlatformException(
        code: 'PlayFailed',
        message: 'Native resume failed',
      );
  }

  @override
  Future<void> pause(int playerId) async {
    calls.add('pause:$playerId');
    if (failPause)
      throw PlatformException(
        code: 'PauseFailed',
        message: 'Native pause failed',
      );
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    calls.add('volume:$volume');
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Colors.green);
}

void main() {
  late _Films films;
  setUp(() {
    films = _Films();
    VideoPlayerPlatform.instance = films;
  });

  Widget host(
    PetAnimationController control, {
    bool reduced = false,
    bool enabled = true,
    PetType type = PetType.bunny,
  }) => MaterialApp(
    home: Scaffold(
      body: MotionScope(
        reduced: reduced,
        child: TickerMode(
          enabled: enabled,
          child: PetCompanion(
            type: type,
            name: 'Luna',
            width: 320,
            controller: control,
          ),
        ),
      ),
    ),
  );

  Future<void> flush(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }

  testWidgets(
    'level-seven pet progress exposes a valid percent and XP description at large text',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.runAsync(loadShotFonts);
      await pumpShotApp(
        tester,
        route: '/pet',
        prefs: ShotSeed.typical(),
        width: 320,
        height: 1400,
        textScale: 2,
        dark: true,
      );
      final progress = find.byType(LinearProgressIndicator);
      expect(progress, findsOneWidget);
      final data = tester.getSemantics(progress).getSemanticsData();
      expect(data.value, '46');
      expect(data.label, contains('320 of 700 XP'));
      expect(data.label, contains('level 8'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    },
  );

  testWidgets(
    'a treat during cooldown still animates and explains the next reward without adding XP',
    (tester) async {
      await tester.runAsync(loadShotFonts);
      final pet = PetState(
        level: 7,
        xp: 320,
        lastFed: DateTime.now(),
        happiness: 82,
      );
      final stored = jsonEncode(pet.toJson());
      final prefs = {...ShotSeed.typical(), 'cc.pet.v1': stored};
      await pumpShotScreen(
        tester,
        const PetScreen(),
        prefs: prefs,
        reducedMotion: false,
        height: 1400,
      );
      await tester.tap(find.text('Treat'));
      await flush(tester);
      expect(films.sources.single.asset, 'assets/pets/films/luna/feed.mp4');
      expect(find.text('Next treat reward in 4h'), findsOneWidget);
      final storage = await SharedPreferences.getInstance();
      expect(storage.getString('cc.pet.v1'), stored);
      expect(find.text('320 / 700 XP'), findsOneWidget);
      await tester.ensureVisible(find.text('Care & growth'));
      await tester.tap(find.text('Care & growth'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('Next reward in 4h · animations stay available'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'replacing a controller preserves the reduced-motion system default',
    (tester) async {
      final first = PetAnimationController();
      final replacement = PetAnimationController();
      await tester.pumpWidget(host(first, reduced: true));
      expect(first.isPlaying, isFalse);
      await tester.pumpWidget(host(replacement, reduced: true));
      expect(replacement.isPlaying, isFalse);
      expect(find.text('Play motion'), findsOneWidget);
      replacement.play(PetAction.celebrate);
      await flush(tester);
      expect(films.sources, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      first.dispose();
      replacement.dispose();
    },
  );

  testWidgets(
    'a native pause failure disposes the movie and retains the working mesh',
    (tester) async {
      final control = PetAnimationController();
      await tester.pumpWidget(host(control));
      control.play(PetAction.water);
      await flush(tester);
      films.failPause = true;
      control.setPlaying(false);
      await flush(tester);
      expect(films.calls, contains('dispose:0'));
      expect(find.byKey(const ValueKey('pet-action-film')), findsNothing);
      expect(find.byKey(const ValueKey('pet-live-mesh')), findsOneWidget);
      expect(find.text('Water · live animation'), findsOneWidget);
      expect(control.isPlaying, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      control.dispose();
    },
  );

  testWidgets(
    'a native lifecycle resume failure falls back without an uncaught platform error',
    (tester) async {
      final control = PetAnimationController();
      await tester.pumpWidget(host(control));
      control.play(PetAction.rest);
      await flush(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await flush(tester);
      films.failPlay = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(films.calls, contains('dispose:0'));
      expect(find.byKey(const ValueKey('pet-action-film')), findsNothing);
      expect(find.text('Rest · live animation'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      control.dispose();
    },
  );

  test(
    'all four original artworks and 36 authored films match the manifest',
    () {
      final manifest =
          jsonDecode(File('assets/pets/films/manifest.json').readAsStringSync())
              as Map<String, dynamic>;
      final clips = (manifest['clips'] as List).cast<Map<String, dynamic>>();
      expect(clips.length, 36);
      for (final type in PetType.values) {
        expect(File(type.artworkAsset).existsSync(), isTrue);
        for (final action in PetAction.values) {
          final clip = clips.singleWhere(
            (c) => c['file'] == type.filmAsset(action),
          );
          final bytes = File(clip['file'] as String).readAsBytesSync();
          expect(bytes.length, clip['bytes']);
          expect(sha256.convert(bytes).toString(), clip['sha256']);
        }
      }
    },
  );

  testWidgets('plays selected local muted film and touch interrupts it', (
    tester,
  ) async {
    final control = PetAnimationController();
    await tester.pumpWidget(host(control));
    control.play(PetAction.water);
    await flush(tester);
    expect(films.sources.single.asset, 'assets/pets/films/luna/water.mp4');
    expect(films.sources.single.sourceType, DataSourceType.asset);
    expect(films.calls, containsAll(['volume:0.0', 'play:0']));
    expect(find.byKey(const ValueKey('pet-action-film')), findsOneWidget);
    final image = find.byKey(const ValueKey('pet-live-mesh'));
    await tester.tapAt(tester.getTopLeft(image) + const Offset(160, 180));
    await flush(tester);
    expect(films.calls, contains('dispose:0'));
    expect(find.byKey(const ValueKey('pet-action-film')), findsNothing);
    expect(find.text('A small nod, just for you'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    control.dispose();
  });

  testWidgets(
    'reduced motion stays still until explicitly played; pause and lifecycle stop playback',
    (tester) async {
      final control = PetAnimationController();
      await tester.pumpWidget(host(control, reduced: true));
      expect(find.text('Play motion'), findsOneWidget);
      control.play(PetAction.cuddle);
      await flush(tester);
      expect(films.sources, isEmpty);
      await tester.tap(find.byKey(const ValueKey('pet-motion-toggle')));
      await flush(tester);
      control.play(PetAction.rest);
      await flush(tester);
      expect(films.calls, contains('play:1'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await flush(tester);
      expect(films.calls.last, 'pause:1');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flush(tester);
      expect(films.calls.last, 'play:1');
      await tester.tap(find.byKey(const ValueKey('pet-motion-toggle')));
      await flush(tester);
      expect(films.calls.last, 'pause:1');
      expect(find.text('Play motion'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      control.dispose();
    },
  );

  testWidgets('off-tab ticker mode pauses and changing pet disposes its film', (
    tester,
  ) async {
    final control = PetAnimationController();
    await tester.pumpWidget(host(control));
    control.play(PetAction.celebrate);
    await flush(tester);
    await tester.pumpWidget(host(control, enabled: false));
    await flush(tester);
    expect(films.calls.last, 'pause:0');
    await tester.pumpWidget(host(control, type: PetType.fox));
    await flush(tester);
    expect(films.calls, contains('dispose:0'));
    control.play(PetAction.feed);
    await flush(tester);
    expect(films.sources.last.asset, 'assets/pets/films/pip/feed.mp4');
    await tester.pumpWidget(const SizedBox());
    await flush(tester);
    expect(films.calls, contains('dispose:1'));
    control.dispose();
  });

  testWidgets('late initialization after pause cannot start playback', (
    tester,
  ) async {
    films.delay = true;
    final control = PetAnimationController();
    await tester.pumpWidget(host(control));
    control.play(PetAction.checkin);
    await flush(tester);
    control.setPlaying(false);
    films.initialize(0);
    await flush(tester);
    expect(films.calls, isNot(contains('play:0')));
    expect(films.calls, contains('dispose:0'));
    await tester.pumpWidget(const SizedBox());
    control.dispose();
  });

  testWidgets('film failure retains live artwork and actionable controls', (
    tester,
  ) async {
    films.fail = true;
    final control = PetAnimationController();
    await tester.pumpWidget(host(control));
    control.play(PetAction.stretch);
    await flush(tester);
    expect(find.byKey(const ValueKey('pet-live-mesh')), findsOneWidget);
    expect(find.text('Stretch · live animation'), findsOneWidget);
    expect(find.byKey(const ValueKey('pet-motion-toggle')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    control.dispose();
  });

  testWidgets('head stroke, hold, ear and paw have distinct touch responses', (
    tester,
  ) async {
    final control = PetAnimationController();
    await tester.pumpWidget(host(control));
    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('pet-live-mesh')),
    );
    await tester.tapAt(origin + const Offset(120, 90));
    await tester.pump();
    expect(find.text('A tiny flick, then settle'), findsOneWidget);
    await tester.tapAt(origin + const Offset(144, 285));
    await tester.pump();
    expect(find.text('A soft paw tap back'), findsOneWidget);
    final stroke = await tester.startGesture(origin + const Offset(155, 175));
    await stroke.moveBy(const Offset(35, 0));
    await tester.pump();
    expect(find.text('A gentle head stroke'), findsOneWidget);
    await stroke.up();
    final hold = await tester.startGesture(origin + const Offset(155, 175));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('A quiet lean into your hand'), findsOneWidget);
    await hold.up();
    await tester.pumpWidget(const SizedBox());
    control.dispose();
  });
}
