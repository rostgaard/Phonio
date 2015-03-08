part of phonio;

class SIPAccount {
  String username   = null;
  String password   = null;
  String server     = null;

  SIPAccount (this.username, this.password, this.server, {bool shouldRegister : false});

  Map get asMap => {
    'username' : this.username,
    'password' : '${password.runes.first}*****${password.runes.last}',
    'server'   : this.server,
  };

  Map toJson() => this.asMap;

  @override
  String toString() => this.username;

  String get inContactFormat => '${this.username}@${this.server}';

}
