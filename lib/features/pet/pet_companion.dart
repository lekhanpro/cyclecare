import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_motion.dart';
import 'pet_models.dart';

enum PetAction {
  water,
  checkin,
  comfort,
  stretch,
  rest,
  feed,
  cuddle,
  celebrate,
  breathe,
}

extension PetActionDetails on PetAction {
  String get label => switch (this) {
    PetAction.water => 'Water',
    PetAction.checkin => 'Check in',
    PetAction.comfort => 'Comfort',
    PetAction.stretch => 'Stretch',
    PetAction.rest => 'Rest',
    PetAction.feed => 'Treat',
    PetAction.cuddle => 'Cuddle',
    PetAction.celebrate => 'Celebrate',
    PetAction.breathe => 'Breathe',
  };
  double get seconds => switch (this) {
    PetAction.breathe => 30,
    PetAction.stretch || PetAction.rest => 6,
    _ => 4.8,
  };
}

extension PetArtwork on PetType {
  String get artworkId => switch (this) {
    PetType.bunny => 'luna',
    PetType.cat => 'miso',
    PetType.bear => 'maple',
    PetType.fox => 'pip',
  };
  String get artworkAsset =>
      'assets/pets/$artworkId-${name == 'Kitty'
          ? 'cat'
          : name == 'Foxy'
          ? 'fox'
          : name.toLowerCase()}.png';
  String filmAsset(PetAction action) =>
      'assets/pets/films/$artworkId/${action.name}.mp4';
}

/// Controls only illustration playback. No animation silently logs health data
/// or awards XP. Existing care/logging notifiers remain the source of truth.
class PetAnimationController extends ChangeNotifier {
  PetAction? _action;
  int _revision = 0;
  bool? _playingChoice;
  bool _systemAllows = true;
  PetAction? get action => _action;
  int get revision => _revision;
  bool get isPlaying => _playingChoice ?? _systemAllows;
  void play(PetAction action) {
    _action = action;
    _revision++;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _playingChoice = playing;
    notifyListeners();
  }

  void toggle() => setPlaying(!isPlaying);
}

/// Approved clay artwork as one connected mesh, plus the authored local films.
/// Touch immediately interrupts a film and returns to the same original image.
class PetCompanion extends StatefulWidget {
  const PetCompanion({
    super.key,
    required this.type,
    required this.name,
    this.width = 260,
    this.controller,
    this.showControls = true,
    this.showHint = true,
    this.onGreeting,
  });
  final PetType type;
  final String name;
  final double width;
  final PetAnimationController? controller;
  final bool showControls;
  final bool showHint;
  final VoidCallback? onGreeting;
  @override
  State<PetCompanion> createState() => _PetCompanionState();
}

enum PetTouch { head, ear, paw, stroke, hold }

