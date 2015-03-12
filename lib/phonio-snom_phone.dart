part of phonio;


abstract class SNOMKey {
  static const String CANCEL = 'CANCEL';
  static const String ENTER = 'ENTER';
  static const String OFFHOOK = 'OFFHOOK';
  static const String ONHOOK = 'ONHOOK';
  static const String RIGHT = 'RIGHT';
  static const String LEFT = 'LEFT';
  static const String UP = 'UP';
  static const String DOWN = 'DOWN';
  static const String VOLUME_UP = 'VOLUME_UP';
  static const String VOLUME_DOWN = 'VOLUME_DOWN';
  static const String MENU = 'MENU';
  static const String REDIAL = 'REDIAL';
  static const String DND = 'DND';
  static const String REC = 'REC';
  static const String F1 = 'F1';
  static const String F2 = 'F2';
  static const String F3 = 'F3';
  static const String F4 = 'F4';
  static const String SPEAKER = 'SPEAKER';
  static const String HEADSET = 'HEADSET';
  static const String TRANSFER = 'TRANSFER';
  static const String F_HOLD = 'F_HOLD';
  static const String _0 = '0';
  static const String _1 = '1';
  static const String _2 = '2';
  static const String _3 = '3';
  static const String _4 = '4';
  static const String _5 = '5';
  static const String _6 = '6';
  static const String _7 = '7';
  static const String _8 = '8';
  static const String _9 = '9';
  static const String asterisk = '*';
  static const String octothorpe = '#';
  static String P(int index) => 'P${index}';
  static String EK(int index) => 'Ek${index}';
}

abstract class SNOMResource {
  static String _commandResource = '/command.htm';

  static Uri Command(Uri base, String key) => Uri.parse('${base.toString()}$_commandResource?key=$key');
  static Uri Dial(Uri base) => Uri.parse('${base.toString()}/index.htm');

  static Uri AutoAnswer(Uri base) => Uri.parse('${base.toString()}/line_sip.htm');

  static Uri ActionURL(Uri base) => Uri.parse('${base.toString()}/action.htm');
}


class SNOMHTTPRequest {

  static const String GET  = 'GET';
  static const String POST = 'POST';

  String method;
  Uri    uri;
  String body;
  Completer<String> response = new Completer<String>();
}


/**
 * This agent have a builtin throttle mechanism that prevents commands from
 * being sent too fast to the phone. This prevents the remote webserver from
 * choking on them and sending back incomplete headers.
 */

class SNOMPhone extends SIPPhone {

  static const String classname = '${libraryName}.SNOMPhone';

  final Uri    _host;
  final Logger log                = new Logger(SNOMPhone.classname);
  final HTTPClientWrapper _client = new HTTPClientWrapper();

  /// Default sip port. Change if needed.
  int port = 5060;

  List<SIPAccount> accounts   = [];

  String get contact => '${this.defaultAccount.inContactFormat}:${this.port}';

  /// TODO: Implement.
  SIPAccount get defaultAccount => throw new StateError('Not implemented!');

  /// Work queue related fields.
  Queue<SNOMHTTPRequest> _httpRequestQueue = new Queue();
  bool _busy = false;

  /**
   * Returns a map represenation of the phone.
   */
  Map get asMap => {
    'host' : this._host.toString(),
    'accounts' : this.accounts
  };

  Future initialize () => throw new UnimplementedError
      ('WIP: Should push the account and callback information to the phone.');

  Future teardown() => throw new UnimplementedError();

  Future register({SIPAccount account : null}) => throw new UnimplementedError();
  /**
   * Serialization function
   */
  Map toJson() => this.asMap;

  bool get connected => this._host != null;

  SNOMPhone(this._host);

  Future hangup() => this.hangupCurrentCall();

  Future hangupSpecific(Call call) => new Future.error(new UnimplementedError());

  Future hangupAll() {
    log.shout('The hangupAll() method is inpure and only hangs up the current call');
    return this.hangupCurrentCall();
  }

  Future answer () {
    SNOMHTTPRequest request = new SNOMHTTPRequest()
      ..method = 'GET'
      ..uri    = SNOMResource.Command(this._host, SNOMKey.F_HOLD);

    return this._enqueue(request);
  }

  Future hold() {
    SNOMHTTPRequest request = new SNOMHTTPRequest()
                      ..method = 'GET'
                      ..uri    = SNOMResource.Command(this._host, SNOMKey.F_HOLD);

    return this._enqueue(request);
  }

  Future<bool> isSnomEmbeddedServer() {

    return this._client.getResponse(this._host)
        .then((IO.HttpClientResponse response) =>
            response.headers.value('server').contains('snom embedded'));
  }

  Future setActionURL (Map<String, String> actionURLs) {
    String buf = '';
    actionURLs.forEach((String key, String value) {
      buf = buf + '$key:${Uri.encodeComponent(value)}\r\n';
    });
    buf = buf + 'Settings:Apply';

    SNOMHTTPRequest request = new SNOMHTTPRequest()
                      ..method = SNOMHTTPRequest.POST
                      ..uri    = SNOMResource.ActionURL(this._host)
                      ..body   = buf;


    return this._enqueue(request);
  }

  Future release(Call call) => new Future.error(new StateError('Not implemented!'));

  Future transfer(Call destination) => new Future.error(new StateError('Not implemented!'));

