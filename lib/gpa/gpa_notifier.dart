import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' show Fluttertoast;
import 'gpa_model.dart';
import 'gpa_spider.dart';

class GPANotifier with ChangeNotifier {
  List<GPAStat> _listWithNotify = [];

  /// 更新gpa总数据时调用（如网络请求）
  set listWithNotify(List<GPAStat> newList) {
    _listWithNotify = newList;
    _sort();
    notifyListeners();
  }

  Total _totalWithNotify = Total(0, 0, 0);

  Total get totalWithNotify => _totalWithNotify;

  set totalWithNotify(Total total) {
    _totalWithNotify = total;
    notifyListeners();
  }

  /// 当前显示的学年
  int _index = 0;

  int get indexWithNotify => _index;

  set indexWithNotify(int newIndex) {
    if (newIndex == _index) return;
    _index = newIndex;
    notifyListeners();
  }

  /// 曲线上显示的种类, 0->weighted  1->gpa  2->credits
  int _type = 0;

  int get typeWithNotify => _type;

  set typeWithNotify(int newType) {
    if (newType == _type) return;
    _type = newType;
    notifyListeners();
  }

  /// 通过[_type]获取种类名称

  String typeName() {
    if (_type == 0) return "Weighted";
    if (_type == 1) return "GPA";
    if (_type == 2) return "Credit";
    return "Error";
  }

  /// 获取当前学年的weighted、gpa、credits
  /// 也可用来判断当前数据是否为空（如gpa_page.dart: [GPAStatsWidget]）
  List<double> get currentDataWithNotify {
    if (_listWithNotify.length == 0) return null;
    var li = _listWithNotify[_index];
    return [li.weighted, li.gpa, li.credits];
  }

  /// 获取曲线上的数据
  List<double> get curveDataWithNotify {
    var doubles = List<double>();
    if (_type == 0) for (var i in _listWithNotify) doubles.add(i.weighted);
    if (_type == 1) for (var i in _listWithNotify) doubles.add(i.gpa);
    if (_type == 2) for (var i in _listWithNotify) doubles.add(i.credits);
    return doubles;
  }

  /// 获取当前学年的course detail
  List<GPACourse> get coursesWithNotify {
    if (_listWithNotify.length == 0) return List();
    return _listWithNotify[_index].courses;
  }

  /// list的排列方式， 0->name 1->score 2->credit
  int _sortType = 0;

  String get sortType {
    switch (_sortType) {
      case 0:
        return "name";
      case 1:
        return "score";
      case 2:
        return "credits";
    }
    return "name";
  }

  /// 分别按 name、score、credit 排序
  void _sort() {
    switch (_sortType) {
      case 0:
        _listWithNotify.forEach((element) {
          element.courses.sort((b, a) => a.name.compareTo(b.name));
        });
        break;
      case 1:
        _listWithNotify.forEach((element) {
          element.courses.sort((b, a) => a.score.compareTo(b.score));
        });
        break;
      case 2:
        _listWithNotify.forEach((element) {
          element.courses.sort((b, a) => a.credit.compareTo(b.credit));
        });
        break;
    }
    notifyListeners();
  }

  /// 更换排列方式
  void reSort() {
    _sortType = (_sortType + 1) % 3;
    _sort();
  }

  GestureTapCallback refreshGPA(BuildContext context) {
    return () {
      Fluttertoast.showToast(
          msg: "刷新数据中……",
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          fontSize: 16);
      getGPABean(onSuccess: (gpaBean) {
        Fluttertoast.showToast(
            msg: "刷新gpa数据成功",
            textColor: Colors.white,
            backgroundColor: Colors.green,
            fontSize: 16);
        _listWithNotify = gpaBean.stats;
        _totalWithNotify = gpaBean.total;
        notifyListeners();
      }, onFailure: (e) {
        // TODO 记得改成 “失败” 文字
        Fluttertoast.showToast(
            msg: e.error.toString(),
            textColor: Colors.white,
            backgroundColor: Colors.red,
            fontSize: 16);
      });
    };
  }
}
