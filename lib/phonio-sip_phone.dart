/*                  This file is part of Phonio
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of phonio;

/// Interface specifying the minimum functionality that a concrete phone
/// should supply.
///
/// Basically, this covers account handling, call management and event
/// notification when, for instance, an incoming phone call arrives.
abstract class SIPPhone {
  /// IP address of the phone. Used in contact string.
  String _ipAddress;

  int get id;

  /// The contact Uri of the phone.
  String get contact;

  bool get ready;

  StreamController<Event> _eventController =
      new StreamController<Event>.broadcast();

  Stream<Event> get eventStream => _eventController.stream;

  void _addEvent(Event event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    } else {
      new Logger('$_libraryName.SIPPhone').info(
          'Discarding event ${event.eventName} - eventcontroller is closed.');
    }
  }

  @override
  bool operator ==(Object other) => other is SIPPhone && id == other.id;

  @override
  int get hashCode => _ipAddress.hashCode;

  Iterable<Call> get activeCalls;

  List<SIPAccount> _accounts = <SIPAccount>[];

  void addAccount(SIPAccount account) => _accounts.add(account);

  Future<Null> initialize();
  Future<Null> teardown();
  Future<Null> finalize() async {
    await _eventController.close();
  }

  Future<Null> register({SIPAccount account: null});
  Future<Null> unregister({SIPAccount account: null});

  SIPAccount get defaultAccount;

  Future<Null> autoAnswer(bool enabled, {SIPAccount account: null});

  Future<Call> originate(String extension, {SIPAccount account: null});

  Future<Null> hangup();

  Future<Null> answer();

  Future<Null> answerSpecific(Call call);

  Future<Null> hangupAll();

  Future<Null> hangupSpecific(Call call);

  Future<Null> hold();

  Future<Null> release(Call call);

  Future<Null> transfer(Call destination);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': runtimeType.toString(),
        'contact': contact,
        'id': id,
        'active_calls': activeCalls,
        'accounts': _accounts,
        'default_account': defaultAccount
      };
}

/// Collection of phones.
class PhoneList extends IterableBase<SIPPhone> {
  Map<int, SIPPhone> _phones = <int, SIPPhone>{};

  @override
  Iterator<SIPPhone> get iterator => _phones.values.iterator;

  /// Lookup a phone from its IPv4 address.
  SIPPhone lookup(String remoteIPv4) => throw new UnimplementedError();

  /// Register a phone in the phone registry.
  void register(SIPPhone phone) {
    _phones[phone.id] = phone;
  }
}
