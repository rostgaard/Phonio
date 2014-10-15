part of phonio;

class SIPAccount {
  int    ID         = null;
  String username   = null;
  String password   = null;
  String server     = null;
  int    SIPPort    = null;
  bool   autoAnswer = false;

  final SIPPhone phone;

  SIPAccount (this.phone) {
    this.phone._accounts.add(this);
  }

  Map get asMap => {
    'id' : this.ID,
    'username' : this.username,
    'server'   : this.server,
    'autoanswer' : this.autoAnswer
  };

  Map toJson() => this.asMap;

}
