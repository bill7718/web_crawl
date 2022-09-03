import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';


void main() async {


  var content = await http.read('https://www.reddit.com/');
  print(content);


}