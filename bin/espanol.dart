import 'dart:io';
import 'package:web_crawl/lingue.dart';

void main() async {

  var elPais = 'https://elpais.com/espana/';
  var elPaisTech = 'https://elpais.com/tecnologia/';
  var elMundo = 'https://www.elmundo.es/';
  var elMundoTech = 'https://www.elmundo.es/economia/innovadores.html';
  var laRazon = 'https://www.larazon.es/';
  var laRazonLife = 'https://www.larazon.es/lifestyle/';
  var laRazonEcon = 'https://www.larazon.es/economia/';
  var laRazonTech = 'https://www.larazon.es/tecnologia/';


  var sites = <String>[
    elPais,
    elPaisTech,
    elMundo, elMundoTech,
    laRazon, laRazonLife, laRazonEcon, laRazonTech
  ];

  var dir = Directory(Directory.current.path + '/es');
  analyse(dir, sites, withSummary: true, compareBacklogWords: true);
}