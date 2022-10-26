import 'dart:io';
import 'package:web_crawl/lingue.dart';
import 'package:web_crawl/lingue2.dart';

void main() async {

  var leMonde = 'https://www.lemonde.fr/';
  var leFigaro = 'https://www.lefigaro.fr/';
  var leFigaroTech = 'https://www.lefigaro.fr/secteur/high-tech';
  var leFigaroEcon = 'https://www.lefigaro.fr/economie';
  var leFigaroIntl = 'https://www.lefigaro.fr/international';
  var leFigaroEdu = 'https://www.lefigaro.fr/demain/education';
  var leFigaroVox = 'https://www.lefigaro.fr/vox';
  var leFigaroCulture = 'https://www.lefigaro.fr/culture';
  var leFigaroSoc = 'https://www.lefigaro.fr/actualite-france';

  var sites = [
    leMonde, leFigaro, leFigaroTech, leFigaroEcon, leFigaroIntl, leFigaroEdu, leFigaroVox, leFigaroCulture, leFigaroSoc
  ];

  var dir = Directory(Directory.current.path + '/fr');
  analyse2(dir, sites, withSummary: true, compareBacklogWords: true);

}