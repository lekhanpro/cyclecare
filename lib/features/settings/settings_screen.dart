import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/app_settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/haptics.dart';
import '../../core/services/security_service.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/widgets.dart';
import '../tracking/application/cycle_tracker_controller.dart';
import '../tracking/domain/cycle_models.dart';
import 'application/app_lock_controller.dart';
import 'application/backup_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings
//
// A settings screen is scanned, never read, so the whole page is built from one
// shape repeated: a titled group, a calm card, hairline-separated rows. Every
// row on this screen — a switch, a link, a stepper, a read-only value — is the
// same primitive with a different trailing slot, which is why the eye can move
// down eight groups without re-learning anything.
//
// Three rules hold it together:
//
//  • One row primitive. [_RowShell] owns the leading tile, the label column,
//    the trailing slot, the 48dp floor, and the decision about whether the
//    control sits beside the label or underneath it. Nothing else measures or
//    pads a row.
//  • Restraint over decoration. Groups are flat outlined cards, not stacked
//    shadows: eight elevated cards down a page reads as eight priorities,
//    which is the same as none.
//  • Rows bend before they break. Type at 200% and a 320dp screen are the two
//    conditions that snap a settings list, so the trailing control moves below
//    its label rather than squeezing it into a two-word column, and no label
//    is ever truncated to keep a control in place.
//
// Reminders remain a link rather than a copy: they own a whole screen with
// per-reminder times, and two places to switch the same notification on is how
// they end up disagreeing.
// ─────────────────────────────────────────────────────────────────────────────

const String _appVersion = '1.0.0';

/// Nominal body size, used only as a probe for the platform's text scaling.
const double _scaleProbe = 14;

/// Scale at which a trailing control stops sharing a line with its label.
/// Below this a switch and two lines of text sit together comfortably.
const double _stackedScale = 1.5;

/// Narrowest a label column may get before the control moves underneath it.
const double _minLabelWidth = 132;

/// Leading icon tile, matching the grouped lists on Home.
const double _leadingTile = AppSpacing.huge;

/// Distance from the card edge to the start of the label column.
const double _labelInset = AppSpacing.lg + _leadingTile + AppSpacing.md;

const EdgeInsets _rowPadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.lg,
  vertical: AppSpacing.md,
);

