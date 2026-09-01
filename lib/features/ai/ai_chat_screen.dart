import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai_service.dart';
import '../../core/services/haptics.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import '../tracking/application/cycle_tracker_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI chat
//
// A chat screen is mostly a list, so the interesting decisions are at the
// edges:
//
//  • The screen tells the truth about whether it works. This build wires
//    [UnavailableAIClient], so there is nothing behind the box — and rather
//    than take a question, fail, and blame a setting that does not exist, the
//    screen reads its own wiring and presents itself as switched off. The
//    moment a real client is supplied, the same check turns it back on.
//  • Health data is never sent without being asked for. Personal-data sharing
//    starts off, and the opt-in spells out every field that would travel with a
//    question rather than describing it as "your data".
//  • Empty state over a canned greeting. A fake first message from the
//    assistant occupies the space where guidance should be and teaches nothing.
//    Four prompts do — they show what this thing is for and remove the
//    blank-page problem in one tap.
//  • The disclaimer is a banner in the scroll, not a permanent strip above it.
//    A fixed strip is read once and then becomes furniture stealing height from
//    every message that follows.
//  • Failures go to a toast plus one bubble. The toast says it broke; the
//    bubble stays behind to say what to do about it, because a toast the user
//    missed is the same as no error handling at all. Neither one invents a
//    remedy the app cannot offer.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Chat message model ───────────────────────────────────────────────────────
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// Assistant messages that report a failure rather than an answer. Styled in
  /// the warning tone so they are never mistaken for health information.
  final bool isError;
}

// ─── AI service provider ──────────────────────────────────────────────────────
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService(
    client: const UnavailableAIClient(),
    contextBuilder: const AIContextBuilder(),
  );
});

/// Whether the assistant can actually answer anything.
///
/// Derived from the wiring instead of hardcoded in the view: the provider above
/// supplies [UnavailableAIClient], so this is false today and the screen renders
/// its disabled state. Supply a working client and the whole screen switches on
/// without a second edit — and it can never claim to work when it cannot.
bool _isConfigured(AIService service) => service.client is! UnavailableAIClient;

/// Every field [AIContextBuilder.buildUserContext] would attach to a question,
/// written out in full. An opt-in that says "your data" is not an opt-in.
const String _sharedDataDetail =
    'your last three period start dates, today\'s cycle day, the days until '
    'your next estimated period, your estimated fertile window, up to seven '
    'recent daily logs (flow, mood, symptoms, pain level, sleep hours), and '
    'what you are using CycleCare for';

