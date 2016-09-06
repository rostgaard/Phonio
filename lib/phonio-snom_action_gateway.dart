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

class SNOMActionGateway {
  Map<String, SNOMPhone> phones = <String, SNOMPhone>{};

  SNOMActionGateway(this.phones);
  String host;

  io.HttpServer _server;

  Future<io.InternetAddress> get addr =>
      io.NetworkInterface.list().then((List<io.NetworkInterface> nics) {
        nics.first.addresses.first;
      });

  Future<io.HttpServer> start({String hostname: '0.0.0.0', int port: 8000}) {
    final router = route.router()
      ..get(SNOMActionURL.callOutgoing, callOutgoing)
      ..get('${SNOMActionURL.dnd}/{dnd_state}', dnd)
      ..get('${SNOMActionURL.hook}/{hook_state}', hook)
      ..get(SNOMActionURL.incoming, callIncoming)
      ..get(SNOMActionURL.keyActionIncoming, callInvite)
      ..get(SNOMActionURL.conn, callConnected)
      ..get(SNOMActionURL.disconn, callDisconnected)
      ..get(SNOMActionURL.logOn, accountLogon)
      ..get(SNOMActionURL.logOff, accountLogff)
      ..get('/phone/list', list)
      ..get('/phone/{id}', get);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router.handler);

    //route.printRoutes(router);

    return shelf_io.serve(handler, hostname, port).then((io.HttpServer server) {
      host = 'http://${server.address.host}:${server.port}';
      _server = server;
    });
  }

  Map<String, String> get actionUrls => <String, String>{
        SNOMActionURL.keyActionAxfr: '$host${SNOMActionURL.axfr}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionBxfr: '$host${SNOMActionURL.bxfr}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionConn: '$host${SNOMActionURL.conn}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionDisconn: '$host${SNOMActionURL.disconn}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionDndOff: '$host${SNOMActionURL.dndOff}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionDndOn: '$host${SNOMActionURL.dndOn}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionHold: '$host${SNOMActionURL.hold}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionUnHold: '$host${SNOMActionURL.unHold}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionIncoming: '$host${SNOMActionURL.incoming}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}'
            '&${SNOMActionURL.calleeKeyValue}',
        SNOMActionURL.keyActionLogOff: '$host${SNOMActionURL.logOff}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionLogOn: '$host${SNOMActionURL.logOn}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionMissed: '$host${SNOMActionURL.missed}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionHookOff: '$host${SNOMActionURL.hookOff}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionHookOn: '$host${SNOMActionURL.hookOn}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionOutgoing: '$host${SNOMActionURL.callOutgoing}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}'
            '&${SNOMActionURL.calleeKeyValue}',
        SNOMActionURL.keyActionRecvAxfr: '$host${SNOMActionURL.recvAxfr}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionCallFwdOff: '$host${SNOMActionURL.callFwdOff}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
        SNOMActionURL.keyActionCallFwdOn: '$host${SNOMActionURL.callFwdOn}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionRegFailed: '$host${SNOMActionURL.regFailed}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionSetupDone: '$host${SNOMActionURL.setupDone}'
            '?${SNOMActionURL.userKeyValue}',
        SNOMActionURL.keyActionXfr: '$host${SNOMActionURL.xfr}'
            '?${SNOMActionURL.userKeyValue}'
            '&${SNOMActionURL.callIdKeyValue}',
      };

  Future<Null> stop({bool force: false}) async {
    await _server.close(force: force);
  }

  /// Called whenever a phone successfully logs in an account.
  ///
  /// Parameters:
  /// uid : the id of the account that was logged in
  Response accountLogon(Request request) {
    this
        .phones[SNOMparameters.user(request)]
        ._addEvent(new AccountState(SNOMparameters.user(request), true));

    return new Response.ok('');
  }

  /// Called whenever a phone successfully logs out of an account.
  ///
  /// Parameters:
  /// uid : the id of the account that was logged in
  Response accountLogff(Request request) {
    this
        .phones[SNOMparameters.user(request)]
        ._addEvent(new AccountState(SNOMparameters.user(request), false));

    return new Response.ok('');
  }

  Response callOutgoing(Request request) {
    phones[SNOMparameters.user(request)]._addEvent(new CallOutgoing(
        SNOMparameters.callID(request), SNOMparameters.callee(request)));

    return new Response.ok('');
  }

  Response dnd(Request request) {
    bool dnd;
    if (SNOMparameters.dnd(request).toLowerCase() == 'on')
      dnd = true;
    else if (SNOMparameters.dnd(request).toLowerCase() == 'off') dnd = false;

    phones[SNOMparameters.user(request)]._addEvent(new DND(dnd));

    return new Response.ok('');
  }

  Response callInvite(Request request) {
    phones[SNOMparameters.user(request)]._addEvent(new CallInvite(
        SNOMparameters.callID(request), SNOMparameters.callee(request)));

    return new Response.ok('');
  }

  Response callConnected(Request request) {
    this
        .phones[SNOMparameters.user(request)]
        ._addEvent(new CallConnected(SNOMparameters.callID(request)));

    return new Response.ok('');
  }

  Response callDisconnected(Request request) {
    this
        .phones[SNOMparameters.user(request)]
        ._addEvent(new CallDisconnected(SNOMparameters.callID(request)));

    return new Response.ok('');
  }

  Response hook(Request request) {
    bool hook;
    if (SNOMparameters.hook(request).toLowerCase() == 'on')
      hook = true;
    else if (SNOMparameters.hook(request).toLowerCase() == 'off') hook = false;

    phones[SNOMparameters.user(request)]._addEvent(new DND(hook));

    return new Response.ok('');
  }

  Response callIncoming(Request request) {
    phones[SNOMparameters.user(request)]._addEvent(new CallIncoming(
        SNOMparameters.callID(request), SNOMparameters.callee(request)));

    return new Response.ok('');
  }

  Response get(Request request) => new Response.ok(
      JSON.encode(phones[route.getPathParameters(request)['id']]));

  Response list(Request request) => new Response.ok(JSON.encode(phones));
}

