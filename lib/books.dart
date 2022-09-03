import 'dart:io';

import 'dart:typed_data';

import 'package:web_crawl/common.dart';

void zdnet(String language ) async {
  var delimitters = ['.'];
  var overrrides = ['Co.', 'Dr.', '1.', '2.', '3.', '4.', '5.'];

  var book = '';
  try {

    var currentDir = Directory.current.path + '/' + language;

    var fBook = File(currentDir + '/zdnet.txt');
    var bookLines = fBook.readAsLinesSync();

    var fOut = File(currentDir + '/processed.txt');
    var fNew = File(currentDir + '/new_words.txt');
    var fToLearn = File(currentDir + '/to_learn.txt');

    var linesOut = <String>{};

    for (var line in bookLines) {
      line = line.replaceAll('', '');

      if (line.isNotEmpty) {
        if (line.length < 100) {
          linesOut.add(line);
        } else {
          linesOut.addAll(parse(line, delimitters: delimitters, exceptions: overrrides));
        }
      }
    }

    var content = '';
    for (var l in linesOut) {
      content = content + l + '\n';
    }
    await fOut.writeAsString(content);

    // now parse the data to determine which words to learn

    var anki = <String>{};
    var fAnki = File(currentDir + '/anki.txt');
    var ankiLines = fAnki.readAsLinesSync();
    anki.addAll(ankiLines);

    var backlogWords = <String, int>{};
    var fBacklogWords = File(currentDir + '/backlog_words.csv');
    var backlogWordsLines = fBacklogWords.readAsLinesSync();
    for (var line in backlogWordsLines) {
      var l = line.split(',');
      if (l.length > 1) {
        backlogWords[l.first.trim()] = int.tryParse(l[1].trim()) ?? 0;
      }
    }
    var numberOfWords = 0;
    var knownWords = 0;
    var wordCount = <String, int>{};
    for (var line in linesOut) {
      var words = split(line);
      for (var word in words) {
        word = clean(word);
        if (word.isNotEmpty) {
          if (!anki.contains(word)) {
            wordCount[word] = wordCount[word] ?? 0;
            wordCount[word] = wordCount[word] + 1;
            numberOfWords++;
          } else {
            numberOfWords++;
            knownWords++;
          }
        }
      }
    }

    // now calculate an index that indicates how useful the word is to learn
    var wordIndex = <String, int>{};

    for (var w in wordCount.keys) {
      wordIndex[w] = 50 * wordCount[w] + 10 * (backlogWords[w] ?? 0) - w.length;
    }

    var words = <String>[];
    words.addAll(wordIndex.keys);
    words.sort((a, b) {
      if (wordIndex[a] > wordIndex[b]) {
        return -1;
      } else {
        return 1;
      }
    });

    // write our list of all the new words so that we can add the ones in English into anki
    var newWords = '';
    for (var w in words) {
      newWords = newWords + w + '\n';
    }
    await fNew.writeAsString(newWords);



    var toLearn = <String>{};
    for (var line in linesOut) {
      var wordToIgnore = '';
      var words = split(line);
      for (var word in words) {
        word = clean(word);
        if (word.isNotEmpty && !anki.contains(word) && !toLearn.contains(word)) {
          if (wordToIgnore.isEmpty) {
            wordToIgnore = word;
          } else {
            if (wordIndex[word] > wordIndex[wordToIgnore]) {
              toLearn.add(word);
            } else {
              toLearn.add(wordToIgnore);
              wordToIgnore = word;
            }
          }
        }
      }
    }

    var toLearnContent = '';
    for (var item in toLearn) {
      toLearnContent = toLearnContent + item + '\n';
    }

    await fToLearn.writeAsString(toLearnContent);

    print('There are $numberOfWords words in this post of which $knownWords are in anki. That is ${(100000 * knownWords / numberOfWords).round() / 1000}% ');


  } catch (ex) {
    print('error  ${ex.toString()}');
    rethrow;
  }
}

List<String> parse(String paragraph,
    {List<String> delimitters = const ['.', ':'], List<String> exceptions = const []}) {
  var response = <String>[];

  var currentIndex = -1;
  var ends = <int>[];

  for (var delimitter in delimitters) {
    var n = 0;
    var i = 0;
    while (n > -1) {
      n = paragraph.indexOf(delimitter, currentIndex + 1);
      i = n;
      if (n > -1) {
        // sentences always have a space
        if (n < paragraph.length - 2) {
          var t = paragraph.substring(n + 1, n + 2);
          if (t != ' ') {
            n = -1;
          }
        }

        for (var exception in exceptions) {
          if (paragraph.startsWith('1')) {
            var z = 0;
          }
          if (n > exception.length - 2) {
            var s = paragraph.substring(n + 1 - exception.length, n + 1);
            if (s == exception) {
              n = -1;
            }
          }
        }
      }

      if (n > -1) {
        ends.add(n);
        currentIndex = n;
      } else {
        currentIndex = i;
        n = i;
      }
    }
  }

  ends.sort((a, b) {
    if (a > b) {
      return 1;
    } else {
      return -1;
    }
  });

  var start = 0;
  for (var i in ends) {
    var u = paragraph.substring(start, i + 1);
    if (u.isNotEmpty) {
      response.add(u.trim());
    }
    start = i + 1;
  }

  return response;
}
