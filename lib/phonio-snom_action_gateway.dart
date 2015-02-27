part of phonio;

class SNOMActionGateway {

  Map<String, SNOMPhone> phones = {};

  SNOMActionGateway (this.phones);
  String host = null;

  IO.HttpServer server;

  /**
   * TODO: Figure out a way to extract the effective external IP.
   */
  Future start({String hostname : '0.0.0.0', int port : 8000}) {
    var router = route.router()
        ..get(SNOMActionURL.CALL_OUTGOING,     this.callOutgoing)
        ..get('${SNOMActionURL.DND}/{dnd_state}',  this.dnd)
        ..get('${SNOMActionURL.HOOK}/{hook_state}',   this.hook)
        ..get(SNOMActionURL.INCOMING,     this.callIncoming)
        ..get(SNOMActionURL.KEY_ACTION_INCOMING,       this.callInvite)
        ..get(SNOMActionURL.CONN,    this.callConnected)
        ..get(SNOMActionURL.DISCONN, this.callDisconnected)
         ..get('/phone/list',        this.list)
        ..get('/phone/{id}',        this.get);

    var handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(exceptionResponse())
        .addHandler(router.handler);

    route.printRoutes(router);



    return shelf_io.serve(handler, hostname, port).then((server) {
      this.host = 'http://${server.address.host}:${server.port}';
      this.server = server;
      print('Serving at ${this.host}');
    });
  }

  Map<String,String> get actionUrls => {
    SNOMActionURL.KEY_ACTION_AXFR         :
      '${this.host}${SNOMActionURL.AXFR}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_BXFR         :
      '${this.host}${SNOMActionURL.BXFR}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_CONN         :
      '${this.host}${SNOMActionURL.CONN}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_DISCONN      :
      '${this.host}${SNOMActionURL.DISCONN}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_DND_OFF      :
      '${this.host}${SNOMActionURL.DND_OFF}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_DND_ON       :
      '${this.host}${SNOMActionURL.DND_ON}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_HOLD         :
      '${this.host}${SNOMActionURL.HOLD}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_UNHOLD       :
      '${this.host}${SNOMActionURL.UNHOLD}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_INCOMING     :
      '${this.host}${SNOMActionURL.INCOMING}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}'
      '&${SNOMActionURL.CalleeKV}',

    SNOMActionURL.KEY_ACTION_LOG_OFF      :
      '${this.host}${SNOMActionURL.LOG_OFF}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_LOG_ON       :
      '${this.host}${SNOMActionURL.LOG_ON}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_MISSED       :
      '${this.host}${SNOMActionURL.MISSED}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_HOOK_OFF     :
      '${this.host}${SNOMActionURL.HOOK_OFF}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_HOOK_ON      :
      '${this.host}${SNOMActionURL.HOOK_ON}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_OUTGOING     :
      '${this.host}${SNOMActionURL.CALL_OUTGOING}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}'
      '&${SNOMActionURL.CalleeKV}',

    SNOMActionURL.KEY_ACTION_RECV_AXFR    :
      '${this.host}${SNOMActionURL.RECV_AXFR}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_CALL_FWD_OFF :
      '${this.host}${SNOMActionURL.CALL_FWD_OFF}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',

    SNOMActionURL.KEY_ACTION_CALL_FWD_ON  :
      '${this.host}${SNOMActionURL.CALL_FWD_ON}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_REG_FAILED   :
      '${this.host}${SNOMActionURL.REG_FAILED}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_SETUP_DONE   :
      '${this.host}${SNOMActionURL.SETUP_DONE}'
      '?${SNOMActionURL.UserKV}',

    SNOMActionURL.KEY_ACTION_XFR          :
      '${this.host}${SNOMActionURL.XFR}'
      '?${SNOMActionURL.UserKV}'
      '&${SNOMActionURL.CallIDKV}',
  };

