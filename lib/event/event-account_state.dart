part of phonio;

class AccountState implements Event {
  final String accountID;
  final bool   signedIn;

  String   get eventName => EventJSONKey.accountState;

  AccountState (this.accountID, this.signedIn);

  @override
  Map toJson() => this.asMap;

  Map get asMap =>
      { EventJSONKey.accountID : this.accountID,
        EventJSONKey.signedIn  : this.signedIn };

  @override
  String toString() => this.toJson().toString();

}
