part of phonio;

class Call {
  String state = CallState.UNKNOWN;

}

abstract class CallState {
  static const String UNKNOWN  = 'UNKNOWN';
  static const String HELD     = 'HELD';
  static const String SPEAKING = 'SPEAKING';
  static const String RINGING  = 'HELD';
}
