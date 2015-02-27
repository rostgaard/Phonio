part of phonio;

abstract class EventJSONKey {
  static const String accountState     = 'account_state';
  static const String callConnected    = 'call_connected';
  static const String callIncoming     = 'call_incoming';
  static const String callInvite       = 'call_invite';
  static const String callDisconnected = 'call_disconnected';
  static const String callOutgoing     = 'call_outbound';
  static const String DND              = 'dnd';
  static const String hook             = 'hook';

  static const String accountID        = 'account_id';
  static const String signedIn         = 'signed_in';
  static const String callID           = 'call_id';
  static const String callee           = 'callee';
}

abstract class Event {

  String   get eventName;
  Map      toJson();

  String toString();

}
