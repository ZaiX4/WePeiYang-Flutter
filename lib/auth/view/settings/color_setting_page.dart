import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:wei_pei_yang_demo/commons/preferences/common_prefs.dart';
import 'package:wei_pei_yang_demo/commons/util/toast_provider.dart';

class ColorSettingPage extends StatefulWidget {
  @override
  _ColorSettingPageState createState() => _ColorSettingPageState();
}

class _ColorSettingPageState extends State<ColorSettingPage> {
  var pref = CommonPreferences();

  @override
  Widget build(BuildContext context) {
    const titleTextStyle = TextStyle(
        fontSize: 14,
        color: Color.fromRGBO(177, 180, 186, 1),
        fontWeight: FontWeight.bold);
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          brightness: Brightness.light,
          centerTitle: true,
          backgroundColor: Colors.white,
          leading: Padding(
            padding: const EdgeInsets.only(left: 5),
            child: GestureDetector(
                child: Icon(Icons.arrow_back,
                    color: Color.fromRGBO(53, 59, 84, 1.0), size: 32),
                onTap: () => Navigator.pop(context)),
          )),
      body: ListView(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.fromLTRB(35, 20, 35, 0),
            child: Text("调色板",
                style: TextStyle(
                    color: Color.fromRGBO(48, 60, 102, 1),
                    fontWeight: FontWeight.bold,
                    fontSize: 28)),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(35, 20, 35, 20),
            alignment: Alignment.centerLeft,
            child: Text("给课表、GPA以及黄页自定义喜欢的颜色。",
                style: TextStyle(
                    color: Colors.grey, fontSize: 11)),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
            alignment: Alignment.centerLeft,
            child: Text('GPA', style: titleTextStyle),
          ),
          Container(
            height: 80,
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              elevation: 0,
              color: Color.fromRGBO(162, 191, 189, 1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              child: InkWell(
                  onTap: () {
                    // TODO
                    ToastProvider.error('还没做呢，悲');
                  },
                  splashFactory: InkRipple.splashFactory,
                  borderRadius: BorderRadius.circular(9),
                  child: Center(
                      child: Text("#A2BFBD",
                          style: TextStyle(color: Colors.white)))),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
            alignment: Alignment.centerLeft,
            child: Text('黄页', style: titleTextStyle),
          ),
          Container(
            height: 80,
            child: Card(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                child: InkWell(
                    onTap: () {
                      // TODO
                      ToastProvider.error('还没做呢，悲');
                    },
                    splashFactory: InkRipple.splashFactory,
                    borderRadius: BorderRadius.circular(9),
                    child: Center(child: Text("")))),
          ),
          Container(
            height: 80,
            child: Card(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                child: InkWell(
                    onTap: () {
                      // TODO
                      ToastProvider.error('还没做呢，悲');
                    },
                    splashFactory: InkRipple.splashFactory,
                    borderRadius: BorderRadius.circular(9),
                    child: Center(child: Text("")))),
          ),
          Container(
            height: 80,
            child: Card(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                child: InkWell(
                    onTap: () {
                      // TODO
                      ToastProvider.error('还没做呢，悲');
                    },
                    splashFactory: InkRipple.splashFactory,
                    borderRadius: BorderRadius.circular(9),
                    child: Center(child: Text("")))),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
            alignment: Alignment.centerLeft,
            child: Text('课表', style: titleTextStyle),
          ),
          Container(
            height: 80,
            child: Card(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                child: InkWell(
                    onTap: () {
                      // TODO
                      ToastProvider.error('还没做呢，悲');
                    },
                    splashFactory: InkRipple.splashFactory,
                    borderRadius: BorderRadius.circular(9),
                    child: Center(child: Text("")))),
          ),
          Container(
            height: 80,
            child: Card(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                child: InkWell(
                    onTap: () {
                      // TODO
                      ToastProvider.error('还没做呢，悲');
                    },
                    splashFactory: InkRipple.splashFactory,
                    borderRadius: BorderRadius.circular(9),
                    child: Center(child: Text("")))),
          ),
          Container(
            height: 80,
            child: Card(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                child: InkWell(
                    onTap: () {
                      // TODO
                      ToastProvider.error('还没做呢，悲');
                    },
                    splashFactory: InkRipple.splashFactory,
                    borderRadius: BorderRadius.circular(9),
                    child: Center(child: Text("")))),
          ),
          Container(height: 40)
        ],
      ),
    );
  }
}
