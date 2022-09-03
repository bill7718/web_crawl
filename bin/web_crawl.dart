import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'dart:io';

void main(List<String> arguments) {
  var ethereumUrl = 'https://coinmarketcap.com/currencies/ethereum/';
  var bitcoinUrl = 'https://coinmarketcap.com/currencies/bitcoin/';
  var tslaUrl = 'https://finance.yahoo.com/quote/BDEV.L?p=BDEV.L&.tsrc=fin-srch';

  var file = File('data.csv');

  Timer.periodic(Duration(milliseconds: 19009), (t) {
    var f = http.read(tslaUrl);

    f.then((content) {
      var doc = parse(content);

      var body = doc.body;
      var price = getContentByAttribute(body, 'data-reactid', '32');
      print(price);
      var volume = getContentByAttribute(body, 'data-reactid', '116');
      print(volume);

      volume = volume.replaceAll(',', '');

      file.writeAsString(price + ',' + volume + '\n', mode: FileMode.append);

    });
  });

/*
  Timer.periodic(Duration(seconds: 7), (t) {
    var f = http.read(ethereumUrl);

    f.then((content) {

      var doc = parse(content);

      var body = doc.body;
      analyseContent(body);

    });
  });

  Timer.periodic(Duration(seconds: 11), (t) {
    var f = http.read(bitcoinUrl);

    f.then((content) {

      var doc = parse(content);

      var body = doc.body;
      analyseContent(body);

    });
  });

 */
}

void analyseContent(Element e) {
  var classes = e.classes;
  var price = false;
  var volume = false;
  for (var value in classes) {
    if (value.startsWith('priceValue')) {
      price = true;
    }

    if (value.startsWith('statsValue')) {
      volume = true;
    }
  }

  if (price || volume) {
    print(e.innerHtml);
  }

  for (var child in e.children) {
    analyseContent(child);
  }

  /*if (e.hasContent() && e.children.isEmpty) {
    print(e.innerHtml);
  }*/
}

String getContentByAttribute(Element e, String attribute, String value) {
  if (e.attributes[attribute] == value && e.children.isEmpty) {
    return e.text;
  }

  for (var child in e.children) {
    var r = getContentByAttribute(child, attribute, value);
    if (r.isNotEmpty) {
      return r;
    }
  }

  return '';
}
