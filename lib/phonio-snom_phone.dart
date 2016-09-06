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

/// Physical keys found on SNOM phones. Typically used in the context of
/// constructing [SNOMResource].
abstract class SNOMKey {
  static const String cancel = 'CANCEL';
  static const String enter = 'ENTER';
  static const String offHook = 'OFFHOOK';
  static const String onHook = 'ONHOOK';
  static const String right = 'RIGHT';
  static const String left = 'LEFT';
  static const String up = 'UP';
  static const String down = 'DOWN';
  static const String volumeUp = 'VOLUME_UP';
  static const String volumeDown = 'VOLUME_DOWN';
  static const String menu = 'MENU';
  static const String redial = 'REDIAL';
  static const String dnd = 'DND';
  static const String rec = 'REC';
  static const String f1 = 'F1';
  static const String f2 = 'F2';
  static const String f3 = 'F3';
  static const String f4 = 'F4';
  static const String speaker = 'SPEAKER';
  static const String headset = 'HEADSET';
  static const String transfer = 'TRANSFER';
  static const String fHold = 'F_HOLD';
  static const String num0 = '0';
  static const String num1 = '1';
  static const String num2 = '2';
  static const String num3 = '3';
  static const String num4 = '4';
  static const String num5 = '5';
  static const String num6 = '6';
  static const String num7 = '7';
  static const String num8 = '8';
  static const String num9 = '9';
  static const String asterisk = '*';
  static const String octothorpe = '#';
  static String p(int index) => 'P$index';
  static String ek(int index) => 'Ek$index';
}

/// A resource on a SNOM embedded webserver. Used for constructing Uri's
/// that send commands to the phone and trieve status information.
abstract class SNOMResource {
  static String _commandResource = '/command.htm';

  static Uri command(Uri base, String key) =>
      Uri.parse('${base.toString()}$_commandResource?key=$key');
  static Uri dial(Uri base) => Uri.parse('${base.toString()}/index.htm');

  static Uri autoAnswer(Uri base) =>
      Uri.parse('${base.toString()}/line_sip.htm');

  static Uri actionURL(Uri base) => Uri.parse('${base.toString()}/action.htm');
}

class SNOMHTTPRequest {
  final String method;
  final Uri uri;
  final String body;
  final Completer<String> response = new Completer<String>();

  SNOMHTTPRequest(this.method, this.uri, {this.body: ''});
}

/// SNOM phone agent wrapper.
///
/// This agent have a builtin throttle mechanism that prevents commands
/// from being sent too fast to the phone.
/// This prevents the remote webserver from choking on them and sending
/// back incomplete headers.
///
/// TODO: Enable call listing and handling of specific calls.
class SNOMPhone extends SIPPhone {
  final Uri _host;
  final Logger _localLog = new Logger('$_libraryName.SNOMPhone');
  final HTTPClientWrapper _client = new HTTPClientWrapper();

  SNOMPhone(this._host);

  @override
  int get id => contact.hashCode;
  @override
  int get ID => id;

  @override
  bool get ready => true;

  /// Default sip port. Change if needed.
  int port = 5060;

  List<SIPAccount> accounts = <SIPAccount>[];

  @override
  List<Call> get activeCalls => throw new UnimplementedError('Implement me!');

  @override
  Future<Null> answerSpecific(Call call) =>
      throw new UnimplementedError('Implement me!');

  /// Returns a map represenation of the phone.
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> root = super.toJson();
    Map<String, dynamic> extension = <String, dynamic>{
      'host': _host.toString(),
    };

    root['snom_phone'] = extension;

