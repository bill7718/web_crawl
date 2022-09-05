import 'dart:async';

import 'deutsche.dart' as deutsche;
import 'francais.dart' as francais;
import 'espanol.dart' as espanol;
import 'italia.dart' as italia;
import 'nederland.dart' as nederland;
import 'porto.dart' as porto;

void main() async {
  porto.main();

  Timer(Duration(milliseconds: 10000), () {
    italia.main();
  });

  Timer(Duration(milliseconds: 30000), () {
    nederland.main();
  });

  Timer(Duration(milliseconds: 50000), () {
    espanol.main();
  });

  Timer(Duration(milliseconds: 70000), () {
    francais.main();
  });

  Timer(Duration(milliseconds: 90000), () {
    deutsche.main();
  });

}
