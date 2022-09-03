import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'dart:io';

import 'package:web_crawl/common.dart';

void main(List<String> arguments) {
  var dieWelt = 'https://www.welt.de/';
  var dieWeltWirtschaft = 'https://www.welt.de/wirtschaft/';
  var dieWeltWirtschaftWebwelt = 'https://www.welt.de/wirtschaft/webwelt/';
  var fazAktuell = 'https://www.faz.net/aktuell/';
  var fazAktuellDigital = 'https://www.faz.net/aktuell/wirtschaft/digitec/';

  var sites = [
    dieWelt,
    dieWeltWirtschaft,
    dieWeltWirtschaftWebwelt,
    fazAktuell,
    fazAktuellDigital
  ];

  var date = DateTime.now().toString().split(' ').first;

  // read reviewed
  var reviewed = <String>{};
  var fReviewed = File('reviewed.txt');
  var reviewedLines = fReviewed.readAsLinesSync();
  for (var line in reviewedLines) {
    reviewed.add(line);
  }

  // read backlog
  var backlog = <String>{};
  var fBacklog = File('backlog.txt');
  var backlogLines = fBacklog.readAsLinesSync();
  for (var line in backlogLines) {
    backlog.add(line);
  }

  var knownWords = <String, int>{};
  var fKnownWords = File('known.csv');
  var knownWordsLines = fKnownWords.readAsLinesSync();
  for (var line in knownWordsLines) {
    var word = line.split(',').first.trim();
    var views = int.parse(line.split(',').last.trim());
    knownWords[word] = views;
  }

  // read items just done
  var fDone = File('done.txt');
  var doneLines = fDone.readAsLinesSync();
  for (var line in doneLines) {
    backlog.remove(line);
    reviewed.add(line);
    var words = split(line.trim());
    for (var word in words) {
      word = clean(word);
      if (word.isNotEmpty) {
        knownWords[word] = knownWords[word] ?? 0;
        knownWords[word] = knownWords[word] + 1;
      }
    }
  }

  // check all the words in the Anki set and those to known words if they are not already present
  //read the current anki catalog
  var ankiCurrent = <String>{};
  var fAnki = File('anki.txt');
  var ankiCurrentLines = fAnki.readAsLinesSync();
  ankiCurrent.addAll(ankiCurrentLines);
  for (var line in ankiCurrentLines) {
    knownWords[line] = knownWords[line] ?? 0;
  }

  // now write out known words and reviewed
  fKnownWords.writeAsStringSync('', mode: FileMode.write);
  for (var key in knownWords.keys) {
    fKnownWords.writeAsStringSync('$key,${knownWords[key]}\n',
        mode: FileMode.append);
  }

  fDone.writeAsStringSync('', mode: FileMode.write);
  fReviewed.writeAsStringSync('', mode: FileMode.write);
  for (var item in reviewed) {
    fReviewed.writeAsStringSync('$item\n', mode: FileMode.append);
  }
  print('getting web page');
  var site = sites[Random().nextInt(5)];
  var f = http.read(site);

  f.then((content) {
    print('retrieved web page');
    var doc = parse(content);

    var body = doc.body;
    var topics = getAllContentByAttribute(body, 'data-qa', 'Teaser.Topic');
    var intros = getAllContentByAttribute(body, 'data-qa', 'Teaser.Intro');
    var headlines =
        getAllContentByAttribute(body, 'data-qa', 'Teaser.Headline');
    var fazHeader =
        getAllContentByAttribute(body, 'class', 'tsr-Base_HeadlineText');
    var fazContent =
        getAllContentByAttribute(body, 'class', 'tsr-Base_Content');

    var allContent = <String>{};
    allContent.addAll(topics);
    allContent.addAll(intros);
    allContent.addAll(headlines);
    allContent.addAll(fazHeader);
    allContent.addAll(fazContent);

    print('adding to backlog');
    for (var item in allContent) {
      if (!reviewed.contains(item.trim())) {
        var words = split(item.trim());
        if (words.length > 1) {
          backlog.add(item.trim());
        }
      }
    }
    print('backlog added');

    var backlogContents = '';
    fBacklog.writeAsStringSync('', mode: FileMode.write);
    for (var item in backlog) {
      backlogContents = backlogContents + item + '\n';
//      fBacklog.writeAsStringSync(item + '\n', mode: FileMode.append);
    }
    fBacklog.writeAsStringSync(backlogContents, mode: FileMode.append);
    print('backlog written');
    processBacklog();
    writePending();
  });
}

