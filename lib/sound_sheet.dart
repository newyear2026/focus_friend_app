import 'package:flutter/material.dart';
import 'focus_preferences.dart';
import 'desk_style.dart';
import 'desk_components.dart';

const soundChoices = [
  ('rain', '창밖의 비', '창가에 톡톡 내리는 빗소리'),
  ('forest', '숲의 바람', '나뭇잎 사이로 스치는 바람'),
  ('fire', '따뜻한 장작', '포근하게 타닥이는 소리'),
];

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
      if (mounted) setState(() => error = '소리를 재생하지 못했어요. 다시 선택해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: deskTheme(context),
    child: Material(
      color: deskPaper,
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
                  const Expanded(
                    child: Text(
                      '집중 사운드',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Text(
                '내 방에 어울리는 소리를 골라요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: deskBlue),
              ),
              const SizedBox(height: 12),
              for (final (id, title, subtitle) in soundChoices) ...[
                Semantics(
                  selected: draft.sound == id && draft.enabled,
                  button: true,
                  child: Material(
                    color: draft.sound == id && draft.enabled
                        ? const Color(0xFFEEF5EF)
                        : deskPaper,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: draft.sound == id && draft.enabled
                            ? deskGreen
                            : const Color(0xFFE7E7EC),
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
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
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
                  const Text(
                    '음량',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                    tooltip: draft.enabled ? '소리 끄기' : '소리 켜기',
                    key: const ValueKey('sound-mute'),
                    onPressed: saving
                        ? null
                        : () =>
                              preview(draft.copyWith(enabled: !draft.enabled)),
                    icon: Icon(
                      draft.enabled && draft.volume > 0
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: deskMuted,
                    ),
                  ),
                  Expanded(
                    child: Slider(
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
                title: const Text(
                  '집중이 끝나면 소리 끄기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                label: saving ? '저장 중…' : '선택 완료',
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
                            error = '설정을 저장하지 못했어요. 다시 시도해 주세요.';
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
