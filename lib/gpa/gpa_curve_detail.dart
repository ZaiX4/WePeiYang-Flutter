import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wei_pei_yang_demo/gpa/gpa_notifier.dart';
import 'dart:math';
import '../home/model/home_model.dart';
import 'package:wei_pei_yang_demo/commons/color.dart';

/// 构建wpy_page中的gpa部分
class GPAPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[GPACurve(), GPAIntro()],
    );
  }
}

class GPAIntro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO list为空时
    return Consumer<GPANotifier>(builder: (context, gpaNotifier, _) {
      var textStyle = TextStyle(
          color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15.0);
      var numStyle = TextStyle(
          color: MyColors.deepBlue,
          fontWeight: FontWeight.bold,
          fontSize: 25.0);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text('Total Weighted', style: textStyle),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${gpaNotifier.currentDataWithNotify[0]}',
                    style: numStyle),
              )
            ],
          ),
          Column(
            children: <Widget>[
              Text('Total Grade', style: textStyle),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${gpaNotifier.currentDataWithNotify[1]}',
                    style: numStyle),
              )
            ],
          ),
        ],
      );
    });
  }
}

/// GPA曲线的总体由[Stack]构成
/// Stack的底层为静态的[_GPACurvePainter],由cubic曲线和黑点构成
/// Stack的顶层为动态的[_GPAPopupPainter],用补间动画控制移动
class GPACurve extends StatefulWidget {
  @override
  _GPACurveState createState() => _GPACurveState();
}

