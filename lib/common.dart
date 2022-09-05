import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';

String clean(String word) {
  var punctuation = [
    ',',
    '?',
    '(',
    '.',
    ')',
    '“',
    '„',
    '!',
    ':',
    ';',
    '"',
    '»',
    '«',
    '+',
    '”',
    '¿',
    '¡',
    '’',
    '‘',
    '’',
    "'"
  ];
  while (word.isNotEmpty && punctuation.contains(last(word))) {
    word = word.substring(0, word.length - 1);
  }

  while (word.isNotEmpty && punctuation.contains(first(word))) {
    word = word.substring(1, word.length);
  }

  if (double.tryParse(word) != null) {
    return '';
  }
  if (double.tryParse(word.replaceAll(',', '.')) != null) {
    return '';
  }

  if (double.tryParse(word.replaceAll(':', '.')) != null) {
    return '';
  }

  if (word.startsWith('L’')) {
    word = word.substring(2);
  }

  if (word.startsWith('l’')) {
    word = word.substring(2);
  }

  if (word.startsWith('d’')) {
    word = word.substring(2);
  }

  if (word.startsWith('D’')) {
    word = word.substring(2);
  }

  if (word.startsWith('n’')) {
    word = word.substring(2);
  }

  if (word.startsWith('N’')) {
    word = word.substring(2);
  }

  if (word.startsWith('c’')) {
    word = word.substring(2);
  }

  if (word.startsWith('C’')) {
    word = word.substring(2);
  }

  if (word.startsWith('s’')) {
    word = word.substring(2);
  }

  if (word.startsWith('S’')) {
    word = word.substring(2);
  }

  if (word.startsWith("L'")) {
    word = word.substring(2);
  }

  if (word.startsWith("l'")) {
    word = word.substring(2);
  }

  if (word.startsWith("d'")) {
    word = word.substring(2);
  }

  if (word.startsWith("D'")) {
    word = word.substring(2);
  }

  if (word.startsWith("s'")) {
    word = word.substring(2);
  }

  if (word.startsWith("S'")) {
    word = word.substring(2);
  }

  if (word.startsWith("n'")) {
    word = word.substring(2);
  }

  if (word.startsWith("N'")) {
    word = word.substring(2);
  }

  if (word.startsWith("c'")) {
    word = word.substring(2);
  }

  if (word.startsWith("C'")) {
    word = word.substring(2);
  }

  if (word.length == 1) {
    return '';
  }

  return word;
}

String last(String w) => w.substring(w.length - 1, w.length);

String first(String w) => w.substring(0, 1);

List<String> split(String toSplit) {
  var splitCharacters = [' ', '-'];
  var response = [toSplit];
  for (var char in splitCharacters) {
    var newSplit = <String>[];
    for (var item in response) {
      newSplit.addAll(item.split(char));
    }
    response.clear();
    response.addAll(newSplit);
  }

  return response;
}

List<String> toSentences(String toSplit) {
  var splitCharacters = ['. ', ': ', '? '];
  var response = [toSplit];
  for (var char in splitCharacters) {
    var newSplit = <String>[];
    for (var item in response) {
      for (var split in item.split(char)) {
        newSplit.add(split.trim());
      }
    }
    response.clear();
    response.addAll(newSplit);
  }

  return response;
}

