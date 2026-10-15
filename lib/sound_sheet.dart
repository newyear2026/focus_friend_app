import 'package:flutter/material.dart';
import 'focus_preferences.dart';
import 'desk_style.dart';
import 'desk_components.dart';
import 'l10n/app_localizations.dart';
import 'localized_names.dart';

const soundIds = ['rain', 'forest', 'fire'];

class SoundSheet extends StatefulWidget {
  const SoundSheet({
    super.key,
    required this.value,
    required this.onPreview,
    required this.onSave,
  });
  final SoundPreferences value;
  final Future<void> Function(SoundPreferences) onPreview;
  final Future<bool> Function(SoundPreferences) onSave;
  @override
  State<SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<SoundSheet> {
  late SoundPreferences draft = widget.value;
  bool saving = false;
  String? error;
  Future<void> preview(SoundPreferences next) async {
    setState(() {
      draft = next;
      error = null;
    });
    try {
      await widget.onPreview(next);
    } catch (_) {
      if (mounted) {
        setState(() => error = AppLocalizations.of(context).soundPreviewError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Theme(
      data: deskTheme(context),
      child: Material(
        color: deskPaper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: deskMuted.withValues(alpha: .4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        l10n.focusSound,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.close,
                      onPressed: saving
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  l10n.soundSheetSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: deskBlue),
                ),
                const SizedBox(height: 12),
                for (final id in soundIds) ...[
                  Semantics(
                    selected: draft.sound == id && draft.enabled,
                    button: true,
                    child: Material(
                      color: draft.sound == id && draft.enabled
                          ? deskCream
                          : deskPaper,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: draft.sound == id && draft.enabled
                              ? deskGreen
                              : deskDivider,
                          width: draft.sound == id && draft.enabled ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('sound-$id'),
                        onTap: saving
                            ? null
                            : () => preview(
                                draft.copyWith(sound: id, enabled: true),
                              ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.asset(
                                  'assets/images/sound-$id.png',
                                  width: 54,
                                  height: 54,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      soundTitle(l10n, id),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      soundSubtitle(l10n, id),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.25,
                                        color: deskMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                draft.sound == id && draft.enabled
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                                size: 29,
                                color: draft.sound == id && draft.enabled
                                    ? deskGreen
                                    : deskMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Text(
                      l10n.volume,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(draft.volume * 100).round()}%',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: draft.enabled ? l10n.mute : l10n.unmute,
                      key: const ValueKey('sound-mute'),
                      onPressed: saving
                          ? null
                          : () => preview(
                              draft.copyWith(enabled: !draft.enabled),
                            ),
                      icon: Icon(
                        draft.enabled && draft.volume > 0
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        color: deskMuted,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        semanticFormatterCallback: (value) =>
                            l10n.volumeValue((value * 100).round()),
                        value: draft.volume,
                        activeColor: deskGreen,
                        onChanged: saving
                            ? null
                            : (value) => setState(
                                () => draft = draft.copyWith(volume: value),
                              ),
                        onChangeEnd: saving
                            ? null
                            : (value) => preview(draft.copyWith(volume: value)),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: deskGreen,
                  title: Text(
                    l10n.stopSoundAtEnd,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  value: draft.stopAtEnd,
                  onChanged: saving
                      ? null
                      : (value) => preview(draft.copyWith(stopAtEnd: value)),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                DeskPrimaryButton(
                  key: const ValueKey('save-sound'),
                  label: saving ? l10n.saving : l10n.soundDone,
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() {
                            saving = true;
                            error = null;
                          });
                          final ok = await widget.onSave(draft);
                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.pop(context, true);
                          } else {
                            setState(() {
                              saving = false;
                              error = l10n.soundSaveError;
                            });
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
