import 'dart:math';

import 'package:extended_tabs/extended_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:we_pei_yang_flutter/commons/util/color_util.dart';
import 'package:we_pei_yang_flutter/commons/util/text_util.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/commons/widgets/loading.dart';
import 'package:we_pei_yang_flutter/feedback/feedback_router.dart';
import 'package:we_pei_yang_flutter/feedback/model/feedback_notifier.dart';
import 'package:we_pei_yang_flutter/feedback/network/feedback_service.dart';
import 'package:we_pei_yang_flutter/feedback/network/post.dart';
import 'package:we_pei_yang_flutter/feedback/view/components/widget/tab.dart';
import 'package:we_pei_yang_flutter/feedback/view/lake_home_page/lake_notifier.dart';
import 'package:we_pei_yang_flutter/feedback/view/lake_home_page/normal_sub_page.dart';
import 'package:we_pei_yang_flutter/feedback/view/new_post_page.dart';
import 'package:we_pei_yang_flutter/feedback/view/search_result_page.dart';
import 'package:we_pei_yang_flutter/main.dart';
import 'package:we_pei_yang_flutter/message/feedback_message_page.dart';

import '../../../commons/preferences/common_prefs.dart';
import '../../../commons/widgets/w_button.dart';
import '../../../home/view/web_views/festival_page.dart';

class FeedbackHomePage extends StatefulWidget {
  FeedbackHomePage({Key? key}) : super(key: key);

  @override
  FeedbackHomePageState createState() => FeedbackHomePageState();
}

