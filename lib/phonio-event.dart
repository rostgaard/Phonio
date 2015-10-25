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

/**
 * JSON serialization and de-serialization keys.
 */
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

/**
 * Base interface for an event.
 */
abstract class Event {

  String   get eventName;
  Map      toJson();

  String toString();

}
