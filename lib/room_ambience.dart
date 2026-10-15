/// Local clock periods; no location or sunrise service is needed.
enum RoomAmbience {
  morning('morning'),
  day('day'),
  evening('evening'),
  night('night');

  const RoomAmbience(this.assetName);
  final String assetName;
  String get asset => 'assets/images/immersive/room-$assetName.png';

  static RoomAmbience at(DateTime localTime) {
    final minute = localTime.hour * 60 + localTime.minute;
    if (minute >= 330 && minute < 480) return morning;
    if (minute >= 480 && minute < 1050) return day;
    if (minute >= 1050 && minute < 1200) return evening;
    return night;
  }
}
