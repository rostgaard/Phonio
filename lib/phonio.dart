library phonio;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_route/shelf_route.dart' as route;
import 'package:shelf_exception_response/exception_response.dart';
import 'dart:async';
import 'dart:io' as IO;
import 'dart:convert';
import 'dart:collection';
import 'package:logging/logging.dart';

part 'phonio-call.dart';
part 'phonio-event.dart';
part 'event/event-call_connected.dart';
part 'event/event-call_disconnected.dart';
part 'event/event-call_incoming.dart';
part 'event/event-call_invite.dart';
part 'event/event-call_outgoing.dart';
part 'event/event-dnd.dart';
part 'event/event-hook.dart';
//part 'phonio-pjsua_process.dart'; //The file does not exists in Git yet.
part 'phonio-sip_account.dart';
part 'phonio-sip_phone.dart';
part 'phonio-snom_phone.dart';
part 'phonio-snom_action_gateway.dart';

const String libraryName = 'phonio';