class _PetCompanionState extends State<PetCompanion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late PetAnimationController _control;
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier<double>(0);
  ui.Image? _image;
  VideoPlayerController? _film;
  VideoPlayerController? _pendingFilm;
  int _filmToken = 0;
  int _imageToken = 0;
  int _seenRevision = 0;
  bool _foreground = true;
  bool _tickerMode = true;
  bool _routeCurrent = true;
  bool _visible = true;
  bool _focused = false;
  bool _disposed = false;
  Duration? _lastTick;
  double _time = 0;
  double _reactionTime = 2;
  double _contactAge = 0;
  Offset? _down;
  Offset? _contact;
  int? _pointer;
  PetTouch? _reaction;
  double _side = 1;
  PetAction? _meshAction;
  String _feedback = 'Stroke the head · touch an ear · tap a paw';
  ScrollPosition? _scroll;
  bool get _active =>
      !_disposed &&
      _control.isPlaying &&
      _foreground &&
      _tickerMode &&
      _routeCurrent &&
      _visible;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _control = widget.controller ?? PetAnimationController();
    _control.addListener(_changed);
    _seenRevision = _control.revision;
    _loadImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _control._systemAllows = !Motion.of(context).reduced;
    _tickerMode = TickerMode.valuesOf(context).enabled;
    _routeCurrent = ModalRoute.isCurrentOf(context) ?? true;
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != _scroll) {
      _scroll?.removeListener(_scrollChanged);
      _scroll = scroll;
      _scroll?.addListener(_scrollChanged);
    }
    _syncActive();
    _scrollChanged();
  }

  @override
  void didUpdateWidget(PetCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _control.removeListener(_changed);
      if (oldWidget.controller == null) _control.dispose();
      _control = widget.controller ?? PetAnimationController();
      _control._systemAllows = !Motion.of(context).reduced;
      _control.addListener(_changed);
      _seenRevision = _control.revision;
      _stopFilm();
      _meshAction = _control.action;
      _time = 0;
    }
    if (oldWidget.type != widget.type) {
      _stopFilm();
      _time = 0;
      _reaction = null;
      _loadImage();
    }
    _syncActive();
  }

  Future<void> _loadImage() async {
    final token = ++_imageToken;
    try {
      final data = await rootBundle.load(widget.type.artworkAsset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 640,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted || token != _imageToken) {
        frame.image.dispose();
        return;
      }
      final previous = _image;
      setState(() => _image = frame.image);
      // A paint recorded in this frame may still reference the previous image.
      WidgetsBinding.instance.addPostFrameCallback((_) => previous?.dispose());
    } catch (_) {
      if (mounted) {
        setState(
          () => _feedback =
              'Artwork could not load. Try reopening your companion.',
        );
      }
    }
  }

  void _scrollChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final bounds = box.localToGlobal(Offset.zero) & box.size;
      final viewport = Offset.zero & MediaQuery.sizeOf(context);
      _visible = bounds.overlaps(viewport);
      _syncActive();
    });
  }

  void _changed() {
    if (!mounted) return;
    if (_seenRevision != _control.revision) {
      _seenRevision = _control.revision;
      _time = 0;
      _reaction = null;
      _reactionTime = 2;
      _stopFilm();
      final action = _control.action;
      _meshAction = action;
      if (action != null) {
        _feedback = '${action.label} with ${widget.name}';
        if (_active) unawaited(_startFilm(action));
      }
    }
    if (_active &&
        _film == null &&
        _pendingFilm == null &&
        _meshAction != null &&
        _time == 0) {
      unawaited(_startFilm(_meshAction!));
    }
    _syncActive();
    setState(() {});
  }

  void _syncActive() {
    if (_active) {
      if (!_ticker.isActive) {
        _lastTick = null;
        _ticker.start();
      }
      final film = _film;
      if (film != null &&
          film.value.isInitialized &&
          !film.value.isPlaying &&
          !film.value.isCompleted) {
        unawaited(_commandFilm(film, play: true));
      }
    } else {
      _ticker.stop();
      _lastTick = null;
      final film = _film;
      if (film != null) unawaited(_commandFilm(film, play: false));
      _frame.value++;
    }
  }

  Future<void> _commandFilm(
    VideoPlayerController film, {
    required bool play,
  }) async {
    final token = _filmToken;
    try {
      if (play) {
        await film.play();
      } else {
        await film.pause();
      }
    } catch (_) {
      if (!mounted || token != _filmToken || _film != film) return;
      _stopFilm();
      setState(
        () => _feedback =
            '${_control.action?.label ?? 'Companion'} · live animation',
      );
    }
  }

  Future<void> _disposeFilm(VideoPlayerController film) async {
    try {
      await film.dispose();
    } catch (_) {
      // A platform disposal failure must not remove the working local mesh.
    }
  }

  void _tick(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    final dt = previous == null
        ? 0.0
        : ((elapsed - previous).inMicroseconds / 1000000).clamp(0.0, .05);
    _time += dt;
    _reactionTime += dt;
    if (_contact != null) {
      _contactAge += dt;
      if (_contactAge > .55 && _reaction == PetTouch.head) {
        setState(() {
          _reaction = PetTouch.hold;
          _reactionTime = .2;
          _feedback = 'A quiet lean into your hand';
        });
      }
    }
    _frame.value++;
  }

  Future<void> _startFilm(PetAction action) async {
    final token = ++_filmToken;
    final film = VideoPlayerController.asset(
      widget.type.filmAsset(action),
      // This widget owns lifecycle suspension and error recovery. Disable the
      // plugin's duplicate observer, whose async commands have no error guard.
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: true,
      ),
    );
    _pendingFilm = film;
    try {
      await film.initialize();
      await film.setVolume(0);
      if (!mounted || token != _filmToken || !_active || _contact != null) {
        await _disposeFilm(film);
        return;
      }
      setState(() => _film = film);
      if (_pendingFilm == film) _pendingFilm = null;
      film.addListener(_filmChanged);
      await film.play();
    } catch (_) {
      if (_film == film) {
        _film = null;
        film.removeListener(_filmChanged);
      }
      await _disposeFilm(film);
      if (mounted && token == _filmToken) {
        // Live mesh is a functional fallback, not a blank failed video.
        setState(() => _feedback = '${action.label} · live animation');
      }
    } finally {
      if (_pendingFilm == film) _pendingFilm = null;
    }
  }

  void _filmChanged() {
    final film = _film;
    if (film != null && (film.value.isCompleted || film.value.hasError)) {
      _stopFilm();
      if (mounted) setState(() {});
    }
  }

  void _stopFilm() {
    ++_filmToken;
    final film = _film;
    final pendingFilm = _pendingFilm;
    _film = null;
    _pendingFilm = null;
    if (film != null) {
      film.removeListener(_filmChanged);
      unawaited(_disposeFilm(film));
    }
    if (pendingFilm != null && pendingFilm != film) {
      unawaited(_disposeFilm(pendingFilm));
    }
  }

  Offset _point(Offset position, Size size) =>
      Offset(position.dx / size.width * 320, position.dy / size.height * 340);

  void _touchDown(PointerDownEvent event, Size size) {
    if (_pointer != null) return;
    _stopFilm();
    _meshAction = _control.action == PetAction.breathe
        ? PetAction.breathe
        : null;
    _pointer = event.pointer;
    _down = event.localPosition;
    _contact = _point(event.localPosition, size);
    _side = _contact!.dx < 160 ? -1 : 1;
    _contactAge = 0;
    final rig = PetMeshRig.forType(widget.type);
    _reaction = _contact!.dy < rig.head.dy - .28 * (rig.chin - rig.head.dy)
        ? PetTouch.ear
        : _contact!.dy > rig.chin + 25
        ? PetTouch.paw
        : PetTouch.head;
    _reactionTime = 0;
    setState(
      () => _feedback = switch (_reaction!) {
        PetTouch.ear => 'A tiny ear hello',
        PetTouch.paw => 'A little paw hello',
        _ => 'Hello, ${widget.name}',
      },
    );
  }

  void _touchMove(PointerMoveEvent event, Size size) {
    if (event.pointer != _pointer || _down == null) return;
    final delta = event.localPosition - _down!;
    if (delta.dy.abs() > 12 && delta.dy.abs() > delta.dx.abs()) {
      _release(cancelled: true); // Keep normal vertical page scrolling.
      return;
    }
    if (delta.dx.abs() > 10 &&
        (_reaction == PetTouch.head ||
            _reaction == PetTouch.hold ||
            _reaction == PetTouch.stroke)) {
      _contact = _point(event.localPosition, size);
      _side = delta.dx.sign;
      _reaction = PetTouch.stroke;
      _reactionTime = .2;
      setState(() => _feedback = 'A gentle head stroke');
    }
  }

  void _release({bool cancelled = false}) {
    _pointer = null;
    _down = null;
    _contact = null;
    _reactionTime = 0;
    if (cancelled) _reaction = null;
    setState(
      () => _feedback = cancelled
          ? 'Stroke the head · touch an ear · tap a paw'
          : switch (_reaction) {
              PetTouch.ear => 'A tiny flick, then settle',
              PetTouch.paw => 'A soft paw tap back',
              PetTouch.stroke ||
              PetTouch.hold => 'A little lean into your hand',
              _ => 'A small nod, just for you',
            },
    );
  }

  void _greet() {
    _stopFilm();
    _meshAction = _control.action == PetAction.breathe
        ? PetAction.breathe
        : null;
    _reaction = PetTouch.head;
    _reactionTime = 0;
    setState(() => _feedback = 'A small nod, just for you');
    widget.onGreeting?.call();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncActive();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_imageToken;
    WidgetsBinding.instance.removeObserver(this);
    _scroll?.removeListener(_scrollChanged);
    _control.removeListener(_changed);
    if (widget.controller == null) _control.dispose();
    _stopFilm();
    _ticker.dispose();
    _frame.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(widget.width, constraints.maxWidth);
            final size = Size(width, width * 340 / 320);
            return FocusableActionDetector(
              shortcuts: const {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _greet();
                    return null;
                  },
                ),
              },
              child: Semantics(
                button: true,
                label:
                    '${widget.name}, ${widget.type.name}. Stroke the head, touch an ear or tap a paw.',
                onTap: _greet,
                child: Listener(
                  onPointerDown: (e) => _touchDown(e, size),
                  onPointerMove: (e) => _touchMove(e, size),
                  onPointerUp: (e) {
                    if (e.pointer == _pointer) _release();
                  },
                  onPointerCancel: (e) {
                    if (e.pointer == _pointer) _release(cancelled: true);
                  },
                  child: SizedBox.fromSize(
                    size: size,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: const Color(0xffedf1e9),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              key: const ValueKey('pet-live-mesh'),
                              painter: PetMeshPainter(
                                image: _image,
                                type: widget.type,
                                frame: _frame,
                                time: () => _time,
                                motion: () => _active,
                                action: () => _meshAction,
                                reaction: () => _reaction,
                                reactionTime: () => _reactionTime,
                                side: () => _side,
                                contact: () => _contact,
                                contactAge: () => _contactAge,
                              ),
                            ),
                          ),
                        ),
                        if (_film != null && _film!.value.isInitialized)
                          IgnorePointer(
                            child: VideoPlayer(
                              _film!,
                              key: const ValueKey('pet-action-film'),
                            ),
                          ),
                        if (_focused)
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xff52384d),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showHint)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _feedback,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xff596753)),
              ),
            ),
          ),
        if (widget.showControls)
          TextButton.icon(
            key: const ValueKey('pet-motion-toggle'),
            onPressed: _control.toggle,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff52384d),
            ),
            icon: Icon(
              _control.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(_control.isPlaying ? 'Pause motion' : 'Play motion'),
          ),
      ],
    );
  }
}