// ─── Screen ───────────────────────────────────────────────────────────────────
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _messages = <ChatMessage>[];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  /// Personal-data sharing, off until the user turns it on.
  ///
  /// Deliberately not remembered between visits. Consent to hand over a cycle
  /// history is worth asking for again, and a switch that is quietly still on a
  /// month later is not consent.
  bool _shareCycleData = false;

  /// Four, not eight. A wall of suggestions is another thing to read; four fit
  /// on screen above the keyboard and still cover the common ground.
  static const _suggestions = <(String, String)>[
    ('🌙', 'What phase am I in right now?'),
    ('😴', 'Why am I so tired before my period?'),
    ('🌿', 'How does the fertile window work?'),
    ('💭', 'Can stress change my cycle?'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final question = text.trim();
    if (question.isEmpty || _loading) return;

    final aiService = ref.read(aiServiceProvider);
    // Nothing behind the box means nothing to send. The screen already says so;
    // this guard keeps a stray tap from producing a failure that looks like a
    // network problem.
    if (!_isConfigured(aiService)) return;

    _ctrl.clear();
    Haptics.tap();

    setState(() {
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final tracker = ref.read(cycleTrackerControllerProvider).valueOrNull;
      // Withheld at the call site, not just behind the service's own flag.
      // Cycle history and daily logs do not leave this widget unless the switch
      // above is on, so there is no path where a future refactor leaks them.
      final sharing = _shareCycleData;

      final response = await aiService.ask(
        question: question,
        allowPersonalData: sharing,
        trackingMode: sharing
            ? (tracker?.preferences.goal.label ?? 'track_periods')
            : 'general education',
        periods: sharing ? tracker?.periods ?? const [] : const [],
        recentLogs: sharing ? tracker?.logs ?? const [] : const [],
        prediction: sharing ? tracker?.prediction : null,
        includeIntimacy: false,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'I could not get an answer just now. You can try again in a '
              'moment — the rest of CycleCare works without me.',
          isUser: false,
          isError: true,
          timestamp: DateTime.now(),
        ));
        _loading = false;
      });
      // The underlying exception message is deliberately not shown: it can name
      // controls this app does not have, and a wrong instruction is worse than
      // no instruction.
      showAppToast(
        context,
        message: 'The assistant could not answer that.',
        kind: ToastKind.error,
      );
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: Motion.of(context)(AppDurations.normal),
        curve: AppCurves.out,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final available = _isConfigured(ref.watch(aiServiceProvider));

    final header = _ChatHeader(
      sharing: _shareCycleData,
      // A null callback is what switches the control off, so the card never has
      // to be told twice that the assistant is unavailable.
      onSharingChanged:
          available ? (value) => setState(() => _shareCycleData = value) : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withOpacity(context.isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: accent,
                size: AppSpacing.lg,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(
              child: Text(
                'CycleCare AI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppLayout.maxContentWidth,
                    ),
                    child: _messages.isEmpty
                        ? _ChatIntro(
                            header: header,
                            suggestions: _suggestions,
                            available: available,
                            gutter: gutter,
                            onPick: _send,
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: EdgeInsets.fromLTRB(
                              gutter,
                              AppSpacing.md,
                              gutter,
                              AppSpacing.sm,
                            ),
                            itemCount:
                                _messages.length + 2 + (_loading ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == 0) return header;
                              final index = i - 1;
                              if (index < _messages.length) {
                                return _MessageBubble(
                                  message: _messages[index],
                                );
                              }
                              if (index == _messages.length && _loading) {
                                return const _TypingIndicator();
                              }
                              // Breathing room so the last bubble never sits
                              // flush against the input bar.
                              return const SizedBox(height: AppSpacing.sm);
                            },
                          ),
                  ),
                );
              },
            ),
          ),
          _InputBar(
            controller: _ctrl,
            loading: _loading,
            available: available,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

/// The two things that sit above every conversation: the safety note, and the
/// switch that decides whether a question travels alone or with a cycle
/// history attached.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.sharing,
    required this.onSharingChanged,
  });

  final bool sharing;
  final ValueChanged<bool>? onSharingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Disclaimer(),
        _DataSharingCard(sharing: sharing, onChanged: onSharingChanged),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: InfoBanner(
        icon: Icons.health_and_safety_outlined,
        tone: AppColors.warning,
        message: 'Educational only — not medical advice. Please talk to a '
            'healthcare professional about anything that worries you.',
      ),
    );
  }
}

/// The consent control.
///
/// Off by default, and the copy names every field rather than summarising it,
/// because "share my data" is not something anyone can agree to meaningfully.
/// The state is said in words and an icon as well as the switch position, so it
/// is never carried by the track colour alone.
class _DataSharingCard extends StatelessWidget {
  const _DataSharingCard({required this.sharing, required this.onChanged});

  final bool sharing;

  /// Null when there is no assistant to send anything to, which is what puts
  /// the switch into its disabled state.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final enabled = onChanged != null;
    final on = sharing && enabled;

