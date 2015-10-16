part of phonio;

/**
 * Interface specifying the minimum functionality that a concrete phone should
 * supply.
 * Basically, this covers account handling, call management and event
 * notification when, for instance, an incoming phone call arrives.
 */
abstract class SIPPhone {

  /// Internal logger.
  static Logger log = new Logger ('$libraryName.SIPPhone');

  /// IP address of the phone. Used in contact string.
  String _IPaddress = null;

  /// Identity of the phone, should be unique for _all_ generalization
  /// instances.
  int get ID;

  /// The contact Uri of the phone.
  String get contact;

  bool get ready;

  StreamController<Event> _eventController = new StreamController.broadcast();

  Stream<Event> get eventStream => this._eventController.stream;

  void _addEvent (Event event) {
    if (! this._eventController.isClosed) {
      this._eventController.add(event);
    }
    else {
      log.info
        ('Discarding event ${event.eventName} - eventcontroller is closed.');
    }
  }

  @override
  bool operator == (SIPPhone other) => this.ID == other.ID;

  @override
  int get hashCode => this._IPaddress.hashCode;

  Iterable<Call> get activeCalls;

  List<SIPAccount> _accounts = [];

  void addAccount(SIPAccount account) =>
    this._accounts.add(account);

  Future initialize();
  Future teardown();
  Future finalize();

  Future register({SIPAccount account : null});
  Future unregister({SIPAccount account : null});

  SIPAccount get defaultAccount;

  Future autoAnswer(bool enabled, {SIPAccount account : null});

  Future<Call> originate (String extension, {SIPAccount account : null});

  Future hangup();

  Future answer();

  Future hangupAll();

  Future hangupSpecific(Call call);

  Future hold();

  Future release(Call call);

  Future transfer(Call destination);

  Map toJson() =>  {
    'type' : this.runtimeType.toString(),
    'contact' : contact,
    'id' : ID,
    'active_calls' : activeCalls,
    'accounts' : _accounts,
    'default_account' : defaultAccount
  };
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




