part of phonio;

abstract class Configuration {
  static int Loglevel = 2;
}


abstract class PJSUACommand {
  static const String REGISTER            = 'r';
  static const String UNREGISTER          = 'u';
  static const String HANGUP_CURRENT      = 'H';
  static const String HANGUP_ALL          = 'h';
  static const String _DIAL               = 'd';
  static const String ENABLE_AUTO_ANSWER  = 'a';
  static const String DISABLE_AUTO_ANSWER = 'm';
  static const String ANSWER_CALL         = 'p';
  static const String QUIT                = 'q';

  static String dialString (String extension)
    => '${PJSUACommand._DIAL}sip:${extension}';
}

abstract class PJSUAEvent {
  static const String READY          = '!READY';
  static const String DIALING        = '!RINGING';
  static const String INCOMING_CALL  = 'CALL_INCOMING';
  static const String OUTGOING_CALL  = 'CALL_OUTGOING';
}

abstract class PJSUAResponse {
  static const String OK    = '+OK';
  static const String ERROR = '-ERROR';
}



//TODO: Throttle the rate of commands being sent per second, as the SIP process tends to choke on them.
class PJSUAProcess extends SIPPhone {

  static const String classname = '${libraryName}.PJSUAProcess';

    Logger           log         = new Logger(PJSUAProcess.classname);
    final String      binaryPath;
    final int port;
    IO.Process       _process    = null;
    Completer       _readyCompleter = new Completer();
    int             _exitCode = null;

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

    Future initialize() => this.connect();

    Future teardown() => this.quitProcess();

    Future register({SIPAccount account : null}) {
      if (account == null) {
        account = this.defaultAccount;
      }

      log.warning('$this only supports registering the default account.');
      return this.registerAccount();
    }

    Future hold() => new Future.error(new UnimplementedError());

    //TODO: Check return value of hangup.
    Future hangup() => hangupCurrentCall();

    Future answer() => this._subscribeAndSend(PJSUACommand.ANSWER_CALL);

    Future hangupSpecific(Call call) => new Future.error(new UnimplementedError());

    //TODO: Check return value of hangupAll.
    Future hangupAll() => this.hangupAllCalls();

    Future release(Call call) => new Future.error(new UnimplementedError());

    Future transfer(Call destination) => new Future.error(new UnimplementedError());

    Future<String> registerAccount() => this._subscribeAndSend(PJSUACommand.REGISTER);

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
      if (!this.connected) {
        List<String> arguments = [this.defaultAccount.username,
                             this.defaultAccount.password,
                             this.defaultAccount.server,
                             this.port.toString(),
                             Configuration.Loglevel.toString()];


        return IO.Process.start(this.binaryPath , arguments).then((IO.Process process) {
          this._process = process;

          this._process.exitCode.then((int exitCode) {
            if (exitCode != 0) {
              this.log.severe('Process exited with status $exitCode.');
            }
            else {
              this.log.finest('Process exited with status $exitCode.');
            }
          });


          process.stdout.transform(ASCII.decoder)
            .transform(new LineSplitter())
            .listen(this._processOutput);

          process.stderr.transform(ASCII.decoder).transform(new LineSplitter()).listen((String line) {
            this.log.severe('(pipe, stderr) $line');
          });
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
      this.log.finest('(pid ${this._process.pid}) $line');

      if (['{'].any((char) => line.startsWith(char))) {
         this._parseAndDispatch(line);
      }

    }

    void _parseAndDispatch(String line) {
      Map map = {};
      try {
        map = JSON.decode(line);
      } catch (error) {
        this.log.severe('Failed to parse line: "$line"');
      }

      if (map.containsKey('event')) {
        if(map['event'] == PJSUAEvent.READY) {
          this._readyCompleter.complete();

        }

        else if(map['event'] == PJSUAEvent.OUTGOING_CALL) {
          //TODO: Extract callID or similar.

          Event outEvent = new CallOutgoing(map['call']['id'].toString(), map['call']['extension']);

          this._addEvent(outEvent);

        }

        else if(map['event'] == PJSUAEvent.INCOMING_CALL) {
          //TODO: Extract callID or similar.
          Event inEvent = new CallIncoming(map['call']['id'].toString(), map['call']['extension']);

          this._addEvent(inEvent);
        }
        else if(map['event'] == "CALL_TSX_STATE") {
          //Ignore these for now.
        }

        else if(map['event'] == "CALL_STATE") {
            //Ignore these for now.
        }

        else {
          log.severe('Unknown message: "$line"');
        }


      } else if (map.containsKey('reply')) {
        this.replyQueue.removeFirst().complete(map['reply']);
      } else {
        this.log.severe('Unrecognized line: "$line"');
      }

    }

    Future<String> _subscribeAndSend (String command) {
      Completer<String> ticket = new Completer<String>();
      this.replyQueue.add(ticket);

      this.log.finest('(pid ${this._process.pid}) Sending command "$command"');
      this._process.stdin.writeln(command);

      return ticket.future;
    }

    Future<int> quitProcess () {
      if (this._process == null) {
        log.info('Process already terminated, returning last known exit code.');
        return new Future.value(this._exitCode);
      }

      Future<int> waitForTermination () {

        return this._process.exitCode
          .then ((int exitCode) => this._exitCode = exitCode)
          // Kill the reference to the process when it is no longer running.
          .whenComplete(() => this._process = null);
      }

      Future<int> trySigTerm () {
        log.info('Process ${this._process.pid} not responding '
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