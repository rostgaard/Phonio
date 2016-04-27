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

library phonio;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_route/shelf_route.dart' as route;
import 'dart:async';
import 'dart:io' as IO;
import 'dart:convert';
import 'dart:collection';
import 'package:logging/logging.dart';

part 'phonio-call.dart';
part 'phonio-event.dart';

part 'event/event-account_state.dart';
part 'event/event-call_connected.dart';
part 'event/event-call_disconnected.dart';
part 'event/event-call_incoming.dart';
part 'event/event-call_invite.dart';
part 'event/event-call_outgoing.dart';
part 'event/event-dnd.dart';
part 'event/event-hook.dart';
part 'phonio-pjsua_process.dart';
part 'phonio-sip_account.dart';
part 'phonio-sip_phone.dart';
part 'phonio-snom_phone.dart';
part 'phonio-snom_action_gateway.dart';

const String libraryName = 'phonio';
