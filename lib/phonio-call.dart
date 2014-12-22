part of phonio;

abstract class CallJSONKey {
  static const String callID  = 'call_id';
  static const String callee  = 'callee';
  static const String inbound = 'inbound';

}

class Call {

  final String ID;
  final String callee;
  final bool   inbound;

  String state = CallState.UNKNOWN;

  Call (this.ID, this.callee, this.inbound);

  Map get asMap =>
      {
        CallJSONKey.callID : this.ID,
        CallJSONKey.callee : this.callee,
        CallJSONKey.inbound : this.inbound
      };

  Map toJson() => this.asMap;

  @override
  String toString() => this.asMap.toString();

}

abstract class CallState {
  static const String UNKNOWN  = 'UNKNOWN';
  static const String HELD     = 'HELD';
  static const String SPEAKING = 'SPEAKING';
  static const String RINGING  = 'HELD';
}