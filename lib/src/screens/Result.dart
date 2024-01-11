import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_tester/src/bloc/QrResultModel.dart';
import 'package:qr_tester/src/screens/home_screen.dart';

class Result extends StatefulWidget {
  final QrResultModel qrResultModel;

  const Result({Key key, this.qrResultModel}) : super(key: key);
  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "CounterFeit = " + widget.qrResultModel.counterfeit.toString()),
            Text("Match = " + widget.qrResultModel.match),
            Text("Base Percentage = " + widget.qrResultModel.base_percentage),
            MaterialButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              },
              child: Text("OK"),
              color: Colors.grey,
            )
          ],
        ),
      ),
    );
  }
}
