import 'package:flutter/material.dart';
import 'gpa_model.dart';

class GPANotifier with ChangeNotifier {
  List<GPAStat> _listWithNotify = [];

  ///更新gpa总数据时调用（如网络请求）
  set listWithNotify(List<GPAStat> newList) {
    _listWithNotify = newList;
    notifyListeners();
  }

  ///当前显示的学年
  int _index = 0;

  int get indexWithNotify => _index;

  set indexWithNotify(int newIndex) {
    if (newIndex == _index) return;
    _index = newIndex;
    notifyListeners();
  }

  ///曲线上显示的种类, 0->weighted  1->gpa  2->credits
  int _type = 0;

  int get typeWithNotify => _type;

  set typeWithNotify(int newType) {
    if (newType == _type) return;
    _type = newType;
    notifyListeners();
  }

  ///获取当前学年的weighted、gpa、credits
  List<double> get currentDataWithNotify {
    if (_listWithNotify.length == 0) return null;
    var li = _listWithNotify[_index];
    return [li.weighted, li.gpa, li.credits];
  }

  ///获取曲线上的数据
  List<double> get curveDataWithNotify {
    var doubles = List<double>();
    if (_type == 0) for (var i in _listWithNotify) doubles.add(i.weighted);
    if (_type == 1) for (var i in _listWithNotify) doubles.add(i.gpa);
    if (_type == 2) for (var i in _listWithNotify) doubles.add(i.credits);
    return doubles;
  }

  ///获取当前学年的course detail
  List<CourseDetail> get coursesWithNotify {
    if (_listWithNotify.length == 0) return List();
    return _listWithNotify[_index].courses;
  }

  void shuffle(){
    _listWithNotify[_index].courses.shuffle();
    notifyListeners();
  }
}