

import 'dart:io';
import 'dart:math';

import 'common.dart';

void main() {

  var dir = Directory(Directory.current.path + '/de');
  // read the backlog
  var backlog = <String>{};
  var fBacklog = File(dir.path + '/backlog.txt');
  var backlogLines = fBacklog.readAsLinesSync();
  backlog.addAll(backlogLines);

  print (backlog.length);

  var result = <int, Map<int,int>>{};
  var i = 1;
  while (i < 99) {
    result[i] = <int,int>{};
    i++;
  }

  var anki = <String>{};
  var fAnki = File(dir.path + '/anki.txt');
  var ankiLines = fAnki.readAsLinesSync();
  anki.addAll(ankiLines);

  var wordCount = <String, int>{};

  for (var line in backlog) {
    var words = split(line);
    for (var word in words) {
      word = clean(word);
      if (word.isNotEmpty && !anki.contains(word)) {
        wordCount[word] = wordCount[word] ?? 0;
        wordCount[word] = wordCount[word] + 1;
      }
    }
  }

  for (var line in backlog) {
    var words = split(line);
    var missingCount = 0;
    var minOccurrence = 99;
    for (var word in words) {
      word = clean(word);
      if (word.isNotEmpty && !anki.contains(word)) {
        minOccurrence = min(minOccurrence, wordCount[word]);
        missingCount++;
      }
    }
    if (missingCount > 0) {
      result[minOccurrence][missingCount] = result[minOccurrence][missingCount] ?? 0;
      result[minOccurrence][missingCount] = result[minOccurrence][missingCount] + 1;
    }

  }

  print (wordCount.length);
  var oneWordCount = 0;
  for (var key in wordCount.keys) {
    if (wordCount[key] == 1) {
      oneWordCount++;
    }
  }
  print (oneWordCount);

  for (var key in result.keys) {
    var numberOfSentences = 0;
    for (var missing in result[key].keys) {
      //print('$key : $missing : ${result[key][missing]}');
      numberOfSentences = numberOfSentences + result[key][missing];
    }
    print('$key : $numberOfSentences ');
  }


}