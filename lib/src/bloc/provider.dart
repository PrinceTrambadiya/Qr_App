import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'bloc.dart';
export 'bloc.dart';

class Provider extends InheritedWidget {
  Bloc bloc;

  Provider({
      Key key, 
      Widget child,
      FirebaseApp firebaseApp
  }) :
    bloc = Bloc(firebaseApp),
    super(key: key, child: child);

  @override
  bool updateShouldNotify(_) => true;

  static Bloc of(BuildContext context) {
    return (context.dependOnInheritedWidgetOfExactType<Provider>() as Provider).bloc;
  }
}