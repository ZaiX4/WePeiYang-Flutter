import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:we_pei_yang_flutter/commons/util/text_util.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/commons/widgets/w_button.dart';
import 'package:we_pei_yang_flutter/commons/widgets/wpy_pic.dart';
import 'package:we_pei_yang_flutter/feedback/network/lost_and_found_post.dart';
import 'package:we_pei_yang_flutter/feedback/view/lost_and_found_page/lost_and_found_notifier.dart';
import '../../../main.dart';
import '../../feedback_router.dart';
import '../../util/color_util.dart';
import '../lake_home_page/lake_notifier.dart';
import 'lost_and_found_search_notifier.dart';

class LostAndFoundSubPage extends StatefulWidget {
  final String type;

  const LostAndFoundSubPage({Key? key, required this.type}) : super(key: key);

  @override
  LostAndFoundSubPageState createState() => LostAndFoundSubPageState();
}

double get searchBarHeight => 42.h;

class LostAndFoundSubPageState extends State<LostAndFoundSubPage> {
  final ScrollController _scrollController = ScrollController();
  void _onRefresh() async {
    context.read<LostAndFoundModel>().clearByType(widget.type);
    await context.read<LostAndFoundModel>().getNext(
          type: widget.type,
          success: () {
            context
                    .read<LostAndFoundModel>()
                    .lostAndFoundSubPageStatus[widget.type] =
                LostAndFoundSubPageStatus.ready;
            context
                .read<LostAndFoundModel>()
                .refreshController[widget.type]
                ?.refreshCompleted();
          },
          failure: (e) {
            context
                    .read<LostAndFoundModel>()
                    .lostAndFoundSubPageStatus[widget.type] =
                LostAndFoundSubPageStatus.error;
            context
                .read<LostAndFoundModel>()
                .refreshController[widget.type]
                ?.refreshFailed();
            ToastProvider.error(e.error.toString());
          },
          category:
              context.read<LostAndFoundModel>().currentCategory[widget.type]!,
        );
  }

  void _onLoading() async {
    await context.read<LostAndFoundModel>().getNext(
          type: widget.type,
          success: () {
            context
                    .read<LostAndFoundModel>()
                    .lostAndFoundSubPageStatus[widget.type] =
                LostAndFoundSubPageStatus.ready;
            context
                .read<LostAndFoundModel>()
                .refreshController[widget.type]
                ?.loadComplete();
          },
          failure: (e) {
            context
                    .read<LostAndFoundModel>()
                    .lostAndFoundSubPageStatus[widget.type] =
                LostAndFoundSubPageStatus.error;
            context
                .read<LostAndFoundModel>()
                .refreshController[widget.type]
                ?.loadFailed();
            ToastProvider.error(e.error.toString());
          },
          category:
              context.read<LostAndFoundModel>().currentCategory[widget.type]!,
        );
  }

  //用于计算时间差
  String _timeAgo(String dateTimeStr) {
    final year = int.parse(dateTimeStr.substring(0, 4));
    final month = int.parse(dateTimeStr.substring(4, 6));
    final day = int.parse(dateTimeStr.substring(6, 8));
    final hour = int.parse(dateTimeStr.substring(8, 10));
    final minute = int.parse(dateTimeStr.substring(10, 12));
    final second = int.parse(dateTimeStr.substring(12, 14));

    final dateTime = DateTime(year, month, day, hour, minute, second);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前发布';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前发布';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前发布';
    } else {
      return '${difference.inSeconds} 秒前发布';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context
                .read<LostAndFoundModel>()
                .lostAndFoundSubPageStatus[widget.type] ==
            LostAndFoundSubPageStatus.unload ||
        context
                .read<LostAndFoundModel>()
                .lostAndFoundSubPageStatus[widget.type] ==
            LostAndFoundSubPageStatus.error) _onRefresh();

