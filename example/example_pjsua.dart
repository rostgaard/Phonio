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

  Phonio.PJSUAProcess pjPhone =
      new Phonio.PJSUAProcess ('bin/simple_agent', 5060);

  pjPhone.addAccount(account);

  pjPhone.initialize()
    .then((_) => pjPhone.register())
    .then((_) {
      pjPhone.originate ('1109')
        .then((Phonio.Call call) {
          print ('Originated $call');
      });
  });
}
