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

import 'package:phonio/phonio.dart' as phonio;

/// Example on how to use the PJSUA backend.
void main() {
  // Define a SIP account.
  phonio.SIPAccount account =
      new phonio.SIPAccount('someuser', 'secretpassword', 'sip.example.com');

  // Create a new process. Nothing will be started until the [initialize]
  // method is called. it needs the path to compatible PJSUA backed, which
  // is currently located in support tools of
  // https://github.com/Bitstackers/OpenReception-Integration-Tests
  phonio.PJSUAProcess pjPhone =
      new phonio.PJSUAProcess('bin/simple_agent', 5060);

  // Add the account to the phone.
  pjPhone.addAccount(account);

  // The initialize returns a future that completes when the backend system
  // process has returned ready
  pjPhone
      .initialize()
      // Every communication method is a future that can be chained.
      .then((_) => pjPhone.register())
      .then((_) {
    pjPhone.originate('1109').then((phonio.Call call) {
      print('Originated $call');
    });
  });
}
