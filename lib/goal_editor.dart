import 'package:flutter/material.dart';
import 'session_engine.dart';
import 'desk_style.dart';
import 'desk_components.dart';
import 'l10n/app_localizations.dart';

class GoalEditor extends StatefulWidget {
  const GoalEditor({
    super.key,
    this.goal,
    required this.now,
    required this.onSave,
  });
  final FocusGoal? goal;
  final DateTime now;
  final Future<bool> Function(FocusGoal?) onSave;
  @override
  State<GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<GoalEditor> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.goal?.name ?? '');
  late final message = TextEditingController(text: widget.goal?.message);
  late DateTime date =
      widget.goal?.target ??
      DateTime(widget.now.year, widget.now.month, widget.now.day + 30);
  late bool showOnHome = widget.goal?.showOnHome ?? true;
  bool saving = false, seededMessage = false;
  String? saveError;
  FocusGoal get draft => FocusGoal(
    name: name.text.trim(),
    date: calendarKey(date),
    message: message.text.trim(),
    showOnHome: showOnHome,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The default cheer depends on the language, so it is filled in once here.
    if (widget.goal == null && !seededMessage) {
      message.text = AppLocalizations.of(context).goalDefaultMessage;
    }
    seededMessage = true;
  }

  @override
  void dispose() {
    name.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> save({bool remove = false}) async {
    if (saving || (!remove && !formKey.currentState!.validate())) return;
    setState(() {
      saving = true;
      saveError = null;
    });
    var success = false;
    try {
      success = await widget.onSave(remove ? null : draft);
    } catch (_) {
      // Keep the entered values available for retry if saving fails.
    }
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        saveError = AppLocalizations.of(context).saveError;
      });
    }
  }

  Future<void> removeGoal() async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.deleteGoalTitle),
          content: Text(l10n.deleteGoalBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
    if (remove == true) await save(remove: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editor = Theme(
      data: deskTheme(context),
      child: Scaffold(
        backgroundColor: deskPaper,
        appBar: AppBar(
          toolbarHeight: 40,
          actions: [
            if (widget.goal != null)
              IconButton(
                tooltip: l10n.deleteGoalTooltip,
                onPressed: saving ? null : removeGoal,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
          backgroundColor: deskPaper,
          foregroundColor: deskInk,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: l10n.back,
            onPressed: saving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saving)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.goalSaving,
                      key: const ValueKey('goal-saving-status'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: deskMuted, fontSize: 13),
                    ),
                  ),
                ),
              if (saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      saveError!,
                      key: const ValueKey('goal-save-error'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ),
              DeskPrimaryButton(
                key: const ValueKey('save-goal'),
                label: saving ? l10n.saving : l10n.saveGoal,
                icon: Icons.check_rounded,
                loading: saving,
                onPressed: saving ? null : () => save(),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              children: [
                Text(
                  l10n.goalTitle,
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.goalSubtitle,
                  style: const TextStyle(fontSize: 16, color: deskBlue),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.preview,
                  style: const TextStyle(fontSize: 14, color: deskMuted),
                ),
                const SizedBox(height: 8),
                TicketPanel(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.countdown(widget.now),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name.text.trim().isEmpty
                                    ? l10n.goalPlaceholderName
                                    : name.text.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (message.text.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  message.text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: deskBlue,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const CompanionImage(size: 80),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _label(l10n.goalNameLabel),
                TextFormField(
                  key: const ValueKey('goal-name'),
                  controller: name,
                  maxLength: 30,
                  style: const TextStyle(fontSize: 17, height: 1.2),
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(l10n.goalNameHint),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.goalNameRequired
                      : null,
                ),
                const SizedBox(height: 14),
                _label(l10n.goalDateLabel),
                OutlinedButton(
                  key: const ValueKey('goal-date'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                    foregroundColor: deskInk,
                    side: const BorderSide(color: deskInk),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(widget.now.year - 10),
                            lastDate: DateTime(widget.now.year + 30),
                            helpText: l10n.goalDateLabel,
                            cancelText: l10n.cancel,
                            confirmText: l10n.select,
                          );
                          if (picked != null && mounted) {
                            setState(() => date = picked);
                          }
                        },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          calendarKey(date).replaceAll('-', '.'),
                          style: const TextStyle(fontSize: 19),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _label(l10n.goalMessageLabel),
                TextFormField(
                  key: const ValueKey('goal-message'),
                  controller: message,
                  maxLength: 60,
                  minLines: 1,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 17, height: 1.2),
                  enabled: !saving,
                  decoration: _decoration(l10n.goalMessageHint),
                  onChanged: (_) => setState(() {}),
                ),
                const Divider(height: 20),
                SwitchListTile.adaptive(
                  key: const ValueKey('goal-home-toggle'),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: deskGreen,
                  title: Text(
                    l10n.showOnHome,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: saving ? deskMuted : deskInk,
                    ),
                  ),
                  subtitle: Text(
                    l10n.showOnHomeSubtitle,
                    style: const TextStyle(color: deskMuted, fontSize: 13),
                  ),
                  value: showOnHome,
                  onChanged: saving
                      ? null
                      : (value) => setState(() => showOnHome = value),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.goalChangeAnytime,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: deskBlue, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return PopScope(canPop: !saving, child: editor);
  }

  Widget _label(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: deskPaper,
    counterText: '',
    isDense: true,
    contentPadding: const EdgeInsets.all(14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: const BorderSide(color: deskInk),
    ),
  );
}
