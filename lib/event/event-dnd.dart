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

class DND implements Event{
  final bool isOn;

  String   get eventName => EventJSONKey.DND;

  DND (this.isOn);

  @override
  Map toJson() => this.asMap;

  Map get asMap =>
      {
        EventJSONKey.DND    : this.isOn
      };

  @override
  String toString() => this.toJson().toString();

}
