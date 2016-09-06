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

/// Global configuration values.
///
/// TODO: Move to dedicated file.
abstract class Configuration {
  static int loglevel = 2;
  static bool reuseProcess = true;
}

/// Keys used in communication with the basic_agent process.
abstract class _PJSUACommand {
  static const String _register = 'r';
  static const String _unregister = 'u';
  static const String _hangupCurrent = 'H';
  static const String _hangupSpecific = 'K';
  static const String _hangupAll = 'h';
  static const String _dial = 'd';
  static const String _enableAutoAnswer = 'a';
  static const String _disableAutoAnswer = 'm';
  static const String _answerCall = 'p';
  static const String _pickupCall = 'P';
  static const String _quit = 'q';

  static String _dialString(String extension) =>
      '${_PJSUACommand._dial}sip:$extension';
}

/// Events that may occur within the agent.
abstract class _PJSUAEvent {
  static const String _ready = '!READY';
  //static const String _ringing = '!RINGING';
  static const String _incomingCall = 'CALL_INCOMING';
  static const String _outgoingCall = 'CALL_OUTGOING';
  static const String _callMedia = 'CALL_MEDIA';
}

// /// Valid responses to commands.
// abstract class _PJSUAResponse {
//   static const String _ok = '+OK';
//   static const String _error = '-ERROR';
// }

/// [PJSUAProcess] class. Implements the SIPPhone interface.
class PJSUAProcess extends SIPPhone {
  final Logger _localLog = new Logger('$_libraryName.PJSUAProcess');
  final String binaryPath;
  final int port;
  io.Process _process;
  Completer<Null> _readyCompleter = new Completer<Null>();
  int _exitCode;

  PJSUAProcess(this.binaryPath, this.port);

  /// The PID of the backed process. Returns -1 if the process does not run.
  int get pid => _process != null ? _process.pid : -1;

  /// The unique, yet replcatable id of the object.
  @override
  int get id => contact.hashCode;

  @override
  @deprecated
  int get ID => id;

  /// Storing the currently active calls.
  final Map<int, Call> _calls = <int, Call>{};

  /// The currently active calls of the phone. Active means not hung up.
  @override
  Iterable<Call> get activeCalls => _calls.values;

  /// The string representation will give the process id, prefixed by name
  /// of the class.
  @override
  String toString() => '$runtimeType (pid $pid)';

  /// Serialization function.
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> root = super.toJson();
    Map<String, dynamic> extension = <String, dynamic>{
      'binary_path': binaryPath,
      'pid': pid,
      'ready': ready,
      'connected': connected
    };

    root['process'] = extension;

