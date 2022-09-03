import 'dart:io';
import 'package:web_crawl/lingue.dart';

void main() async {

  var jn = 'https://www.jn.pt/';
  var jneco = 'https://www.jn.pt/economia.html';
  var jnmundo = 'https://www.jn.pt/mundo.html';
  var jninovacao = 'https://www.jn.pt/inovacao.html';
  var jnlocal = 'https://www.jn.pt/local.html';


  var sites = [
    jn, jneco, jnmundo, jninovacao, jnlocal
  ];

  var dir = Directory(Directory.current.path + '/pt');
  await analyse(dir, sites,withSummary: true, compareBacklogWords: true);
}