part of phonio;

class DND implements Event{
  final bool isOn;

  String   get eventName => EventJSONKey.DND;

  DND (this.isOn);

  @override
  Map toJson() => this.asMap;

  Map get asMap =>
      {
        EventJSONKey.DND    : this.isOn
      };

  @override
  String toString() => this.toJson().toString();

}
