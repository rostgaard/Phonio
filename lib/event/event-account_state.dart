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

/// [AccountState] event. Occurs if there are changes in account state.
///
/// A change may be a registration or and unregistration.
class AccountState implements Event {
  /// The ID of the account.

  final String accountId;

  /// Indicates if the account is signed in or not.
  final bool signedIn;

  /// Default constructor.
  AccountState(this.accountId, this.signedIn);

  @override
  String get eventName => _EventJSONKey._accountState;

  ///
  @deprecated
  String get accountID => accountId;

  /// Returns a map representation of the [AccountState] object.
  ///
  /// May be used as serialization function.
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        _EventJSONKey._accountId: accountId,
        _EventJSONKey._signedIn: signedIn
      };

  ///
  @deprecated
  Map<String, dynamic> get asMap => toJson();

  /// Returns a string representation of the [AccountState] object.
  @override
  String toString() => toJson().toString();
}
