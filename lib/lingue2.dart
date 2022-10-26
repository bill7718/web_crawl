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

void analyse2(Directory dir, List<String> sites, {bool withSummary = false, bool compareBacklogWords = false}) async {
  var time = DateTime.now().millisecondsSinceEpoch;

  var random = Random();
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

  var fDeleted = File(dir.path + '/deleted.txt');
  var deleted = <String>{};

  var anki = <String>{};
  var fAnki = File(dir.path + '/anki.txt');
  var ankiLines = fAnki.readAsLinesSync();
  anki.addAll(ankiLines);

  // read items just done
  var fDone = File(dir.path + '/done.txt');
  var doneLines = fDone.readAsLinesSync();
  for (var line in doneLines) {
    backlog.remove(line);
    reviewed.add(line);
  }

  var t1 = DateTime.now().millisecondsSinceEpoch;
  //print('All files read in ${t1 - time} milliseconds');

  print('backlog length before : ${backlog.length}');
  for (var site in sites) {
    var content = await getFromWebsite(site);

    //print ('$site: ${content.length}');
    for (var item in content) {
      var tidyItem = item.replaceAll('  ', ' ');
      if (!reviewed.contains(tidyItem)) {
        backlog.add(tidyItem);
      }
    }
  }
  print('backlog length after : ${backlog.length}');

  var t2 = DateTime.now().millisecondsSinceEpoch;
  //print('Web site read and backlog updated in ${t2 - t1} milliseconds');

  var t3 = DateTime.now().millisecondsSinceEpoch;
  //print('Backlog saved in ${t3 - t2} milliseconds');
  //print('Backlog written in ${t3 - t3a} milliseconds');

  // split the backlog into 3 sets
  // - a set where all the words are known
  // - one where there is one word missing
  // - one where there is more than one word missing

  var wordCount = <String, int>{};
  var backLogAllKnown = <String>{};
  var backlogOneMissing = <String>{};
  var backlogManyMissing = <String>{};
  var backlogTooRecent = <String>{};

  var pending = <String>{};

  var backlogIndex = 0;
  var maxBacklogIndex = backlog.length - 2000;
  for (var line in backlog) {
    backlogIndex++;
    var words = split(line);
    var missingCount = 0;
    for (var w in words) {
      var word = clean(w);
      if (word.isNotEmpty) {
        if (!anki.contains(word)) {
          missingCount++;
        }
        wordCount[word] == null ? wordCount[word] = 1 : wordCount[word] = wordCount[word] + 1;
      }
    }
    switch (missingCount) {
      case 0:
        backLogAllKnown.add(line);
        break;

      case 1:
        backlogOneMissing.add(line);
        break;

      default:
        if (backlogIndex > maxBacklogIndex) {
          backlogTooRecent.add(line);
        } else {
          backlogManyMissing.add(line);
        }
    }
  }

  pending.addAll(backLogAllKnown);

  // if there are fewer than 50 lines in pending make up the numbers with phrases that have one word missing
  var minOccurrence = 1;
  var attempts = 0;
  var maxAttempts = 103;
  var minWordCount = 999;
  while (pending.length < 50 && minOccurrence < 99 && backlogOneMissing.isNotEmpty) {
    var line = backlogOneMissing.elementAt(random.nextInt(backlogOneMissing.length));
    minWordCount = 999;
    for (var w in split(line)) {
      var word = clean(w);
      if (word.isNotEmpty && !anki.contains(word)) {
        minWordCount = min(wordCount[word], minWordCount);
      }
    }
    if (minWordCount <= minOccurrence) {
      pending.add(line);
      backlogOneMissing.remove(line);
      attempts = 0;
    } else {
      attempts++;
      if (attempts > maxAttempts) {
        minOccurrence++;
        attempts = 0;
      }
    }
  }
  print('We are up to $minOccurrence for sentences with one word missing');

  // if this does not reduce the backlog length enough then just remove lines where there are too many words missing until we get the right length
  minOccurrence = 1;
  attempts = 0;

  while (backlog.length > (70000 + pending.length)) {
    var line = backlogManyMissing.elementAt(random.nextInt(backlogManyMissing.length));
    minWordCount = 999;
    for (var w in split(line)) {
      var word = clean(w);
      if (word.isNotEmpty) {
        minWordCount = min(wordCount[word], minWordCount);
      }
    }
    if (minWordCount <= minOccurrence) {
      deleted.add(line);
      backlog.remove(line);
      backlogManyMissing.remove(line);
      attempts = 0;
    } else {
      attempts++;
      if (attempts > maxAttempts) {
        minOccurrence++;
        attempts = 0;
      }
    }
  }

  // rebuild the word count from the backlog
  wordCount.clear();
  backLogAllKnown.clear();
  backlogOneMissing.clear();
  backlogManyMissing.clear();
  backlogTooRecent.clear();

  backlogIndex = 0;
  maxBacklogIndex = backlog.length - 2000;
  var totalWordCount = 0;
  var totalInAnkiCount = 0;
  for (var line in backlog) {
    backlogIndex++;
    var words = split(line);
    var missingCount = 0;
    for (var w in words) {
      var word = clean(w);
      if (word.isNotEmpty) {
        totalWordCount++;
        if (!anki.contains(word)) {
          missingCount++;
        } else {
          totalInAnkiCount++;
        }
        wordCount[word] == null ? wordCount[word] = 1 : wordCount[word] = wordCount[word] + 1;
      }
    }
    switch (missingCount) {
      case 0:
        backLogAllKnown.add(line);

        break;
      case 1:
        backlogOneMissing.add(line);

        break;
      default:
        if (backlogIndex > maxBacklogIndex) {
          backlogTooRecent.add(line);
        } else {
          backlogManyMissing.add(line);
        }
    }
  }

  // read in the backlog base to determine if there are any new words or there are any trending words
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

  // also make a count of the number of words by occurrence (up to 6)

  var wordNumberCount = <int, int>{};
  wordNumberCount[1] = 0;
  wordNumberCount[2] = 0;
  wordNumberCount[3] = 0;
  wordNumberCount[4] = 0;
  wordNumberCount[5] = 0;
  wordNumberCount[6] = 0;

  var inAnki = 0;
  var mostPopularWord = '';

  for (var word in wordCount.keys) {
    if (baseWordCount[word] == null) {
      if (!anki.contains(word)) {
        baseWordCount[word] = 1;
        newWords.add(word);
      }
    } else {
      var delta = wordCount[word] - baseWordCount[word];
      if (delta >= 3 && wordCount[word] >= 8 && baseWordCount[word] * 1.1 < wordCount[word] && !anki.contains(word)) {
        trending.add(word);
        baseWordCount[word] = wordCount[word];
      }
    }
    if (wordCount[word] < 7 && !anki.contains(word)) {
      wordNumberCount[wordCount[word]] = wordNumberCount[wordCount[word]] + 1;
    }
    if (anki.contains(word)) {
      inAnki++;
    } else {
      if (mostPopularWord.isEmpty) {
        mostPopularWord = word;
      }
      if (wordCount[mostPopularWord] < wordCount[word]) {
        mostPopularWord = word;
      }
    }
  }

  for (var tw in trending) {
    print('$tw : ${wordCount[tw]}');
  }

  var totalReviewedWords = 0;
  // work out how many words we have reviewed
  for (var line in reviewed) {
    var words = split(line);
    for (var w in words) {
      var word = clean(w);
      if (word.isNotEmpty) {
        totalReviewedWords++;
      }
    }
  }

  // apply the summary
  var summary = <String>[];
  var fSummary = File(dir.path + '/summary.csv');
  var summaryLines = fSummary.readAsLinesSync();
  summary.addAll(summaryLines);

  var lastLine = summary.last;

  var now = DateTime.now();
  var today = now.day.toString().padLeft(2, '0') + '/' + now.month.toString().padLeft(2, '0') + '/' + now.year.toString();
  var lastDate = lastLine.split(',').first;
  if (lastDate == today) {
    summary.removeLast();
  }
  final previousDayTotalReviewed = int.parse(summary.last.split(',')[2]);
  final reviewedToday = totalReviewedWords - previousDayTotalReviewed;
  final todaysSummary = '$today, ${reviewedToday.toString().padLeft(4, '0')}, $totalReviewedWords, ${wordNumberCount[1]}, '
      '${wordNumberCount[2]}, ${wordNumberCount[3]}, ${wordNumberCount[4]}, ${wordNumberCount[5]}, ${wordNumberCount[6]}, '
      '${backLogAllKnown.length.toString().padLeft(3, '0')}, ${backlogOneMissing.length}, $totalWordCount, $totalInAnkiCount, ${wordCount.length}, $inAnki';

  print(todaysSummary);
  summary.add(todaysSummary);

  var summaryContent = '';
  for (var s in summary) {
    summaryContent = summaryContent + s + '\n';
  }
  fSummary.writeAsStringSync(summaryContent);

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

  for (var l in deleted) {
    fDeleted.writeAsStringSync(l + '\n', mode: FileMode.append);
  }

  var pctKnown = (100000 * totalInAnkiCount ~/ totalWordCount) / 1000;
  var occurrencesPerWord = (1000 * totalWordCount ~/ wordCount.length) / 1000;
  print('Percent known $pctKnown% : Occurrences per word $occurrencesPerWord');
  print('The most popular missing word is $mostPopularWord. It occurs ${wordCount[mostPopularWord]} times.');

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
  fBacklog.writeAsStringSync(backlogContent, mode: FileMode.write);

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

  baseContent = '';
  var tempBaseContent = '';
  for (var baseWordKey in baseWordCount.keys) {
    tempBaseContent = tempBaseContent + baseWordKey + ', ' + baseWordCount[baseWordKey].toString() + '\n';
    if (tempBaseContent.length > 4096) {
      baseContent = baseContent + tempBaseContent;
      tempBaseContent = '';
    }
  }
  baseContent = baseContent + tempBaseContent;
  fBaseBacklogWords.writeAsStringSync(baseContent);

  var fPending = File(dir.path + '/pending.txt');
  var pendingContent = '';
  for (var item in pending) {
    pendingContent = pendingContent + item + '\n';
  }
  fPending.writeAsStringSync(pendingContent, mode: FileMode.write);

  var j = 0;
}