    return root;
  }

  @override
  String get contact => '${defaultAccount.inContactFormat}:$port';

  @override
  bool get ready => _readyCompleter.isCompleted;

  int _defaultAccountID;

  @override
  SIPAccount get defaultAccount {
    if (_defaultAccountID == null) {
      return _accounts.first;
    }

    return _accounts[_defaultAccountID];
  }

  /// The Job queue is a simple FIFO of Futures that complete in-order.
  Queue<Completer<String>> replyQueue = new Queue<Completer<String>>();

  bool get connected => _process != null;

  @override
  Future<Null> autoAnswer(bool enabled, {SIPAccount account: null}) async {
    // Default to the first account
    int accountID = (account != null ? _accounts.indexOf(account) + 1 : 1);

    _localLog.finest(
        '${enabled ? 'Enabling' : 'Disabling' } autoanswer on account $account');

    await _subscribeAndSend((enabled
        ? _PJSUACommand._enableAutoAnswer + accountID.toString()
        : _PJSUACommand._disableAutoAnswer));
  }

  @override
  Future<Null> initialize() async {
    if (!ready) {
      await connect();
    } else {
      _eventController = new StreamController<Event>.broadcast();
    }
  }

  @override
  Future<Null> teardown() async {
    await hangupAll();
    await _eventController.close();
  }

  @override
  Future<Null> finalize() async {
    if (!_eventController.isClosed) {
      await _eventController.close();
    }

    if (pid != -1) {
      await quitProcess();
    }
  }

  /// Register a a SIP account with the process.
  @override
  Future<Null> register({SIPAccount account: null}) async {
    if (account == null) {
      account = defaultAccount;
    } else {
      _localLog.severe('$this only supports registering the default account.');
    }

    await registerAccount();
  }

  /// Put a call on hold.
  @override
  Future<Null> hold() async {
    throw new UnimplementedError();
  }

  //TODO: Check return value of hangup.
  @override
  Future<Null> hangup() async {
    await hangupCurrentCall();
  }

  @override
  Future<Null> answer() async {
    await _subscribeAndSend(_PJSUACommand._answerCall);
  }

  @override
  Future<Null> answerSpecific(Call call) async {
    await _subscribeAndSend('${_PJSUACommand._pickupCall}${call.id}');
  }

  @override
  Future<Null> hangupSpecific(Call call) async {
    await _subscribeAndSend('${_PJSUACommand._hangupSpecific}${call.id}');
  }

  /// TODO: Check return value of hangupAll.
  @override
  Future<Null> hangupAll() async {
    await hangupAllCalls();
  }

  @override
  Future<Null> release(Call call) async {
    throw new UnimplementedError();
  }

  @override
  Future<Null> transfer(Call destination) async {
    throw new UnimplementedError();
  }

  Future<String> registerAccount() async {
    return _subscribeAndSend(_PJSUACommand._register);
  }

  /// TODO: Return call. Null is an evil and wrong value to return.
  @override
  Future<Call> originate(String extension, {SIPAccount account: null}) {
    if (account == null) {
      account = defaultAccount;
    }

    return this
        ._subscribeAndSend(_PJSUACommand._dialString(extension))
        .then((_) => null);
  }

  @override
  Future<Null> unregister({SIPAccount account: null}) async {
    _localLog.warning('Unregistering default account, as account handling '
        'is not implemented');
    await unregisterAccount();
  }

  Future<String> unregisterAccount() async {
    return _subscribeAndSend(_PJSUACommand._unregister);
  }

  Future<String> hangupCurrentCall() async {
    return _subscribeAndSend(_PJSUACommand._hangupCurrent);
  }

  Future<Null> hangupAllCalls() async {
    await _subscribeAndSend(_PJSUACommand._hangupAll);
  }

  Future<Null> connect() async {
    if (_readyCompleter.isCompleted) {
      return new Future<Null>.value(null);
    }

    if (!connected) {
      _eventController = new StreamController<Event>.broadcast();
      List<String> arguments = <String>[
        defaultAccount.username,
        defaultAccount.password,
        defaultAccount.server,
        port.toString(),
        Configuration.loglevel.toString()
      ];

      replyQueue.map((Completer<String> completer) {
        completer.completeError(new StateError('Process is starting'));
      });
      replyQueue.clear();

      return io.Process.start(binaryPath, arguments).then((io.Process process) {
        _process = process;

        _process.exitCode.then((int exitCode) {
          if (exitCode != 0) {
            _localLog.severe('Process exited with status $exitCode.');
          } else {
            _localLog.finest('Process exited with status $exitCode.');
          }
        });

        this
            ._process
            .stdout
            .transform(ASCII.decoder)
            .transform(new LineSplitter())
            .listen(_processOutput,
                onError: (dynamic error) => _localLog.severe('Error:', error));

        this
            ._process
            .stderr
            .transform(ASCII.decoder)
            .transform(new LineSplitter())
            .listen((String line) {
          _localLog.severe('(pipe, stderr) $line');
        }, onError: (dynamic error) => _localLog.severe('Error:', error));

        return whenReady();
      });
    }

    throw new StateError('Process already started.');
  }

  /// Future returning when the process is ready. Should be used to assert
  /// that the process is ready before sending commands to it.
  Future<Null> whenReady() async {
    if (!ready) {
      await _readyCompleter.future;
    }
  }

  void _processOutput(String line) {
    if (ready) {
      _localLog.finest('(pid $pid) $line');
    }

    if (<String>['{'].any((String char) => line.startsWith(char))) {
      _parseAndDispatch(line);
    }
  }

  void _parseAndDispatch(String line) {
    Map<dynamic, dynamic> map = <dynamic, dynamic>{};
    try {
      map = JSON.decode(line);
    } catch (error) {
      _localLog.severe('Failed to parse line: "$line"');
    }

    if (map.containsKey('event')) {
      if (map['event'] == _PJSUAEvent._ready) {
        _readyCompleter.complete();
      } else if (map['event'] == _PJSUAEvent._outgoingCall) {
        final int callId = map['call']['id'];
        final String callee = map['call']['extension'];

        Call call =
            new Call(callId.toString(), callee, false, defaultAccount.username);
        _calls[callId] = call;

        Event outEvent = new CallOutgoing(call.id, call.callee);

        _addEvent(outEvent);
      } else if (map['event'] == _PJSUAEvent._incomingCall) {
        final int callId = map['call']['id'];
        final String callee = map['call']['extension'];

        Call call =
            new Call(callId.toString(), callee, true, defaultAccount.username);
        _calls[callId] = call;
        Event inEvent = new CallIncoming(call.id, call.callee);

        _addEvent(inEvent);
      } else if (map['event'] == "CALL_TSX_STATE") {
        //Ignore these for now.
      } else if (map['event'] == "CALL_STATE") {
        // Disconnect.
        if (map['call']['state'] == 6) {
          final int callId = map['call']['id'];
          Event disconnectEvent = new CallDisconnected(callId.toString());

          _calls.remove(callId);
          _addEvent(disconnectEvent);
        }
      } else if (map['event'] == _PJSUAEvent._callMedia) {
        //final int callId = map['call']['id'];
        //TODO: Update media state of call.
      } else {
        _localLog.severe('Unknown message: "$line"');
      }
    } else if (map.containsKey('reply')) {
      replyQueue.removeFirst().complete(map['reply']);
    } else {
      _localLog.severe('Unrecognized line: "$line"');
    }
  }

  Future<String> _subscribeAndSend(String command) {
    if (_process == null) {
      return new Future<String>.error(new StateError('Process not started!'));
    }

    Completer<String> ticket = new Completer<String>();
    replyQueue.add(ticket);

    _localLog.finest('(pid $pid) Sending command "$command"');
    _process.stdin.writeln(command);

    return ticket.future;
  }

  Future<int> quitProcess() {
    if (!_eventController.isClosed) {
      _localLog.finest('Closing eventController');
      _eventController.close();
    }

    if (_process == null) {
      _localLog
          .info('Process already terminated, returning last known exit code.');
      return new Future<int>.value(_exitCode);
    }

    Future<int> waitForTermination() {
      return _process.exitCode.then((int exitCode) => _exitCode = exitCode)
          // Kill the reference to the process when it is no longer running.
          .whenComplete(() {
        _process = null;
      });
    }

    Future<int> trySigTerm() {
      _localLog.info('Process $pid not responding '
          'to QUIT command, Sending SIGTERM');
      _process.kill((io.ProcessSignal.SIGTERM));
      return waitForTermination();
    }

    Future<Null> doSigKill() async {
      _localLog.warning('Sending SIGKILL to ${_process.pid} as a last resort');
      _process.kill((io.ProcessSignal.SIGKILL));
      await waitForTermination();
    }

    return this
        ._subscribeAndSend(_PJSUACommand._quit)
        .then((String reply) => waitForTermination())
        .timeout(new Duration(seconds: 5), onTimeout: trySigTerm)
        .timeout(new Duration(seconds: 10), onTimeout: doSigKill);
  }

  Future<Null> waitFor(String line) async => throw new UnimplementedError();
}
