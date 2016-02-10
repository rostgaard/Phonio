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

/**
 * Global configuration values.
 * TODO: Move to dedicated file.
 */
abstract class Configuration {
  static int Loglevel = 2;
  static bool reuseProcess = true;
}

/**
 * Keys used in communication with the basic_agent process.
 */
abstract class PJSUACommand {
  static const String REGISTER            = 'r';
  static const String UNREGISTER          = 'u';
  static const String HANGUP_CURRENT      = 'H';
  static const String HANGUP_SPECIFIC     = 'K';
  static const String HANGUP_ALL          = 'h';
  static const String _DIAL               = 'd';
  static const String ENABLE_AUTO_ANSWER  = 'a';
  static const String DISABLE_AUTO_ANSWER = 'm';
  static const String ANSWER_CALL         = 'p';
  static const String PICKUP_CALL         = 'P';
  static const String QUIT                = 'q';

  static String dialString (String extension)
    => '${PJSUACommand._DIAL}sip:${extension}';
}

/**
 * Events that may occur within the agent.
 */
abstract class PJSUAEvent {
  static const String READY          = '!READY';
  static const String DIALING        = '!RINGING';
  static const String INCOMING_CALL  = 'CALL_INCOMING';
  static const String OUTGOING_CALL  = 'CALL_OUTGOING';
  static const String CALL_MEDIA     = 'CALL_MEDIA';
}

/**
 * Valid responses to commands.
 */
abstract class PJSUAResponse {
  static const String OK    = '+OK';
  static const String ERROR = '-ERROR';
}

/**
 * [PJSUAProcess] class. Implements the SIPPhone interface.
 */
class PJSUAProcess extends SIPPhone {

  static const String classname = '${libraryName}.PJSUAProcess';

  static final Logger log         = new Logger(PJSUAProcess.classname);
    final String      binaryPath;
    final int port;
    IO.Process       _process    = null;
    Completer       _readyCompleter = new Completer();
    int             _exitCode = null;

    /// The PID of the backed process. Returns -1 if the process does not run.
    int get pid => this._process != null ? this._process.pid : -1;

    /// The unique, yet replcatable id of the object.
    int get ID => this.contact.hashCode;

    /// Storing the currently active calls.
    Map<int,Call> _calls = {};

    /// The currently active calls of the phone. Active means not hung up.
    Iterable<Call> get activeCalls => _calls.values;

    /**
     * The string represenation will give the process id, prefixed by name
     * of the class.
     */
    @override
    String toString() => '${this.runtimeType} (pid ${this.pid})';

    @override
    Map toJson() {
      Map root = super.toJson();
      Map extension = {
        'binary_path' : binaryPath,
        'pid' : pid,
        'ready' : ready,
        'connected' : connected
      };

      root['process'] = extension;

      return root;
    }

    String get contact => '${this.defaultAccount.inContactFormat}:${this.port}';

    bool get ready => this._readyCompleter.isCompleted;

    int _defaultAccountID = null;
    SIPAccount get defaultAccount {
      if (this._defaultAccountID == null) {
        return this._accounts.first;
      }

      return this._accounts[this._defaultAccountID];
    }

    /// The Job queue is a simple FIFO of Futures that complete in-order.
    Queue<Completer<String>> replyQueue   = new Queue<Completer<String>>();

    bool           get connected   => this._process != null;

    PJSUAProcess (this.binaryPath, this.port);

    Future autoAnswer(bool enabled, {SIPAccount account : null}) {
      // Default to the first account
      int accountID = (account != null ? this._accounts.indexOf(account)+1 : 1);

      log.finest('${enabled ? 'Enabling' : 'Disabling' } autoanswer on account $account');

      return this._subscribeAndSend((enabled ? PJSUACommand.ENABLE_AUTO_ANSWER+accountID.toString()
                                             : PJSUACommand.DISABLE_AUTO_ANSWER));
    }