    return AppCard(
      emphasis: CardEmphasis.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  on ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                  size: AppSpacing.xl,
                  color: on ? context.accentColor : context.mutedColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send my cycle data with questions',
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: context.inkColor,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        on
                            ? 'On — the details below go with each question.'
                            : 'Off — your questions are sent on their own.',
                        style: text.bodySmall?.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Switch(value: on, onChanged: onChanged),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Turning this on sends $_sharedDataDetail. Leave it off and only '
            'the words you type are sent.',
            style: text.bodySmall?.copyWith(color: context.subtleColor),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _ChatIntro extends StatelessWidget {
  const _ChatIntro({
    required this.header,
    required this.suggestions,
    required this.available,
    required this.gutter,
    required this.onPick,
  });

  final Widget header;
  final List<(String, String)> suggestions;
  final bool available;
  final double gutter;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.md,
        gutter,
        AppSpacing.sm,
      ),
      children: [
        header,
        if (available)
          const EmptyState(
            icon: Icons.auto_awesome_rounded,
            title: 'Ask me anything about your cycle',
            message: 'Periods, hormones, fertility, symptoms, sleep — plain '
                'answers, no jargon. I explain things; I do not diagnose them.',
          )
        else
          // The honest version. No setting is named, because there is no
          // setting: the assistant simply has nothing behind it in this build.
          const EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'The assistant is not set up',
            message: 'CycleCare AI has no language model connected in this '
                'build, so it cannot answer questions. Nothing you type here '
                'is sent anywhere. Everything else in CycleCare works as '
                'usual.',
          ),
        const SizedBox(height: AppSpacing.xs),
        SectionHeader(
          title: available ? 'Try starting with' : 'What it would help with',
          subtitle: available ? null : 'Unavailable until it is connected',
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            right: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
        ),
        for (var i = 0; i < suggestions.length; i++)
          Reveal(
            index: i,
            offsetY: AppSpacing.md,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _Suggestion(
                emoji: suggestions[i].$1,
                question: suggestions[i].$2,
                available: available,
                onTap: () => onPick(suggestions[i].$2),
              ),
            ),
          ),
      ],
    );
  }
}

/// A starter question. Tappable when there is something to answer it, and a
/// plainly inert example when there is not — an arrow that leads nowhere is
/// worse than no arrow.
class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.emoji,
    required this.question,
    required this.available,
    required this.onTap,
  });

  final String emoji;
  final String question;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = ActionTile(
      icon: Icons.chat_bubble_outline_rounded,
      emoji: emoji,
      title: question,
      trailing: Icon(
        available ? Icons.north_east_rounded : Icons.block_rounded,
        size: AppSpacing.lg,
        color: context.subtleColor,
      ),
      onTap: available ? onTap : null,
    );

    if (available) return tile;

    return Semantics(
      container: true,
      label: question,
      hint: 'Unavailable — the assistant is not set up',
      excludeSemantics: true,
      child: tile,
    );
  }
}

// ─── Bubbles ─────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isUser = message.isUser;
    final accent = context.accentColor;

    // The user's own words sit on the accent; the assistant sits on a card.
    // Ownership is carried by colour *and* side *and* the tail, so the
    // conversation is still readable without relying on any one of them.
    final Color fill;
    final Color textColor;
    if (isUser) {
      fill = accent;
      textColor = Theme.of(context).colorScheme.onPrimary;
    } else if (message.isError) {
      fill = AppColors.warning.withOpacity(context.isDark ? 0.18 : 0.11);
      textColor = context.inkColor;
    } else {
      fill = context.cardColor;
      textColor = context.inkColor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        label: isUser
            ? 'You'
            : message.isError
                ? 'CycleCare AI, problem'
                : 'CycleCare AI',
        value: message.text,
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _AssistantAvatar(error: message.isError),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadii.card),
                      topRight: const Radius.circular(AppRadii.card),
                      // The tail sits on the side the message came from, so the
                      // shape alone tells you who is speaking.
                      bottomLeft: Radius.circular(
                        isUser ? AppRadii.card : AppRadii.connected,
                      ),
                      bottomRight: Radius.circular(
                        isUser ? AppRadii.connected : AppRadii.card,
                      ),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: message.isError
                                ? AppColors.warning.withOpacity(0.32)
                                : context.lineColor,
                            width: AppStrokes.hairline,
                          ),
                  ),
                  child: Text(
                    message.text,
                    style: text.bodyMedium?.copyWith(color: textColor),
                  ),
                ),
              ),
              // Keeps the user's bubble from running the full width, so the
              // two speakers never line up on the same edge.
              if (isUser)
                const SizedBox(width: AppSpacing.xxxl + AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({this.error = false});

  final bool error;

  @override
  Widget build(BuildContext context) {
    final tone = error ? AppColors.warning : context.accentColor;

    return Container(
      width: AppSpacing.xxxl,
      height: AppSpacing.xxxl,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.withOpacity(context.isDark ? 0.22 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        error ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
        color: tone,
        size: AppSpacing.lg,
      ),
    );
  }
}

