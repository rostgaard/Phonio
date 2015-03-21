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
