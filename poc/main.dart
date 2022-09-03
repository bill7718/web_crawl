

void main() {

  var c = c2();

  greet(i1Implementer(c));
}

void greet(i1 greeter) {
  print(greeter.hello());
}



abstract class i1 {

  String hello();
}

class i1Implementer extends i1 {

  final dynamic object;

  i1Implementer(this.object);

  @override
  String hello()=>object.hello();

}

class c1  {

  String hello()=>'hi';
}

class c2  {

  String hello()=>'hiya';
}