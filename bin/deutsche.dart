import 'dart:io';
import 'dart:math';
import 'package:web_crawl/books.dart';
import 'package:web_crawl/lingue.dart';
import 'package:web_crawl/lingue2.dart';

void main() async {

  var dieWelt = 'https://www.welt.de/';
  var dieWeltWirtschaft = 'https://www.welt.de/wirtschaft/';
  var dieWeltWirtschaftWebwelt = 'https://www.welt.de/wirtschaft/webwelt/';
  var fazAktuell = 'https://www.faz.net/aktuell/';
  var fazAktuellDigital = 'https://www.faz.net/aktuell/wirtschaft/digitec/';
  var fazAktuellMedezin = 'https://www.faz.net/aktuell/wissen/medizin-ernaehrung/';
  var fazAktuellDebatten = 'https://www.faz.net/aktuell/feuilleton/debatten/';
  var fazAktuellTrends = 'https://www.faz.net/aktuell/stil/trends-nischen/';
  var fazCareer = 'https://www.faz.net/aktuell/karriere-hochschule/buero-co/';
  var fazDigital = 'https://www.faz.net/aktuell/technik-motor/digital/';
  var frDe = 'https://www.fr.de/';
  var heise = 'https://www.heise.de/developer/';

  var sites = [
    dieWelt,
    dieWeltWirtschaft,
    dieWeltWirtschaftWebwelt,
    fazAktuell,
    fazAktuellDigital,
    fazAktuellDebatten,
    fazAktuellTrends,
    fazAktuellMedezin,
    fazCareer,
    fazDigital,
    frDe,
    heise
  ];

  var probability  = 1001;
  var r = Random();
  var get = <String>[];
  for (var site in sites) {
    if (r.nextInt(999) > 999 - probability) {
      get.add(site);
    }
  }

  var dir = Directory(Directory.current.path + '/de');
  analyse2(dir, get, withSummary: true, compareBacklogWords: true);
}
