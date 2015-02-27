part of phonio;

abstract class SIPPhone {

  String _IPaddress = null;

  int get ID => this.hashCode;

  StreamController<Event> _eventController = new StreamController.broadcast();

  Stream<Event> get eventStream => this._eventController.stream;

  void _addEvent (Event event) => this._eventController.add(event);

  @override
  bool operator == (SIPPhone other) => this.ID == other.ID;

  @override
  int get hashCode => this._IPaddress.hashCode;

  List<Call> activeCalls;

  List<SIPAccount> _accounts = [];

  SIPAccount get defaultAccount;

  Future autoAnswer(bool enabled, {SIPAccount account : null});

  Future<Call> originate (String extension, {SIPAccount account : null});

  Future hangup();

  Future hangupAll();

  Future hangupSpecific(Call call);

  Future hold();

  Future release(Call call);

  Future transfer(Call destination);
}

class PhoneList extends IterableBase<SIPPhone> {

  Map<int, SIPPhone> _phones = null;

  Iterator get iterator => this._phones.values.iterator;

  lookup (String remoteIPv4) {

  }

  register (SIPPhone phone) {
    this._phones[phone.ID] = phone;
  }
}




