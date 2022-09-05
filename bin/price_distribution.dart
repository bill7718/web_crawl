

import 'dart:collection';
import 'dart:io';

void main() {

  var file = File('data.csv');

  var start = 70000;
  var end = 90000;
  var map = <int, double>{};

  var i = start;
  while (i < end) {
    map[i] = 0.0;
    i++;
  }



  var lines = file.readAsLinesSync();

  var startPrice;
  var endPrice;
  var startVolume;
  var endVolume;

  for (var line in lines) {
    if (line.isNotEmpty) {

      startPrice = endPrice;
      startVolume = endVolume;

      endPrice = double.parse(line.split(',').first);
      endVolume = double.parse(line.split(',').last);

      if (startPrice != null) {

       if (endPrice == startPrice) {
         map[(startPrice * 100).round()] = endVolume - startVolume;
       } else {
         int price = (startPrice * 100).round();
         if (endPrice > startPrice) {
           while (price <= endPrice * 100) {
             map[price] = map[price] + (endVolume - startVolume) / (endPrice - startPrice + 1);
             price++;
           }
         } else {
           while (price >= endPrice * 100) {
             map[price] = map[price] + (endVolume - startVolume) / (startPrice - endPrice + 1);
             price--;
           }
         }
       }
      }
    }
  }
  var distribution = File('distribution.csv');

  for (var price in map.keys) {
    if (map[price] > 0) {
      distribution.writeAsStringSync('${price/100} , ${map[price].round()} \n', mode: FileMode.append);
    }
  }






}