/// True once type is scaled far enough that side-by-side rows stop working.
bool _typeIsLarge(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(_scaleProbe) / _scaleProbe >=
    _stackedScale;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gutter = AppLayout.pageGutterFor(constraints.maxWidth);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                gutter,
                AppSpacing.sm,
                gutter,
                AppSpacing.xxxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Reveal(offsetY: AppSpacing.md, child: _ProfileSection()),
                      SizedBox(height: AppSpacing.xl),
                      Reveal(
                        index: 1,
                        offsetY: AppSpacing.md,
                        child: _AppearanceSection(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Reveal(
                        index: 2,
                        offsetY: AppSpacing.md,
                        child: _CalendarSection(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Reveal(
                        index: 3,
                        offsetY: AppSpacing.md,
                        child: _NotificationsSection(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Reveal(
                        index: 4,
                        offsetY: AppSpacing.md,
                        child: _SecuritySection(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Reveal(
                        index: 5,
                        offsetY: AppSpacing.md,
                        child: _DataSection(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Reveal(
                        index: 6,
                        offsetY: AppSpacing.md,
                        child: _MoreSection(),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Reveal(
                        index: 7,
                        offsetY: AppSpacing.md,
                        child: _AboutSection(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences =
        ref.watch(cycleTrackerControllerProvider).valueOrNull?.preferences;
    if (preferences == null) {
      return const _GroupSkeleton(title: 'You');
    }

    final name = preferences.profileName.trim();

    return _SettingsGroup(
      title: 'You',
      children: [
        _NavRow(
          leading: _Avatar(name: name),
          title: name.isEmpty ? 'Add your name' : name,
          subtitle: _profileLine(preferences),
          value: 'Edit',
          quietTitle: name.isEmpty,
          hint: 'Opens your name and birth year',
          onTap: () => _editProfile(context, ref, preferences),
        ),
        _BlockRow(
          label: 'Tracking for',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final goal in TrackingGoal.values)
                SelectableChip(
                  label: goal.label,
                  selected: goal == preferences.goal,
                  onSelected: (_) {
                    // A goal is never "unset" — tapping the active chip is a
                    // no-op rather than a write that clears it.
                    if (goal == preferences.goal) return;
                    _savePreferences(ref, preferences.copyWith(goal: goal));
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

String _profileLine(CyclePreferences preferences) {
  final goal = preferences.goal.label;
  final year = preferences.profileBirthYear;
  if (year == null) return goal;
  return '$goal · ${DateTime.now().year - year}';
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;

    return Container(
      width: _leadingTile,
      height: _leadingTile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withOpacity(context.isDark ? 0.24 : 0.13),
        shape: BoxShape.circle,
      ),
      child: name.isEmpty
          ? Icon(
              Icons.person_rounded,
              size: AppSpacing.xl,
              color: accent,
            )
          : Text(
              name.characters.first.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
            ),
    );
  }
}

Future<void> _editProfile(
  BuildContext context,
  WidgetRef ref,
  CyclePreferences preferences,
) async {
  final saved = await showAppSheet<bool>(
    context: context,
    title: 'Your profile',
    child: _ProfileSheet(preferences: preferences),
  );
  if (saved == true && context.mounted) {
    showAppToast(context, message: 'Profile updated');
  }
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet({required this.preferences});

  final CyclePreferences preferences;

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  bool _saving = false;
  String? _yearError;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.preferences.profileName);
    _yearController = TextEditingController(
      text: widget.preferences.profileBirthYear?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final thisYear = DateTime.now().year;
    final rawYear = _yearController.text.trim();

    // An empty field keeps the stored year rather than clearing it: the
    // preferences model cannot write a null back over a value, and doing
    // nothing is better than pretending it cleared.
    var year = widget.preferences.profileBirthYear;
    if (rawYear.isNotEmpty) {
      final parsed = int.tryParse(rawYear);
      if (parsed == null || parsed < 1920 || parsed > thisYear) {
        setState(() => _yearError = 'Enter a year between 1920 and $thisYear');
        return;
      }
      year = parsed;
    }

    setState(() {
      _saving = true;
      _yearError = null;
    });

    await _savePreferences(
      ref,
      widget.preferences.copyWith(
        profileName: _nameController.text.trim(),
        profileBirthYear: year,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'What should CycleCare call you?',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _yearController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Birth year',
            counterText: '',
            errorText: _yearError,
            helperText: 'Optional. Shapes guidance, never leaves the device.',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Save',
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Appearance
// ─────────────────────────────────────────────────────────────────────────────

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsSyncProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return _SettingsGroup(
      title: 'Appearance',
      subtitle:
          '${settings.palette.label} · ${_themeLabel(settings.themeMode)}',
      children: [
        _ChoiceRow<ThemeMode>(
          label: 'Theme',
          // Three states, not a dark-mode switch. A boolean cannot say "follow
          // the phone", which is what most people actually want.
          segments: const {
            ThemeMode.system: 'System',
            ThemeMode.light: 'Light',
            ThemeMode.dark: 'Dark',
          },
          value: settings.themeMode,
          onChanged: notifier.setThemeMode,
        ),
        _BlockRow(
          label: 'Palette',
          child: _PaletteChoice(
            selected: settings.palette,
            onSelected: notifier.setPalette,
          ),
        ),
      ],
    );
  }
}

String _themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'System theme',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

/// The palette picker, as named options rather than an unlabelled swatch grid.
///
/// A wrap of pills instead of a fixed-width grid for one reason: the grid put
/// every colour name in a 60dp column, which is the first thing to shred at
/// 200% type. A pill carries its own width, wraps its label, and keeps a full
/// touch target at every scale.
class _PaletteChoice extends StatelessWidget {
  const _PaletteChoice({required this.selected, required this.onSelected});

  final AppPalette selected;
  final ValueChanged<AppPalette> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final palette in AppPalette.values)
          _PaletteOption(
            palette: palette,
            selected: palette == selected,
            onTap: () {
              if (palette == selected) return;
              Haptics.selection();
              onSelected(palette);
            },
          ),
      ],
    );
  }
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadii.pill);
    final tone = palette.seed;

    return Pressable(
      onTap: onTap,
      haptic: false,
      selected: selected,
      semanticLabel: '${palette.label} palette',
      semanticHint: selected ? 'Currently in use' : 'Recolours the app',
      excludeChildSemantics: true,
      inMutuallyExclusiveGroup: true,
      scale: 0.96,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: motion(AppDurations.fast),
        curve: AppCurves.out,
        constraints: const BoxConstraints(
          minHeight: AppLayout.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tone.withOpacity(context.isDark ? 0.28 : 0.13)
              : context.cardColor,
          borderRadius: radius,
          border: Border.all(
            color: selected ? tone : context.lineColor,
            width: selected ? AppStrokes.selected : AppStrokes.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.xxl,
              height: AppSpacing.xxl,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: AppSpacing.lg,
                      // The surface behind the group: white on cream, dark
                      // card in dark mode. Either way the tick belongs to the
                      // card rather than to the swatch.
                      color: context.cardColor,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                palette.label,
                style:
                    (selected ? text.labelLarge : text.labelMedium)?.copyWith(
                  color: selected ? context.inkColor : context.mutedColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar & predictions
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarSection extends ConsumerWidget {
  const _CalendarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsSyncProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final preferences =
        ref.watch(cycleTrackerControllerProvider).valueOrNull?.preferences;

    return _SettingsGroup(
      title: 'Calendar & predictions',
      subtitle: 'What the calendar draws, and the numbers behind it',
      children: [
        _ChoiceRow<WeekStart>(
          label: 'Week starts on',
          segments: {
            for (final start in WeekStart.values) start: start.label,
          },
          value: settings.weekStart,
          onChanged: notifier.setWeekStart,
        ),
        _SwitchRow(
          icon: Icons.spa_rounded,
          accent: AppColors.fertile,
          title: 'Fertile window',
          subtitle: 'Shade the days around predicted ovulation',
          value: settings.showFertileWindow,
          onChanged: notifier.setShowFertileWindow,
        ),
        _SwitchRow(
          icon: Icons.egg_alt_rounded,
          accent: AppColors.ovulation,
          title: 'Ovulation day',
          subtitle: 'Mark the single most likely day',
          value: settings.showOvulation,
          onChanged: notifier.setShowOvulation,
        ),
        if (preferences != null) ...[
          _StepperRow(
            icon: Icons.loop_rounded,
            title: 'Average cycle length',
            subtitle: 'First day of bleeding to the next',
            value: preferences.averageCycleLength,
            min: 18,
            max: 60,
            onChanged: (value) => _savePreferences(
              ref,
              preferences.copyWith(averageCycleLength: value),
            ),
          ),
          _StepperRow(
            icon: Icons.water_drop_rounded,
            accent: AppColors.period,
            title: 'Average period length',
            subtitle: 'How many days you usually bleed',
            value: preferences.averagePeriodLength,
            min: 1,
            max: 14,
            onChanged: (value) => _savePreferences(
              ref,
              preferences.copyWith(averagePeriodLength: value),
            ),
          ),
          _StepperRow(
            icon: Icons.nightlight_round,
            accent: AppColors.luteal,
            title: 'Luteal phase length',
            subtitle: 'Ovulation to your period. Leave at 14 if unsure.',
            value: preferences.lutealPhaseLength,
            min: 9,
            max: 18,
            onChanged: (value) => _savePreferences(
              ref,
              preferences.copyWith(lutealPhaseLength: value),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifications
//
// One link, in the same grouped card as everything else. Reminders have their
// own screen with per-reminder times, lead times and a test send — none of
// which fits in a settings row.
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      title: 'Notifications',
      children: [
        _NavRow(
          icon: Icons.notifications_active_rounded,
          title: 'Reminders',
          subtitle:
              'Period and ovulation nudges, pill time, daily check-ins, and '
              'anything else you add',
          hint: 'Opens your reminders',
          onTap: () => context.push(AppRoutes.reminders),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy & security
// ─────────────────────────────────────────────────────────────────────────────

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsSyncProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final lock = ref.watch(lockStatusProvider).valueOrNull;

    return _SettingsGroup(
      title: 'Privacy & security',
      children: [
        _NavRow(
          icon: (lock?.enabled ?? false)
              ? Icons.lock_rounded
              : Icons.lock_open_rounded,
          title: 'App lock',
          subtitle: lock?.summary ?? 'Checking this device…',
          value: lock?.badge,
          hint: 'Opens PIN and biometric setup',
          onTap: () => _openLockSheet(context, ref),
        ),
        _SwitchRow(
          icon: Icons.visibility_off_rounded,
          title: 'Privacy mode',
          subtitle: 'Keep CycleCare out of the app switcher preview',
          value: settings.privacyMode,
          onChanged: notifier.setPrivacy,
        ),
        _SwitchRow(
          icon: Icons.vibration_rounded,
          title: 'Haptics',
          subtitle: 'A small tap when something actually changes',
          value: settings.hapticsEnabled,
          onChanged: notifier.setHaptics,
        ),
      ],
    );
  }
}

Future<void> _openLockSheet(BuildContext context, WidgetRef ref) async {
  final message = await showAppSheet<String>(
    context: context,
    title: 'App lock',
    child: const _AppLockSheet(),
  );
  if (message != null && context.mounted) {
    showAppToast(context, message: message);
  }
}

/// PIN, biometrics, and turning the lock off.
///
/// Modelled directly on what `SecurityService` can actually do: a PIN is the
/// base lock and biometrics sit on top of it. That ordering is not cosmetic —
/// the unlock screen falls back to the PIN when a fingerprint fails, so
/// enabling biometrics without one would be a way to lock yourself out of your
/// own records.
class _AppLockSheet extends ConsumerStatefulWidget {
  const _AppLockSheet();

  @override
  ConsumerState<_AppLockSheet> createState() => _AppLockSheetState();
}

class _AppLockSheetState extends ConsumerState<_AppLockSheet> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _busy = false;
  bool _switchingToPin = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _setPin(LockStatus status) async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4) {
      setState(() => _error = 'Use at least 4 digits');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'Those two PINs do not match');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    await ref.read(securityServiceProvider).setPin(pin);
    ref.invalidate(lockStatusProvider);

    if (!mounted) return;
    Navigator.of(context).pop(
      status.enabled ? 'PIN updated' : 'App lock is on',
    );
  }

  Future<void> _toggleBiometric(bool next, LockStatus status) async {
    if (!next) {
      // There is no way to step down from biometric to PIN without proving a
      // PIN, so the switch stays on until one is set. Better an honest extra
      // step than a toggle that flips and changes nothing.
      final confirmed = await confirmAction(
        context,
        title: 'Turn off biometric unlock?',
        message: 'CycleCare will ask for your PIN instead. Set the PIN below '
            'to finish the switch.',
        confirmLabel: 'Use PIN instead',
        destructive: false,
      );
      if (!confirmed || !mounted) return;
      setState(() => _switchingToPin = true);
      return;
    }

    if (!status.hasPin) {
      showAppToast(
        context,
        message: 'Set a PIN first — it is the fallback if biometrics fail',
        kind: ToastKind.warning,
      );
      return;
    }

    setState(() => _busy = true);

    // Verified before it is enabled. A sensor that cannot read the user right
    // now must not become the thing standing between them and their data.
    var authenticated = false;
    try {
      authenticated =
          await ref.read(securityServiceProvider).authenticateWithBiometric();
    } catch (_) {
      authenticated = false;
    }

    if (!authenticated) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(
        context,
        message: 'Could not verify — biometric unlock left off',
        kind: ToastKind.warning,
      );
      return;
    }

    await ref.read(securityServiceProvider).enableBiometricLock();
    ref.invalidate(lockStatusProvider);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _switchingToPin = false;
    });
    showAppToast(context, message: 'Biometric unlock is on');
  }

  Future<void> _disableLock() async {
    final confirmed = await confirmAction(
      context,
      title: 'Turn off app lock?',
      message: 'Anyone who picks up your phone will be able to open CycleCare '
          'and read your logs. Your PIN is deleted.',
      confirmLabel: 'Turn off',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    await ref.read(securityServiceProvider).disableLock();
    ref.invalidate(lockStatusProvider);

    if (!mounted) return;
    Navigator.of(context).pop('App lock is off');
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = ref.watch(lockStatusProvider).valueOrNull ??
        const LockStatus(
          enabled: false,
          type: LockType.none,
          biometricAvailable: false,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoBanner(
          icon: status.enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
          tone: status.enabled ? AppColors.success : AppColors.warning,
          title: status.enabled
              ? 'Locked with ${status.badge.toLowerCase()}'
              : 'Not locked',
          message: status.summary,
        ),
        if (_switchingToPin) ...[
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            icon: Icons.pin_rounded,
            tone: AppColors.info,
            message: 'Set a PIN below to finish switching away from '
                'biometric unlock.',
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            status.hasPin ? 'Change your PIN' : 'Set a PIN',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: context.inkColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'PIN (4–6 digits)',
            counterText: '',
            errorText: _error,
            prefixIcon: const Icon(Icons.pin_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _confirmController,
          keyboardType: TextInputType.number,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Confirm PIN',
            counterText: '',
            prefixIcon: Icon(Icons.check_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: status.hasPin ? 'Save new PIN' : 'Turn on app lock',
          icon: Icons.lock_rounded,
          loading: _busy,
          onPressed: () => _setPin(status),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          emphasis: CardEmphasis.outlined,
          padding: EdgeInsets.zero,
          child: _SwitchRow(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric unlock',
            subtitle: !status.biometricAvailable
                ? 'No face or fingerprint enrolled on this device'
                : !status.hasPin
                    ? 'Set a PIN first — it is the fallback if this fails'
                    : 'Face or fingerprint, PIN as backup',
            value: status.usesBiometric,
            enabled: status.biometricAvailable && !_busy,
            onChanged: (next) => _toggleBiometric(next, status),
          ),
        ),
        if (status.enabled) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Turn off app lock',
            icon: Icons.lock_open_rounded,
            outlined: true,
            destructive: true,
            onPressed: _busy ? null : _disableLock,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your PIN is hashed and stored in this device\'s secure keystore. It '
          'never leaves the phone and cannot be recovered — if you forget it, '
          'reinstalling is the only way back in.',
          style: text.bodySmall?.copyWith(color: context.mutedColor),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data
// ─────────────────────────────────────────────────────────────────────────────

class _DataSection extends ConsumerStatefulWidget {
  const _DataSection();

  @override
  ConsumerState<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<_DataSection> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final json =
          await ref.read(cycleTrackerControllerProvider.notifier).exportJson();
      await Share.share(json, subject: 'CycleCare data export');
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          message: 'Could not share the export just now',
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _restore() async {
    final restored = await showAppSheet<BackupPreview>(
      context: context,
      title: 'Restore from backup',
      child: const _RestoreSheet(),
    );
    if (restored == null || !mounted) return;

    showAppToast(
      context,
      message: 'Restored ${restored.periodCount} periods and '
          '${restored.logCount} logs',
    );
  }

  /// The one irreversible action on this screen, so the dialog says so in as
  /// many words: permanent, no undo, no server copy, nobody can restore it.
  Future<void> _deleteEverything() async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete everything permanently?',
      message: 'Every period, log, and setting on this device is erased for '
          'good. This cannot be undone, there is no copy on a server, and '
          'nobody — including support — can bring it back. Export a backup '
          'first if you might want any of it later.',
      confirmLabel: 'Delete permanently',
    );
    if (!confirmed || !mounted) return;

    await ref.read(cycleTrackerControllerProvider.notifier).deleteAllData();
    if (!mounted) return;
    showAppToast(
      context,
      message: 'All data deleted',
      kind: ToastKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      title: 'Data',
      subtitle: 'Everything is stored on this device only',
      children: [
        _NavRow(
          icon: Icons.ios_share_rounded,
          title: 'Export my data',
          subtitle: 'Share a full JSON copy — periods, logs and settings',
          hint: 'Opens the share sheet',
          onTap: _exporting ? null : _export,
          accessory: _exporting
              ? const SizedBox.square(
                  dimension: AppSpacing.xl,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Preparing your export',
                  ),
                )
              : null,
        ),
        _NavRow(
          icon: Icons.restore_rounded,
          title: 'Restore from backup',
          subtitle: 'Paste an export to bring your history back',
          hint: 'Replaces what is on this device, after a confirmation',
          onTap: _restore,
        ),
        _NavRow(
          icon: Icons.delete_forever_rounded,
          title: 'Delete all data',
          subtitle: 'Erases every period, log and setting. Permanent.',
          destructive: true,
          hint: 'Asks you to confirm, then erases everything permanently',
          onTap: _deleteEverything,
        ),
      ],
    );
  }
}

/// Paste-to-restore.
///
/// There is no file picker in this project, so the clipboard is the transport.
/// The text is parsed as it is typed and the result is stated plainly before
/// anything is written — "N periods and M daily logs from 3 Mar 2026" is
/// something a user can recognise as theirs, which "valid backup" is not.
class _RestoreSheet extends ConsumerStatefulWidget {
  const _RestoreSheet();

  @override
  ConsumerState<_RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends ConsumerState<_RestoreSheet> {
  final TextEditingController _controller = TextEditingController();
  BackupCheck? _check;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _inspect(String source) {
    // Nothing is judged until there is enough text to judge. Reporting "not
    // valid JSON" against a half-pasted brace is just nagging.
    setState(() {
      _check = source.trim().length < 12
          ? null
          : ref.read(backupServiceProvider).inspect(source);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted) return;
    if (text == null || text.trim().isEmpty) {
      showAppToast(
        context,
        message: 'Nothing on the clipboard',
        kind: ToastKind.info,
      );
      return;
    }
    _controller.text = text;
    _inspect(text);
  }

  Future<void> _restore(BackupPreview preview) async {
    final exported = preview.exportedAt;
    final confirmed = await confirmAction(
      context,
      title: 'Replace everything with this backup?',
      message: 'This backup has ${preview.periodCount} '
          '${preview.periodCount == 1 ? 'period' : 'periods'} and '
          '${preview.logCount} daily '
          '${preview.logCount == 1 ? 'log' : 'logs'}'
          '${exported == null ? '' : ', saved ${_formatDate(exported)}'}. '
          'Everything currently in CycleCare is replaced and cannot be '
          'recovered.',
      confirmLabel: 'Replace my data',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(backupServiceProvider).restore(preview);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppToast(
        context,
        message: 'Could not write the backup to this device',
        kind: ToastKind.error,
      );
      return;
    }

    // The tracker caches everything it loaded at startup, so it has to be told
    // the storage underneath it changed.
    ref.invalidate(cycleTrackerControllerProvider);

    if (!mounted) return;
    Navigator.of(context).pop(preview);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final check = _check;
    final ready = check is BackupReady ? check.preview : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Open a CycleCare export — the JSON you shared with yourself — and '
          'paste the whole thing here.',
          style: text.bodySmall?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _controller,
          minLines: 5,
          maxLines: 9,
          keyboardType: TextInputType.multiline,
          onChanged: _inspect,
          style: text.bodySmall,
          decoration: const InputDecoration(
            labelText: 'Backup JSON',
            hintText: '{ "periods": [ … ], "dailyLogs": [ … ] }',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Pressable(
            onTap: _pasteFromClipboard,
            scale: 0.95,
            semanticLabel: 'Paste from clipboard',
            semanticHint: 'Fills the field above with your copied backup',
            excludeChildSemantics: true,
            borderRadius: BorderRadius.circular(AppRadii.compact),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.content_paste_rounded,
                    size: AppSpacing.lg,
                    color: context.accentColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Paste from clipboard',
                    style: text.labelLarge?.copyWith(
                      color: context.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (check != null) ...[
          const SizedBox(height: AppSpacing.lg),
          switch (check) {
            BackupReady(preview: final preview) => InfoBanner(
                icon: Icons.inventory_2_rounded,
                tone: AppColors.success,
                title: 'Backup looks good',
                message: _describe(preview),
              ),
            BackupRejected(reason: final reason) => InfoBanner(
                icon: Icons.warning_rounded,
                tone: AppColors.warning,
                title: 'Cannot read this backup',
                message: reason,
              ),
          },
        ],
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: 'Restore this backup',
          icon: Icons.restore_rounded,
          loading: _busy,
          destructive: true,
          onPressed: ready == null ? null : () => _restore(ready),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Restoring replaces what is on this device. Nothing is merged.',
          textAlign: TextAlign.center,
          style: text.labelSmall?.copyWith(color: context.subtleColor),
        ),
      ],
    );
  }
}

String _describe(BackupPreview preview) {
  final periods =
      '${preview.periodCount} ${preview.periodCount == 1 ? 'period' : 'periods'}';
  final logs =
      '${preview.logCount} daily ${preview.logCount == 1 ? 'log' : 'logs'}';
  final exported = preview.exportedAt;
  final when = exported == null ? '' : ', saved ${_formatDate(exported)}';
  final settings = preview.preferences == null
      ? ' Your cycle settings are left as they are.'
      : ' Cycle settings come along too.';
  return '$periods and $logs$when.$settings';
}

String _formatDate(DateTime value) => DateFormat('d MMM yyyy').format(value);

// ─────────────────────────────────────────────────────────────────────────────
// More features
//
// These screens are reachable from Home too, but Settings is where people go
// looking for a feature they half-remember, so the links stay.
// ─────────────────────────────────────────────────────────────────────────────

class _MoreSection extends StatelessWidget {
  const _MoreSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      title: 'More',
      children: [
        _NavRow(
          icon: Icons.pregnant_woman_rounded,
          title: 'Pregnancy',
          onTap: () => context.push(AppRoutes.pregnancy),
        ),
        _NavRow(
          icon: Icons.medication_rounded,
          title: 'Birth control',
          onTap: () => context.push(AppRoutes.birthControl),
        ),
        _NavRow(
          icon: Icons.people_rounded,
          title: 'Partner sharing',
          onTap: () => context.push(AppRoutes.partner),
        ),
        _NavRow(
          icon: Icons.health_and_safety_rounded,
          title: 'Health conditions',
          onTap: () => context.push(AppRoutes.health),
        ),
        _NavRow(
          icon: Icons.school_rounded,
          title: 'Learn',
          onTap: () => context.push(AppRoutes.education),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// About
// ─────────────────────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: 'About',
          children: [
            const _ValueRow(
              icon: Icons.info_rounded,
              title: 'Version',
              value: _appVersion,
            ),
            _NavRow(
              icon: Icons.gavel_rounded,
              title: 'Medical disclaimer',
              hint: 'Opens what this app can and cannot tell you',
              onTap: () => _showDisclaimer(context),
            ),
            _NavRow(
              icon: Icons.shield_rounded,
              title: 'How your data is handled',
              hint: 'Opens where your entries are stored',
              onTap: () => _showPrivacyNote(context),
            ),
            _NavRow(
              icon: Icons.description_rounded,
              title: 'Open-source licences',
              hint: 'Opens the licence list',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'CycleCare',
                applicationVersion: _appVersion,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const InfoBanner(
          icon: Icons.favorite_rounded,
          tone: AppColors.warning,
          title: 'Not a medical device',
          message: 'CycleCare predicts from what you log. It is not a '
              'diagnosis, not contraception, and not a substitute for a '
              'clinician who can examine you.',
        ),
      ],
    );
  }
}

// Long-form copy is held in named constants rather than inline in the list
// literals below. Adjacent string literals inside a list are indistinguishable
// from a missing comma at a glance, which is exactly what the
// `no_adjacent_strings_in_list` lint is warning about.
const _disclaimerIntro =
    'CycleCare is a personal health tracking app for educational and '
    'informational use. It is not a medical device and does not provide '
    'medical advice, diagnosis, or treatment.';

const _disclaimerPredictions =
    'Predictions are estimates built from the data you log. Cycles vary with '
    'stress, illness, travel, medication and age, and no model can account for '
    'all of it. Do not rely on CycleCare as a method of contraception.';

const _disclaimerScreening =
    'Screening questions and educational articles in this app are written to '
    'help you have a better conversation with a clinician. They cannot tell '
    'you what you have.';

const _disclaimerEscalation =
    'If something feels wrong — pain that stops your day, bleeding that soaks '
    'through protection hourly, a period that vanishes for three months — talk '
    'to a healthcare professional rather than an app.';

Future<void> _showDisclaimer(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    title: 'Medical disclaimer',
    child: const _ProseBlock(
      paragraphs: [
        _disclaimerIntro,
        _disclaimerPredictions,
        _disclaimerScreening,
        _disclaimerEscalation,
      ],
    ),
  );
}

const _privacyStorage =
    'Your periods, logs and settings are stored on this device. There is no '
    'account required to use tracking, and nothing about your cycle is '
    'uploaded in the background.';

const _privacyPin =
    'Your app lock PIN is hashed and kept in the platform keystore, separately '
    'from your health data.';

const _privacyExport =
    'Export hands you the whole data set as JSON, and you choose where it '
    'goes. Restore reads that same file back. Delete all data removes it from '
    'this device for good.';

const _privacyNetwork =
    'If you sign in or use the AI companion, only what you send in those '
    'features leaves the device.';

Future<void> _showPrivacyNote(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    title: 'How your data is handled',
    child: const _ProseBlock(
      paragraphs: [
        _privacyStorage,
        _privacyPin,
        _privacyExport,
        _privacyNetwork,
      ],
    ),
  );
}

class _ProseBlock extends StatelessWidget {
  const _ProseBlock({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Text(
            paragraphs[i],
            style: text.bodyMedium?.copyWith(color: context.mutedColor),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row primitives
//
// One layout, five behaviours. Built on Pressable rather than ListTile so the
// press feedback, spacing, typography and semantics are the same here as
// everywhere else in the app — and so a switch row can decide for itself
// whether the switch fits beside its label.
// ─────────────────────────────────────────────────────────────────────────────

/// A titled card of rows, separated by hairlines.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A settings screen is navigated by its headers, so they are announced
        // as headers and merged into one node instead of two loose strings.
        MergeSemantics(
          child: Semantics(
            header: true,
            child: SectionHeader(title: title, subtitle: subtitle),
          ),
        ),
        AppCard(
          emphasis: CardEmphasis.outlined,
          padding: EdgeInsets.zero,
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const _RowDivider(),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hairline between rows, inset to start where the labels start.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppStrokes.hairline,
      thickness: AppStrokes.hairline,
      indent: _labelInset,
      endIndent: AppSpacing.lg,
      color: context.lineColor,
    );
  }
}

/// The one row layout on this screen.
///
/// Leading tile, label column, and up to three trailing pieces: a [value]
/// string, a [control] the user operates, and an [accessory] that is always
/// small and fixed (a chevron, a spinner).
///
/// The row measures itself. When type is scaled up, or when the label column
/// would be squeezed below [_minLabelWidth] on a narrow screen, the value and
/// the control drop below the label instead of fighting it for width. Labels
/// wrap freely and are never truncated — a settings row that says
/// "Average cycle…" has failed at the only job it has.
class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.value,
    this.control,
    this.controlExtent = 0,
    this.accessory,
    this.accent,
    this.enabled = true,
    this.destructive = false,
    this.quietTitle = false,
  }) : assert(
          icon != null || leading != null,
          'a row needs either an icon or a custom leading widget',
        );

  final String title;
  final IconData? icon;
  final Widget? leading;
  final String? subtitle;

  /// Current setting, shown as text beside or under the label.
  final String? value;

  /// Something the user operates: a switch, a stepper.
  final Widget? control;

  /// Roughly how wide [control] is, used to decide whether it still fits
  /// beside the label.
  final double controlExtent;

  /// Always beside the label, never stacked.
  final Widget? accessory;

  final Color? accent;
  final bool enabled;
  final bool destructive;

  /// For placeholder titles like "Add your name", which are prompts rather
  /// than values.
  final bool quietTitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tone = destructive ? scheme.error : (accent ?? context.accentColor);

    final titleColor = destructive
        ? scheme.error
        : !enabled
            ? context.subtleColor
            : quietTitle
                ? context.mutedColor
                : context.inkColor;
    final bodyColor = enabled ? context.mutedColor : context.subtleColor;

    final leadingTile = leading ??
        Container(
          width: _leadingTile,
          height: _leadingTile,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withOpacity(
              enabled ? (context.isDark ? 0.20 : 0.11) : 0.07,
            ),
            borderRadius: BorderRadius.circular(AppRadii.compact),
          ),
          child: Icon(
            icon,
            size: AppSpacing.xl,
            color: enabled ? tone : context.subtleColor,
          ),
        );

    final valueStyle = text.labelLarge?.copyWith(
      color: enabled ? context.mutedColor : context.subtleColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final trailingRoom = (control == null ? 0 : controlExtent) +
            (accessory == null ? 0 : AppSpacing.xl + AppSpacing.sm) +
            (value == null ? 0 : AppSpacing.huge);
        final labelRoom = constraints.maxWidth -
            _rowPadding.horizontal -
            _leadingTile -
            AppSpacing.md -
            trailingRoom;

        final stacked = (control != null || value != null) &&
            (_typeIsLarge(context) || labelRoom < _minLabelWidth);

        final label = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                style: text.bodySmall?.copyWith(color: bodyColor),
              ),
            ],
            if (stacked && value != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(value!, style: valueStyle),
            ],
          ],
        );

        final head = Row(
          children: [
            leadingTile,
            const SizedBox(width: AppSpacing.md),
            Expanded(child: label),
            if (!stacked && value != null) ...[
              const SizedBox(width: AppSpacing.sm),
              // Capped rather than flexible: a flex sibling would claim half
              // the free width from the label even when the value is one
              // word long, leaving a gap and a needlessly wrapped title.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth / 3,
                ),
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  style: valueStyle,
                ),
              ),
            ],
            if (!stacked && control != null) ...[
              const SizedBox(width: AppSpacing.sm),
              control!,
            ],
            if (accessory != null) ...[
              const SizedBox(width: AppSpacing.sm),
              accessory!,
            ],
          ],
        );

        return ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppLayout.minTouchTarget,
          ),
          child: Padding(
            padding: _rowPadding,
            child: stacked && control != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      head,
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: _leadingTile + AppSpacing.md,
                          top: AppSpacing.md,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: control,
                        ),
                      ),
                    ],
                  )
                : head,
          ),
        );
      },
    );
  }
}

/// A row that goes somewhere. Announced as a button, with a hint for what
/// happens on the other side.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.title,
    required this.onTap,
    this.icon,
    this.leading,
    this.subtitle,
    this.value,
    this.hint,
    this.destructive = false,
    this.quietTitle = false,
    this.accessory,
  });

  final String title;
  final IconData? icon;
  final Widget? leading;
  final String? subtitle;
  final String? value;
  final String? hint;
  final VoidCallback? onTap;
  final bool destructive;
  final bool quietTitle;

  /// Replaces the chevron — a spinner while an export is being prepared.
  final Widget? accessory;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Pressable(
      onTap: onTap,
      enabled: enabled,
      scale: 0.99,
      semanticLabel: title,
      semanticValue: value,
      semanticHint: hint ?? subtitle ?? 'Opens $title',
      excludeChildSemantics: true,
      child: _RowShell(
        icon: icon,
        leading: leading,
        title: title,
        subtitle: subtitle,
        value: value,
        enabled: enabled,
        destructive: destructive,
        quietTitle: quietTitle,
        accessory: accessory ??
            Icon(
              Icons.chevron_right_rounded,
              size: AppSpacing.xl,
              color: context.subtleColor,
            ),
      ),
    );
  }
}