class PetMeshRig {
  const PetMeshRig(
    this.head,
    this.chin,
    this.earLeft,
    this.earRight,
    this.pawLeft,
    this.pawRight,
  );
  final Offset head, earLeft, earRight, pawLeft, pawRight;
  final double chin;
  static PetMeshRig forType(PetType type) => switch (type) {
    PetType.bunny => const PetMeshRig(
      Offset(163, 171),
      223,
      Offset(124, 116),
      Offset(202, 116),
      Offset(144, 284),
      Offset(177, 284),
    ),
    PetType.cat => const PetMeshRig(
      Offset(157, 146),
      206,
      Offset(98, 91),
      Offset(219, 89),
      Offset(132, 295),
      Offset(176, 295),
    ),
    PetType.bear => const PetMeshRig(
      Offset(158, 139),
      195,
      Offset(89, 70),
      Offset(228, 68),
      Offset(119, 247),
      Offset(185, 247),
    ),
    PetType.fox => const PetMeshRig(
      Offset(150, 149),
      205,
      Offset(94, 113),
      Offset(213, 111),
      Offset(132, 299),
      Offset(174, 299),
    ),
  };
}

/// Same broad anatomical weights as the approved continuous browser mesh.
/// This deforms one image; it never rotates separate cutouts or redraws a face.
class PetMeshPainter extends CustomPainter {
  PetMeshPainter({
    required this.image,
    required this.type,
    required ValueNotifier<double> frame,
    required this.time,
    required this.motion,
    required this.action,
    required this.reaction,
    required this.reactionTime,
    required this.side,
    required this.contact,
    required this.contactAge,
  }) : super(repaint: frame);
  final ui.Image? image;
  final PetType type;
  final double Function() time, reactionTime, side, contactAge;
  final bool Function() motion;
  final PetAction? Function() action;
  final PetTouch? Function() reaction;
  final Offset? Function() contact;
  static const divisions = 56;
  static final _indices = <int>[
    for (var y = 0; y < divisions; y++)
      for (var x = 0; x < divisions; x++) ...[
        y * (divisions + 1) + x,
        y * (divisions + 1) + x + 1,
        (y + 1) * (divisions + 1) + x,
        y * (divisions + 1) + x + 1,
        (y + 1) * (divisions + 1) + x + 1,
        (y + 1) * (divisions + 1) + x,
      ],
  ];
  static double _smooth(double n) {
    n = n.clamp(0, 1);
    return n * n * (3 - 2 * n);
  }

