part of phonio;

class Hook implements Event{
  final bool isOn;

  String   get eventName => EventJSONKey.hook;

  Hook (this.isOn);

  @override
  Map toJson() => this.asMap;

  Map get asMap =>
      {
        EventJSONKey.hook : this.isOn
      };

  @override
  String toString() => this.toJson().toString();

}
