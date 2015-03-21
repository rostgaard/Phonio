import '../lib/phonio.dart' as Phonio;

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