double evaluateContent(String content, Map<String, int> known) {
  var response = 0.00;
  var words = split(content);
  for (var word in words) {
    word = clean(word);
    if (word.isEmpty) {
      response = response + 1.0;
    } else {
      if (known.keys.contains(word)) {
        response = response + sqrt(word.length);
      } else {
        response = response - 10 * sqrt(word.length);
      }
    }
  }
  return response;
}

List<String> getAllContentByAttribute(
    Element e, String attribute, String value) {
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

void processBacklog() {
  // read known words
  var knownWords = <String, int>{};
  var fKnownWords = File('known.csv');
  var knownWordsLines = fKnownWords.readAsLinesSync();
  for (var line in knownWordsLines) {
    var word = line.split(',').first.trim();
    var views = int.parse(line.split(',').last.trim());
    knownWords[word] = views;
  }

  var backlogWords = <String, int>{};
  var fBacklogWords = File('backlog.csv');
  fBacklogWords.writeAsStringSync('', mode: FileMode.write);

  // read backlog
  var fBacklog = File('backlog.txt');
  var backlogLines = fBacklog.readAsLinesSync();

  //read the reviewed items
  var fReviewed = File('reviewed.txt');
  var reviewed = fReviewed.readAsLinesSync().toSet();

  //empty pending
  var fPending = File('pending.txt');
  fPending.writeAsStringSync('', mode: FileMode.write);

  print('looking for phrases in backlog');
  var missingCounts = <int, Map<int, int>>{};
  var phraseMissingCount = <int, int>{};
  var phraseMissingWordCount = <int, int>{};
  var wordValue = <String, double>{};
  for (var line in backlogLines) {
    var words = split(line);
    var missing = 0;
    for (var word in words) {
      word = clean(word);
      if (!knownWords.containsKey(word) && word.isNotEmpty) {
        missing++;
      }
      if (word.isNotEmpty) {
        backlogWords[word] = backlogWords[word] ?? 0;
        backlogWords[word] = backlogWords[word] + 1;
      }
    }

    if ((missing < 2 || words.length < 3) ||
        (missing < 2 && words.length > 4)) {
      fPending.writeAsStringSync(line + '\n', mode: FileMode.append);
    } else {
      missingCounts[words.length] = missingCounts[words.length] ?? <int, int>{};
      missingCounts[words.length][missing] =
          missingCounts[words.length][missing] ?? 0;
      missingCounts[words.length][missing] =
          missingCounts[words.length][missing] + 1;

      phraseMissingCount[missing] = phraseMissingCount[missing] ?? 0;
      phraseMissingCount[missing] = phraseMissingCount[missing] + 1;
      phraseMissingWordCount[missing] = phraseMissingWordCount[missing] ?? 0;
      phraseMissingWordCount[missing] =
          phraseMissingWordCount[missing] + words.length;

      for (var word in words) {
        word = clean(word);
        if (!knownWords.containsKey(word) && word.isNotEmpty) {
          wordValue[word] = wordValue[word] ?? 0.0;
          wordValue[word] = wordValue[word] + sqrt(line.length) / missing;
        }
      }

      if (words.length > 9) {
        var sentences = toSentences(line);
        for (var sentence in sentences) {
          missing = 0;
          var sentenceWords = split(sentence);
          for (var word in sentenceWords) {
            word = clean(word);
            if (!knownWords.containsKey(word) && word.isNotEmpty) {
              missing++;
            }
          }
          if (missing < 2 && sentenceWords.length > 2) {
            if (!reviewed.contains(sentence)) {
              fPending.writeAsStringSync(sentence + '\n',
                  mode: FileMode.append);
            }
          } else {
            if (sentenceWords.length > 2) {
              missingCounts[sentenceWords.length] =
                  missingCounts[sentenceWords.length] ?? <int, int>{};
              missingCounts[sentenceWords.length][missing] =
                  missingCounts[sentenceWords.length][missing] ?? 0;
              missingCounts[sentenceWords.length][missing] =
                  missingCounts[sentenceWords.length][missing] + 1;

              phraseMissingCount[missing] = phraseMissingCount[missing] ?? 0;
              phraseMissingCount[missing] = phraseMissingCount[missing] + 1;
              phraseMissingWordCount[missing] =
                  phraseMissingWordCount[missing] ?? 0;
              phraseMissingWordCount[missing] =
                  phraseMissingWordCount[missing] + sentenceWords.length;

              for (var word in sentenceWords) {
                word = clean(word);
                if (!knownWords.containsKey(word) && word.isNotEmpty) {
                  wordValue[word] = wordValue[word] ?? 0.0;
                  wordValue[word] =
                      wordValue[word] + sqrt(sentence.length) / missing;
                }
              }
            }
          }
        }
      }
    }
  }
  print('finished looking for phrases in backlog');
  var totalWords = 0;
  var backlogWordsContent = '';
  for (var key in backlogWords.keys) {
    totalWords = totalWords + backlogWords[key];
    backlogWordsContent = backlogWordsContent + '$key,${backlogWords[key]}\n';
    //fBacklogWords.writeAsStringSync('$key,${backlogWords[key]}\n', mode: FileMode.append);
  }
  fBacklogWords.writeAsStringSync(backlogWordsContent, mode: FileMode.append);

  var fMissing = File('missing.csv');
  fMissing.writeAsStringSync('', mode: FileMode.write);
  for (var wordCount in missingCounts.keys) {
    for (var numberMissing in missingCounts[wordCount].keys) {
      fMissing.writeAsStringSync(
          '$wordCount,$numberMissing,${missingCounts[wordCount][numberMissing]}\n',
          mode: FileMode.append);
    }
  }

  //print('Marginal words :  $marginalWords');

  //read the current anki catalog
  var ankiCurrent = <String>{};
  var fAnki = File('anki.txt');
  var ankiCurrentLines = fAnki.readAsLinesSync();
  ankiCurrent.addAll(ankiCurrentLines);

  // build the pending anki list
  var fAnkiPending = File('anki_pending.txt');
  fAnkiPending.writeAsStringSync('', mode: FileMode.write);
  var priority = <int, String>{};
  for (var key in backlogWords.keys) {
    var known = knownWords[key] ?? 0;
    var p = (known + 1) * backlogWords[key];
    if (!ankiCurrent.contains(key)) {
      priority[p] = key;
    }
  }

  for (var key in priority.keys) {
    if (key > (0.15 * sqrt(totalWords))) {
      fAnkiPending.writeAsStringSync('${priority[key]}\n',
          mode: FileMode.append);
    }
  }

  print(
      'There are ${backlogWords.length} different words occurring $totalWords times in the backlog.\nThat is ${(100 * totalWords / backlogWords.length).round()/100} average occurrences per word\n');

  var totalKnownWords = 0;
  for (var key in knownWords.keys) {
    totalKnownWords = totalKnownWords + knownWords[key];
  }

  print(
      'There are ${knownWords.length} different words occurring $totalKnownWords times in known words.\nThat is ${(100 * totalKnownWords / knownWords.length).round() / 100} average occurrences per word\n');
  print('\n');
  var i = 2;
  while (i < 11) {
    var missingPercentage =
        (100 * phraseMissingCount[i] * i / phraseMissingWordCount[i]).round();
    print(
        'There are ${phraseMissingCount[i]} phrases with $i missing words containing a total of ${phraseMissingWordCount[i]} words. $missingPercentage% of the words are missing.');
    i++;
  }

  // identify the most useful additional word an add to anki pending
  var bestWord = '';
  var bestValue = -9999.00;
  for (var word in wordValue.keys) {
    if (wordValue[word] > bestValue) {
      bestWord = word;
      bestValue = wordValue[word];
    }
    if (wordValue[word] > 50) {
      fAnkiPending.writeAsStringSync('$word\n', mode: FileMode.append);
    }
  }
  //fAnkiPending.writeAsStringSync('$bestWord\n', mode: FileMode.append);
  print('Best word is $bestWord with score $bestValue');
}

void writePending() {
  var htmlContentPart1 = '''
<!DOCTYPE html>
<html>
<head>
<title>Phrases</title>
<style>
  p {
  
	font-family: 'Calibri';
	font-size: 24px;
	margin-left: 25px;
  }
</style>
</head>
<body>

<h1>Phrases </h1>\n''';
  var htmlContentPart2 = '''
</body>
</html>
''';
  var fPending = File('pending.txt');
  var pendingLines = fPending.readAsLinesSync();

  var fContent = File('content.html');
  fContent.writeAsStringSync(htmlContentPart1, mode: FileMode.write);

  for (var line in pendingLines) {
    fContent.writeAsStringSync('<p>$line</p>\n', mode: FileMode.append);
  }
  fContent.writeAsStringSync(htmlContentPart2, mode: FileMode.append);
}
