import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:web_crawl/common.dart';

int minSentenceLength = 4;
int minSentencePartLength = minSentenceLength + 6;
int minCharacterLength = 60;

Map<String, String> languages = {
  'de': 'German',
  'es': 'Spanish',
  'it': 'Italian',
  'nl': 'Dutch',
  'pt': 'Portuguese',
  'fr': 'French'
};

void analyse(Directory dir, List<String> sites,
    {bool withSummary = false, bool compareBacklogWords = false}) async {
  var time = DateTime.now().millisecondsSinceEpoch;

  // read the backlog
  var backlog = <String>{};
  var fBacklog = File(dir.path + '/backlog.txt');
  var backlogLines = fBacklog.readAsLinesSync();
  backlog.addAll(backlogLines);

  var reviewed = <String>{};
  var fReviewed = File(dir.path + '/reviewed.txt');
  var reviewedLines = fReviewed.readAsLinesSync();
  reviewed.addAll(reviewedLines);

  var fNewWords = File(dir.path + '/new_words.txt');
  var newWords = <String>{};

  var fTrending = File(dir.path + '/trending.txt');
  var trending = <String>{};

  var reviewedReverse = reviewedLines.reversed;

  var wordPendingValue = <String, double>{};
  var value = 1.0;
  for (var line in reviewedReverse) {
    var words = split(line);
    for (var word in words) {
      word = clean(word);
      if (word.isNotEmpty) {
        wordPendingValue[word] = wordPendingValue[word] ?? value;
      }
    }
    value = value * 0.999;
  }

  var anki = <String>{};
  var fAnki = File(dir.path + '/anki.txt');
  var ankiLines = fAnki.readAsLinesSync();
  anki.addAll(ankiLines);

  var ankiWordParts = <String>{};
  for (var item in anki) {
    if (item.length > 3) {
      ankiWordParts.add(item.toLowerCase());
    }
  }

  // read items just done
  var fDone = File(dir.path + '/done.txt');
  var doneLines = fDone.readAsLinesSync();
  for (var line in doneLines) {
    backlog.remove(line);
    reviewed.add(line);
  }

  var t1 = DateTime.now().millisecondsSinceEpoch;
  //print('All files read in ${t1 - time} milliseconds');

  print ('backlog length before : ${backlog.length}');
  for (var site in sites) {
    var content = await getFromWebsite(site);

    //print ('$site: ${content.length}');
    for (var item in content) {
      var tidyItem = item.replaceAll('  ', ' ');
      if (!reviewed.contains(tidyItem)) {
        backlog.add(tidyItem);
      }
    }
    //backlog.addAll(content);
  }
  print ('backlog length after : ${backlog.length}');
  var t2 = DateTime.now().millisecondsSinceEpoch;
  //print('Web site read and backlog updated in ${t2 - t1} milliseconds');

  var t3 = DateTime.now().millisecondsSinceEpoch;
  //print('Backlog saved in ${t3 - t2} milliseconds');
  //print('Backlog written in ${t3 - t3a} milliseconds');

  // process the backlog to determine the best words to use / add to Anki
  var wordValue = <String, double>{};
  var wordCount = <String, int>{};
  var pending = <String>{};
  var coveredByAnki = 0;
  var combinationOfAnki = 0;
  var combinedWords = <String>{};
  var guessable = <String>{};
  var missingCount = <int, int>{};
  var backlogCount = 0;
  var combinationInPendingCount = 0;
  var oneMissingWordSentence = <int, String>{};
  var oneMissingWordSentences = <int, List<String>>{};
  var i = 1;
  while (i < 9999) {
    oneMissingWordSentence[i] = '';
    oneMissingWordSentences[i] = [];
    i++;
  }
  var z = 0;
  while (z < 25) {
    missingCount[z] = 0;
    z++;
  }

  for (var line in backlog) {
    var words = split(line);
    var missingWordIsCombination = false;
    var missing = 0;
    var sentenceValue = 1.0;
    var lastMissingWord = '';
    for (var word in words) {
      word = clean(word);
      if (word.isNotEmpty) {
        wordCount[word] = wordCount[word] ?? 0;
        wordCount[word] = wordCount[word] + 1;
      }
      if (word.isNotEmpty) {
        if (!anki.contains(word)) {
          lastMissingWord = word;
          missing++;
          if (isCombination(word, ankiWordParts)) {
            combinationOfAnki++;
            missingWordIsCombination = true;
            combinedWords.add(word);
            if (word.length < 8) {
              print(word);
            }
          }
        } else {
          sentenceValue = sentenceValue * (wordPendingValue[word] ?? 0.1);
          coveredByAnki++;
        }
      }
    }

    if (words.length >= minSentenceLength) {
      backlogCount++;
      missingCount[missing] = missingCount[missing] ?? 0;
      missingCount[missing] = missingCount[missing] + 1;
    }

    if (missing == 1 && !missingWordIsCombination) {
      if (oneMissingWordSentence[wordCount[lastMissingWord]].length <=
          line.length) {
        oneMissingWordSentence[wordCount[lastMissingWord]] = line;
      }
      if (line.length > minCharacterLength) {
        oneMissingWordSentences[wordCount[lastMissingWord]].add(line);
      }
    }

    if (missing == 0 ||
        (missing == 1 &&
            missingWordIsCombination &&
            combinationInPendingCount < 4)) {
      // add to pending
      if (!reviewed.contains(line) &&
          words.length >= minSentenceLength &&
          (sentenceValue < 0.08 || reviewed.length < 5000)) {
        pending.add(line);
        for (var word in words) {
          var w = clean(word);
          if (w.isNotEmpty) {
            wordPendingValue[w] = 1.0;
          }
        }
        if (missingWordIsCombination) {
          combinationInPendingCount++;
        }
      }
    } else {
      if (words.length < 9) {
        for (var word in words) {
          word = clean(word);
          if (word.isNotEmpty) {
            if (!anki.contains(word)) {
              wordValue[word] = wordValue[word] ?? 0.00;
              wordValue[word] =
                  wordValue[word] + sqrt(line.length) / (missing * missing);
            }
          }
        }
      } else {
        var sentences = toSentences(line);
        for (var sentence in sentences) {
          missing = 0;
          sentenceValue = 1.0;
          var words = split(sentence);
          if (words.length >= minSentenceLength) {
            for (var word in words) {
              word = clean(word);
              if (!anki.contains(word) && word.isNotEmpty) {
                missing++;
              } else {
                sentenceValue = sentenceValue * (wordPendingValue[word] ?? 1.0);
              }
            }
            if (missing == 0) {
              if (!reviewed.contains(sentence) &&
                  words.length >= minSentencePartLength &&
                  (sentenceValue < 0.03 || reviewed.length < 5000)) {
                for (var word in words) {
                  var w = clean(word);
                  if (w.isNotEmpty) {
                    wordPendingValue[w] = 1.0;
                  }
                }
                pending.add(sentence);
              }
            } else {
              for (var word in words) {
                word = clean(word);
                if (word.isNotEmpty && !anki.contains(word)) {
                  wordValue[word] = wordValue[word] ?? 0.00;
                  wordValue[word] = wordValue[word] +
                      sqrt(sentence.length) / (missing * missing);
                }
              }
            }
          }
        }
      }
    }
  }

  print('\nAnalysing ${languages[dir.path.split("/").last]}\n');

  var totalSentencesWithOneWordMissing = 0;
  for (var m in oneMissingWordSentences.keys) {
    totalSentencesWithOneWordMissing =
        totalSentencesWithOneWordMissing + oneMissingWordSentences[m].length;
  }

  var maxLines = 70000;
  var removeLimit = 0;
  var maxAttemptsBeforeLimitIncrease = 103;
  var failedAttempts = 0;

  var r = Random();
  var kAverage = 0.00;
  var keptWithOneMissingWord = <String>{};


  if (backlog.length > maxLines) {
    pending.add(backlog.first);
    backlog.remove(backlog.first);
    var excessLength = backlog.length - maxLines;

    var i = backlog.length - maxLines;
    var j = 0;
    while ((j < i && backlog.length > maxLines) || (pending.length < 50 && j < 2000)) {
      var minOccurrence = 999;
      var missingCount = 0;
      var numberOfWords = 0;
      var ankiNumber = 0;
      var k = r.nextInt(backlog.length - 1000);
      var line = backlog.elementAt(k);
      var words = split(line);
      for (var word in words) {
        var w = clean(word);
        if (w.isNotEmpty) {
          numberOfWords++;
          if (!anki.contains(w)) {
            minOccurrence = min(minOccurrence, wordCount[w]);
            missingCount++;
          }
          if (anki.contains(w)) {
            ankiNumber++;
          }
        }
      }

      if (minOccurrence <= removeLimit ||
          numberOfWords < 4 ||
          (ankiNumber == numberOfWords && numberOfWords < 6))  {
        if (missingCount != 1 || (numberOfWords < 4 && missingCount > 0)) {
          if (backlog.length > maxLines) {
            kAverage = kAverage + k;
            backlog.remove(line);
          }
        } else {
          pending.add(line);          // add to pending if this is the only missing word in the sentence
        }
        //print('${line.length} : $line');
        failedAttempts = 0;
      } else {
        failedAttempts++;
        if (failedAttempts > maxAttemptsBeforeLimitIncrease) {
          removeLimit++;
          print(
              'Remove limit increased to $removeLimit after $j attempts and ${excessLength + maxLines - backlog.length} lines removed');
          failedAttempts = 0;
        }
        if (missingCount == 1) {
          keptWithOneMissingWord.add(line);
        }
      }

      j++;
    }
    if ((excessLength + maxLines - backlog.length) > 0) {
      kAverage = kAverage / (excessLength + maxLines - backlog.length);
      print(
          '$j attempts needed to remove ${excessLength + maxLines - backlog.length} lines at ${(1000 * j / (excessLength + maxLines - backlog.length)).round()} attempts per thousand. The average position of a removed line is ${kAverage.round()} ');
    }
  }

  // save the updated backlog
  var backlogContent = '';
  var backLogSubContent = '';
  for (var line in backlog) {
    backLogSubContent = backLogSubContent + line.trim() + '\n';
    if (backLogSubContent.length > 4096) {
      backlogContent = backlogContent + backLogSubContent;
      backLogSubContent = '';
    }
  }
  backlogContent = backlogContent + backLogSubContent;
  var t3a = DateTime.now().millisecondsSinceEpoch;

  fBacklog.writeAsStringSync(backlogContent, mode: FileMode.write);

  var t4 = DateTime.now().millisecondsSinceEpoch;
  print('Backlog processed in ${t4 - t3} milliseconds');

  var fWords = File(dir.path + '/backlog_words.csv');
  var wordCountContent = '';
  var wordCountSubContent = '';
  var totalWords = 0;
  var wordsInFirst1000 = 0;
  var wordIndex = 0;
  var wordNumbers = <int, int>{};
  wordNumbers[1] = 0;
  wordNumbers[2] = 0;
  wordNumbers[3] = 0;
  wordNumbers[4] = 0;
  wordNumbers[5] = 0;
  wordNumbers[6] = 0;

  var backlogWords = <String>[];
  backlogWords.addAll(wordCount.keys);
  backlogWords.sort((String a, String b) {
    var aIndex = wordCount[a] * 100 - a.length;
    var bIndex = wordCount[b] * 100 - b.length;
    if (!anki.contains(a)) {
      aIndex = aIndex + 10000000000;
    }
    if (!anki.contains(b)) {
      bIndex = bIndex + 10000000000;
    }

    if (aIndex > bIndex) {
      return -1;
    } else {
      return 1;
    }
  });

  var knownWords = 0;
  var unknownWords = 0;

  backlogWords.forEach((word) {
    var inAnki = ', N';
    if (anki.contains(word)) {
      inAnki = ', Y';
      knownWords++;
    } else {
      unknownWords++;
    }

    var inCombined = ', N';
    if (combinedWords.contains(word)) {
      inCombined = ', Y';
    }

    if (wordCount[word] < 7 && !anki.contains(word)) {
      wordNumbers[wordCount[word]] = wordNumbers[wordCount[word]] + 1;
    }

    wordCountSubContent = wordCountSubContent +
        word +
        ',' +
        wordCount[word].toString() +
        inAnki +
        inCombined +
        '\n';
    totalWords = totalWords + wordCount[word];
    if (wordCountSubContent.length > 8192) {
      wordCountContent = wordCountContent + wordCountSubContent;
      wordCountSubContent = '';
    }
    if (wordIndex < 1000) {
      wordsInFirst1000 = wordsInFirst1000 + wordCount[word];
      wordIndex++;
    }
  });

  wordCountContent = wordCountContent + wordCountSubContent;

  fWords.writeAsStringSync(wordCountContent, mode: FileMode.write);

  var t5 = DateTime.now().millisecondsSinceEpoch;
  //print('WordCount saved in ${t5 - t4} milliseconds');
  print(wordNumbers);
  var k = 0;
  while (missingCount[k] != null) {
    if (missingCount[k] == 0) {
      missingCount.remove(k);
    }
    k++;
  }
  print(missingCount);

  print(
      'There are ${wordCount.length} different words occurring $totalWords times in the backlog.\nThat is ${(10000 * totalWords / wordCount.length).round() / 10000} average occurrences per word');
  print(
      'of these $coveredByAnki are words in the Anki list. That is ${(100000 * coveredByAnki / totalWords).round() / 1000}%');
  print(
      'in addition, there are ${combinedWords.length} words occurring $combinationOfAnki times that are a combination of Anki words. That is ${(10000 * combinationOfAnki / totalWords).round() / 100}%\n');

  var fPending = File(dir.path + '/pending.txt');
  var pendingContent = '';
  for (var item in pending) {
    pendingContent = pendingContent + item + '\n';
  }
  fPending.writeAsStringSync(pendingContent, mode: FileMode.write);

  // now work out the best 400 words to add to Anki
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

  var fAnkiPending = File(dir.path + '/anki_pending.txt');
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
  print(
      'There are $backlogCount sentences with more than ${minSentenceLength - 1} words. That is a average of ${(1000 * totalWords / backlogCount).round() / 1000} words  per line.');

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
	margin-block-end: 0.1em;
	margin-block-start: 0.2em;
  }
  span {
  
	font-family: 'Calibri';
	font-size: 19px;
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

  var fContent = File(dir.path + '/content.html');
  fContent.writeAsStringSync(htmlContentPart1, mode: FileMode.write);

  for (var line in pending) {
    fContent.writeAsStringSync('<span>$line</span><br/>\n', mode: FileMode.append);
  }
  fContent.writeAsStringSync(htmlContentPart2, mode: FileMode.append);

  var reviewedContent = '';
  var reviewedSubContent = '';
  for (var item in reviewed) {
    reviewedSubContent = reviewedSubContent + item + '\n';
    if (reviewedSubContent.length > 4096) {
      reviewedContent = reviewedContent + reviewedSubContent;
      reviewedSubContent = '';
    }
  }
  reviewedContent = reviewedContent + reviewedSubContent;
  fReviewed.writeAsStringSync(reviewedContent, mode: FileMode.write);
  fDone.writeAsStringSync('', mode: FileMode.write);

  var reviewedWordCount = <String, int>{};
  for (var line in reviewed) {
    var words = split(line);
    for (var word in words) {
      word = clean(word);
      if (word.isNotEmpty) {
        reviewedWordCount[word] = reviewedWordCount[word] ?? 0;
        reviewedWordCount[word] = reviewedWordCount[word] + 1;
      }
    }
  }

  var totalReviewedWords = 0;
  reviewedWordCount.forEach((word, value) {
    totalReviewedWords = totalReviewedWords + value;
  });

  if (reviewedWordCount.isNotEmpty) {
    print(
        'There are ${reviewedWordCount.length} different words occurring $totalReviewedWords times in the reviewed list.\nThat is ${(10000 * totalReviewedWords / reviewedWordCount.length).round() / 10000} average occurrences per word\n');
  }

  if (withSummary) {
    var summary = <String>[];
    var fSummary = File(dir.path + '/summary.csv');
    var summaryLines = fSummary.readAsLinesSync();
    summary.addAll(summaryLines);

    var lastLine = summary.last;

    var now = DateTime.now();
    var today = now.day.toString().padLeft(2, '0') +
        '/' +
        now.month.toString().padLeft(2, '0') +
        '/' +
        now.year.toString();

    var lastDate = lastLine.split(',').first;
    final summaryTotalReviewed = int.parse(lastLine.split(',')[2]);
    var summaryReviewedToday = 0;
    if (lastDate == today) {
      summaryReviewedToday = int.parse(lastLine.split(',')[1]);
    } else {
      summary.add(today +
          ',' +
          summaryReviewedToday.toString() +
          ',' +
          summaryTotalReviewed.toString() +
          ', ${wordNumbers[1] ?? 0}');
    }

    summaryReviewedToday =
        summaryReviewedToday + totalReviewedWords - summaryTotalReviewed;
    summary.removeLast();
    summary.add(today +
        ', ' +
        summaryReviewedToday.toString() +
        ', ' +
        totalReviewedWords.toString() +
        ', ${wordNumbers[1] ?? 0}, ${wordNumbers[2] ?? 0}, ${wordNumbers[3] ?? 0}, ${wordNumbers[4] ?? 0}, ${wordNumbers[5] ?? 0}, ${wordNumbers[6] ?? 0}' +
        ', ${missingCount[0] ?? 0}, ${missingCount[1] ?? 0}, $totalWords, $coveredByAnki, ${wordCount.length}, $knownWords');
    var summaryContent = '';
    for (var s in summary) {
      summaryContent = summaryContent + s + '\n';
    }
    fSummary.writeAsStringSync(summaryContent);
  }

  var unknownAnd50 = 0;
  for (var word in wordCount.keys) {
    if (wordCount[word] > 49 && !anki.contains(word)) {
      unknownAnd50++;
    }
  }

  print(
      'There are $unknownAnd50 words that occur at least 50 times that are not in the anki list.');

  // work out the most common word that is not in the Anki list
  var mostPopularMissingWord = '';
  var mostPopularMissingWordCount = 0;
  for (var word in wordCount.keys) {
    if (!anki.contains(word)) {
      if (wordCount[word] > mostPopularMissingWordCount) {
        mostPopularMissingWord = word;
        mostPopularMissingWordCount = wordCount[word];
      }
    }
  }

  print(
      'The most popular missing word is $mostPopularMissingWord which occurs $mostPopularMissingWordCount times. That is once every ${(totalWords / mostPopularMissingWordCount).round()} words\n\n');

  var t9 = DateTime.now().millisecondsSinceEpoch;
  //print('Process completed in ${t9 - t5} milliseconds');

  print(
      'The most common 1000 words in the backlog occur $wordsInFirst1000 times');

  var fWordPendingValues = File(dir.path + '/pendingValues.csv');
  var wordPendingValuesContent = '';
  for (var key in wordPendingValue.keys) {
    wordPendingValuesContent =
        wordPendingValuesContent + '$key, ${wordPendingValue[key]}\n';
  }
  fWordPendingValues.writeAsStringSync(wordPendingValuesContent);

  if (compareBacklogWords) {
    var fBaseBacklogWords = File(dir.path + '/backlog_words_base.csv');
    var baseContent = fBaseBacklogWords.readAsStringSync();
    var baseWordCount = <String, int>{};
    var lines = baseContent.split('\n');
    for (var line in lines) {
      try {
        if (line.isNotEmpty) {
          var record = line.split(',');
          baseWordCount[record.first] = int.tryParse(record[1]);
        }
      } catch (ex) {
        print(line);
      }
    }

    for (var key in wordCount.keys) {
      var diff = wordCount[key] - (baseWordCount[key] ?? 0);
      if (wordCount[key] > 10) {
        if (diff > 2) {
          if (diff > wordCount[key] * 0.1 && !anki.contains(key)) {
            trending.add(key);
            print('$key, ${wordCount[key]}, ${(baseWordCount[key] ?? 0)}');
            baseWordCount[key] = wordCount[key];
          }
        }
      } else {
        if ((diff + wordCount[key]) > 13 && !anki.contains(key)) {
          trending.add(key);
          print('$key, ${wordCount[key]}, ${(baseWordCount[key] ?? 0)}');
          baseWordCount[key] = wordCount[key];
        }
      }
      if (baseWordCount[key] == null) {
        baseWordCount[key] = wordCount[key];
        newWords.add(key);
      }
    }

    baseContent = '';
    var tempBaseContent = '';
    for (var baseWordKey in baseWordCount.keys) {
      tempBaseContent = tempBaseContent +
          baseWordKey +
          ', ' +
          baseWordCount[baseWordKey].toString() +
          '\n';
      if (tempBaseContent.length > 4096) {
        baseContent = baseContent + tempBaseContent;
        tempBaseContent = '';
      }
    }
    baseContent = baseContent + tempBaseContent;
    fBaseBacklogWords.writeAsStringSync(baseContent);

    for (var w in newWords) {
      if (!anki.contains(w) && !w.contains(',')) {
        fNewWords.writeAsStringSync(w + '\n', mode: FileMode.append);
      }
    }

    for (var w in trending) {
      if (!anki.contains(w) && !w.contains(',')) {
        fTrending.writeAsStringSync(w + '\n', mode: FileMode.append);
      }
    }
  }

  /*
  var oneMissing = <String>{};
  var fOneMissing = File(dir.path + '/oneMissing.txt');

  var thousandLines = <int>[];
  var threeOrFewer = <int>[];
  var threeOrFewerCount = 0;
  var oneWordTotal = 0;
  var backlogIndex = 0;
  var oneWordCount = 0;
  for (var line in backlog) {
    var words = split(line);
    if (words.length < 4) {
      threeOrFewerCount++;
    } else {
      for (var word in words) {
        var w = clean(word);
        if (wordCount[w] == 1 && !anki.contains(w)) {
          oneWordCount++;
          oneMissing.add(line);
          break;
        }
      }
    }
    backlogIndex++;
    if (backlogIndex == 1000) {
      thousandLines.add(oneWordCount);
      threeOrFewer.add(threeOrFewerCount);
      oneWordTotal = oneWordTotal + oneWordCount;
      backlogIndex = 0;
      oneWordCount = 0;
      threeOrFewerCount = 0;
    }
  }
  print(threeOrFewer);
  print(thousandLines);
  print('There are $oneWordTotal lines with a word that appears once.');


  var oneMissingContent = '';
  while (keptWithOneMissingWord.isNotEmpty) {
    oneMissingContent = oneMissingContent + keptWithOneMissingWord.first + '\n';
    keptWithOneMissingWord.remove(keptWithOneMissingWord.first);
  }
  fOneMissing.writeAsStringSync(oneMissingContent);

*/

}

class WordOccurrenceCount {
  String word;
  int count;

  WordOccurrenceCount(this.word, this.count);
}
