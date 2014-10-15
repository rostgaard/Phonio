import 'dart:async' as async;

import '../lib/phonio.dart';

import 'package:logging/logging.dart';

const String pbxHost = 'myhost';

final SIPAccount account1107 =
  new SIPAccount(new SNOMPhone(Uri.parse('http://${SNOMphonesHostnames['1107']}')));

final SIPAccount account1108 =
  new SIPAccount(new SNOMPhone(Uri.parse('http://${SNOMphonesHostnames['1108']}')));

final SIPAccount account1109 =
  new SIPAccount(new SNOMPhone(Uri.parse('http://${SNOMphonesHostnames['1109']}')));

final Map<String, String> SNOMphonesHostnames =
{'1107' : 'phone1.exampe.com',
 '1108' : 'phone2.exampe.com',
 '1109' : 'phone3.exampe.com'};

void main() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen(print);

  Map<String, SNOMPhone> SNOMphonesResolutionMap = {};

  [account1107, account1108, account1109].forEach((SIPAccount account)
      => SNOMphonesResolutionMap.addAll({account.username : account.phone}));


  SNOMphonesResolutionMap.forEach((id, phone) =>
      phone.eventStream.listen((String event) => print ('EVENT: $id $event')));

  SNOMActionGateway snomgw = new SNOMActionGateway(SNOMphonesResolutionMap);
  snomgw.start(hostname: pbxHost)
    .then((_) => snomgw.phones.values.forEach((SNOMPhone p) => p.setActionURL(snomgw.actionUrls)));
  SNOMPhone phone = snomgw.phones['1107'];


  snomgw.phones.values.forEach((SNOMPhone p) => p.autoAnswer(true));

  phone.originate ('1108').then((_) =>
    phone.hangupCurrentCall());
  phone.originate ('1109').then((_) =>
    phone.hangupCurrentCall());

  phone.originate ('1109')
  .then((_) => new async.Future.delayed(new Duration(seconds : 1), () => phone.hangupCurrentCall() )
  .then((_) => new async.Future.delayed(new Duration(seconds : 1), () => phone.originate ('1109')) )
  .then((_) => new async.Future.delayed(new Duration(seconds : 1), () => phone.hangupCurrentCall() )
  ));

}
