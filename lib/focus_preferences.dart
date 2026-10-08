String calendarKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DailyFocus {
  const DailyFocus({this.milliseconds = 0, this.count = 0});
  final int milliseconds, count;
  DailyFocus add(int duration) =>
      DailyFocus(milliseconds: milliseconds + duration, count: count + 1);
  Map<String, dynamic> toJson() => {
    'milliseconds': milliseconds,
    'count': count,
  };
  factory DailyFocus.fromJson(Map<String, dynamic> json) => DailyFocus(
    milliseconds: json['milliseconds'] as int,
    count: json['count'] as int,
  );
}

class FocusGoal {
  const FocusGoal({
    required this.name,
    required this.date,
    this.message = '',
    this.showOnHome = true,
  });
  final String name, date, message;
  final bool showOnHome;
  DateTime get target => DateTime.parse(date);
  String countdown(DateTime now) {
    final days = DateTime.utc(
      target.year,
      target.month,
      target.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    return days == 0
        ? 'D-day'
        : days > 0
        ? 'D-$days'
        : 'D+${-days}';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date,
    'message': message,
    'showOnHome': showOnHome,
  };
  factory FocusGoal.fromJson(Map<String, dynamic> json) => FocusGoal(
    name: json['name'] as String,
    date: json['date'] as String,
    message: json['message'] as String? ?? '',
    showOnHome: json['showOnHome'] as bool? ?? true,
  );
}

class SoundPreferences {
  const SoundPreferences({
    this.sound = 'rain',
    this.volume = .4,
    this.enabled = false,
    this.stopAtEnd = true,
  });
  final String sound;
  final double volume;
  final bool enabled, stopAtEnd;
  SoundPreferences copyWith({
    String? sound,
    double? volume,
    bool? enabled,
    bool? stopAtEnd,
  }) => SoundPreferences(
    sound: sound ?? this.sound,
    volume: volume ?? this.volume,
    enabled: enabled ?? this.enabled,
    stopAtEnd: stopAtEnd ?? this.stopAtEnd,
  );
  Map<String, dynamic> toJson() => {
    'sound': sound,
    'volume': volume,
    'enabled': enabled,
    'stopAtEnd': stopAtEnd,
  };
  factory SoundPreferences.fromJson(Map<String, dynamic> json) =>
      SoundPreferences(
        sound: ['rain', 'forest', 'fire'].contains(json['sound'])
            ? json['sound'] as String
            : 'rain',
        volume: (json['volume'] as num? ?? .4).toDouble().clamp(0, 1),
        enabled: json['enabled'] as bool? ?? false,
        stopAtEnd: json['stopAtEnd'] as bool? ?? true,
      );
}
