/// Local clock periods; no location or sunrise service is needed.
enum RoomAmbience {
  morning('아침', 'morning'),
  day('낮', 'day'),
  evening('저녁', 'evening'),
  night('밤', 'night');

  const RoomAmbience(this.label, this.assetName);
  final String label;
  final String assetName;
  String get asset => 'assets/images/room-$assetName-empty.png';

  static RoomAmbience at(DateTime localTime) {
    final minute = localTime.hour * 60 + localTime.minute;
    if (minute >= 330 && minute < 480) return morning;
    if (minute >= 480 && minute < 1050) return day;
    if (minute >= 1050 && minute < 1200) return evening;
    return night;
  }
}
