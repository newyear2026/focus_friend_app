import 'package:flutter/material.dart';
import 'session_engine.dart';
import 'desk_style.dart';
import 'desk_components.dart';

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
  late final message = TextEditingController(
    text: widget.goal?.message ?? '오늘도 한 걸음씩',
  );
  late DateTime date =
      widget.goal?.target ??
      DateTime(widget.now.year, widget.now.month, widget.now.day + 30);
  late bool showOnHome = widget.goal?.showOnHome ?? true;
  bool saving = false;
  String? saveError;
  FocusGoal get draft => FocusGoal(
    name: name.text.trim(),
    date: calendarKey(date),
    message: message.text.trim(),
    showOnHome: showOnHome,
  );
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
    final success = await widget.onSave(remove ? null : draft);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        saveError = '저장하지 못했어요. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: deskTheme(context),
    child: Scaffold(
      backgroundColor: deskPaper,
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: deskPaper,
        foregroundColor: deskInk,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: '뒤로',
          onPressed: saving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(22, 8, 22, 12),
        child: DeskPrimaryButton(
          key: const ValueKey('save-goal'),
          label: saving ? '저장 중…' : '목표 저장',
          icon: Icons.check_rounded,
          onPressed: saving ? null : () => save(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            children: [
              const Text(
                '목표와 다짐',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                '오늘의 집중에 작은 이유를 더해요',
                style: TextStyle(fontSize: 16, color: deskBlue),
              ),
              const SizedBox(height: 16),
              const Text(
                '미리보기',
                style: TextStyle(fontSize: 14, color: deskMuted),
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
                                  ? '나의 작은 목표'
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
              _label('목표 이름'),
              TextFormField(
                key: const ValueKey('goal-name'),
                controller: name,
                maxLength: 30,
                style: const TextStyle(fontSize: 17, height: 1.2),
                enabled: !saving,
                textInputAction: TextInputAction.next,
                decoration: _decoration('예: 자격증 시험'),
                onChanged: (_) => setState(() {}),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '목표 이름을 적어 주세요.'
                    : null,
              ),
              const SizedBox(height: 14),
              _label('목표 날짜'),
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
                          helpText: '목표 날짜',
                          cancelText: '취소',
                          confirmText: '선택',
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
              _label('나에게 한마디'),
              TextFormField(
                key: const ValueKey('goal-message'),
                controller: message,
                maxLength: 60,
                minLines: 1,
                maxLines: 2,
                style: const TextStyle(fontSize: 17, height: 1.2),
                enabled: !saving,
                decoration: _decoration('나에게 전하고 싶은 응원'),
                onChanged: (_) => setState(() {}),
              ),
              const Divider(height: 20),
              SwitchListTile.adaptive(
                key: const ValueKey('goal-home-toggle'),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: deskGreen,
                title: const Text(
                  '홈 화면에 표시',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  '책상 위에 목표를 작게 보여줘요',
                  style: TextStyle(color: deskMuted, fontSize: 13),
                ),
                value: showOnHome,
                onChanged: saving
                    ? null
                    : (value) => setState(() => showOnHome = value),
              ),
              const SizedBox(height: 8),
              const Text(
                '목표는 언제든 바꿔도 괜찮아요',
                textAlign: TextAlign.center,
                style: TextStyle(color: deskBlue, fontSize: 13),
              ),
              if (saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    saveError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (widget.goal != null)
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final remove = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('목표를 삭제할까요?'),
                              content: const Text('집중 기록과 모은 소품은 그대로 남아요.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          if (remove == true) await save(remove: true);
                        },
                  child: const Text(
                    '목표 삭제',
                    style: TextStyle(color: deskMuted),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
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