// ─── Typing indicator ────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        liveRegion: true,
        label: 'CycleCare AI is thinking',
        child: ExcludeSemantics(
          child: Row(
            children: [
              const _AssistantAvatar(),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadii.card),
                    topRight: Radius.circular(AppRadii.card),
                    bottomRight: Radius.circular(AppRadii.card),
                    bottomLeft: Radius.circular(AppRadii.connected),
                  ),
                  border: Border.all(
                    color: context.lineColor,
                    width: AppStrokes.hairline,
                  ),
                ),
                child: const _TypingDots(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three dots pulsing out of phase.
///
/// One controller drives all three rather than three staggered controllers —
/// cheaper, and it guarantees the dots stay in lockstep instead of drifting
/// apart over a long wait. Under reduced motion the loop never starts and the
/// dots render at a fixed opacity, which still reads as "working".
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  /// A breathing loop, not a response to a tap, so it sits outside the
  /// [AppDurations] scale on purpose. It only ever runs when the platform
  /// allows animation.
  static const Duration _pulse = Duration(milliseconds: 1100);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _pulse,
  );
  bool _started = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.of(context).reduced;
    final tone = context.mutedColor;

    // MediaQuery isn't available in initState, so the looping decision is made
    // here — once, and only if the platform allows animation.
    if (!reduced && !_started) {
      _started = true;
      _controller.repeat();
    }

    if (reduced) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            _Dot(color: tone, opacity: 0.4 + i * 0.2),
          ],
        ],
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              _Dot(
                color: tone,
                // A third of a cycle between dots gives the wave its direction.
                opacity: _wave((_controller.value + i / 3) % 1),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Triangle wave between 0.3 and 1 — a sine would spend most of its time at
  /// the extremes, which reads as blinking rather than breathing.
  double _wave(double t) => 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sm,
      height: AppSpacing.sm,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity.clamp(0.0, 1.0)),
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Input ───────────────────────────────────────────────────────────────────

/// Grows with the text up to five lines, then scrolls internally.
///
/// A single-line field turns a three-sentence question into a keyhole; an
/// unbounded one lets a long paste eat the whole conversation. Five is the
/// point where both problems are small.
///
/// When the assistant has nothing behind it the field is switched off rather
/// than left inviting: a box that accepts a question it cannot answer is the
/// least honest thing on the screen.
class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.loading,
    required this.available,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool loading;
  final bool available;
  final ValueChanged<String> onSend;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  @override
  void initState() {
    super.initState();
    // Drives the send button between its idle and active states as the user
    // types, without rebuilding the message list.
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final accent = context.accentColor;
    final canSend = widget.available &&
        widget.controller.text.trim().isNotEmpty &&
        !widget.loading;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.canvasColor,
        border: Border(
          top: BorderSide(
            color: context.lineColor,
            width: AppStrokes.hairline,
          ),
        ),
      ),
      // The bar spans the window; what sits inside it is bound to the same
      // reading width as the conversation above.
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: AppLayout.minTouchTarget,
                  ),
                  decoration: BoxDecoration(
                    color: widget.available
                        ? context.cardColor
                        : context.lineColor.withOpacity(
                            context.isDark ? 0.34 : 0.42,
                          ),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(
                      color: context.lineColor,
                      width: AppStrokes.hairline,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: widget.controller,
                    enabled: widget.available,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: text.bodyMedium?.copyWith(color: context.inkColor),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      hintText: widget.available
                          ? 'Ask about your cycle…'
                          : 'The assistant is not set up',
                      hintStyle: text.bodyMedium?.copyWith(
                        color: context.subtleColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Pressable(
                onTap: canSend
                    ? () => widget.onSend(widget.controller.text)
                    : null,
                enabled: canSend,
                scale: 0.9,
                semanticLabel: 'Send',
                semanticHint: !widget.available
                    ? 'The assistant is not set up'
                    : widget.loading
                        ? 'Waiting for an answer'
                        : canSend
                            ? null
                            : 'Type a question first',
                excludeChildSemantics: true,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: AnimatedContainer(
                  duration: motion(AppDurations.fast),
                  curve: AppCurves.out,
                  width: AppLayout.minTouchTarget,
                  height: AppLayout.minTouchTarget,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: canSend ? accent : accent.withOpacity(0.24),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: AppSpacing.xl,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