    Future initialize() =>
        !ready
        ? connect()
        : new Future.value
        (_eventController = new StreamController.broadcast());

    Future teardown() => this.hangupAll()
        .then((_) => _eventController.close());

    Future finalize() =>
        !_eventController.isClosed
        ? _eventController.close()
          .then((_) =>
              pid != -1
              ? quitProcess()
              : null)
        : pid != -1
          ? quitProcess()
          : null;

    /**
     * Register a a SIP account with the process.
     */
    Future register({SIPAccount account : null}) {
      if (account == null) {
        account = this.defaultAccount;
      }
      else {
        log.severe('$this only supports registering the default account.');
      }

      return this.registerAccount();
    }

    /**
     * Put a call on hold.
     */
    Future hold() => new Future.error(new UnimplementedError());

    //TODO: Check return value of hangup.
    Future hangup() => hangupCurrentCall();

    Future answer() => this._subscribeAndSend(PJSUACommand.ANSWER_CALL);

    Future answerSpecific(Call call) =>
        this._subscribeAndSend('${PJSUACommand.PICKUP_CALL}${call.ID}');

    Future hangupSpecific(Call call) =>
        this._subscribeAndSend('${PJSUACommand.HANGUP_SPECIFIC}${call.ID}');

    //TODO: Check return value of hangupAll.
    Future hangupAll() => this.hangupAllCalls();

    Future release(Call call) => new Future.error(new UnimplementedError());

    Future transfer(Call destination) => new Future.error(new UnimplementedError());

    Future<String> registerAccount() => this._subscribeAndSend(PJSUACommand.REGISTER);

    /**
     * TODO: Return call. Null is an evil and wrong value to return.
     */
    Future<Call> originate (String extension, {SIPAccount account : null}) {
      if (account == null) {
        account = this.defaultAccount;
      }

      return this._subscribeAndSend
          (PJSUACommand.dialString(extension))
              .then ((_) => null);
    }

    Future unregister({SIPAccount account : null}) {
      log.warning('Unregistering default account, as account handling '
                  'is not implemented');
      return this.unregisterAccount();
    }

    Future<String> unregisterAccount() => this._subscribeAndSend(PJSUACommand.UNREGISTER);

    Future<String> hangupCurrentCall() => this._subscribeAndSend(PJSUACommand.HANGUP_CURRENT);
    Future<String> hangupAllCalls() => this._subscribeAndSend(PJSUACommand.HANGUP_ALL);

    Future connect () {
      if (this._readyCompleter.isCompleted) {
        return new Future.value(null);
      }

      if (!this.connected) {
        this._eventController = new StreamController.broadcast();
        List<String> arguments = [this.defaultAccount.username,
                             this.defaultAccount.password,
                             this.defaultAccount.server,
                             this.port.toString(),
                             Configuration.Loglevel.toString()];

        this.replyQueue.map((Completer<String> completer) {
          completer.completeError(new StateError('Process is starting'));
        });
        this.replyQueue.clear();

        return IO.Process.start(this.binaryPath , arguments).then((IO.Process process) {
          this._process = process;

          this._process.exitCode.then((int exitCode) {
            if (exitCode != 0) {
              log.severe('Process exited with status $exitCode.');
            }
            else {
              log.finest('Process exited with status $exitCode.');
            }
          });

          this._process.stdout
            .transform(ASCII.decoder)
            .transform(new LineSplitter())
            .listen(this._processOutput, onError : (error) => log.severe ('Error:', error));


          this._process.stderr
            .transform(ASCII.decoder)
            .transform(new LineSplitter()).listen((String line) {
            log.severe('(pipe, stderr) $line');
          }, onError : (error) => log.severe ('Error:', error));

          return this.whenReady();
         });
      }

      return new Future.error(new StateError('Process already started.'));
    }

    /**
     * Future returning when the process is ready. Should be used to assert that
     * the process is ready before sending commands to it.
     */
    Future whenReady () {
      if (this.ready) {
        return new Future.value(null);
      }
      else {
        return this._readyCompleter.future;
      }
    }

