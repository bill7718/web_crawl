import 'package:web_crawl/common.dart';
import 'dart:io';
import 'dart:math';
import 'dart:convert';

void main() {
  var dir = Directory(Directory.current.path + '/de');
  build(dir);
}

void build(Directory dir) {
  var t0 = DateTime.now().microsecondsSinceEpoch;
  var random = Random();

  var roots = <int, double>{};
  var inverseRoots = <int, double>{};
  var i = 0;
  while (i < 1000) {
    roots[i] = sqrt(i);
    inverseRoots[i] = 1 / sqrt(i);
    i++;
  }

  var exclusions = {
    'der',
    'die',
    'in',
    'und',
    'für',
    'im',
    'den',
    'auf',
    'von',
    'ist',
    'sich' 'mit',
    'zu',
    'das',
    'wie'
  };

  var sentences = <String>{};
  var fReviewed = File(dir.path + '/reviewed.txt');
  var reviewedLines = fReviewed.readAsLinesSync();
  sentences.addAll(reviewedLines);

  var fBacklog = File(dir.path + '/backlog.txt');
  var backlogLines = fBacklog.readAsLinesSync();
  sentences.addAll(backlogLines);

  var fDeleted = File(dir.path + '/deleted.txt');
  var deletedLines = fDeleted.readAsLinesSync();
  sentences.addAll(deletedLines);



  var occurrence = <String>{};
  var fOccurrence = File(dir.path + '/occurrenceAnalysis.csv');

  var wordCount = <String, double>{};
  var coOccurrence = <String, Map<String, double>>{};

  for (var line in sentences) {
    var words = split(line);
    var words2 = <String>[];
    words2.addAll(words);

    for (var w in words) {
      var r = inverseRoots[words.length];
      var r1 = roots[words.length];
      var word = clean(w).toLowerCase();
      if (word.isNotEmpty && !exclusions.contains(word)) {
        wordCount[word] = wordCount[word] ?? 0;
        wordCount[word] = wordCount[word] + r1;

        for (var w2 in words2) {
          var word2 = clean(w2).toLowerCase();
          if (word2.isNotEmpty &&
              !exclusions.contains(word2) &&
              word2 != word) {
            coOccurrence[word] = coOccurrence[word] ?? <String, double>{};
            coOccurrence[word][word2] = coOccurrence[word][word2] ?? 0;
            coOccurrence[word][word2] = coOccurrence[word][word2] + r;
          }
        }
      }
    }
  }

  var t1 = DateTime.now().microsecondsSinceEpoch;

  print(t1 - t0);

  print(wordCount.length);

  // get a list of target word axes
  var inverseWordCount = <double, String>{};

  for (var z in wordCount.keys) {
    if (wordCount[z] > 100) {
      inverseWordCount[wordCount[z]] = z;
    }
  }

  var counts = <double>[];
  counts.addAll(inverseWordCount.keys);
  counts.sort((a, b) {
    return a > b ? -1 : 1;
  });

  var sampleCounts = counts.getRange(256, 768);
  var sample = <String>[];
  for (var v in sampleCounts) {
    sample.add(inverseWordCount[v]);
  }

  var t2 = DateTime.now().microsecondsSinceEpoch;

  print(t2 - t1);

  print(
      '${sample.last} : ${wordCount[sample.last]} :: ${inverseWordCount.length}');
  //print(wordCount['preise']);

  var normalisedSample = <String, Map<String, double>>{};
  for (var s in sample) {
    normalisedSample[s] = <String, double>{};
    for (var k in coOccurrence[s].keys) {
      if (!sample.contains(k)) {
        normalisedSample[s][k] = 1000 * coOccurrence[s][k] / wordCount[s];
      }
    }
  }

  var totalUnattached = 0.00;
  for (var w in wordCount.keys) {
    if (coOccurrence[w] != null && wordCount[w] > 200 && !sample.contains(w)) {
      var current = normaliseItem(wordCount[w], coOccurrence[w]);
      var vector = <String, double>{};
      var i = 0;
      while (i < sample.length) {
        if (current[sample[i]] != null) {
          vector[sample[i]] = current[sample[i]];
          current.remove(sample[i]);
        }
        i++;
      }
      var initialDelta = sumWordOccurrenceDelta(current);

      // set up the initial data
      var attemptRecord = <String, LastAttempt>{};
      for (var k in sample) {
        attemptRecord[k] = LastAttempt(0.01, 1, true);
      }
      var t = <String, double>{};
      var failedAttempts = 0;
      while (failedAttempts < 1000) {
        var i = random.nextInt(sample.length);
        t = evaluateAttempt(current, normalisedSample[sample[i]], attemptRecord[sample[i]].newDelta);
        if (t != null) {
          failedAttempts = 0;
          current = t;
          attemptRecord[sample[i]].result = true;
        } else {
          failedAttempts++;
          attemptRecord[sample[i]].result = false;
        }
      }
      var f = sumWordOccurrenceDelta(current);
      totalUnattached += f;
      print('$t1 : $w : ${wordCount[w]} : $initialDelta : $f : $totalUnattached');
      fOccurrence.writeAsStringSync('$t1, $w, ${wordCount[w]}, $initialDelta, $f \n', mode: FileMode.append);
    }
  }

  var t3 = DateTime.now().microsecondsSinceEpoch;

  print(t3 - t2);
}

Map<String, double> normaliseItem(double factor, Map<String, double> values) {
  var response = <String, double>{};
  for (var k in values.keys) {
    response[k] = 1000 * values[k] / factor;
  }
  return response;
}

Map<String, double> evaluateAttempt(Map<String, double> wordOccurrence,
    Map<String, double> axis, double factor) {

  var delta = sumWordOccurrenceDelta(wordOccurrence);
  var trialMerge = merge(wordOccurrence, axis, factor);
  var trialDelta = sumWordOccurrenceDelta(trialMerge);

  if (trialDelta < delta) {
    return trialMerge;
  } else {
    return null;
  }
}


double sumWordOccurrenceDelta(Map<String, double> wordOccurrence) {
  var response = 0.00;
  for (var v in wordOccurrence.values) {
    v > 0 ? response += v : response -= v;
  }
  return response;
}

Map<String, double> merge(Map<String, double> wordOccurrence,
    Map<String, double> axis, double factor) {
  var response = <String, double>{};
  response.addAll(wordOccurrence);
  for (var k in axis.keys) {
    response[k] =  response[k] ?? 0.00;
    response[k] = response[k] + factor * axis[k] * -1;
  }
  return response;
}

class LastAttempt {
  double deltaFactor;
  int deltaMultiplier;
  bool result;
  LastAttempt(this.deltaFactor, this.deltaMultiplier, this.result);

  double get newDelta {
    if (deltaMultiplier > 0) {
      if (result) {
        deltaMultiplier++;
        return deltaMultiplier * deltaFactor;
      } else {
        deltaMultiplier--;
        if (deltaMultiplier == 0) {
          deltaFactor = deltaFactor * 0.99;
          deltaMultiplier = -1;
        }
        return deltaFactor * -1;
      }
    } else {
      if (result) {
        deltaMultiplier--;
        return deltaMultiplier * deltaFactor;
      } else {
        deltaMultiplier++;
        if (deltaMultiplier == 0) {
          deltaFactor = deltaFactor * 0.99;
          deltaMultiplier = 1;
        }
        return deltaFactor;
      }
    }
  }
}
