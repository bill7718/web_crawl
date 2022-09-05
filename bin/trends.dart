
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:web_crawl/common.dart';

void main() async {

  var singularityHub = 'https://singularityhub.com/';

  var c = Completer<Set<String>>();

  var content = await http.read(singularityHub);
  var doc = parse(content);

  var body = doc.body;

  //var titles = getAllContentWithinAttribute(body, 'a' , 'title');

  var titles = <String>{};
  titles.addAll(getAllContentWithinAttribute(body, 'a' , 'title'));

  print(titles);

  var merlinTwitter = await http.read('https://twitter.com/merlinaero');
  var doc1 = parse(merlinTwitter);
  print(doc1.body.innerHtml);

}