Future<Set<String>> getFromWebsite(String url) async {
  var c = Completer<Set<String>>();

  var content = await http.read(url);
  var doc = parse(content);

  var body = doc.body;

  if (url.contains('lemonde')) {
    var paragraphs = getAllContentByTag(
      body,
      'p',
    );
    var images = getAllContentWithinAttribute(body, 'img', 'alt');
    var response = <String>{};
    response.addAll(paragraphs);
    response.addAll(images);
    return response;
  }

  if (url.contains('figaro') || url.contains('mundo')) {
    var paragraphs = getAllContentByTag(
      body,
      'p',
    );
    var h1 = getAllContentByTag(
      body,
      'h1',
    );
    var h2 = getAllContentByTag(
      body,
      'h2',
    );
    var response = <String>{};
    response.addAll(paragraphs);
    response.addAll(h1);
    response.addAll(h2);
    return response;
  }

  if (url.contains('heise')) {
    var paragraphs = getAllContentByTag(
      body,
      'p',
    );
    var h1 = getAllContentByTag(
      body,
      'h1',
    );

    var response = <String>{};
    response.addAll(paragraphs);
    response.addAll(h1);
    return response;
  }

  if (url.contains('repubblica') || url.contains('messaggero')) {
    var paragraphs = getAllContentByTag(
      body,
      'a',
    );
    var response = <String>{};
    response.addAll(paragraphs);
    return response;
  }

  if (url.contains('graaf')) {
    var paragraphs = getAllContentByTag(
      body,
      'p',
    );
    var headings = getAllContentByTag(
      body,
      'h2',
    );
    var response = <String>{};
    response.addAll(paragraphs);
    response.addAll(headings);
    return response;
  }

  if (url.contains('pais')) {
    var paragraphs = getAllContentByTag(
      body,
      'p',
    );
    var images = getAllContentWithinAttribute(body, 'img', 'alt');
    var links = getAllContentByTag(
      body,
      'a',
    );
    var response = <String>{};
    response.addAll(paragraphs);
    response.addAll(images);
    response.addAll(links);
    return response;
  }

  if (url.contains('larazon')) {
    var paragraphs = getAllContentByTag(
      body,
      'p',
    );
    var images = getAllContentWithinAttribute(body, 'img', 'alt');
    var links = getAllContentWithinAttribute(body, 'a', 'aria-label');
    var response = <String>{};
    response.addAll(paragraphs);
    response.addAll(images);
    response.addAll(links);
    return response;
  }

  if (url.contains('jn.pt')) {
    var paragraphs = getAllContentByTag(
      body,
      'a',
    );
    var spans = getAllContentByTag(
      body,
      'span',
    );
    var response = <String>{};
    response.addAll(paragraphs);
    response.addAll(spans);
    return response;
  }

  var topics = getAllContentByAttribute(body, 'data-qa', 'Teaser.Topic');
  var intros = getAllContentByAttribute(body, 'data-qa', 'Teaser.Intro');
  var headlines = getAllContentByAttribute(body, 'data-qa', 'Teaser.Headline');
  var fazHeader = getAllContentByAttribute(body, 'class', 'tsr-Base_HeadlineText');
  var fazContent = getAllContentByAttribute(body, 'class', 'tsr-Base_Content');
  var frdeHeader = getAllContentByAttribute(body, 'class', 'id-Teaser-el-content-headline-text');
  var frdeContent = getAllContentByAttribute(body, 'class', 'id-Teaser-el-content-text-text');

  var allContent = <String>{};
  allContent.addAll(topics);
  allContent.addAll(intros);
  allContent.addAll(headlines);
  allContent.addAll(fazHeader);
  allContent.addAll(fazContent);
  allContent.addAll(frdeHeader);
  allContent.addAll(frdeContent);

  c.complete(allContent);

  return c.future;
}

List<String> getAllContentByAttribute(Element e, String attribute, String value) {
  var response = <String>[];

  if (e.attributes[attribute] == value && e.children.isEmpty) {
    response.add(e.text.replaceAll(' ', ' ').trim());
    return response;
  }

  for (var child in e.children) {
    var r = getAllContentByAttribute(child, attribute, value);
    response.addAll(r);
  }

  return response;
}

bool isCombination(String word, Set<String> wordParts) {
  word = word.toLowerCase();

  for (var item in wordParts) {
    if (word == item) {
      return true;
    }
    if (word.startsWith(item) && word.length >= item.length + 4) {
      if (isCombination(word.substring(item.length), wordParts)) {
        return true;
      }
    }
  }

  return false;
}

List<String> getAllContentByTag(Element e, String tag) {
  var response = <String>[];

  if (e.outerHtml.startsWith('<' + tag + ' ')) {
    if (e.children.isEmpty) {
      var s = e.text;
      s = s.replaceAll(' ', ' ');
      s = s.replaceAll('​', '');
      s = s.trim();
      response.add(s);
      return response;
    }
  }

  for (var child in e.children) {
    var r = getAllContentByTag(child, tag);
    response.addAll(r);
  }

  return response;
}

List<String> getAllContentWithinAttribute(Element e, String tag, String attribute) {
  var response = <String>[];

  if (e.outerHtml.startsWith('<' + tag + ' ')) {
    var content = e.attributes[attribute];
    if (content != null) {
      response.add(content.replaceAll(' ', ' ').trim());
    }
    return response;
  }

  for (var child in e.children) {
    var r = getAllContentWithinAttribute(child, tag, attribute);
    response.addAll(r);
  }

  return response;
}