/// A row that toggles a boolean.
///
/// The whole row is the target, not just the switch — a control at the far
/// edge of a phone is a bad target — and [MergeSemantics] folds the label,
/// the supporting line and the switch into one node, so the toggle is
/// announced with the thing it toggles instead of as a bare "on".
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.accent,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? accent;
  final bool enabled;

  void _handle(bool next) {
    Haptics.selection();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Pressable(
        onTap: enabled ? () => _handle(!value) : null,
        enabled: enabled,
        haptic: false,
        // The switch inside carries the toggle semantics; a second button
        // role on the same node would announce twice.
        semanticButton: false,
        scale: 0.995,
        child: _RowShell(
          icon: icon,
          title: title,
          subtitle: subtitle,
          accent: accent,
          enabled: enabled,
          // A Material switch is about a button-height wide.
          controlExtent: AppLayout.buttonHeight,
          control: Switch.adaptive(
            value: value,
            onChanged: enabled ? _handle : null,
          ),
        ),
      ),
    );
  }
}

/// A read-only row: a label and the value it currently holds.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: _RowShell(
        icon: icon,
        title: title,
        value: value,
      ),
    );
  }
}

/// A row holding a bounded integer, adjusted one step at a time.
///
/// A stepper rather than a slider in a dialog: cycle length is a number people
/// know to the day, and a slider makes hitting 29 instead of 28 a game of
/// skill. Two taps, no modal, saved immediately.
class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.subtitle,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // The readout keeps a fixed width so the row does not shuffle as the
    // number changes, and that width grows with type so "60d" never clips.
    final readoutWidth =
        MediaQuery.textScalerOf(context).scale(AppSpacing.huge);
    final action = title.toLowerCase();

    return _RowShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      accent: accent,
      controlExtent: AppLayout.minTouchTarget * 2 + readoutWidth,
      control: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            label: 'Decrease $action',
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: readoutWidth,
            child: Semantics(
              liveRegion: true,
              label: '$title, $value days',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$value',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: context.inkColor,
                      ),
                    ),
                    Text(
                      'd',
                      style: text.labelSmall?.copyWith(
                        color: context.mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            label: 'Increase $action',
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final live = onTap != null;
    final radius = BorderRadius.circular(AppRadii.control);

    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              Haptics.selection();
              onTap!();
            },
      enabled: live,
      haptic: false,
      scale: 0.9,
      semanticLabel: label,
      excludeChildSemantics: true,
      borderRadius: radius,
      child: Container(
        width: AppLayout.minTouchTarget,
        height: AppLayout.minTouchTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.lineColor.withOpacity(live ? 0.6 : 0.28),
          borderRadius: radius,
        ),
        child: Icon(
          icon,
          size: AppSpacing.xl,
          color: live ? context.inkColor : context.subtleColor,
        ),
      ),
    );
  }
}

