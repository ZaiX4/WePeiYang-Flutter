import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:we_pei_yang_flutter/auth/network/auth_service.dart';
import 'package:we_pei_yang_flutter/commons/channel/push/push_manager.dart';
import 'package:we_pei_yang_flutter/commons/channel/statistics/umeng_statistics.dart';
import 'package:we_pei_yang_flutter/commons/preferences/common_prefs.dart';
import 'package:we_pei_yang_flutter/commons/util/color_util.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/feedback/view/lake_home_page/home_page.dart';
import 'package:we_pei_yang_flutter/feedback/view/lake_home_page/lake_notifier.dart';
import 'package:we_pei_yang_flutter/feedback/view/profile_page.dart';
import 'package:we_pei_yang_flutter/home/view/wpy_page.dart';
import 'package:we_pei_yang_flutter/main.dart';
import 'package:we_pei_yang_flutter/studyroom/model/studyroom_provider.dart';
import 'package:we_pei_yang_flutter/urgent_report/report_server.dart';

import '../../auth/view/user/account_upgrade_dialog.dart';

class HomePage extends StatefulWidget {
  final int? page;

  HomePage(this.page);

  @override
  _HomePageState createState() => _HomePageState();
}

///这里是微北洋主页面
class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  /// bottomNavigationBar对应的分页
  List<Widget> pageList = [];
  /// 现在在第几栏目
  int _currentIndex = 0;
  /// 上一次点击的时间，可以用来约束点击操作
  DateTime? _lastPressedAt;
  /// 底部分页控制器
  late final TabController _tabController;
  /// FeedbackHomePageState用来管理主页面信息
  final feedbackKey = GlobalKey<FeedbackHomePageState>();

  @override
  /// 页面初始化
  void initState() {

    super.initState();

    ///主页面有三个页面，WBY页面，论坛页面FeedbackHomePage，个人信息页面
    pageList
      ..add(WPYPage())
      ..add(FeedbackHomePage(key: feedbackKey))
      ..add(ProfilePage());
    _tabController = TabController(
      length: pageList.length,
      vsync: this,
      initialIndex: 0,
    )..addListener(() {
      /*这句用来检测用户切换页面，如果当前页面索引不同于之前，则更新currentIndex并更新页面*/
        if (_tabController.index != _tabController.previousIndex) {
          setState(() {
            _currentIndex = _tabController.index;
          });
        }
      });

    ///当该组件渲染完成后...
    WidgetsBinding.instance.addPostFrameCallback((_) async {

      ///PushManager是一个状态管理类,其中initGeTuiSdk用来给用户弹出一个页面(是否开启个性推荐),然后这样.
      ///PushManager类用来管理微北洋的推送信息
      context.read<PushManager>().initGeTuiSdk();

      final pushManager = context.read<PushManager>();

      ///userCid用来跟踪用户设备信息
      ///nowTime获取当前时间
      final nowCid = (await pushManager.getCid()) ?? "";
      final nowTime = DateTime.now();

      ///获取上一次的时间
      ///CommonPreference类用于存放用户的个人偏好设置
      DateTime lastTime;
      try {
        lastTime = DateTime.tryParse(CommonPreferences.lastPushTime.value)!;
      }
      catch (_) {
        lastTime = nowTime.subtract(Duration(days: 3));
      }

      ///如果设备跟上次不一样了,就更新用户信息
      var lastPushCid = CommonPreferences.lastPushCid.value;
      var userNumber = CommonPreferences.userNumber.value;
      var pushUserNumber = CommonPreferences.pushUserNumber.value;

      ///如果与上次登录的设备,用户id不同则更新
      if (nowCid != lastPushCid || userNumber != pushUserNumber ||
          nowTime.difference(lastTime).inDays >= 3) {

        ///登录类更新cid信息,如果更新成功,则更新本地用户配置
        AuthService.updateCid(nowCid, onResult: (_) {
          debugPrint('cid $nowCid 更新成功');

          CommonPreferences.lastPushCid.value = nowCid;
          CommonPreferences.pushUserNumber.value = CommonPreferences.userNumber.value;
          CommonPreferences.lastPushTime.value = DateFormat('yyyy-MM-dd').format(nowTime);

        }, onFailure: (_) {
          debugPrint('cid $nowCid 更新失败');
        });
      }

      ///更新提交时间
      var hasReport = await ReportService.getTodayHasReported();
      if (hasReport) {
        CommonPreferences.reportTime.value = DateTime.now().toString();
      } else {
        CommonPreferences.reportTime.value = '';
      }

      // 检查当前是否有未处理的事件
      context.findAncestorStateOfType<WePeiYangAppState>()?.checkEventList();
      // 友盟统计账号信息
      UmengCommonSdk.onProfileSignIn(CommonPreferences.account.value);
      // 刷新自习室数据
      context.read<CampusProvider>().init();

    });

    if (widget.page != null) {
      _tabController.animateTo(widget.page!);
    } else {
      _tabController.animateTo(0);
    }

    ///等待渲染结束
    ///进行账户升级(可能是远古需求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var accountUpgrade = CommonPreferences.accountUpgrade.value;
      if (accountUpgrade.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => AccountUpgradeDialog(),
        );
      }
    });

  }//init

  @override
  Widget build(BuildContext context) {
    ///WePeiYangApp是启动页面
    double width = WePeiYangApp.screenWidth / 3;

    ///底部第一页面的按钮(对应到WPYPage)
    var homePage = SizedBox(
      height: 70.h,
      width: width,
      child: IconButton(
        splashRadius: 1,
        icon: _currentIndex == 0
            ? SvgPicture.asset(
                'assets/svg_pics/home.svg',
              )
            : SvgPicture.asset(
                'assets/svg_pics/home.svg',
                color: ColorUtil.grey144,
              ),
        color: ColorUtil.whiteFFColor,
        onPressed: () => _tabController.animateTo(0),
      ),
    );

    ///底部第二页面的按钮
    var feedbackPage = SizedBox(
      height: 70.h,
      width: width,
      child: IconButton(
        splashRadius: 1,
        icon: _currentIndex == 1
            ? SvgPicture.asset(
                'assets/svg_pics/lake.svg',
              )
            : SvgPicture.asset(
                'assets/svg_pics/lake_grey.svg',
              ),
        color: ColorUtil.whiteFFColor,
        onPressed: () {
          if (_currentIndex == 1) {
            feedbackKey.currentState?.listToTop();
            // 获取剪切板微口令
            context.read<LakeModel>().getClipboardWeKoContents(context);
          } else
            _tabController.animateTo(1);
        },
      ),
    );

    ///底部第三页面的按钮
    var selfPage = SizedBox(
      height: 70.h,
      width: width,
      child: IconButton(
        splashRadius: 1,
        icon: _currentIndex == 2
            ? SvgPicture.asset(
                'assets/svg_pics/my.svg',
              )
            : SvgPicture.asset(
                'assets/svg_pics/my.svg',
                color: ColorUtil.grey144,
              ),
        color: ColorUtil.whiteFFColor,
        onPressed: () => _tabController.animateTo(2),
      ),
    );

    ///底部按钮所在区域
    var bottomNavigationBar = Container(
      decoration: BoxDecoration(
        color: ColorUtil.whiteFFColor,
        boxShadow: [
          BoxShadow(color: ColorUtil.black26, spreadRadius: -1, blurRadius: 2)
        ],
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
      ),

      /// 适配iOS底部安全区
      child: SafeArea(
        child: Row(children: <Widget>[homePage, feedbackPage, selfPage]),
      ),
    );

    ///修改系统样式
    return AnnotatedRegion<SystemUiOverlayStyle>(

      value: _tabController.index == 2
          ? SystemUiOverlayStyle.light
              .copyWith(systemNavigationBarColor: ColorUtil.whiteFFColor)
          : SystemUiOverlayStyle.dark
              .copyWith(systemNavigationBarColor: ColorUtil.whiteFFColor),

      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: bottomNavigationBar,

        body: WillPopScope(
          ///实现侧滑退出
          onWillPop: () async {
            if (_tabController.index == 0) {
              if (_lastPressedAt == null ||
                  DateTime.now().difference(_lastPressedAt!) >
                      Duration(seconds: 1)) {
                //两次点击间隔超过1秒则重新计时
                _lastPressedAt = DateTime.now();
                ToastProvider.running('再按一次退出程序');
                return false;
              }
            } else if (context.read<LakeModel>().currentTab != 0) {
              context.read<LakeModel>().tabController.animateTo(0);
              return false;
            } else {
              _tabController.animateTo(0);
              return false;
            }
            return true;
          },

          ///底部的页面切换按钮
          child: TabBarView(
            controller: _tabController,
            physics: NeverScrollableScrollPhysics(),
            children: pageList,
          ),
        ),
      ),
    );
  }
}