  Future autoAnswer(bool enabled, {SIPAccount account : null}) {

    //XXX: Add _REAL_ account index!
    int accountIndex = 1;

    SNOMHTTPRequest request = new SNOMHTTPRequest()
                      ..method = SNOMHTTPRequest.POST
                      ..uri    = SNOMResource.AutoAnswer(this._host)
                      ..body   = 'user_auto_connect${accountIndex}:${enabled ? 'on' : 'off'}\r\nSettings:Apply';


    return this._enqueue(request);
  }

  Future<String> hangupCurrentCall() {
    SNOMHTTPRequest request = new SNOMHTTPRequest()
                      ..method = 'GET'
                      ..uri    = SNOMResource.Command(this._host, SNOMKey.CANCEL);

    return this._enqueue(request);
  }


  Future<Call> originate (String extension, {SIPAccount account : null}) {
      Completer<Call> completer = new Completer();

      SNOMHTTPRequest request = new SNOMHTTPRequest()
                      ..method = 'POST'
                      ..uri    = SNOMResource.Dial(this._host)
                      ..body   = "NUMBER:$extension";

    this.eventStream.firstWhere((Event event) => event is CallOutgoing)
       .then((CallOutgoing e) {
          Call call = new Call(e.callID, e.callee, false);
          completer.complete(call);
       })
       .catchError((error, stackTrace) => completer.completeError(error, stackTrace));

     this._enqueue(request);

    return completer.future;
  }

  /**
   * Every request sent to the phone is enqueued and executed in-order without
   * the possibility to pipeline requests. The SNOM phones does not take kindly
   * to concurrent requests, and this is a mean to prevent this from happening.
   */
  Future<String> _enqueue (SNOMHTTPRequest request) {
      if (!this._busy) {
        this._busy = true;
        log.finest('No requests enqueued. Sending request directly.');
        return this._performRequest (request);
      } else {
        log.finest('Requests enqueued. Enqueueing this request.');

        this._httpRequestQueue.add(request);
        return request.response.future;
      }
  }

  Future <String> _performRequest (SNOMHTTPRequest request) {

    void dispatchNext() {
      if (this._httpRequestQueue.isNotEmpty) {
        SNOMHTTPRequest currentRequest = this._httpRequestQueue.removeFirst();

        this._performRequest (currentRequest)
          .then((String response) => currentRequest.response.complete(response));
      } else {
        this._busy = false;
      }
    }

    switch (request.method.toUpperCase()) {
      case 'GET' :
        return this._client.get (request.uri)
            ..whenComplete(() => new Future(dispatchNext));

      case 'POST' :
        return this._client.post (request.uri, request.body)
            ..whenComplete(() => new Future(dispatchNext));

      default :
        throw new StateError('Unsupported HTTP method: ${request.method}');

    }
  }
}

/**
 * Convenience wrapper class for performing HTTP requests.
  */
class HTTPClientWrapper {

  static final String className = '${libraryName}.Client';
  static final Logger log       = new Logger(className);

  final IO.HttpClient client    = new IO.HttpClient();
  /**
   * HTTP GET.
   */
  Future<String> get(Uri resource) {
    log.finest('GET $resource');

    final Completer<String> completer = new Completer<String>();

    client.getUrl(resource).then((IO.HttpClientRequest request) {
        request.headers.set(IO.HttpHeaders.CONNECTION, 'keep-alive');
        return request.close();
      }).then((IO.HttpClientResponse response) {

      String buffer = "";
      try {
        response.transform(UTF8.decoder).listen((contents) {
          buffer = '${buffer}${contents}';
        }).onDone(() {
          completer.complete(buffer);
        });
      } catch (error, stacktrace) {
        completer.completeError(error, stacktrace);
      }
    }).catchError((error, stackTrace) => completer.completeError(error,stackTrace));

    return completer.future;

  }

  /**
   * HTTP response.
   */
  Future<IO.HttpClientResponse> getResponse(Uri resource) {
    log.finest('GET $resource');

    return client.getUrl(resource).then((IO.HttpClientRequest request) =>
        request.close());
  }

  /**
   * HTTP POST.
   */
  Future<String> post(Uri resource, String payload) {
    log.finest(resource);

    final Completer<String> completer = new Completer<String>();

    client.postUrl(resource).then((IO.HttpClientRequest request) {
        request.headers.contentType = new IO.ContentType ('application',
                                                          'x-www-form-urlencoded');
        request.headers.set(IO.HttpHeaders.CONNECTION, 'keep-alive');

        request.write(payload);

        return request.close();

      }).then((IO.HttpClientResponse response) {
      String buffer = "";
      if (response.statusCode == 200 || response.statusCode == 302) {

        response.transform(UTF8.decoder).listen((contents) {
          buffer = '${buffer}${contents}';

        }).onDone(() {
          log.finest('Completing');

          completer.complete(buffer);
        });
      } else {
        completer.completeError(new StateError('Bad response from server: ${response.headers}'));
      }
    });

    return completer.future;
  }

  /**
   * HTTP PUT. Not supported by SNOM.
   */

  Future<String> put(Uri resource, String payload)
     => new Future.error(new StateError('Not supported by SNOM phones.'));

  /**
   * HTTP DELETE. Not supported by SNOM.
   */
  Future<String> delete(Uri resource)
     => new Future.error(new StateError('Not supported by SNOM phones.'));
}
