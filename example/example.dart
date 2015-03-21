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

void main() {

  Phonio.SIPAccount account =
    new Phonio.SIPAccount('someuser', 'secretpassword', 'sip.example.com');

  Phonio.SNOMPhone snomPhone = new Phonio.SNOMPhone
      (Uri.parse('http://snomhost.example.com'));

  Map phoneMap = { account.username : snomPhone};

  Phonio.SNOMActionGateway snomgw = new Phonio.SNOMActionGateway(phoneMap);

  snomgw.start(hostname: 'myExternalHostname')
    .then((_) => snomPhone.setActionURL(snomgw.actionUrls));

  snomPhone.accounts.add(account);

  snomPhone.autoAnswer(true);

  snomPhone.originate ('1109')
  .then((Phonio.Call call) {
    print ('Originated $call');
  });

}
