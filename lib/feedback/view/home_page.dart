import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:wei_pei_yang_demo/commons/util/toast_provider.dart';
import 'package:wei_pei_yang_demo/feedback/model/feedback_notifier.dart';
import 'package:wei_pei_yang_demo/feedback/util/color_util.dart';
import 'package:wei_pei_yang_demo/feedback/util/http_util.dart';
import 'package:wei_pei_yang_demo/feedback/util/feedback_router.dart';
import 'package:wei_pei_yang_demo/feedback/util/screen_util.dart';
import 'package:wei_pei_yang_demo/feedback/view/components/post_card.dart';
import 'package:wei_pei_yang_demo/feedback/view/detail_page.dart';
import 'package:wei_pei_yang_demo/lounge/ui/widget/loading.dart';
import 'package:wei_pei_yang_demo/message/feedback_badge_widget.dart';
import 'package:wei_pei_yang_demo/message/message_provider.dart';

class FeedbackHomePage extends StatefulWidget {
  @override
  _FeedbackHomePageState createState() => _FeedbackHomePageState();
}

enum FeedbackHomePageStatus {
  loading,
  idle,
  error,
}

class _FeedbackHomePageState extends State<FeedbackHomePage> {
  int currentPage = 1, totalPage = 1;
  FeedbackHomePageStatus status;

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  _onRefresh() {
    setState(() {
      status = FeedbackHomePageStatus.loading;
    });
    currentPage = 1;
    Provider.of<FeedbackNotifier>(context, listen: false).initHomePostList(
      (page) {
        setState(() {
          totalPage = page;
          status = FeedbackHomePageStatus.idle;
          _refreshController.refreshCompleted();
        });
      },
      () {
        setState(() {
          status = FeedbackHomePageStatus.error;
        });
      },
    );
  }

  _onLoading() {
    if (currentPage != totalPage) {
      currentPage++;
      getPosts(
        tagId: '',
        page: currentPage,
        onSuccess: (list, page) {
          totalPage = page;
          Provider.of<FeedbackNotifier>(context, listen: false).addHomePosts(list);
          _refreshController.loadComplete();
        },
        onFailure: () {
          _refreshController.loadFailed();
        },
      );
    } else {
      _refreshController.loadComplete();
    }
  }

  @override
  void initState() {
    currentPage = 1;
    status = FeedbackHomePageStatus.loading;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<FeedbackNotifier>(context, listen: false).initHomePostList(
        (page) {
          setState(() {
            totalPage = page;
            status = FeedbackHomePageStatus.idle;
          });
        },
        () {
          setState(() {
            status = FeedbackHomePageStatus.error;
          });
        },
      );
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await Provider.of<MessageProvider>(context,listen: false).refreshFeedbackCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Click and jump to NewPostPage.
      floatingActionButton: FloatingActionButton(
        backgroundColor: ColorUtil.mainColor,
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, FeedbackRouter.newPost);
        },
      ),
      body: Padding(
        padding: EdgeInsets.only(top: ScreenUtil.paddingTop),
        child: Consumer<FeedbackNotifier>(
          builder: (BuildContext context, notifier, Widget child) {
            return SmartRefresher(
              physics: BouncingScrollPhysics(),
              controller: _refreshController,
              header: ClassicHeader(),
              enablePullDown: true,
              onRefresh: _onRefresh,
              footer: ClassicFooter(),
              enablePullUp: currentPage != totalPage,
              onLoading: _onLoading,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(1080),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: '搜索问题',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(1080),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    fillColor:
                                        ColorUtil.searchBarBackgroundColor,
                                    filled: true,
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: ColorUtil.mainColor,
                                    ),
                                  ),
                                  enabled: false,
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                          context, FeedbackRouter.search)
                                      .then((value) async {
                                    if (value == true) {
                                      notifier.clearHomePostList();
                                      _onRefresh();
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            color: ColorUtil.mainColor,
                            icon: FeedbackBadgeWidget(
                              type: FeedbackMessageType.home,
                              child: Image.asset(
                                  'lib/feedback/assets/img/profile.png'),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                FeedbackRouter.profile,
                              );
                            },
                          )
                        ],
                      ),
                    ),

                    if (status == FeedbackHomePageStatus.loading)
                      Container(
                        padding: EdgeInsets.only(
                            top: ScreenUtil.screenHeight / 2 -
                                ScreenUtil.paddingTop -
                                AppBar().preferredSize.height),
                        child: Loading(),
                      ),

                    if (status == FeedbackHomePageStatus.error)
                      Container(
                        padding: EdgeInsets.only(
                            top: ScreenUtil.screenHeight / 2 -
                                ScreenUtil.paddingTop -
                                AppBar().preferredSize.height),
                        child: Text('加载失败咯...'),
                      ),

                    /// The list of posts.
                    if (status == FeedbackHomePageStatus.idle)
                      MediaQuery.removePadding(
                        removeTop: true,
                        context: context,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return notifier.homePostList[index].topImgUrl !=
                                        '' &&
                                    notifier.homePostList[index].topImgUrl !=
                                        null
                                ? PostCard.image(
                                    notifier.homePostList[index],
                                    onContentPressed: () {
                                      Navigator.pushNamed(
                                          context, FeedbackRouter.detail,
                                          arguments: DetailPageArgs(
                                              notifier.homePostList[index],
                                              index,
                                              PostOrigin.home));
                                    },
                                    onLikePressed: () {
                                      postHitLike(
                                        id: notifier.homePostList[index].id,
                                        isLiked: notifier
                                            .homePostList[index].isLiked,
                                        onSuccess: () {
                                          notifier
                                              .changeHomePostLikeState(index);
                                        },
                                        onFailure: () {
                                          ToastProvider.error('校务专区点赞失败，请重试');
                                        },
                                      );
                                    },
                                  )
                                : PostCard(
                                    notifier.homePostList[index],
                                    onContentPressed: () {
                                      Navigator.pushNamed(
                                          context, FeedbackRouter.detail,
                                          arguments: DetailPageArgs(
                                              notifier.homePostList[index],
                                              index,
                                              PostOrigin.home));
                                    },
                                    onLikePressed: () {
                                      postHitLike(
                                        id: notifier.homePostList[index].id,
                                        isLiked: notifier
                                            .homePostList[index].isLiked,
                                        onSuccess: () {
                                          notifier
                                              .changeHomePostLikeState(index);
                                        },
                                        onFailure: () {
                                          ToastProvider.error('校务专区点赞失败，请重试');
                                        },
                                      );
                                    },
                                  );
                          },
                          itemCount: notifier.homePostList.length,
                        ),
                      )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  HomeHeaderDelegate({@required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return this.child;
  }

  @override
  double get maxExtent => AppBar().preferredSize.height;

  @override
  double get minExtent => AppBar().preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}