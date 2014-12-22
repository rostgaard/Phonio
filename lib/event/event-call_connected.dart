part of phonio;

class CallConnected implements Event{
  final String callID;

  String   get eventName => EventJSONKey.callConnected;

  CallConnected (this.callID);

  @override
  Map toJson() => this.asMap;

  Map get asMap =>
      { EventJSONKey.callID : this.callID,
      };

  @override
  String toString() => this.toJson().toString();
}