  static double _weight(
    double x,
    double y,
    double cx,
    double cy,
    double rx,
    double ry,
  ) => math.exp(-math.pow((x - cx) / rx, 2) - math.pow((y - cy) / ry, 2));

  @override
  void paint(Canvas canvas, Size size) {
    final texture = image;
    if (texture == null) return;
    final rig = PetMeshRig.forType(type), t = time();
    final active = motion();
    final a = action();
    final duration = a?.seconds ?? 0;
    final envelope = !active || a == null
        ? 0.0
        : _smooth(t / .7) * (1 - _smooth((t - (duration - .9)) / .9));
    var tilt = 0.0,
        nod = 0.0,
        chest = active ? math.sin(t * 2 * math.pi / 4.6) * .0015 : 0.0,
        ear = 0.0,
        paw = 0.0,
        lean = 0.0;
    switch (a) {
      case PetAction.water:
        tilt = -1.8 * envelope;
        nod = math.sin(t * 1.3) * .9 * envelope;
        paw = -2 * envelope;
      case PetAction.checkin:
        nod = (.8 + math.sin(t * 2.5) * .65) * envelope;
        tilt = .9 * envelope;
      case PetAction.comfort:
        tilt = 1.9 * envelope;
        chest += .009 * envelope;
      case PetAction.stretch:
        chest += .025 * envelope;
        paw = -4 * envelope;
        nod = -1.1 * envelope;
      case PetAction.rest:
        tilt = 2.3 * envelope;
        nod = 1.4 * envelope;
      case PetAction.feed:
        nod = math.sin(t * 5) * .8 * envelope;
        paw = -2.5 * envelope;
      case PetAction.cuddle:
        tilt = -2 * envelope;
        lean = 1.5 * envelope;
      case PetAction.celebrate:
        ear = math.sin(t * 4) * 2 * envelope;
        paw = -math.max(0, math.sin(t * 3)) * 3 * envelope;
      case PetAction.breathe:
        if (active && t < 30) {
          final b = t % 10;
          final amount = b < 4
              ? (1 - math.cos(b / 4 * math.pi)) / 2
              : (1 + math.cos((b - 4) / 6 * math.pi)) / 2;
          chest = amount * .025;
          nod = -amount * .8;
        }
      case null:
        break;
    }
    final r = reactionTime(), s = side();
    final e = active ? _smooth(r / .14) * (1 - _smooth((r - .55) / .85)) : 0.0;
    switch (reaction()) {
      case PetTouch.ear:
        ear += math.sin(r * 8) * 3 * e;
        tilt += s * .7 * e;
      case PetTouch.paw:
        paw -= 3.5 * math.sin(math.min(r / .7, 1) * math.pi) * e;
        nod += .6 * e;
      case PetTouch.stroke || PetTouch.hold:
        tilt += s * 1.5 * e;
        lean += s * .8 * e;
      case PetTouch.head:
        nod += 1.5 * e;
        ear += 1.2 * e;
      case null:
        break;
    }
    final angle = tilt * math.pi / 180, points = <Offset>[], uv = <Offset>[];
    for (var iy = 0; iy <= divisions; iy++)
      for (var ix = 0; ix <= divisions; ix++) {
        final bx = ix / divisions * 320, by = 10 + iy / divisions * 320;
        var x = bx, y = by;
        final hw = 1 - _smooth((by - (rig.chin - 22)) / 40),
            ground = 1 - _smooth((by - 285) / 34);
        final dx = bx - rig.head.dx, dy = by - (rig.chin - 5);
        x +=
            (dx * (math.cos(angle) - 1) - dy * math.sin(angle)) * hw +
            lean * ground;
        y +=
            (dx * math.sin(angle) + dy * (math.cos(angle) - 1)) * hw + nod * hw;
        final torso = _weight(bx, by, 160, (rig.chin + 300) / 2, 67, 46);
        x += (bx - 160) * chest * torso;
        y -= (300 - by) * chest * torso;
        final ej = s > 0 ? rig.earRight : rig.earLeft;
        final ew = _weight(
          bx,
          by,
          ej.dx + (s > 0 ? 16 : -16),
          ej.dy - 40,
          35,
          48,
        );
        x += ear * ew;
        y -= ear.abs() * .25 * ew;
        final hp = s < 0 ? rig.pawLeft : rig.pawRight;
        y += paw * _weight(bx, by, hp.dx, hp.dy, 24, 29);
        final local = active ? contact() : null;
        if (local != null) {
          y +=
              math.min(1.5, contactAge() * 5) *
              _weight(bx, by, local.dx, local.dy, 30, 28);
        }
        points.add(Offset(x * size.width / 320, y * size.height / 340));
        uv.add(
          Offset(
            ix / divisions * texture.width,
            iy / divisions * texture.height,
          ),
        );
      }
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      points,
      textureCoordinates: uv,
      indices: _indices,
    );
    final paint = Paint()
      ..shader = ui.ImageShader(
        texture,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      )
      ..filterQuality = FilterQuality.medium;
    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    vertices.dispose();
  }

  @override
  bool shouldRepaint(PetMeshPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.type != type;
}
