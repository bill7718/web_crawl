import 'dart:io';
import 'dart:math';

import 'package:web_crawl/common.dart';

void main() {
  build();
  //analyse();
}

void build() async {
  var luther = <String>[];
  var fLuther = File(Directory.current.path + '/luther/luther.txt');
  var lutherLines = fLuther.readAsLinesSync();
  luther.addAll(lutherLines);

  print(luther.length);

  var fOut = File(Directory.current.path + '/luther/main.csv');
  var fVerses = File(Directory.current.path + '/luther/verses.txt');
  var verses = <String>{};
  var out = '';

  // 'Das Alte Testament';

  var i = 1373;
  print(luther[i]);
  var book = '';
  var chapter = 0;
  var verseNumber = 0;
  var verse = '';

  while (i < luther.length && i < 99999999) {
    try {
      if (luther[i] == 'Kapitel 1') {
        var temp = '';
        if (verse.isNotEmpty) {
          temp = 'N, $book, $chapter, $verseNumber, $verse';
        }
        book = luther[i - 1];
        if (book.startsWith('German')) {
          book = luther[i - 2];
        }
        if (book == '558') {
          book = 'Job';
        }
        temp = temp.replaceAll(book, '');
        if (temp.isNotEmpty) {
          out = out + temp + '\n';
          verses.add(verse);
        }
        chapter = int.parse(luther[i].split(' ').last);
        print('$book chapter $chapter');
        verseNumber = 0;
        verse = '';
      } else {
        if (luther[i].startsWith('Kapitel') && luther[i] != 'Kapitel') {
          if (verse.isNotEmpty) {
            out = out + 'N, $book, $chapter, $verseNumber, $verse\n';
            verses.add(verse);
          }
          chapter = int.parse(luther[i].split(' ').last);
          print('$book chapter $chapter');
          verseNumber = 0;
          verse = '';
        } else {
          if (int.tryParse(luther[i]) != null ||
              luther[i] == 'Kapitel' ||
              luther[i] == 'German Bible Anonymous') {
          } else {
            verse = verse + ' ';
            var line = luther[i];
            while (line.isNotEmpty) {
              var nextVerse = (verseNumber + 1).toString();
              var nextVerseStart = line.indexOf(nextVerse);
              if (nextVerseStart == -1) {
                verse = verse + line;
                line = '';
              } else {
                if (nextVerseStart == 0) {
                  if (verseNumber > 0) {
                    out = out + 'N, $book, $chapter, $verseNumber, $verse\n';
                    verses.add(verse);
                    verseNumber++;
                    verse = '';
                    line = line.substring(verseNumber.toString().length);
                  } else {
                    verseNumber = 1;
                    line = line.substring(1);
                  }
                } else {
                  verse = verse + line.substring(0, nextVerseStart);
                  out = out + 'N, $book, $chapter, $verseNumber, $verse\n';
                  verses.add(verse);
                  verseNumber++;
                  line = line.substring(
                      nextVerseStart + verseNumber.toString().length);
                  verse = '';
                }
              }
            }
          }
        }
      }

      i++;
    } catch (ex) {
      print('error on line $i\n ${ex.toString()}');
      rethrow;
    }
  }

  await fOut.writeAsString(out);
  print(verses.length);

  var verseData = '';
  for (var verseItem in verses) {
    verseData = verseData + verseItem + '\n';
  }
  await fVerses.writeAsString(verseData);

}

