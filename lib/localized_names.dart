import 'l10n/app_localizations.dart';
import 'room_ambience.dart';
import 'focus_friend.dart';

String friendName(AppLocalizations l10n, FocusFriend friend) =>
    switch (friend) {
      FocusFriend.redpanda => l10n.friendRedpanda,
      FocusFriend.penguin => l10n.friendPenguin,
      FocusFriend.otter => l10n.friendOtter,
      FocusFriend.squirrel => l10n.friendSquirrel,
      FocusFriend.fennec => l10n.friendFennec,
    };

String friendRoom(AppLocalizations l10n, FocusFriend friend) =>
    switch (friend) {
      FocusFriend.redpanda => l10n.roomRedpanda,
      FocusFriend.penguin => l10n.roomPenguin,
      FocusFriend.otter => l10n.roomOtter,
      FocusFriend.squirrel => l10n.roomSquirrel,
      FocusFriend.fennec => l10n.roomFennec,
    };

/// Display names for ids that are stored in saved state and must not change.
String soundTitle(AppLocalizations l10n, String id) => switch (id) {
  'forest' => l10n.soundForestTitle,
  'fire' => l10n.soundFireTitle,
  _ => l10n.soundRainTitle,
};

String soundSubtitle(AppLocalizations l10n, String id) => switch (id) {
  'forest' => l10n.soundForestSubtitle,
  'fire' => l10n.soundFireSubtitle,
  _ => l10n.soundRainSubtitle,
};

String propName(AppLocalizations l10n, String key) => switch (key) {
  'plant' => l10n.propPlant,
  'mug' => l10n.propMug,
  _ => l10n.propLamp,
};

String ambienceName(AppLocalizations l10n, RoomAmbience ambience) =>
    switch (ambience) {
      RoomAmbience.morning => l10n.ambienceMorning,
      RoomAmbience.day => l10n.ambienceDay,
      RoomAmbience.evening => l10n.ambienceEvening,
      RoomAmbience.night => l10n.ambienceNight,
    };
