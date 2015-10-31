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
 * Occurs if there are changes in account state. A change may be a registration
 * or and unregistration.
 */
class AccountState implements Event {
  /// The ID of the account.
  final String accountID;

  /// Indicates if the account is signed in or not.
  final bool signedIn;

  String get eventName => EventJSONKey.accountState;

  /**
   * Default constructor.
   */
  AccountState(this.accountID, this.signedIn);

  /**
   * JSON serialization function.
   */
  @override
  Map toJson() => this.asMap;

  /**
   * Returns a map representation of the [AccountState] object.
   */
  Map get asMap => {
        EventJSONKey.accountID: this.accountID,
        EventJSONKey.signedIn: this.signedIn
      };

  /**
   * Returns a string representation of the [AccountState] object.
   */
  @override
  String toString() => this.toJson().toString();
}
