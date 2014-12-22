part of phonio;

class CallDisconnected implements Event {
  final String callID;

  String   get eventName => EventJSONKey.callDisconnected;

  CallDisconnected(this.callID);

  @override
  Map toJson() => this.asMap;

  Map get asMap =>
      {
        EventJSONKey.callID : this.callID,
      };

  @override
  String toString() => this.toJson().toString();

}
