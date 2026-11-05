import 'package:flutter/material.dart';
import 'desk_style.dart';
import 'l10n/app_localizations.dart';

const _paper = Color(0xFFFFF8E9);
const _ink = Color(0xFF352724);
const _muted = Color(0xFF77665C);
const _line = Color(0xFFE8DDC9);
const _icon = Color(0xFF765239);

/// The same release notes are available automatically and from Settings.
Future<void> showUpdateNewsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      constraints: BoxConstraints(
        maxWidth: 600,
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      builder: (_) => const UpdateNewsSheet(),
    );

class UpdateNewsSheet extends StatelessWidget {
  const UpdateNewsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      key: const ValueKey('update-news-sheet'),
      color: _paper,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                  child: SizedBox(width: 40, height: 4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 12),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: _icon, size: 25),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      l10n.updateNewsTitle,
                      style: const TextStyle(
                        color: _icon,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('update-news-close'),
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: _icon,
                    iconSize: 27,
                  ),
                ],
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                key: const ValueKey('update-news-content'),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.updateNewsHeading,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 30,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.updateNewsIntro,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _NewsRow(
                      icon: Icons.pets_outlined,
                      title: l10n.updateNewsMotionTitle,
                      body: l10n.updateNewsMotionBody,
                    ),
                    const Divider(height: 1, thickness: 1, color: _line),
                    _NewsRow(
                      icon: Icons.event_available_outlined,
                      title: l10n.updateNewsRecordsTitle,
                      body: l10n.updateNewsRecordsBody,
                    ),
                    const Divider(height: 1, thickness: 1, color: _line),
                    _NewsRow(
                      icon: Icons.check_circle_outline_rounded,
                      title: l10n.updateNewsFixesTitle,
                      body: l10n.updateNewsFixesBody,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: FilledButton(
                key: const ValueKey('update-news-done'),
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: deskAccent,
                  foregroundColor: deskInkShadow,
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                child: Text(l10n.updateNewsDone, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: _icon, size: 29),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