abstract class SNOMparameters {
  static String user(Request request) =>
      request.requestedUri.queryParameters[SNOM.paramUid];

  static String callID(Request request) =>
      request.requestedUri.queryParameters[SNOM.paramCallId];

  static String dnd(Request request) =>
      route.getPathParameters(request)['dnd_state'];

  static String hook(Request request) =>
      route.getPathParameters(request)['hook_state'];

  static String callee(Request request) =>
      request.requestedUri.queryParameters[SNOM.paramCallee];

  static String ipv4(Request request) =>
      request.requestedUri.queryParameters[SNOM.paramIPv4];
}

abstract class SNOM {
  static const String paramUid = 'uid';
  static const String paramCallId = 'cid';
  static const String paramDnd = 'dnd';
  static const String paramHook = 'hook';
  static const String paramCallee = 'callee';
  static const String paramIPv4 = 'ipv4';
  static const String keySettings = 'Settings';
  static const String valueApply = 'Apply';

  static const String varActiveUser = r'$active_user';
  static const String varLocalSipUrl = r'$local';
  static const String varRemoteSipUrl = r'$remote';
  static const String varActiveUrl = r'$active_url';
  static const String varActiveHost = r'$active_host';
  static const String varCstaId = r'$csta_id';
  static const String varCallId = r'$call-id';
  static const String varDisplayLocal = r'$display_local';
  static const String varDisplayRemote = r'$display_remote';
  static const String varExpansionModule = r'$expansion_module';
  static const String varActiveFKey = r'$active_key'; // Active line?
  static const String varPhoneIp = r'$phone_ip';
  static const String varNumCalls = r'$nr_ongoing_calls';

  /// Context-Url
  ///
  /// Used in log_on/off-action
  static const String varContextUrl = r'$context_url';

  /// reason-header for cancel/hangup
  static const String varCancelReason = r'$cancel_reason';
}

abstract class SNOMActionURL {
  static const String userKeyValue = '${SNOM.paramUid}=${SNOM.varActiveUser}';
  static const String callIdKeyValue = '${SNOM.paramCallId}=${SNOM.varCallId}';
  static const String calleeKeyValue =
      '${SNOM.paramCallee}=${SNOM.varRemoteSipUrl}';

  static const String callOutgoing = '/outgoing_call';

  /// Attended transfer
  static const String axfr = '/axfr';

  /// Blind transfer
  static const String bxfr = '/bxfr';
  static const String conn = '/conn';
  static const String disconn = '/dconn';
  static const String dnd = '/dnd';
  static const String dndOn = '$dnd/on';
  static const String dndOff = '$dnd/off';
  static const String hold = '/hold';
  static const String unHold = '/unhold';
  static const String incoming = '/call/incoming';
  static const String logOff = '/logoff';
  static const String logOn = '/logon';
  static const String missed = '/missed';
  static const String hook = '/hook';
  static const String hookOn = '$hook/on';
  static const String hookOff = '$hook/off';
  static const String setupDone = '/ready';
  static const String callFwdOff = '/fwdoff';
  static const String callFwdOn = '/fwdon';
  static const String regFailed = '/regfail';
  static const String xfr = '/xfr';
  static const String recvAxfr = '/recv_axfr';

  // SNOM POST keys. Do not change unless you roll out a custom firmware.
  static const String keyActionAxfr = 'action_attended_transfer';
  static const String keyActionBxfr = 'action_blind_transfer';
  static const String keyActionConn = 'action_connected_url';
  static const String keyActionDisconn = 'action_disconnected_url';
  static const String keyActionDndOff = 'action_dnd_off_url';
  static const String keyActionDndOn = 'action_dnd_on_url';
  static const String keyActionHold = 'action_hold';
  static const String keyActionUnHold = 'action_unhold';
  static const String keyActionIncoming = 'action_incoming_url';
  static const String keyActionLogOff = 'action_log_off_url';
  static const String keyActionLogOn = 'action_log_on_url';
  static const String keyActionMissed = 'action_missed_url';
  static const String keyActionHookOff = 'action_offhook_url';
  static const String keyActionHookOn = 'action_onhook_url';
  static const String keyActionOutgoing = 'action_outgoing_url';
  static const String keyActionRecvAxfr = 'action_received_attended_transfer';
  static const String keyActionCallFwdOff = 'action_redirection_off_url';
  static const String keyActionCallFwdOn = 'action_redirection_on_url';
  static const String keyActionRegFailed = 'action_reg_failed';
  static const String keyActionSetupDone = 'action_setup_url';
  static const String keyActionXfr = 'action_transfer';
}
