import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wei_pei_yang_demo/gpa/gpa_curve_detail.dart';
import 'gpa_model.dart';
import 'gpa_notifier.dart';

class GPAPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var s = TextStyle(fontSize: 40);
    return Scaffold(
      appBar: GPAppBar(),
      backgroundColor: Color.fromRGBO(127, 139, 89, 1.0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            RadarChartWidget(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: GPAStatsWidget(),
            ),
            GPACurve(),
            CourseListWidget(),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
            Center(child: Text("12345", style: s)),
          ],
        ),
      ),
    );
  }
}

class GPAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    List<CourseDetail> list1 = [];
    List<GPAStat> gpaList = [];
    list1.add(CourseDetail("高等数学2A", "数学", 6, 93));
    list1.add(CourseDetail("C/C++程序设计（双语）", "计算机", 3.5, 91));
    list1.add(CourseDetail("线性代数及其应用", "数学", 3.5, 94));
    list1.add(CourseDetail("思想道德修养与法律基础", "思想政治理论", 3, 55));
    list1.add(CourseDetail("大学英语1", "外语", 2, 97));
    list1.add(CourseDetail("计算机导论", "计算机", 1.5, 76));
    list1.add(CourseDetail("大学生心理健康", "文化素质教育必修", 1, 60));
    list1.add(CourseDetail("体育A", "体育", 1, 78));
    list1.add(CourseDetail("健康教育", "健康教育", 0.5, 86));
    list1.add(CourseDetail("大学计算机基础1", "计算机", 0, 100));
    gpaList.add(GPAStat(84.88, 3.484, 22.0, list1));
    gpaList.add(GPAStat(77.72, 3.060, 25.0, list1));
    gpaList.add(GPAStat(85.86, 3.466, 29.5, list1));
    gpaList.add(GPAStat(89.00, 3.700, 1.0, list1));
    return AppBar(
      backgroundColor: Color.fromRGBO(127, 139, 89, 1.0),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 5),
        child: GestureDetector(
            child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onTap: () => Navigator.pop(context)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: GestureDetector(
              child: Icon(Icons.error_outline, color: Colors.white, size: 25),
              onTap: () {
                //TODO popup info
              }),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: GestureDetector(
              child: Icon(Icons.loop, color: Colors.white, size: 25),
              onTap: () {
                //TODO refresh
                Provider.of<GPANotifier>(context).listWithNotify = gpaList;
              }),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class RadarChartWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GPANotifier>(
      builder: (context, gpaNotifier, _) => GestureDetector(
        onTapDown: (TapDownDetails detail) {
          //TODO tap animation here
          Provider.of<GPANotifier>(context).shuffle();
        },
        child: Container(
          height: 350,
          //TODO 少于3个时不显示
          child: CustomPaint(
            painter: _RadarChartPainter(gpaNotifier.coursesWithNotify),
            size: Size(double.maxFinite, 160),
          ),
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<CourseDetail> courses;

  _RadarChartPainter(this.courses);

  double centerX;
  double centerY;
  double outer;
  double inner;
  double middle;
  double slice;
  List<Offset> outerPoints = List();
  List<Offset> innerPoints = List();
  List<Offset> middlePoints = List();

  double _count(double x) => pow(pow(x, 2) / 100, 2) / 10000;

  _drawCredit(Canvas canvas, Size size) {
    double maxCredit = 0;
    courses.forEach((element) {
      if (element.credit > maxCredit) maxCredit = element.credit;
    });
    final Paint creditPaint = Paint()
      ..color = Color.fromRGBO(135, 147, 99, 1)
      ..style = PaintingStyle.fill;
    final Path creditPath = Path();
    for (var i = 0; i < courses.length; i++) {
      var ratio = courses[(i + 1) % courses.length].credit / maxCredit;
      var biasX = (outerPoints[i].dx - centerX) * ratio;
      var biasY = (outerPoints[i].dy - centerY) * ratio;
      creditPath
        ..moveTo(centerX, centerY)
        ..lineTo(centerX + biasX, centerY + biasY)
        ..arcTo(
            Rect.fromCircle(
                center: size.center(Offset.zero), radius: outer * ratio),
            slice * (i * 2 + 1),
            slice * 2,
            false)
        ..lineTo(centerX, centerY)
        ..close();
    }
    canvas.drawPath(creditPath, creditPaint);
  }

  _drawScoreFill(Canvas canvas) {
    final Paint fillPaint = Paint()
      ..color = Color.fromRGBO(230, 230, 230, 0.25)
      ..style = PaintingStyle.fill;
    final Path fillPath = Path()..moveTo(centerX, centerY);
    for (var x = 0; x <= courses.length; x++) {
      var i = x % courses.length;
      double ratio = _count(courses[i].score);
      var biasX = (innerPoints[i].dx - centerX) * ratio;
      var biasY = (innerPoints[i].dy - centerY) * ratio;
      if (x == 0)
        fillPath.moveTo(centerX + biasX, centerY + biasY);
      else
        fillPath.lineTo(centerX + biasX, centerY + biasY);
    }
    canvas.drawPath(fillPath, fillPaint);
  }

  _drawLine(Canvas canvas) {
    final Paint linePaint = Paint()
      ..color = Color.fromRGBO(165, 176, 133, 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path linePath = Path();
    for (var i = 0; i < courses.length; i++) {
      linePath
        ..moveTo(centerX, centerY)
        ..lineTo(innerPoints[i].dx, innerPoints[i].dy);
    }
    canvas.drawPath(linePath, linePaint);
  }

  _drawScoreOutLine(Canvas canvas) {
    final Paint outLinePaint = Paint()
      ..color = Color.fromRGBO(237, 243, 229, 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;
    final Path outLinePath = Path()..moveTo(centerX, centerY);
    for (var x = 0; x <= courses.length; x++) {
      var i = x % courses.length;
      double ratio = _count(courses[i].score);
      var biasX = (innerPoints[i].dx - centerX) * ratio;
      var biasY = (innerPoints[i].dy - centerY) * ratio;
      if (x == 0)
        outLinePath.moveTo(centerX + biasX, centerY + biasY);
      else
        outLinePath.lineTo(centerX + biasX, centerY + biasY);
    }
    canvas.drawPath(outLinePath, outLinePaint);
  }

  _drawText(Canvas canvas) {
    for (var i = 0; i < courses.length; i++) {
      var textPainter = TextPainter(
          text: TextSpan(
              text: courses[i].name,
              style: TextStyle(fontSize: 10, color: Colors.white)),
          maxLines: 3,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center)
        ..layout(maxWidth: 40, minWidth: 0);
      var position = Offset(middlePoints[i].dx - (textPainter.width) / 2,
          middlePoints[i].dy - (textPainter.height / 2));
      textPainter.paint(canvas, position);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _initPoints(size);
    _drawCredit(canvas, size);
    _drawScoreFill(canvas);
    _drawLine(canvas);
    _drawScoreOutLine(canvas);
    _drawText(canvas);
  }

  _initPoints(Size size) {
    centerX = size.center(Offset.zero).dx;
    centerY = size.center(Offset.zero).dy;
    outer = size.height / 2;
    inner = outer * 2 / 3;
    middle = (outer + inner) / 2;

    ///若list长度为10,则分成20份
    slice = pi / courses.length;
    for (var i = 0; i < courses.length; i++)
      outerPoints.add(Offset(centerX + outer * cos(slice * (i * 2 + 1)),
          centerY + outer * sin(slice * (i * 2 + 1))));
    for (var i = 0; i < courses.length; i++)
      innerPoints.add(Offset(centerX + inner * cos(slice * i * 2),
          centerY + inner * sin(slice * i * 2)));
    for (var i = 0; i < courses.length; i++)
      middlePoints.add(Offset(centerX + middle * cos(slice * i * 2),
          centerY + middle * sin(slice * i * 2)));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;
}

/// 其实代码很像gpa_curve_detail.dart中的GPAIntro,只不过没法复用555
class GPAStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO list为空时
    return Consumer<GPANotifier>(builder: (context, gpaNotifier, _) {
      var textStyle = TextStyle(
          color: Color.fromRGBO(169, 179, 144, 1.0),
          fontWeight: FontWeight.bold,
          fontSize: 15.0);
      var numStyle = TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25.0);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text('Weighted', style: textStyle),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${gpaNotifier.currentDataWithNotify[0]}',
                    style: numStyle),
              )
            ],
          ),
          Column(
            children: <Widget>[
              Text('GPA', style: textStyle),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${gpaNotifier.currentDataWithNotify[1]}',
                    style: numStyle),
              )
            ],
          ),
          Column(
            children: <Widget>[
              Text('Credits', style: textStyle),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${gpaNotifier.currentDataWithNotify[2]}',
                    style: numStyle),
              )
            ],
          ),
        ],
      );
    });
  }
}

class CourseListWidget extends StatefulWidget {
  @override
  _CourseListState createState() => _CourseListState();
}

class _CourseListState extends State<CourseListWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}