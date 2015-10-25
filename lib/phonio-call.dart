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
  static const String callID  = 'call_id';
  static const String callee  = 'callee';
  static const String inbound = 'inbound';

}

/**
 * Class representing a call within the phonio framework.
 */
class Call {

  final String ID;
  final String callee;
  final String callerID;
  final bool   inbound;

  String state = CallState.UNKNOWN;

  Call (this.ID, this.callee, this.inbound, this.callerID);

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

/**
 * Call state "enum".
 */
abstract class CallState {
  static const String UNKNOWN  = 'UNKNOWN';
  static const String HELD     = 'HELD';
  static const String SPEAKING = 'SPEAKING';
  static const String RINGING  = 'HELD';
}