///这是论坛页面,也是微北洋最核心的部分
class FeedbackHomePageState extends State<FeedbackHomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  final fbKey = new GlobalKey<FbTagsWrapState>();
  ///初始化时会调用刷新函数并使页面不可见
  bool initializeRefresh = false;
  bool canSee = false;

  double get searchBarHeight => 42.h;
  double get tabBarHeight => 46.h;

  ///各标签页信息
  late final FbDepartmentsProvider _departmentsProvider;

  ///简化代码
  dynamic lakeModel() => context.read<LakeModel>();

  ///初始化页面
  void initPage() {
    context.read<LakeModel>().checkTokenAndGetTabList(_departmentsProvider,
        success: () {
      context.read<FbHotTagsProvider>().initRecTag(failure: (e) {
        ToastProvider.error(e.error.toString());
      });
      context.read<FbHotTagsProvider>().initHotTags();
      FeedbackService.getUserInfo(
          onSuccess: () {},
          onFailure: (e) {
            ToastProvider.error(e.error.toString());
          });
    });
  }

  @override
  void initState() {
    super.initState();
    _departmentsProvider =
        Provider.of<FbDepartmentsProvider>(context, listen: false);
    initPage();
    ///获取剪切板数据并跳转
    context.read<LakeModel>().getClipboardWeKoContents(context);
  }

  @override
  bool get wantKeepAlive => true;///活着

  /*原代码:
    void listToTop() {
    if (context
            .read<LakeModel>()
            .lakeAreas[context
                .read<LakeModel>()
                .tabList[context.read<LakeModel>().tabController.index]
                .id]!
            .controller
            .offset >
        1500) {
      context
          .read<LakeModel>()
          .lakeAreas[context.read<LakeModel>().tabController.index]!
          .controller
          .jumpTo(1500);
    }
        context
        .read<LakeModel>()
        .lakeAreasList[context
            .read<LakeModel>()
            .tabList[context.read<LakeModel>().tabController.index]
            .id]!
        .controller
        .animateTo(-85,
            duration: Duration(milliseconds: 400), curve: Curves.easeOutCirc);
     }
  */
  void listToTop() {

    var tabControllerIndex = lakeModel().tabController.index;
    var lakeAreasId = lakeModel().tabList[tabControllerIndex].id;
    var lakeArea = lakeModel().lakeAreasList[lakeAreasId];

    if (lakeArea!.controller.offset > 1500) {
      var tabLakeArea = lakeModel().lakeAreasList[tabControllerIndex];
      tabLakeArea!.controller.jumpTo(1500);
    }
    lakeArea.controller.animateTo(
        -85,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCirc
    );
  }

  void _onFeedbackTapped() {

    if (!lakeModel().tabController.indexIsChanging) {

      if (canSee) {
        lakeModel().onFeedbackOpen();
        fbKey.currentState?.tap();
        setState(() {
          canSee = false;
        });
      } else {
        lakeModel().onFeedbackOpen();
        fbKey.currentState?.tap();
        setState(() {
          canSee = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final status = context.select((LakeModel model) => model.mainStatus);
    final tabList = context.select((LakeModel model) => model.tabList);

    ///如果还没刷新
    if (initializeRefresh) {
          lakeModel()
          .lakeAreasList[lakeModel().tabController.index]!
          .controller
          .animateTo(-85,
              duration: Duration(milliseconds: 1000),
              curve: Curves.easeOutCirc);
      initializeRefresh = false;
    }

    ///搜索框实现
    var searchBar = WButton(

      onPressed: () => Navigator.pushNamed(context, FeedbackRouter.search),

      child: Container(
        height: searchBarHeight - 8,
        margin: EdgeInsets.fromLTRB(15, 8, 15, 0),
        decoration: BoxDecoration(
            color: ColorUtil.backgroundColor,
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child: Row(children: [
          SizedBox(width: 14),
          Icon(
            Icons.search,
            size: 19,
            color: ColorUtil.grey108,
          ),
          SizedBox(width: 12),
          Consumer<FbHotTagsProvider>(
              builder: (_, data, __) => Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: WePeiYangApp.screenWidth - 260),
                        child: Text(
                          data.recTag == null
                              ? '搜索发现'
                              : '#${data.recTag?.name}#',
                          overflow: TextOverflow.ellipsis,
                          style: TextUtil.base.grey6C.NotoSansSC.w400.sp(15),
                        ),
                      ),
                      Text(
                        data.recTag == null ? '' : '  为你推荐',
                        overflow: TextOverflow.ellipsis,
                        style: TextUtil.base.grey6C.NotoSansSC.w400.sp(15),
                      ),
                    ],
                  )),
          Spacer()
        ]),
      ),
    );

    ///其它的页面
    var expanded = Expanded(
      child: SizedBox(
        height: tabBarHeight - 6.h,
        ///如果没有加载,则显示加载页面
        child: status == LakePageStatus.unload
            ? Align(
                alignment: Alignment.center,
                child: Consumer<ChangeHintTextProvider>(
                  builder: (loadingContext, loadingProvider, __) {
                    loadingProvider.calculateTime();
                    return loadingProvider.timeEnded
                        ? WButton(
                            onPressed: () {
                              var model = lakeModel();
                              model.mainStatus = LakePageStatus.loading;
                              loadingProvider.resetTimer();
                              initPage();
                            },
                            child: Text('重新加载'))
                        : Loading();
                  },
                ),
              )///否则如果正在加载

            : status == LakePageStatus.loading
                ? Align(alignment: Alignment.center, child: Loading())
                : status == LakePageStatus.idle
                    ? Builder(builder: (context) {

                      ///顶部的切换栏实现
                      return TabBar(
                        // 设置指示器底部的内边距
                        indicatorPadding: EdgeInsets.only(bottom: 2),
                        // 设置标签底部的内边距
                        labelPadding: EdgeInsets.only(bottom: 3),
                        // 允许选项卡水平滚动
                        isScrollable: true,
                        // 使用弹性滚动物理效果
                        physics: BouncingScrollPhysics(),
                        // 使用LakeModel中的tabController控制选项卡
                        controller: lakeModel().tabController,
                        // 设置选中标签的文本颜色
                        labelColor: ColorUtil.blue2CColor,
                        // 设置选中标签的文本样式
                        labelStyle: TextUtil.base.w400.NotoSansSC.sp(18),
                        // 设置未选中标签的文本颜色
                        unselectedLabelColor: ColorUtil.black2AColor,
                        // 设置未选中标签的文本样式
                        unselectedLabelStyle: TextUtil.base.w400.NotoSansSC.sp(18),
                        // 设置选项卡指示器的样式，这里使用了CustomIndicator
                        indicator: CustomIndicator(
                          borderSide: BorderSide(
                            color: ColorUtil.blue2CColor,
                            width: 2,
                          ),
                        ),
                        // 生成选项卡标签，根据tabList中的数据动态生成
                        tabs: List<Widget>.generate(
                          tabList.length,
                              (index) => DaTab(
                            // 设置选项卡的文本内容
                            text: tabList[index].shortname,
                            // 如果选项卡的名称是'校务专区'，则显示下拉按钮
                            withDropDownButton: tabList[index].name == '校务专区',
                          ),
                        ),
                        // 当用户点击选项卡时触发的回调函数
                        onTap: (index) {
                          // 如果选中的选项卡的id是1，执行_onFeedbackTapped函数
                          if (tabList[index].id == 1) {
                            _onFeedbackTapped();
                          }
                        },
                      );

        })
                    : WButton(
                        onPressed: () => context
                            .read<LakeModel>()
                            .checkTokenAndGetTabList(_departmentsProvider),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '点击重新加载分区',
                            style: TextUtil.base.mainColor.w400.sp(16),
                          ),
                        ),
                      ),
      ),
    );

    return Scaffold(
      backgroundColor: ColorUtil.whiteFFColor,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
                // 因为上面的空要藏住搜索框
                top: MediaQuery.of(context).padding.top < searchBarHeight
                    ? searchBarHeight + tabBarHeight
                    : MediaQuery.of(context).padding.top + searchBarHeight,
                bottom: 70.h - 18),
            child: Selector<LakeModel, List<WPYTab>>(
              selector: (BuildContext context, LakeModel lakeModel) {
                return lakeModel.tabList;
              },
              builder: (_, tabs, __) {
                if (!lakeModel().tabControllerLoaded) {
                  lakeModel().tabController = TabController(
                      length: tabs.length,
                      vsync: this,
                      initialIndex: min(max(0, tabs.length - 1), 1))
                    ..addListener(() {
                      if (context
                              .read<LakeModel>()
                              .tabController
                              .index
                              .toDouble() ==
                          context
                              .read<LakeModel>()
                              .tabController
                              .animation!
                              .value) {
                        WPYTab tab =
                            lakeModel().lakeAreasList[1]!.tab;
                        if (lakeModel().tabController.index !=
                                tabList.indexOf(tab) &&
                            canSee) _onFeedbackTapped();
                        lakeModel().currentTab =
                            lakeModel().tabController.index;
                        lakeModel().onFeedbackOpen();
                      }
                    });
                }
                int cacheNum = 0;
                return tabs.length == 1
                    ? ListView(children: [SizedBox(height: 0.35.sh), Loading()])
                    : ExtendedTabBarView(
                        cacheExtent: cacheNum,
                        controller: lakeModel().tabController,
                        children: List<Widget>.generate(
                          // 为什么判空去掉了 因为 tabList 每次清空都会被赋初值
                          tabs.length,
                          (i) => NSubPage(
                            index: tabList[i].id,
                          ),
                        ),
                      );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                // 因为上面的空要藏住搜索框
                top: (MediaQuery.of(context).padding.top < searchBarHeight
                        ? searchBarHeight + tabBarHeight
                        : MediaQuery.of(context).padding.top +
                            searchBarHeight) +
                    tabBarHeight -
                    4),
            child: Visibility(
              child: WButton(
                  onPressed: () {
                    if (canSee) _onFeedbackTapped();
                  },
                  child: FbTagsWrap(key: fbKey)),
              maintainState: true,
              visible: canSee,
            ),
          ),
          Selector<LakeModel, bool>(
              selector: (BuildContext context, LakeModel lakeModel) {
            return lakeModel.barExtended;
          }, builder: (_, barExtended, __) {
            return AnimatedContainer(
                height: searchBarHeight + tabBarHeight,
                margin: EdgeInsets.only(
                    top: barExtended
                        ? MediaQuery.of(context).padding.top < searchBarHeight
                            ? searchBarHeight
                            : MediaQuery.of(context).padding.top
                        : MediaQuery.of(context).padding.top < searchBarHeight
                            ? 0
                            : MediaQuery.of(context).padding.top -
                                searchBarHeight),
                color: ColorUtil.whiteFFColor,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOutCirc,
                child: Column(children: [
                  searchBar,
                  SizedBox(
                    height: tabBarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(width: 4),
                        expanded,
                        SizedBox(width: 4)
                      ],
                    ),
                  )
                ]));
          }),
          // 挡上面
          Container(
              color: ColorUtil.whiteFFColor,
              height: MediaQuery.of(context).padding.top < searchBarHeight
                  ? searchBarHeight
                  : MediaQuery.of(context).padding.top),
          Positioned(
            bottom: ScreenUtil().bottomBarHeight + 90.h,
            right: 20.w,
            child: Hero(
              tag: "addNewPost",
              child: InkWell(
                  splashColor: ColorUtil.transparent,
                  highlightColor: ColorUtil.transparent,
                  child: Container(
                    height: 72.r,
                    width: 72.r,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/images/add_post.png"),
                      ),
                    ),
                  ),
                  onTap: () {
                    if (tabList.isNotEmpty) {
                      initializeRefresh = true;
                      context.read<NewPostProvider>().postTypeNotifier.value =
                          tabList[1].id;
                      Navigator.pushNamed(context, FeedbackRouter.newPost,
                          arguments: NewPostArgs(false, '', 0, ''));
                    }
                  }),
            ),
          ),
          Consumer<FestivalProvider>(
              builder: (BuildContext context, fp, Widget? child) {
            if (fp.popUpIndex() != -1) {
              int index = fp.popUpIndex();
              final url = fp.festivalList[index].url;
              final picUrl = fp.festivalList[index].image;
              return Positioned(
                bottom: ScreenUtil().bottomBarHeight + 180.h,
                right: 20.w + 6.r,
                child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Container(
                      height: 60.r,
                      width: 60.r,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(100.r)),
                        image: DecorationImage(
                            image: NetworkImage(picUrl), fit: BoxFit.cover),
                      ),
                    ),
                    onTap: () async {
                      if (!url.isEmpty) {
                        if (url.startsWith('browser:')) {
                          final launchUrl = url
                              .replaceAll('browser:', '')
                              .replaceAll(
                                  '<token>', '${CommonPreferences.token.value}')
                              .replaceAll('<laketoken>',
                                  '${CommonPreferences.lakeToken.value}');
                          if (await canLaunchUrlString(launchUrl)) {
                            launchUrlString(launchUrl,
                                mode: LaunchMode.externalApplication);
                          } else {
                            ToastProvider.error('好像无法打开活动呢，请联系天外天工作室');
                          }
                        } else
                          Navigator.pushNamed(context, FeedbackRouter.haitang,
                              arguments: FestivalArgs(
                                  url,
                                  context
                                      .read<FestivalProvider>()
                                      .festivalList[index]
                                      .title));
                      }
                    }),
              );
            } else
              return SizedBox();
          }),
        ],
      ),
    );
  }
}