    var searchBar = InkWell(
      onTap: (){
        context.read<LostAndFoundModel2>().currentType = widget.type;
        Navigator.pushNamed(context, FeedbackRouter.lostAndFoundSearch);
      },
      child: Container(
        height: searchBarHeight - 8,
        margin: EdgeInsets.fromLTRB(15, 8, 15, 0),
        decoration: BoxDecoration(
            color: ColorUtil.greyEAColor,
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
                              ? '天大不能没有微北洋'
                              : '#${data.recTag?.name}#',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle().grey6C.NotoSansSC.w400.sp(15),
                        ),
                      ),
                    ],
                  )),
          Spacer()
        ]),
      ),
    );

    return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            searchBar,
            SizedBox(
              height: 7,
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: 8.h),
              child: Selector<LostAndFoundModel, String>(
                selector: (context, model) {
                  return model.currentCategory[widget.type]!;
                },
                builder: (context, category, _) {
                  return Flex(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    direction: Axis.horizontal,
                    children: <Widget>[
                      Expanded(
                        child:
                            LostAndFoundTag(category: '全部', type: widget.type),
                        flex: 4,
                      ),
                      Expanded(
                        child: LostAndFoundTag(
                            category: '生活日用', type: widget.type),
                        flex: 5,
                      ),
                      Expanded(
                        child: LostAndFoundTag(
                            category: '数码产品', type: widget.type),
                        flex: 5,
                      ),
                      Expanded(
                        child: LostAndFoundTag(
                            category: '钱包卡证', type: widget.type),
                        flex: 5,
                      ),
                      Expanded(
                        child:
                            LostAndFoundTag(category: '其他', type: widget.type),
                        flex: 4,
                      ),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsetsDirectional.only(start: 17.w, end: 17.w),
                child: Selector<LostAndFoundModel, List<LostAndFoundPost>>(
                    selector: (context, model) {
                  return model.postList[widget.type]!.toList();
                }, builder: (context, postList, _) {
                  return SmartRefresher(
                    enablePullDown: true,
                    enablePullUp: true,
                    header: ClassicHeader(
                      idleText: '下拉以刷新 (乀*･ω･)乀',
                      releaseText: '下拉以刷新',
                      refreshingText: "正在刷新喵",
                      completeText: '刷新完成 (ﾉ*･ω･)ﾉ',
                      failedText: '刷新失败（；´д｀）ゞ',
                    ),
                    controller: context
                        .read<LostAndFoundModel>()
                        .refreshController[widget.type]!,
                    footer: ClassicFooter(
                      idleText: '下拉以刷新',
                      noDataText: '无数据',
                      loadingText: '加载中，请稍等  ;P',
                      failedText: '加载失败（；´д｀）ゞ',
                    ),
                    onRefresh: _onRefresh,
                    onLoading: _onLoading,
                    //使用StaggeredGridView.countBuilder构造瀑布流
                    child: StaggeredGridView.countBuilder(
                      controller: _scrollController,
                      crossAxisCount: 2,
                      itemCount: postList.length,
                      itemBuilder: (BuildContext context, int index) => InkWell(
                          onTap: () {},
                          child: Card(
                            margin: const EdgeInsets.all(16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: const BorderSide(
                                  color: Colors.transparent, width: 0.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                postList[index].coverPhotoPath == null
                                    ? SizedBox(
                                        width: double.infinity,
                                        child: Card(
                                          child: Text(
                                            postList[index].text,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff898989),
                                            ),
                                          ),
                                          elevation: 0,
                                          color: Color(0xfff8f8f8),
                                        ))
                                    : Container(child: LayoutBuilder(
                                        builder: (context, constrains) {
                                          final maxWidth =
                                              constrains.constrainWidth();
                                          final width = postList[index]
                                                  .coverPhotoSize
                                                  ?.width
                                                  .toDouble() ??
                                              1;
                                          final height = postList[index]
                                                  .coverPhotoSize
                                                  ?.height
                                                  .toDouble() ??
                                              0;
                                          return Container(
                                            child: WpyPic(
                                              postList[index].coverPhotoPath!,
                                              withHolder: false,
                                              holderHeight:
                                                  height * maxWidth / width,
                                              width: width,
                                            ),
                                            height: height >= 3 * width
                                                ? 3 * maxWidth
                                                : height * maxWidth / width,
                                          );
                                        },
                                      )),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    postList[index].title,
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text(
                                        _timeAgo(
                                            postList[index].detailedUploadTime),
                                        style: TextStyle(
                                          color: Color(0xff898989),
                                        ),
                                      ),
                                      Row(
                                        children: <Widget>[
                                          SvgPicture.asset(
                                              'assets/images/icon_flame.svg',
                                              width: 16.0,
                                              height: 16.0),
                                          Text(
                                            '${postList[index].hot.toString()}',
                                            style: TextStyle(
                                              color: Color(0xff898989),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                      staggeredTileBuilder: (int index) =>
                          const StaggeredTile.fit(1),
                    ),
                  );
                }),
              ),
            )
          ],
        ));
  }
}

class LostAndFoundTag extends StatefulWidget {
  final String type;
  final String category;
  const LostAndFoundTag({
    Key? key,
    required this.type,
    required this.category,
  }) : super(key: key);

  @override
  LostAndFoundTagState createState() => LostAndFoundTagState();
}

class LostAndFoundTagState extends State<LostAndFoundTag> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, right: 8.w),
      child: WButton(
        onPressed: () async {
          context
              .read<LostAndFoundModel>()
              .resetCategory(type: widget.type, category: widget.category);
          context.read<LostAndFoundModel>().clearByType(widget.type);
          await context.read<LostAndFoundModel>().getNext(
                type: widget.type,
                success: () {
                  context
                          .read<LostAndFoundModel>()
                          .lostAndFoundSubPageStatus[widget.type] =
                      LostAndFoundSubPageStatus.ready;
                  context
                      .read<LostAndFoundModel>()
                      .refreshController[widget.type]
                      ?.refreshCompleted();
                },
                failure: (e) {
                  context
                          .read<LostAndFoundModel>()
                          .lostAndFoundSubPageStatus[widget.type] =
                      LostAndFoundSubPageStatus.error;
                  context
                      .read<LostAndFoundModel>()
                      .refreshController[widget.type]
                      ?.refreshFailed();
                  ToastProvider.error(e.error.toString());
                },
                category: context
                    .read<LostAndFoundModel>()
                    .currentCategory[widget.type]!,
              );
        },
        child: Container(
          height: 30.w,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: widget.category ==
                      context
                          .read<LostAndFoundModel>()
                          .currentCategory[widget.type]
                  ? Color.fromARGB(255, 234, 243, 254)
                  : Color.fromARGB(248, 248, 248, 248)),
          child: Center(
            child: Text(widget.category,
                style: widget.category ==
                        context
                            .read<LostAndFoundModel>()
                            .currentCategory[widget.type]
                    ? TextUtil.base.normal.NotoSansSC.w400.sp(8.5.sp).blue2C
                    : TextUtil.base.normal.NotoSansSC.w400.sp(8.5.sp).black2A),
          ),
        ),
      ),
    );
  }
}
