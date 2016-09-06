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

/// JSON serialization and de-serialization keys.
abstract class _EventJSONKey {
  static const String _accountState = 'account_state';
  static const String _callConnected = 'call_connected';
  static const String _callIncoming = 'call_incoming';
  static const String _callInvite = 'call_invite';
  static const String _callDisconnected = 'call_disconnected';
  static const String _callOutgoing = 'call_outbound';
  static const String _dnd = 'dnd';
  static const String _hook = 'hook';

  static const String _accountId = 'account_id';
  static const String _signedIn = 'signed_in';
  static const String _callId = 'call_id';
  static const String _callee = 'callee';
}

/// Base interface for an event.
abstract class Event {
  /// The name for the event.
  String get eventName;

  /// Serialization function.
  Map<String, dynamic> toJson();

  @override
  String toString();
}