    return root;
  }

  @override
  String get contact => '${defaultAccount.inContactFormat}:$port';

  @override
  SIPAccount get defaultAccount => throw new UnimplementedError();

  /// Work queue related fields.
  Queue<SNOMHTTPRequest> _httpRequestQueue = new Queue<SNOMHTTPRequest>();
  bool _busy = false;

  @override
  Future<Null> initialize() => throw new UnimplementedError(
      'WIP: Should push the account and callback information to the phone.');

  @override
  Future<Null> teardown() => throw new UnimplementedError();

  @override
  Future<Null> register({SIPAccount account: null}) =>
      throw new UnimplementedError();

  @override
  Future<Null> unregister({SIPAccount account: null}) =>
      throw new UnimplementedError();
  bool get connected => _host != null;

  @override
  Future<Null> hangup() async {
    await hangupCurrentCall();
  }

  @override
  Future<Null> hangupSpecific(Call call) async =>
      throw new UnimplementedError();

  @override
  Future<Null> hangupAll() async {
    _localLog.shout(
        'The hangupAll() method is inpure and only hangs up the current call');
    await hangupCurrentCall();
  }

  @override
  Future<Null> answer() async {
    SNOMHTTPRequest request =
        new SNOMHTTPRequest('GET', SNOMResource.command(_host, SNOMKey.fHold));

    await _enqueue(request);
  }

  @override
  Future<Null> hold() async {
    SNOMHTTPRequest request =
        new SNOMHTTPRequest('GET', SNOMResource.command(_host, SNOMKey.fHold));

    await _enqueue(request);
  }

  Future<bool> isSnomEmbeddedServer() {
    return _client.getResponse(_host).then((io.HttpClientResponse response) =>
        response.headers.value('server').contains('snom embedded'));
  }

  Future<String> setActionURL(Map<String, String> actionURLs) {
    String buf = '';
    actionURLs.forEach((String key, String value) {
      buf = buf + '$key:${Uri.encodeComponent(value)}\r\n';
    });
    buf = buf + 'Settings:Apply';

    SNOMHTTPRequest request =
        new SNOMHTTPRequest('POST', SNOMResource.actionURL(_host), body: buf);

    return _enqueue(request);
  }

  @override
  Future<Null> release(Call call) async => throw new UnimplementedError();

  @override
  Future<Null> transfer(Call destination) async =>
      throw new UnimplementedError();

  @override
  Future<Null> autoAnswer(bool enabled, {SIPAccount account: null}) async {
    //XXX: Add _REAL_ account index!
    int accountIndex = 1;

    final String payload =
        'user_auto_connect$accountIndex:${enabled ? 'on' : 'off'}\r\n'
        'Settings:Apply';

    SNOMHTTPRequest request = new SNOMHTTPRequest(
        'POST', SNOMResource.autoAnswer(_host),
        body: payload);

    await _enqueue(request);
  }

  Future<String> hangupCurrentCall() {
    SNOMHTTPRequest request =
        new SNOMHTTPRequest('GET', SNOMResource.command(_host, SNOMKey.cancel));

    return _enqueue(request);
  }

  @override
  Future<Null> finalize() async =>
      throw new UnimplementedError('Implement me!');

  @override
  Future<Call> originate(String extension, {SIPAccount account: null}) {
    Completer<Call> completer = new Completer<Call>();

    SNOMHTTPRequest request = new SNOMHTTPRequest(
        'POST', SNOMResource.dial(_host),
        body: "NUMBER:$extension");

    this
        .eventStream
        .firstWhere((Event event) => event is CallOutgoing)
        .then((CallOutgoing e) {
      Call call = new Call(e.callId, e.callee, false, defaultAccount.username);
      completer.complete(call);
    }).catchError((dynamic error, StackTrace stackTrace) =>
            completer.completeError(error, stackTrace));

    _enqueue(request);

    return completer.future;
  }

  /// Every request sent to the phone is enqueued and executed in-order
  /// without the possibility to pipeline requests. The SNOM phones does
  /// not take kindly to concurrent requests, and this is a mean to prevent
  /// this from happening.
  Future<String> _enqueue(SNOMHTTPRequest request) {
    if (!_busy) {
      _busy = true;
      _localLog.finest('No requests enqueued. Sending request directly.');
      return _performRequest(request);
    } else {
      _localLog.finest('Requests enqueued. Enqueueing this request.');

      _httpRequestQueue.add(request);
      return request.response.future;
    }
  }

  Future<String> _performRequest(SNOMHTTPRequest request) {
    void dispatchNext() {
      if (_httpRequestQueue.isNotEmpty) {
        SNOMHTTPRequest currentRequest = _httpRequestQueue.removeFirst();

        _performRequest(currentRequest).then(
            (String response) => currentRequest.response.complete(response));
      } else {
        _busy = false;
      }
    }

    switch (request.method.toUpperCase()) {
      case 'GET':
        return _client.get(request.uri)
          ..whenComplete(() => new Future<String>(dispatchNext));

      case 'POST':
        return _client.post(request.uri, request.body)
          ..whenComplete(() => new Future<String>(dispatchNext));

      default:
        throw new StateError('Unsupported HTTP method: ${request.method}');
    }
  }
}

/// Convenience wrapper class for performing HTTP requests.
class HTTPClientWrapper {
  final Logger _log = new Logger('$_libraryName.Client');

  final io.HttpClient client = new io.HttpClient();

  /// HTTP GET.
  Future<String> get(Uri resource) {
    _log.finest('GET $resource');

    final Completer<String> completer = new Completer<String>();

    client.getUrl(resource).then((io.HttpClientRequest request) {
      request.headers.set(io.HttpHeaders.CONNECTION, 'keep-alive');
      return request.close();
    }).then((io.HttpClientResponse response) {
      String buffer = "";
      try {
        response.transform(UTF8.decoder).listen((String contents) {
          buffer = '$buffer$contents';
        }).onDone(() {
          completer.complete(buffer);
        });
      } catch (error, stacktrace) {
        completer.completeError(error, stacktrace);
      }
    }).catchError((dynamic error, StackTrace stackTrace) =>
        completer.completeError(error, stackTrace));

    return completer.future;
  }

  /// HTTP response.
  Future<io.HttpClientResponse> getResponse(Uri resource) {
    _log.finest('GET $resource');

    return client
        .getUrl(resource)
        .then((io.HttpClientRequest request) => request.close());
  }

  /// HTTP POST.
  Future<String> post(Uri resource, String payload) {
    _log.finest(resource);

    final Completer<String> completer = new Completer<String>();

    client.postUrl(resource).then((io.HttpClientRequest request) {
      request.headers.contentType =
          new io.ContentType('application', 'x-www-form-urlencoded');
      request.headers.set(io.HttpHeaders.CONNECTION, 'keep-alive');

      request.write(payload);

      return request.close();
    }).then((io.HttpClientResponse response) {
      String buffer = "";
      if (response.statusCode == 200 || response.statusCode == 302) {
        response.transform(UTF8.decoder).listen((String contents) {
          buffer = '$buffer$contents';
        }).onDone(() {
          _log.finest('Completing');

          completer.complete(buffer);
        });
      } else {
        completer.completeError(
            new StateError('Bad response from server: ${response.headers}'));
      }
    });

    return completer.future;
  }

  /// HTTP PUT. Not supported by SNOM.
  Future<String> put(Uri resource, String payload) async =>
      throw new StateError('Not supported by SNOM phones.');

  /// HTTP DELETE. Not supported by SNOM.
  Future<String> delete(Uri resource) async =>
      throw new StateError('Not supported by SNOM phones.');
}