  /**
   *
   */
  Response callOutgoing(Request request) {

    this.phones[SNOMparameters.user(request)]
    ._addEvent(new CallOutgoing
        (SNOMparameters.callID(request),
         SNOMparameters.callee(request)));

    return new Response.ok('');
  }

  /**
   *
   */
  Response dnd(Request request) {
    bool dnd = null;
    if (SNOMparameters.dnd(request).toLowerCase() == 'on')
      dnd = true;
    else if (SNOMparameters.dnd(request).toLowerCase() == 'off')
      dnd = false;

    this.phones[SNOMparameters.user(request)]
      ._addEvent(new DND(dnd));

    return new Response.ok('');
  }

  /**
   *
   */
  Response callInvite(Request request) {
    this.phones[SNOMparameters.user(request)]
      ._addEvent(new CallInvite(SNOMparameters.callID(request),
                                SNOMparameters.callee(request)));

    return new Response.ok('');
  }

  /**
   *
   */
  Response callConnected(Request request) {
    this.phones[SNOMparameters.user(request)]
      ._addEvent(new CallConnected(SNOMparameters.callID(request)));

    return new Response.ok('');
  }


  /**
   *
   */
  Response callDisconnected(Request request) {
    this.phones[SNOMparameters.user(request)]
    ._addEvent(new CallDisconnected(SNOMparameters.callID(request)));

    return new Response.ok('');
  }


  /**
   *
   */
  Response hook(Request request) {
    bool hook = null;
    if (SNOMparameters.hook(request).toLowerCase() == 'on')
      hook = true;
    else if (SNOMparameters.hook(request).toLowerCase() == 'off')
      hook = false;

    this.phones[SNOMparameters.user(request)]._addEvent(new DND(hook));

    return new Response.ok('');
  }

  /**
   *
   */
  Response callIncoming(Request request) {
    this.phones[SNOMparameters.user(request)]
      ._addEvent(new CallIncoming(SNOMparameters.callID(request),
                                  SNOMparameters.callee(request)));

    return new Response.ok('');
  }


  Response get(Request request) =>
      new Response.ok(JSON.encode(this.phones[route.getPathParameters(request)['id']]));

  Response list(Request request)  =>
      new Response.ok(JSON.encode(this.phones));

}

abstract class SNOMparameters {

  static String user(Request request)
    => request.requestedUri.queryParameters[SNOM.PARAM_UID];

  static String callID(Request request) =>
      request.requestedUri.queryParameters[SNOM.PARAM_CALL_ID];

  static String dnd(Request request)    =>
      route.getPathParameters(request)['dnd_state'];

  static String hook(Request request)   =>
      route.getPathParameters(request)['hook_state'];

  static String callee(Request request) =>
      request.requestedUri.queryParameters[SNOM.PARAM_CALLEE];

  static String IPv4(Request request)   =>
      request.requestedUri.queryParameters[SNOM.PARAM_IPv4];

}

abstract class SNOM {
  static const String PARAM_UID     = 'uid';
  static const String PARAM_CALL_ID = 'cid';
  static const String PARAM_DND     = 'dnd';
  static const String PARAM_HOOK    = 'hook';
  static const String PARAM_CALLEE  = 'callee';
  static const String PARAM_IPv4    = 'ipv4';
  static const String KEY_SETTINGS  = 'Settings';
  static const String VALUE_APPLY   = 'Apply';


  static const String VAR_ACTIVE_USER   = '\$active_user';
  static const String VAR_LOCAL_SIP_URI = '\$local';
  static const String VAR_REMOTE_SIP_URI = '\$remote';
  static const String VAR_ACTIVE_URL = '\$active_url';
  static const String VAR_ACTIVE_HOST = '\$active_host';
  static const String VAR_CSTA_ID = '\$csta_id';
  static const String VAR_CALL_ID = '\$call-id';
  static const String VAR_DISPLAY_LOCAL = '\$display_local';
  static const String VAR_DISPLAY_REMOTE = '\$display_remote';
  static const String VAR_EXPANSION_MODULE = '\$expansion_module';
  static const String VAR_ACTIVE_F_KEY = '\$active_key'; // Active line?
  static const String VAR_PHONE_IP = '\$phone_ip';
  static const String VAR_NUM_CALLS = '\$nr_ongoing_calls';
  static const String VAR_CONTEXT_URL = '\$context_url'; // used in log_on/off-action
  static const String VAR_CANCEL_REASON = '\$cancel_reason'; // reason-header for cancel/hangup
}

