import 'package:flutter/material.dart';
import 'desk_style.dart';
import 'l10n/app_localizations.dart';

/// Each language names itself, so it is findable from any other language.
const nativeLanguageNames = {
  'ko': '한국어',
  'en': 'English',
  'ja': '日本語',
  'es': 'Español',
};

/// The app language a phone language resolves to; English covers the rest.
String supportedLanguage(String? tag) {
  final code = tag?.split(RegExp('[-_]')).first;
  return nativeLanguageNames.containsKey(code) ? code! : 'en';
}

String _localName(AppLocalizations l10n, String code) => switch (code) {
  'ko' => l10n.languageNameKo,
  'ja' => l10n.languageNameJa,
  'es' => l10n.languageNameEs,
  _ => l10n.languageNameEn,
};

/// Pops with the chosen tag, where a null tag means "use phone setting";
/// dismissing pops with no record at all.
class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key, required this.value, required this.system});
  final String? value;
  final String? system;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget option(String? tag, String title, String? detail) {
      final selected = tag == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: selected ? deskCream : deskPaper,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected ? deskGreen : deskDivider,
                width: selected ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('language-${tag ?? 'system'}'),
              onTap: () => Navigator.pop(context, (tag: tag)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
                child: Row(
                  children: [
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
                          if (detail != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              detail,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                color: deskMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked,
                      size: 27,
                      color: selected ? deskGreen : deskMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
                const SizedBox(height: 14),
                Text(
                  l10n.languageSheetTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.languageSheetSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: deskBlue),
                ),
                const SizedBox(height: 14),
                option(
                  null,
                  l10n.followSystem,
                  l10n.languageNow(
                    nativeLanguageNames[supportedLanguage(system)]!,
                  ),
                ),
                for (final MapEntry(key: code, value: name)
                    in nativeLanguageNames.entries)
                  option(
                    code,
                    name,
                    // "한국어 / 한국어" says nothing; show it only when it helps.
                    _localName(l10n, code) == name
                        ? null
                        : _localName(l10n, code),
                  ),
                const SizedBox(height: 2),
                Text(
                  l10n.languageFallbackNote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: deskMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
