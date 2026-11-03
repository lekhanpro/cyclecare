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

  /// Measured height of the floating input bar, used as the conversation's
  /// bottom padding.
  ///
  /// Measured rather than assumed because the bar grows: the field runs to five
  /// lines, and the safe-area inset differs per device. A hardcoded guess here
  /// is how the last bubble ends up permanently hidden behind the glass. Seeded
  /// with the resting height so the first frame is already close.
  double _barHeight = AppLayout.minTouchTarget + AppSpacing.lg;

  /// Four, not eight. A wall of suggestions is another thing to read; four fit
  /// on screen above the keyboard and still cover the common ground.
  ///
  /// Each icon names the subject of its question rather than decorating it:
  /// a generic phase question takes [AppIcons.cycle] rather than the luteal
  /// moon, because pinning one phase's icon to a question about all of them
  /// would answer it wrongly before it is asked.
  static const _suggestions = <(IconData, String)>[
    (AppIcons.cycle, 'What phase am I in right now?'),
    (AppIcons.sleep, 'Why am I so tired before my period?'),
    (AppIcons.fertile, 'How does the fertile window work?'),
    (AppIcons.moodAnxious, 'Can stress change my cycle?'),
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
      // The bar overlays the conversation rather than sitting in a column
      // beside it, and that is what makes it glass rather than a grey strip.
      // Stacked in a Column the bar had nothing behind it to refract — a
      // backdrop blur over a flat page samples flat page. Overlaid, the
      // messages travel under it, so the blur has the bubbles and the accent
      // to work with and the bar reads as a pane the conversation passes
      // beneath. The list's bottom padding is the bar's measured height, so
      // nothing is ever stranded underneath it.
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gutter = AppLayout.pageGutterFor(constraints.maxWidth);
                final bottom = _barHeight + AppSpacing.sm;

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
                            bottomInset: bottom,
                            onPick: _send,
                          )
                        : ListView.builder(
                            controller: _scrollCtrl,
                            padding: EdgeInsets.fromLTRB(
                              gutter,
                              AppSpacing.md,
                              gutter,
                              bottom,
                            ),
                            itemCount:
                                _messages.length + 1 + (_loading ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i == 0) return header;
                              final index = i - 1;
                              if (index < _messages.length) {
                                return _MessageBubble(
                                  message: _messages[index],
                                );
                              }
                              return const _TypingIndicator();
                            },
                          ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _InputBar(
              controller: _ctrl,
              loading: _loading,
              available: available,
              onSend: _send,
              onHeightChanged: (height) {
                if (height == _barHeight) return;
                setState(() => _barHeight = height);
              },
            ),
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

/// The safety note.
///
/// Was amber. Amber is `AppColors.warning`, which is a fixed semantic hue and
/// therefore the one colour on the screen that belongs to none of the eight
/// palettes — against a berry or forest-green accent it read as a browser
/// warning pasted into the app, and it was the loudest thing on a screen whose
/// loudest thing should be the conversation.
///
/// Two separate mistakes were stacked there. Amber also says "something has
/// gone wrong", and nothing has: this is a standing condition of using the
/// assistant at all, true on every visit. A permanent alert is the fastest way
/// to teach someone to stop seeing it. So the tone is the palette accent, which
/// reads as the app talking about itself, and the prominence comes from the
/// banner's position and its title rather than from colour it has to borrow.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InfoBanner(
        icon: AppIcons.shield,
        tone: context.accentColor,
        title: 'Educational only — not medical advice',
        message: 'Please talk to a healthcare professional about anything '
            'that worries you.',
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
///
/// Two things were wrong with how the field list was presented, and they pulled
/// in opposite directions:
///
///  • It was set in [ThemeSurfaces.subtleColor] — the tertiary tier, which the
///    design system reserves for disabled states and captions. A 45-word
///    disclosure of exactly which health records leave the device is the most
///    important paragraph on the screen, and it was rendered in the tier used
///    for text nobody needs to read. It is now secondary ink at body size with
///    the line height opened up.
///  • At that length it also dominated a screen whose subject is the
///    conversation, which is the usual reason such copy gets dimmed in the
///    first place. Dimming is the wrong fix for too-long: the answer is to
///    stop showing all of it at once.
///
/// So the list is disclosed rather than dimmed, and the disclosure is driven by
/// the switch. While sharing is off the fields are a reference — collapsed, one
/// tap away, with the count visible so it is never a surprise. Turning the
/// switch on opens it, so the one moment the user actually consents is the one
/// moment they are shown, in full, what they just consented to. Consent that
/// has to be hunted for is not consent.
class _DataSharingCard extends StatefulWidget {
  const _DataSharingCard({required this.sharing, required this.onChanged});

