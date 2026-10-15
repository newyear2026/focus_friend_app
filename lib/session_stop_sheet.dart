import 'package:flutter/material.dart';
import 'book_page_frame.dart';
import 'desk_components.dart';
import 'desk_style.dart';
import 'l10n/app_localizations.dart';
import 'session_engine.dart';

class SessionStopSheet extends StatelessWidget {
  const SessionStopSheet({super.key, required this.mode});

  final SessionMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 440;
          final short = constraints.maxHeight < 420;
          final largeText = MediaQuery.textScalerOf(context).scale(24) > 30;
          final inset = wide ? 24.0 : 12.0;
          final portrait = largeText
              ? 64.0
              : short
              ? 64.0
              : wide
              ? 112.0
              : constraints.maxWidth >= 410
              ? 96.0
              : 88.0;
          return BookPageFrame(
            child: SingleChildScrollView(
              key: const ValueKey('session-stop-scroll'),
              padding: EdgeInsets.fromLTRB(
                28,
                largeText ? 76 : (short ? 30 : 44),
                28,
                26,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: largeText ? 12 : (short ? 32 : 28),
                    ),
                    child: Row(
                      children: [
                        CompanionImage(size: portrait),
                        SizedBox(width: largeText ? 16 : (wide ? 28 : 20)),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Semantics(
                              header: true,
                              child: Text(
                                l10n.stopSheetTitle,
                                style: const TextStyle(
                                  color: deskInk,
                                  fontSize: 24,
                                  height: 1.3,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode == SessionMode.focus
                              ? l10n.stopFocusSummary
                              : l10n.stopOtherBody,
                          style: const TextStyle(
                            color: deskInk,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (mode == SessionMode.focus) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.stopFocusRewardsHint,
                            style: const TextStyle(
                              color: deskMuted,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DeskPrimaryButton(
                    key: const ValueKey('continue-session'),
                    label: l10n.keepGoing,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    key: const ValueKey('confirm-stop-session'),
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: deskInk,
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(l10n.endSession),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