/// A labelled slot for controls that are not rows — a chip wrap, the palette
/// picker.
class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelMedium?.copyWith(color: context.mutedColor),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// A small set of mutually exclusive options.
///
/// A segmented track while it fits, a chip wrap once it does not. The segmented
/// control is a fixed 48dp tall with single-line labels, so at large type
/// "Saturday" would be shortened to "S…" — a chip carries its own height and
/// wraps instead.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return _BlockRow(
      label: label,
      child: _typeIsLarge(context)
          ? Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in segments.entries)
                  SelectableChip(
                    label: entry.value,
                    selected: entry.key == value,
                    onSelected: (_) {
                      if (entry.key == value) return;
                      onChanged(entry.key);
                    },
                  ),
              ],
            )
          : SegmentedSelector<T>(
              segments: segments,
              value: value,
              onChanged: onChanged,
            ),
    );
  }
}

/// Placeholder with the same footprint as the loaded group, so the screen does
/// not jump when the tracker resolves.
class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MergeSemantics(
          child: Semantics(
            header: true,
            child: SectionHeader(title: title),
          ),
        ),
        AppCard(
          emphasis: CardEmphasis.outlined,
          padding: EdgeInsets.zero,
          borderRadius: radius,
          child: Semantics(
            label: 'Loading your profile',
            child: ExcludeSemantics(
              child: Padding(
                padding: _rowPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppLayout.minTouchTarget,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: _leadingTile,
                        height: _leadingTile,
                        decoration: BoxDecoration(
                          color: context.lineColor.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: AppSpacing.md,
                              width: AppLayout.narrowWidth / 3,
                              decoration: BoxDecoration(
                                color: context.lineColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.connected,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              height: AppSpacing.md,
                              width: AppLayout.narrowWidth / 4,
                              decoration: BoxDecoration(
                                color: context.lineColor.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.connected,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Persistence helper ──────────────────────────────────────────────────────

/// Single funnel for every cycle-preference write on this screen.
Future<void> _savePreferences(WidgetRef ref, CyclePreferences next) {
  return ref
      .read(cycleTrackerControllerProvider.notifier)
      .updatePreferences(next);
}