    void _processOutput (String line) {
      if (this.ready) {
        log.finest('(pid ${this.pid}) $line');
      }

      if (['{'].any((char) => line.startsWith(char))) {
         this._parseAndDispatch(line);
      }

    }

    void _parseAndDispatch(String line) {
      Map map = {};
      try {
        map = JSON.decode(line);
      } catch (error) {
        log.severe('Failed to parse line: "$line"');
      }

      if (map.containsKey('event')) {
        if(map['event'] == PJSUAEvent.READY) {
          this._readyCompleter.complete();

        }

        else if(map['event'] == PJSUAEvent.OUTGOING_CALL) {
          final int callId = map['call']['id'];
          final String callee = map['call']['extension'];

          Call call = new Call(callId.toString(), callee, false, defaultAccount.username);
          _calls[callId] = call;

          Event outEvent = new CallOutgoing(call.ID, call.callee);

          this._addEvent(outEvent);

        }

        else if(map['event'] == PJSUAEvent.INCOMING_CALL) {
          final int callId = map['call']['id'];
          final String callee = map['call']['extension'];

          Call call = new Call(callId.toString(), callee, true, defaultAccount.username);
          _calls[callId] = call;
          Event inEvent = new CallIncoming(call.ID, call.callee);

          this._addEvent(inEvent);
        }
        else if(map['event'] == "CALL_TSX_STATE") {
          //Ignore these for now.
        }

        else if(map['event'] == "CALL_STATE") {
           // Disconnect.
           if (map['call']['state'] == 6) {
             final int callId = map['call']['id'];
             Event disconnectEvent =
                 new CallDisconnected(callId.toString());

             _calls.remove(callId);
             this._addEvent(disconnectEvent);
           }
        }
        else if(map['event'] == PJSUAEvent.CALL_MEDIA) {
          //final int callId = map['call']['id'];
          //TODO: Update media state of call.
        }
        else {
          log.severe('Unknown message: "$line"');
        }


      } else if (map.containsKey('reply')) {
        this.replyQueue.removeFirst().complete(map['reply']);
      } else {
        log.severe('Unrecognized line: "$line"');
      }

    }

    Future<String> _subscribeAndSend (String command) {
      if (this._process == null) {
        return new Future.error(new StateError('Process not started!'));
      }

      Completer<String> ticket = new Completer<String>();
      this.replyQueue.add(ticket);

      log.finest('(pid ${this.pid}) Sending command "$command"');
      this._process.stdin.writeln(command);

      return ticket.future;
    }

    Future<int> quitProcess () {
      if (!this._eventController.isClosed) {
        log.finest('Closing eventController');
        this._eventController.close();
       }

      if (this._process == null) {
        log.info('Process already terminated, returning last known exit code.');
        return new Future.value(this._exitCode);
      }

      Future<int> waitForTermination () {

        return this._process.exitCode
          .then ((int exitCode) => this._exitCode = exitCode)
          // Kill the reference to the process when it is no longer running.
          .whenComplete(() {
            this._process = null;
          });
      }

      Future<int> trySigTerm () {
        log.info('Process ${this.pid} not responding '
                 'to QUIT command, Sending SIGTERM');
        this._process.kill((IO.ProcessSignal.SIGTERM));
        return waitForTermination();
      }

      Future doSigKill () {
        log.warning('Sending SIGKILL to ${this._process.pid} as a last resort');
        this._process.kill((IO.ProcessSignal.SIGKILL));
        return waitForTermination();
      }

      return this._subscribeAndSend(PJSUACommand.QUIT)
        .then((String reply) => waitForTermination())
        .timeout(new Duration (seconds : 5), onTimeout: trySigTerm)
        .timeout(new Duration (seconds : 10), onTimeout: doSigKill);

    }

    Future waitFor (String line, {int timeoutSeconds : 10}) =>
        new Future (() => throw new StateError('Not implemented!'));
 }