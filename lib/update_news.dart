import 'package:flutter/services.dart';

/// Installed-build metadata, kept outside the focus-session snapshot.
class UpdateNewsState {
  const UpdateNewsState({
    required this.currentBuild,
    required this.lastAcknowledgedBuild,
    required this.wasUpdated,
  });

  final int currentBuild;
  final int? lastAcknowledgedBuild;

  /// Android's install/update timestamps identify users upgrading from a build
  /// that predates update-news tracking.
  final bool wasUpdated;

  bool get needsBaseline => lastAcknowledgedBuild == null && !wasUpdated;

  bool get shouldShow => lastAcknowledgedBuild == null
      ? wasUpdated
      : currentBuild > lastAcknowledgedBuild!;
}

abstract interface class UpdateNewsStore {
  Future<UpdateNewsState> load();
  Future<void> acknowledge(int build);
}

class AndroidUpdateNewsStore implements UpdateNewsStore {
  static const _channel = MethodChannel('focus_friend/local');

  @override
  Future<UpdateNewsState> load() async {
    final raw = await _channel.invokeMapMethod<String, Object?>(
      'getUpdateNews',
    );
    final current = raw?['currentBuild'];
    final previous = raw?['lastAcknowledgedBuild'];
    final updated = raw?['wasUpdated'];
    if (current is! int ||
        current <= 0 ||
        (previous != null && (previous is! int || previous <= 0)) ||
        updated is! bool) {
      throw const FormatException('Invalid update-news metadata');
    }
    return UpdateNewsState(
      currentBuild: current,
      lastAcknowledgedBuild: previous as int?,
      wasUpdated: updated,
    );
  }

  @override
  Future<void> acknowledge(int build) =>
      _channel.invokeMethod<void>('acknowledgeUpdateNews', {'build': build});
}

/// Decides whether the current installation has news still to present.
///
/// The UI owns presentation timing (idle, foreground, and no other sheet).
/// Create a new instance for each app launch so a failed disk write is retried
/// next time without repeatedly interrupting the current visit.
class UpdateNews {
  UpdateNews(this.store);

  final UpdateNewsStore store;
  bool _prepared = false;
  Future<void>? _preparing;
  int? _pendingBuild;

  bool get pending => _pendingBuild != null;

  Future<void> prepare() {
    if (_prepared) return Future<void>.value();
    return _preparing ??= _prepare().whenComplete(() => _preparing = null);
  }

  Future<void> _prepare() async {
    final state = await store.load();
    if (state.needsBaseline) {
      // The first installation is not an update. Remember it silently so the
      // first later upgrade can be recognized even after many app launches.
      await store.acknowledge(state.currentBuild);
    }
    _pendingBuild = state.shouldShow ? state.currentBuild : null;
    _prepared = true;
  }

  Future<void> acknowledge() async {
    // Settings can open the sheet before the startup read has finished.
    // Resolve that same read before deciding which installed build was seen.
    if (!_prepared) await prepare();
    final build = _pendingBuild;
    _pendingBuild = null;
    if (build == null) return;
    // Suppress in this process before writing. If storage fails, the next
    // launch can retry; opening the home screen again must not reopen news.
    await store.acknowledge(build);
  }
}
