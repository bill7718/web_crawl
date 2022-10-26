import 'dart:io';
import 'package:web_crawl/lingue.dart';
import 'package:web_crawl/lingue2.dart';

void main() async {

  var laRepublica = 'https://www.repubblica.it/';
  var ilMessagero = 'https://www.ilmessaggero.it/';



  var sites = [
    laRepublica,
    ilMessagero

  ];

  var dir = Directory(Directory.current.path + '/it');
  analyse2(dir, sites, withSummary: true, compareBacklogWords: true);
}