class _GPACurveState extends State<GPACurve>
    with SingleTickerProviderStateMixin {
  /// 上次 / 本次选中的点
  int _lastTaped = 1;
  int _newTaped = 1;

  @override
  Widget build(BuildContext context) {
    return Consumer<GPANotifier>(builder: (context, gpaNotifier, _) {
      List<Point<double>> points = [];
      List<double> curveData = gpaNotifier.curveDataWithNotify;
      //TODO list为空时
      _initPoints(points, curveData);
      return GestureDetector(

          /// 点击监听
          onTapDown: (TapDownDetails detail) {
            RenderBox renderBox = context.findRenderObject();
            var localOffset = renderBox.globalToLocal(detail.globalPosition);
            setState(() {
              var result = judgeTaped(localOffset, points);
              if (result != 0) _newTaped = result;
            });
          },
          //TODO 滑动监听，出了点问题，总之先砍掉（selected已经删了）
          // onHorizontalDragUpdate: (DragUpdateDetails detail) {
          //   RenderBox renderBox = context.findRenderObject();
          //   var localOffset = renderBox.globalToLocal(detail.globalPosition);
          //   setState(() {
          //     selected = judgeSelected(localOffset);
          //   });
          // },
          child: Container(
            child: Stack(
              children: <Widget>[
                /// Stack底层
                CustomPaint(
                  painter: _GPACurvePainter(points: points, taped: _newTaped),
                  size: Size(double.maxFinite, 160.0),
                ),

                /// Stack顶层
                TweenAnimationBuilder(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(
                      begin: 0.0, end: (_lastTaped == _newTaped) ? 0.0 : 1.0),
                  onEnd: () => setState(() => _lastTaped = _newTaped),
                  builder: (BuildContext context, value, Widget child) {
                    var lT = points[_lastTaped], nT = points[_newTaped];
                    return Transform.translate(
                      /// 计算两次点击之间的偏移量Offset
                      /// 40.0和60.0用来对准黑白圆点的圆心
                      offset: Offset(lT.x - 50.0 + (nT.x - lT.x) * value,
                          lT.y - 55.0 + (nT.y - lT.y) * value),
                      child: Container(
                        width: 100.0,
                        height: 70.0,
                        child: Column(
                          children: <Widget>[
                            Container(
                              height: 40.0,
                              child: Card(
                                color: Colors.white,
                                elevation: 3.0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5.0)),
                                child: Center(
                                  child: Text('${curveData[_newTaped - 1]}',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          color: MyColors.deepBlue,
                                          fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ),
                            CustomPaint(
                              painter: _GPAPopupPainter(),
                              size: Size(100.0, 30.0),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ));
    });
  }

  //TODO
  _initPoints(List<Point<double>> points, List<double> list) {
    var width = GlobalModel.getInstance().screenWidth;
    var step = width / (list.length + 1);

    /// start和end的设计使曲线呈上升趋势
    /// 求gpa最小值（算上起止）与最值差，使曲线高度符合比例
    var startStat = list.first * 0.95;
    var minStat = min(list.reduce(min),startStat);
    var maxStat = list.reduce(max);
    var endStat = (list.last * 1.1) > maxStat ? maxStat : list.last * 1.1;
    var gap = maxStat - minStat;
    points.add(Point(0, 140 - (startStat - minStat) / gap * 120));
    for (var i = 1; i <= list.length; i++) {
      points.add(Point(i * step, 140 - (list[i - 1] - minStat) / gap * 120));
    }
    points.add(Point(width, 140 - (endStat - minStat) / gap * 120));
  }

  /// 判断触碰位置是否在任意圆内, r应大于点的默认半径radius,使圆点易触
  int judgeTaped(Offset touchOffset, List<Point<double>> points,
      {double r = 15.0}) {
    var sx = touchOffset.dx;
    var sy = touchOffset.dy;
    for (var i = 1; i < points.length - 1; i++) {
      var x = points[i].x;
      var y = points[i].y;
      if (!((sx - x) * (sx - x) + (sy - y) * (sy - y) > r * r)) return i;
    }
    return 0;
  }
}

/// 绘制GPACurve栈上层的可移动点
class _GPAPopupPainter extends CustomPainter {
  static const outerWidth = 4.0;
  static const innerRadius = 5.0;
  static const outerRadius = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint outerPaint = Paint()
      ..color = MyColors.deepBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerWidth;
    canvas.drawCircle(size.center(Offset.zero), innerRadius, innerPaint);
    canvas.drawCircle(size.center(Offset.zero), outerRadius, outerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;
}

/// 绘制GPACurve栈底层的曲线、黑点
class _GPACurvePainter extends CustomPainter {
  final List<Point<double>> points;
  final int taped;

  const _GPACurvePainter({@required this.points, @required this.taped});

  _drawLine(Canvas canvas, List<Point<double>> points) {
    final Paint paint = Paint()
      ..color = MyColors.dust
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final Path path = Path()
      ..moveTo(0, points[0].y)
      ..cubicThrough(points);
    canvas.drawPath(path, paint);
  }

  /// 默认黑点半径为6.0，选中后为9.0
  _drawPoint(Canvas canvas, List<Point<double>> points, int selected,
      {double radius = 6.0}) {
    final Paint paint = Paint()
      ..color = MyColors.darkGrey2
      ..style = PaintingStyle.fill;
    for (var i = 1; i < points.length - 1; i++) {
      if (i == selected)
        canvas.drawCircle(
            Offset(points[i].x, points[i].y), radius + 3.0, paint);
      else
        canvas.drawCircle(Offset(points[i].x, points[i].y), radius, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawLine(canvas, points);
    _drawPoint(canvas, points, taped);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;
}

/// 利用点坐标数组绘制三阶贝塞尔曲线
/// cp1和cp2为辅助点
extension Cubic on Path {
  cubicThrough(List<Point<double>> list) {
    for (var i = 0; i < list.length - 1; i++) {
      var point1 = list[i];
      var point2 = list[i + 1];

      ///调整bias可以控制曲线起伏程度
      var bias = (point2.x - point1.x) * 0.3;
      var cp1 = Point(point1.x + bias, point1.y);
      var cp2 = Point(point2.x - bias, point2.y);
      cubicTo(cp1.x, cp1.y, cp2.x, cp2.y, point2.x, point2.y);
    }
  }
}