abstract class SNOMActionURL {

  static const String UserKV   = '${SNOM.PARAM_UID}=${SNOM.VAR_ACTIVE_USER}';
  static const String CallIDKV = '${SNOM.PARAM_CALL_ID}=${SNOM.VAR_CALL_ID}';
  static const String CalleeKV = '${SNOM.PARAM_CALLEE}=${SNOM.VAR_REMOTE_SIP_URI}';

  static const String CALL_OUTGOING = '/outgoing_call';
  static const String AXFR          = '/axfr';
  static const String BXFR          = '/bxfr';
  static const String CONN          = '/conn';
  static const String DISCONN       = '/dconn';
  static const String DND           = '/dnd';
  static const String DND_ON        = '${DND}/on';
  static const String DND_OFF       = '${DND}/off';
  static const String HOLD          = '/hold';
  static const String UNHOLD        = '/unhold';
  static const String INCOMING      = '/call/incoming';
  static const String LOG_OFF       = '/logoff';
  static const String LOG_ON        = '/logon';
  static const String MISSED        = '/missed';
  static const String HOOK          = '/hook';
  static const String HOOK_ON       = '${HOOK}/on';
  static const String HOOK_OFF      = '${HOOK}/off';
  static const String SETUP_DONE    = '/ready';
  static const String CALL_FWD_OFF  = '/fwdoff';
  static const String CALL_FWD_ON   = '/fwdon';
  static const String REG_FAILED    = '/regfail';
  static const String XFR           = '/xfr';
  static const String RECV_AXFR     = '/recv_axfr';


  /// SNOM POST keys. Do not change unless you roll out a custom firmware.
  static const String KEY_ACTION_AXFR         = 'action_attended_transfer';
  static const String KEY_ACTION_BXFR         = 'action_blind_transfer';
  static const String KEY_ACTION_CONN         = 'action_connected_url';
  static const String KEY_ACTION_DISCONN      = 'action_disconnected_url';
  static const String KEY_ACTION_DND_OFF      = 'action_dnd_off_url';
  static const String KEY_ACTION_DND_ON       = 'action_dnd_on_url';
  static const String KEY_ACTION_HOLD         = 'action_hold';
  static const String KEY_ACTION_UNHOLD       = 'action_unhold';
  static const String KEY_ACTION_INCOMING     = 'action_incoming_url';
  static const String KEY_ACTION_LOG_OFF      = 'action_log_off_url';
  static const String KEY_ACTION_LOG_ON       = 'action_log_on_url';
  static const String KEY_ACTION_MISSED       = 'action_missed_url';
  static const String KEY_ACTION_HOOK_OFF     = 'action_offhook_url';
  static const String KEY_ACTION_HOOK_ON      = 'action_onhook_url';
  static const String KEY_ACTION_OUTGOING     = 'action_outgoing_url';
  static const String KEY_ACTION_RECV_AXFR    = 'action_received_attended_transfer';
  static const String KEY_ACTION_CALL_FWD_OFF = 'action_redirection_off_url';
  static const String KEY_ACTION_CALL_FWD_ON  = 'action_redirection_on_url';
  static const String KEY_ACTION_REG_FAILED   = 'action_reg_failed';
  static const String KEY_ACTION_SETUP_DONE   = 'action_setup_url';
  static const String KEY_ACTION_XFR          = 'action_transfer';
}