void analyse() async {
  var lutherIn = <String>[];
  var lutherOut = <String>[];
  var fLuther = File(Directory.current.path + '/luther/analysed.csv');
  var fLutherOut = File(Directory.current.path + '/luther/analysed.csv');
  var fLutherPending = File(Directory.current.path + '/luther/pending.csv');
  var pendingIn = <String>[];
  var newReviewed = <String>{};
  var lutherP = <String>[];
  var lutherLines = fLuther.readAsLinesSync();
  lutherIn.addAll(lutherLines);

  var wordCount = <String, int>{};
  var wordValue = <String, double>{};

  var anki = <String>{};
  var fAnki = File(Directory.current.path + '/de/anki.txt');
  var ankiLines = fAnki.readAsLinesSync();
  anki.addAll(ankiLines);

  var pendingInLines = fLutherPending.readAsLinesSync();
  pendingIn.addAll(pendingInLines);

  for (var item in pendingIn) {
    if (item.startsWith('R')) {
      newReviewed.add(item.substring(1).trim());
    }
  }

  var knownCount = 0;

  var known = 0;
  var unknown = 0;
  var missingCount = <int, int>{};
  while (missingCount.length < 50) {
    missingCount[missingCount.length] = 0;
  }

  var testamentFactor = 3.0;
  var augmentationFactor = 1.0;
  var previousLine = '';
  for (var line in lutherIn) {
    var missing = 0;

    if (line.startsWith('N')) {
      var data = line.split(',');
      if (data[1].trim() == 'Genesis') {
        testamentFactor = 1.0;
      }
      augmentationFactor = testamentFactor;
      if (data[3].trim() == '1') {
        augmentationFactor = augmentationFactor * 2;
        if (data[2].trim() == '1') {
          augmentationFactor = augmentationFactor * 1.5;
        }
      } else {
        var previousLineData = previousLine.split(',');
        if (previousLineData.first.trim() != 'N') {
          augmentationFactor = augmentationFactor * 3;
        }
      }
      var i = 4;
      var verse = '';
      while (i < data.length) {
        verse = verse + ', ' + data[i];
        i++;
      }
      var words = verse.trim().split(' ');
      for (var word in words) {
        var w = clean(word);
        if (w.isNotEmpty) {
          wordCount[w] = wordCount[w] ?? 0;
          wordCount[w] = wordCount[w] + 1;

          if (anki.contains(w)) {
            known++;
          } else {
            unknown++;
            missing++;
          }
        }
      }

      missingCount[missing] = missingCount[missing] ?? 0;
      missingCount[missing] = missingCount[missing] + 1;

      if (missing > 0) {
        for (var word in words) {
          var w = clean(word);
          if (w.isNotEmpty) {
            if (!anki.contains(w)) {
              wordValue[w] = wordValue[w] ?? 0.00;
              wordValue[w] = wordValue[w] +
                  augmentationFactor * sqrt(line.length) / (missing * missing);
            }
          }
        }
        lutherOut.add(line);
      } else {
        lutherOut.add('P' + line.substring(1));
        lutherP.add('P' + line.substring(1));
      }
    } else {
      knownCount++;
      if (line.startsWith('P,')) {
        if (line.contains('Job')) {
          var h = 1;
        }
        if (newReviewed.contains(line.substring(1).trim())) {
          line = 'R' + line.substring(1);
        } else {
          lutherP.add(line);
        }
      }
      lutherOut.add(line);
    }
    previousLine = line;
  }

  var fWords = File(Directory.current.path + '/luther/backlog_words.csv');
  var wordCountContent = '';
  var wordCountSubContent = '';
  var totalWords = 0;
  wordCount.forEach((word, value) {
    wordCountSubContent =
        wordCountSubContent + word + ',' + value.toString() + '\n';
    totalWords = totalWords + value;
    if (wordCountSubContent.length > 4096) {
      wordCountContent = wordCountContent + wordCountSubContent;
      wordCountSubContent = '';
    }
  });

  wordCountContent = wordCountContent + wordCountSubContent;
  fWords.writeAsStringSync(wordCountContent, mode: FileMode.write);

  print(
      'There are ${known + unknown} words in all, of these $known are in the anki list. That is ${(10000 * known / (known + unknown)).round() / 100}%\n');

  var score = 0.0;
  for (var key in missingCount.keys) {
    score = score + (missingCount[key] * (1 / (1 + key)));
  }
  print(
      'Available Index ${score.round()} with ${missingCount[0] + knownCount} verses that have all words known and ${missingCount[1]} with one word missing and ${missingCount[2]} with two words missing.');

  var invertedWordValue = <double, String>{};
  wordValue.forEach((word, value) {
    invertedWordValue[value] = word;
  });

  var values = invertedWordValue.keys.toList();
  values.sort((double a, double b) {
    if (a > b) {
      return -1;
    } else {
      return 1;
    }
  });

  var fAnkiPending = File(Directory.current.path + '/luther/anki_pending.txt');
  var ankiPendingContent = '';
  var ankiPendingOccurrences = 0;
  var totalWordValue = 0.00;
  var index = 0;
  while (index < 4000 && index < values.length) {
    var w = invertedWordValue[values[index]];
    ankiPendingContent = ankiPendingContent + w + '\n';
    if (index < 50) {
      ankiPendingOccurrences =
          ankiPendingOccurrences + wordCount[invertedWordValue[values[index]]];
      totalWordValue = totalWordValue + values[index];
    }

    index++;
  }
  fAnkiPending.writeAsStringSync(ankiPendingContent, mode: FileMode.write);

  print(
      'The top 50 Anki Pending items occur $ankiPendingOccurrences times with a value of ${totalWordValue.round()}');
  print(
      'That is an average of once every ${(50 * totalWords / ankiPendingOccurrences).round()} words.\n');

  var lutherOutContent = '';
  fLutherOut.writeAsStringSync('', mode: FileMode.write);
  for (var line in lutherOut) {
    lutherOutContent = lutherOutContent + line + '\n';
    if (lutherOutContent.length > 4096) {
      fLutherOut.writeAsStringSync(lutherOutContent, mode: FileMode.append);
      lutherOutContent = '';
    }
  }
  if (lutherOutContent.isNotEmpty) {
    fLutherOut.writeAsStringSync(lutherOutContent, mode: FileMode.append);
  }

  var lutherPContent = '';
  fLutherPending.writeAsStringSync('', mode: FileMode.write);
  for (var line in lutherP) {
    lutherPContent = lutherPContent + line + '\n';
  }
  if (lutherPContent.isNotEmpty) {
    fLutherPending.writeAsStringSync(lutherPContent, mode: FileMode.append);
  }

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
  
  .reviewed {
    opacity: 50%;
  }
  
</style>
</head>
<body>

<h1>Luther </h1>\n''';
  var htmlContentPart2 = '''
</body>
</html>
''';

  var fContent = File(Directory.current.path + '/luther/content.html');
  fContent.writeAsStringSync(htmlContentPart1, mode: FileMode.write);

  var currentBook = '';
  var currentChapter = '';
  var displayedBook = '';
  var displayedChapter = '';
  var displayedVerse = 0;
  var currentReviewed = <String>[];
  for (var line in lutherOut) {

    var data = line.split(',');

    if (data[1].trim() != currentBook) {
      currentReviewed.clear();
    } else {
      if (data[2].trim() != currentChapter) {
        currentReviewed.clear();
      }
    }
    currentBook = data[1].trim();
    currentChapter = data[2].trim();

    if (data.first == 'P') {
      if (data[1].trim() != displayedBook) {
        displayedBook = data[1].trim();
        var bookHeading = '<h2>$displayedBook</h2>';
        fContent.writeAsStringSync(bookHeading, mode: FileMode.append);
        displayedChapter = data[2].trim();
        var chapterHeading = '<h3>Chapter $displayedChapter</h3>';
        fContent.writeAsStringSync(chapterHeading, mode: FileMode.append);
      } else {
        if (data[2].trim() != displayedChapter) {
          displayedChapter = data[2].trim();
          var chapterHeading = '<h3>Chapter $displayedChapter</h3>';
          fContent.writeAsStringSync(chapterHeading, mode: FileMode.append);
        }
      }

      for (var reviewed in currentReviewed) {
        var reviewedData = reviewed.split(',');
        var verseNumber = int.parse(reviewedData[3]);
        if (verseNumber != displayedVerse + 1) {
          fContent.writeAsStringSync('<p></p>', mode: FileMode.append);
        }
        var i = 4;
        var verse = '';
        while (i < reviewedData.length) {
          verse = verse + ', ' + reviewedData[i];
          i++;
        }
        verse = verse.substring(2);
        fContent.writeAsStringSync('<p class="reviewed">$verseNumber $verse</p>', mode: FileMode.append);
        displayedVerse = verseNumber;
      }
      currentReviewed.clear();
      var verseNumber = int.parse(data[3]);
      if (verseNumber != displayedVerse + 1) {
        fContent.writeAsStringSync('<p></p>', mode: FileMode.append);
      }
      var i = 4;
      var verse = '';
      while (i < data.length) {
        verse = verse + ', ' + data[i];
        i++;
      }
      verse = verse.substring(2);
      fContent.writeAsStringSync('<p>$verseNumber $verse</p>', mode: FileMode.append);
      displayedVerse = verseNumber;
    }

    if (data.first == 'R') {
      if (data[1].trim() == displayedBook && data[2].trim() == displayedChapter) {
        var verseNumber = int.parse(data[3]);
        if (verseNumber != displayedVerse + 1) {
          fContent.writeAsStringSync('<p></p>', mode: FileMode.append);
        }
        var i = 4;
        var verse = '';
        while (i < data.length) {
          verse = verse + ', ' + data[i];
          i++;
        }
        verse = verse.substring(2);
        fContent.writeAsStringSync('<p class="reviewed">$verseNumber $verse</p>', mode: FileMode.append);
        displayedVerse = verseNumber;
      } else {
        currentReviewed.add(line);
      }
    }
  }



  fContent.writeAsStringSync(htmlContentPart2, mode: FileMode.append);
}
