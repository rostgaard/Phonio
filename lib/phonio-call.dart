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

abstract class CallJSONKey {
  static const String callID = 'call_id';
  static const String callee = 'callee';
  static const String inbound = 'inbound';
}

/// Class representing a call within the phonio framework.
class Call {
  final String id;
  final String callee;
  final String callerId;

  final bool inbound;

  String state = CallState.unknown;

  Call(this.id, this.callee, this.inbound, this.callerId);

  Map<String, dynamic> toJson() => <String, dynamic>{
        CallJSONKey.callID: id,
        CallJSONKey.callee: callee,
        CallJSONKey.inbound: inbound
      };

  @override
  String toString() => toJson().toString();
}

/// Call state "enum".
abstract class CallState {
  static const String unknown = 'UNKNOWN';
  static const String held = 'HELD';
  static const String speaking = 'SPEAKING';
  static const String ringing = 'RINGING';
}
