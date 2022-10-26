import 'dart:io';
import 'package:web_crawl/lingue.dart';
import 'package:web_crawl/lingue2.dart';

void main() async {

  var telegraaf = 'https://www.telegraaf.nl/';
  var telegraafFinancieel = 'https://www.telegraaf.nl/financieel';
  var telegraafLifeStyle = 'https://www.telegraaf.nl/lifestyle';

  var sites = [
    telegraaf,
    telegraafFinancieel,
    telegraafLifeStyle

  ];

  var dir = Directory(Directory.current.path + '/nl');
  analyse2(dir, sites, withSummary: true, compareBacklogWords: true);
}