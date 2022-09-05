import 'dart:io';
import 'package:web_crawl/lingue.dart';

void main() async {

  var laRepublica = 'https://www.repubblica.it/';
  var ilMessagero = 'https://www.ilmessaggero.it/';



  var sites = [
    laRepublica,
    ilMessagero

  ];

  var dir = Directory(Directory.current.path + '/it');
  analyse(dir, sites, withSummary: true, compareBacklogWords: true);
}