  final bool sharing;

  /// Null when there is no assistant to send anything to, which is what puts
  /// the switch into its disabled state.
  final ValueChanged<bool>? onChanged;

  @override
  State<_DataSharingCard> createState() => _DataSharingCardState();
}

class _DataSharingCardState extends State<_DataSharingCard> {
  /// Starts closed, and the user can close it again after turning sharing on —
  /// forcing it open would make the card impossible to get past.
  bool _expanded = false;

  @override
  void didUpdateWidget(_DataSharingCard old) {
    super.didUpdateWidget(old);
    // Opens on the transition into sharing, not on every rebuild while it is
    // on. This is the consent moment; the fields are shown unasked.
    if (widget.sharing && !old.sharing) _expanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final enabled = widget.onChanged != null;
    final on = widget.sharing && enabled;

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
                  on ? Icons.lock_open_rounded : AppIcons.privacy,
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
                            : 'Off — only the words you type are sent.',
                        style: text.bodySmall?.copyWith(
                          color: context.mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Switch(value: on, onChanged: widget.onChanged),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          _DisclosureToggle(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),

          AnimatedSize(
            duration: motion(AppDurations.normal),
            curve: AppCurves.inOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Turning this on sends $_sharedDataDetail. Leave it off '
                      'and only the words you type are sent.',
                      style: text.bodyMedium?.copyWith(
                        // Secondary ink, not tertiary: this is the paragraph
                        // the decision rests on. 1.55 line height because a
                        // 45-word block at the default 1.45 is a grey slab.
                        height: 1.55,
                        color: context.mutedColor,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// The affordance that opens the field list.
///
/// Reads as a labelled control rather than a bare chevron: a chevron alone does
/// not say what unfolds, and on a consent card the user has to know that the
/// thing being hidden is the list of their own health records.
class _DisclosureToggle extends StatelessWidget {
  const _DisclosureToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadii.compact);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Pressable(
        onTap: onTap,
        scale: 0.96,
        semanticLabel: 'What exactly gets sent',
        semanticHint: expanded ? 'Collapses the list' : 'Expands the list',
        excludeChildSemantics: true,
        borderRadius: radius,
        minimumSize: const Size(0, AppLayout.minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What exactly gets sent',
                style: text.labelLarge?.copyWith(color: context.accentColor),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: motion(AppDurations.fast),
                curve: AppCurves.out,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: AppSpacing.xl,
                  color: context.accentColor,
                ),
              ),
            ],
          ),
        ),
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
    required this.bottomInset,
    required this.onPick,
  });

  final Widget header;
  final List<(IconData, String)> suggestions;
  final bool available;
  final double gutter;

  /// Clearance for the floating input bar, which overlays this list.
  final double bottomInset;

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.md,
        gutter,
        bottomInset,
      ),
      children: [
        header,
        if (available)
          const EmptyState(
            icon: AppIcons.ai,
            title: 'Ask me anything about your cycle',
            message: 'Periods, hormones, fertility, symptoms, sleep — plain '
                'answers, no jargon. I explain things; I do not diagnose them.',
          )
        else
          const _NotSetUpCard(),
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(
          title: available ? 'Try starting with' : 'What it would help with',
          subtitle: available
              ? null
              : 'Examples only — these do nothing until a model is connected',
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
                icon: suggestions[i].$1,
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

/// The "no model connected" state, designed rather than defaulted.
///
/// This must stay honest, and honest is the hard part: the obvious ways to make
/// an empty state look designed all make this one lie. So the constraints are
/// deliberate and none of them may be traded for polish —
///
///  • No action. [EmptyState] offers one, and anything offerable here would be
///    a button that cannot work. A dead primary button is the single most
///    dishonest thing a screen can show.
///  • No setting named, because there is no setting. "Add your API key in
///    Settings" would send the user looking for a control this build does not
///    have, and a wrong instruction is worse than none.
///  • Not a warning tone. Nothing has failed and nothing is broken — the
///    feature was shipped unwired, which is a fact about the build rather than
///    an error the user caused or can clear.
///
/// What is left to design with is composition, so that is what it uses: a quiet
/// outlined surface with the icon struck through, the state said plainly in the
/// title, and the reassurance that matters most — nothing is being sent — given
/// its own line at full ink instead of buried mid-paragraph. The result reads as
/// a deliberate "not in this build" rather than a screen that failed to load.
class _NotSetUpCard extends StatelessWidget {
  const _NotSetUpCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'The assistant is not set up',
      value: 'CycleCare AI has no language model connected in this build, so '
          'it cannot answer questions. Nothing you type here is sent anywhere.',
      child: ExcludeSemantics(
        child: AppCard(
          emphasis: CardEmphasis.outlined,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            children: [
              Container(
                width: AppSpacing.huge + AppSpacing.xxl,
                height: AppSpacing.huge + AppSpacing.xxl,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.lineColor.withOpacity(
                    context.isDark ? 0.40 : 0.55,
                  ),
                  shape: BoxShape.circle,
                ),
                // The assistant's own icon with a slash through it, rather than
                // a generic cloud-off. It names *this* feature as switched off
                // instead of suggesting the network or the device is at fault.
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      AppIcons.ai,
                      size: AppSpacing.xxl + AppSpacing.xs,
                      color: context.mutedColor,
                    ),
                    Transform.rotate(
                      angle: -0.78,
                      child: Container(
                        width: AppSpacing.huge,
                        height: AppStrokes.selected,
                        decoration: BoxDecoration(
                          color: context.mutedColor,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'The assistant is not set up',
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.inkColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'CycleCare AI has no language model connected in this build, '
                'so it cannot answer questions.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: context.mutedColor),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Lifted out of the paragraph and onto its own line. On a screen
              // that takes typed health questions, "nothing is sent" is the
              // fact the user most needs, and it was the third sentence of a
              // grey block.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    AppIcons.privacy,
                    size: AppSpacing.lg,
                    color: context.accentColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'Nothing you type here is sent anywhere',
                      style: text.labelLarge?.copyWith(
                        color: context.inkColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Everything else in CycleCare works as usual.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: context.mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A starter question. Tappable when there is something to answer it, and a
/// plainly inert example when there is not — an arrow that leads nowhere is
/// worse than no arrow.
class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.icon,
    required this.question,
    required this.available,
    required this.onTap,
  });

  final IconData icon;
  final String question;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = ActionTile(
      icon: icon,
      title: question,
      // The question's own icon leads the row, so the trailing glyph is free to
      // carry the one thing the row's text cannot: whether tapping it does
      // anything. A struck-through arrow rather than a generic block sign keeps
      // it reading as "this arrow is off" instead of "this is forbidden".
      accent: available ? null : context.mutedColor,
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
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final dark = context.isDark;

    // The user's own words sit on the accent; the assistant sits on a card.
    // Ownership is carried by colour *and* side *and* the tail, so the
    // conversation is still readable without relying on any one of them.
    final Color fill;
    final Color textColor;
    if (isUser) {
      fill = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (message.isError) {
      fill = AppColors.warning.withOpacity(dark ? 0.18 : 0.11);
      textColor = context.inkColor;
    } else {
      fill = context.cardColor;
      textColor = context.inkColor;
    }

    // Two rungs, by who is speaking. The assistant's bubbles are resting
    // cards, so they take the workhorse shadow. The user's bubble is a
    // saturated block, and a black shadow under one turns its bottom edge
    // muddy exactly where it meets the page — so it takes the tinted glow
    // instead, for the same reason the hero does.
    final shadows = isUser
        ? AppElevation.glow(scheme.primary, dark)
        : message.isError
            ? AppElevation.none
            : AppElevation.low(dark);

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
                    boxShadow: shadows,
                  ),
                  child: Text(
                    message.text,
                    style: text.bodyMedium?.copyWith(
                      // Opened from the theme's 1.45. A chat bubble is read as
                      // a paragraph rather than scanned as a label, and the
                      // assistant's answers are the longest prose in the app.
                      height: 1.5,
                      color: textColor,
                    ),
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
///
/// This is the app's one piece of floating chrome and therefore its one
/// legitimate [GlassTone.chrome] surface: the conversation scrolls underneath
/// it, so the blur has real content to sample and the bar reads as a pane the
/// messages pass beneath. [GlassTone.chrome] is the heavy-veil tone for exactly
/// this reason — what travels behind it is arbitrary, including the user's
/// saturated accent bubbles, and the hint text has to stay legible over all of
/// it.
class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.loading,
    required this.available,
    required this.onSend,
    required this.onHeightChanged,
  });

  final TextEditingController controller;
  final bool loading;
  final bool available;
  final ValueChanged<String> onSend;

  /// Reports the bar's rendered height so the conversation can reserve exactly
  /// that much bottom padding.
  final ValueChanged<double> onHeightChanged;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Drives the send button between its idle and active states as the user
    // types, without rebuilding the message list.
    widget.controller.addListener(_onTextChanged);
    _reportHeight();
  }

  /// Measures after layout and hands the height up.
  ///
  /// Post-frame rather than during build: the bar's height depends on how many
  /// lines the field has grown to, which is not known until it has been laid
  /// out. Reporting it from here means the parent reserves the real height
  /// instead of a guess that goes stale the moment the question runs long.
  void _reportHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      widget.onHeightChanged(box.size.height);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    // The field grows as the question runs past one line, which changes the
    // bar's height and therefore the clearance the conversation needs.
    _reportHeight();
  }

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final accent = context.accentColor;
    final dark = context.isDark;
    final canSend = widget.available &&
        widget.controller.text.trim().isNotEmpty &&
        !widget.loading;

    return GlassSurface(
      key: _barKey,
      tone: GlassTone.chrome,
      // Only the top corners round. The bar is attached to the bottom of the
      // window rather than floating in it, so rounding the bottom would leave
      // two slivers of page colour in the corners — the inverse of the reason
      // the hero rounds only its bottom edge.
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadii.sheet),
        topRight: Radius.circular(AppRadii.sheet),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.paddingOf(context).bottom,
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
                    // Opaque, not another translucent layer. The field sits on
                    // glass, and glass on glass doubles the veil and turns the
                    // one surface the user types into the muddiest thing on the
                    // screen. A solid well inside a translucent bar is also how
                    // iOS builds this.
                    color: widget.available
                        ? context.cardColor
                        : context.lineColor.withOpacity(dark ? 0.34 : 0.42),
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
                      // Secondary rather than tertiary ink. The hint is the
                      // only label this control has, and subtleColor is the
                      // disabled tier — too faint to read as an invitation.
                      hintStyle: text.bodyMedium?.copyWith(
                        color: context.mutedColor,
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
                    color: canSend
                        ? accent
                        : context.lineColor.withOpacity(dark ? 0.46 : 0.60),
                    shape: BoxShape.circle,
                    // Lit only when it will do something, so the live state is
                    // the one that stands off the glass.
                    boxShadow:
                        canSend ? AppElevation.glow(accent, dark) : null,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    size: AppSpacing.xl,
                    // The disabled fill used to be the accent at 24% with
                    // onPrimary ink on top — a near-white arrow on a pale
                    // tint, which fails contrast at exactly the moment the
                    // control most needs to be readable as "off". Disabled now
                    // drops to a neutral well with muted ink, which carries
                    // both the state and the arrow.
                    color: canSend
                        ? Theme.of(context).colorScheme.onPrimary
                        : context.mutedColor,
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