class FbTagsWrap extends StatefulWidget {
  FbTagsWrap({Key? key}) : super(key: key);

  @override
  FbTagsWrapState createState() => FbTagsWrapState();
}

class FbTagsWrapState extends State<FbTagsWrap>
    with SingleTickerProviderStateMixin {
  bool _tagsContainerCanAnimate = true;
  bool _tagsContainerBackgroundIsShow = false;
  bool _tagsWrapIsShow = false;
  double _tagsContainerBackgroundOpacity = 0;

  _offstageTheBackground() {
    _tagsContainerCanAnimate = true;
    if (_tagsContainerBackgroundOpacity < 1) {
      _tagsContainerBackgroundIsShow = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var tagsWrap = Consumer<FbDepartmentsProvider>(
      builder: (_, provider, __) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Wrap(
            spacing: 6,
            children: List.generate(provider.departmentList.length, (index) {
              return InkResponse(
                radius: 30,
                highlightColor: ColorUtil.transparent,
                child: Chip(
                  backgroundColor: ColorUtil.white234,
                  label: Text(provider.departmentList[index].name,
                      style: TextUtil.base.normal.black2A.NotoSansSC.sp(13)),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    FeedbackRouter.searchResult,
                    arguments: SearchResultPageArgs(
                        '',
                        '',
                        provider.departmentList[index].id.toString(),
                        '#${provider.departmentList[index].name}',
                        1,
                        0),
                  );
                },
              );
            }),
          ),
        );
      },
    );
    var _departmentSelectionContainer = Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: ColorUtil.whiteFDFE,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22))),
      child: AnimatedSize(
        curve: Curves.easeOutCirc,
        duration: Duration(milliseconds: 400),
        child: Offstage(offstage: !_tagsWrapIsShow, child: tagsWrap),
      ),
    );
    return Stack(
      children: [
        Offstage(
            offstage: !_tagsContainerBackgroundIsShow,
            child: AnimatedOpacity(
              opacity: _tagsContainerBackgroundOpacity,
              duration: Duration(milliseconds: 500),
              onEnd: _offstageTheBackground,
              child: Container(
                color: ColorUtil.black45,
              ),
            )),
        Offstage(
          offstage: !_tagsContainerBackgroundIsShow,
          child: _departmentSelectionContainer,
        ),
      ],
    );
  }

  void tap() {
    if (_tagsContainerCanAnimate) _tagsContainerCanAnimate = false;
    if (_tagsWrapIsShow == false)
      setState(() {
        _tagsWrapIsShow = true;
        _tagsContainerBackgroundIsShow = true;
        _tagsContainerBackgroundOpacity = 1.0;
      });
    else
      setState(() {
        _tagsContainerBackgroundOpacity = 0;
        _tagsWrapIsShow = false;
      });
  }
}
