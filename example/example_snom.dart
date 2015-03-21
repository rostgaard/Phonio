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

import 'package:phonio/phonio.dart' as Phonio;

/**
 * Example on how to use the SNOM backend.
 */
void main() {

  // Define a SIP account.
  Phonio.SIPAccount account =
    new Phonio.SIPAccount('someuser', 'secretpassword', 'sip.example.com');

  /* Create a new process. Nothing will be started until the [initialize]
     method is called. */
  Phonio.SNOMPhone snomPhone = new Phonio.SNOMPhone
      (Uri.parse('http://snomhost.example.com'));

  /* Helper map that is needed to enable the [SNOMActionGateway] to
     dispatch events into the approprate event stream */
  Map phoneMap = { account.username : snomPhone};

  // This gateway is needed to receive events from SNOM phones.
  Phonio.SNOMActionGateway snomgw = new Phonio.SNOMActionGateway(phoneMap);

  // Start the gateway.
  snomgw.start(hostname: 'myExternalHostname')
    /* The gateway provides a heler function that, when coupled with the
       [setActionURL] method of a [SNOMPhone] registers the callback urls that
       will be used whenever the SNOM phone triggers an event (such as
       incoming an call) */
    .then((_) => snomPhone.setActionURL(snomgw.actionUrls));

  // Add the account to the phone.
  snomPhone.accounts.add(account);

  // Every communication method is a future that can be chained.
  snomPhone.autoAnswer(true)
    .then ((_) => snomPhone.register())
    .then ((_) => snomPhone.originate ('1109')
      .then((Phonio.Call call) {
        print ('Originated $call');
      }));
}
