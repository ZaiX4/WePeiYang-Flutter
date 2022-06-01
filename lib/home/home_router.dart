import 'package:flutter/material.dart' show Widget;
import 'package:we_pei_yang_flutter/home/view/home_page.dart';
import 'package:we_pei_yang_flutter/home/view/web_views/fifty_two_hz_page.dart';
import 'package:we_pei_yang_flutter/home/view/web_views/wiki_page.dart';
import 'package:we_pei_yang_flutter/home/view/web_views/restart_school_days_game.dart';
import 'package:we_pei_yang_flutter/home/view/web_views/notices_page.dart';

class HomeRouter {
  static String home = 'home/home';
  static String wiki = 'home/wiki';
  static String hz = 'home/52hz';
  static String restartGame = 'home/restartGame';
  static String notice = 'home/notice';
  static final Map<String, Widget Function(Object arguments)> routers = {
    home: (_) => HomePage(),
    wiki: (_) => WikiPage(),
    hz: (_) => FiftyTwoHzPage(),
    restartGame: (_) => RestartSchoolDaysGamePage(),
    notice:(_) => NoticesPage()
  };
}
