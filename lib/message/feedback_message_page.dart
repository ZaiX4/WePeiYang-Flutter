import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_html_css/simple_html_css.dart';
import 'package:we_pei_yang_flutter/commons/util/text_util.dart';

import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/commons/util/font_manager.dart';
import 'package:we_pei_yang_flutter/feedback/feedback_router.dart';
import 'package:we_pei_yang_flutter/feedback/util/color_util.dart';
import 'package:we_pei_yang_flutter/generated/l10n.dart';
import 'package:we_pei_yang_flutter/lounge/provider/provider_widget.dart';
import 'package:we_pei_yang_flutter/lounge/ui/widget/loading.dart';
import 'package:we_pei_yang_flutter/message/message_service.dart';
import 'package:we_pei_yang_flutter/message/message_provider.dart';

enum MessageType {
  favor,
  contain,
  reply,
  lake
}

extension MessageTypeExtension on MessageType {
  String get name =>
      [S.current.like, S.current.comment, '校务回复', '湖底通知'][this.index];

  List<MessageType> get others {
    List<MessageType> result = [];
    MessageType.values.forEach((element) {
      if (element != this) result.add(element);
    });
    return result;
  }

  String get action {
    switch (this) {
      case MessageType.favor:
        return S.current.like_a_question;
      case MessageType.contain:
        return S.current.comment_a_question;
      case MessageType.reply:
        return S.current.reply_a_question;
      default:
        return "";
    }
  }

  int getMessageCount(MessageProvider model) {
    switch (this) {
      case MessageType.favor:
        return model.classifiedMessageCount?.favor ?? 0;
      case MessageType.contain:
        return model.classifiedMessageCount?.contain ?? 0;
      case MessageType.reply:
        return model.classifiedMessageCount?.reply ?? 0;
      default:
        return 0;
    }
  }
}

class FeedbackMessagePage extends StatefulWidget {
  @override
  _FeedbackMessagePageState createState() => _FeedbackMessagePageState();
}

class _FeedbackMessagePageState extends State<FeedbackMessagePage>
    with TickerProviderStateMixin {
  final List<MessageType> types = MessageType.values;

  TabController _tabController;

  ValueNotifier<int> currentIndex = ValueNotifier(2);
  ValueNotifier<int> refresh = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: types.length, vsync: this, initialIndex: 2);
  }

  onRefresh() {
    Provider.of<MessageProvider>(context, listen: false).refreshFeedbackCount();
    refresh.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff7f7f8),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppBar(
            titleSpacing: 0,
            leadingWidth: 25,
            brightness: Brightness.light,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              '消息中心',
              style: TextUtil.base.black2A.w500.NotoSansSC.sp(18)
            ),
            leading: IconButton(
              icon: Image.asset('assets/images/lake_butt_icons/back.png',width: 14),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: TabBar(
                tabs: types.map((t) {
                  return MessageTab(type: t);
                }).toList(),
                controller: _tabController,
                onTap: (index) {
                  currentIndex.value = _tabController.index;
                },
                indicator: CustomIndicator(
                  borderSide: BorderSide(
                    width: 3.5,
                    color: Color(0xff363c54),
                  ),
                ),
                labelPadding: const EdgeInsets.only(left: 8, right: 12),
                isScrollable: false,
                unselectedLabelColor: Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: types.map((t) {
          return MessagesList(type: t);
        }).toList(),
      ),
    );
  }
}

class MessageTab extends StatefulWidget {
  final MessageType type;

  const MessageTab({Key key, this.type}) : super(key: key);

  @override
  _MessageTabState createState() => _MessageTabState();
}

class _MessageTabState extends State<MessageTab> {
  _FeedbackMessagePageState pageState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pageState = context.findAncestorStateOfType<_FeedbackMessagePageState>();
  }

  @override
  Widget build(BuildContext context) {
    Widget tab = ValueListenableBuilder(
      valueListenable: pageState.currentIndex,
      builder: (_, int current, __) {
        return Text(
          widget.type.name,
          style: TextStyle(
            color: current == widget.type.index
                ? Color(0xff2a2a2a)
                : Color(0xffb1b2be),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Consumer<MessageProvider>(builder: (_, model, __) {
        var count = widget.type.getMessageCount(model);
        if (count.isZero) {
          return tab;
        } else {
          return Center(
            child: Badge(
              child: tab,
              badgeContent: Text(
                count.toString(),
                style: TextStyle(color: Colors.white, fontSize: 7),
              ),
            ),
          );
        }
      }),
    );
  }
}

class MessagesList extends StatefulWidget {
  final MessageType type;

  MessagesList({Key key, this.type}) : super(key: key);

  @override
  _MessagesListState createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList>
    with AutomaticKeepAliveClientMixin {
  List<FeedbackMessageItem> items = [];
  RefreshController _refreshController = RefreshController(
      initialRefresh: true, initialRefreshStatus: RefreshStatus.refreshing);

  onRefresh({bool refreshCount = true}) async {
    if (widget == null) return;
    // monitor network fetch
    try {
      var result = await MessageService.getDetailMessages(widget.type, 0);
      items.clear();
      items.addAll(
          result.data.where((element) => element.type == widget.type.index));
      if (mounted) {
        if (refreshCount) {
          Provider.of<MessageProvider>(context, listen: false)
              .refreshFeedbackCount();
        }
        setState(() {});
      }
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
    // if failed,use refreshFailed()
    // _refreshController.refreshCompleted();
  }

  _onLoading() async {
    try {
      var result = await MessageService.getDetailMessages(
          widget.type, items.length ~/ 10 + 2);
      items.addAll(
          result.data.where((element) => element.type == widget.type.index));
      if (mounted) setState(() {});
      if (result.data.isEmpty) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.loadFailed();
    }

    // if failed,use loadFailed(),if no data return,use LoadNodata()
    // items.add((items.length + 1).toString());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var list = await MessageService.getDetailMessages(widget.type, 0);
      items.addAll(list.data.where((element) {
        return element.type == widget.type.index;
      }));
      if (mounted) {
        Provider.of<MessageProvider>(context, listen: false)
            .refreshFeedbackCount();
        setState(() {});
        context
            .findAncestorStateOfType<_FeedbackMessagePageState>()
            .refresh
            .addListener(() => onRefresh(
                  refreshCount: false,
                ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget child;

    if (_refreshController.isRefresh) {
      child = Center(
        child: Loading(),
      );
    } else if (items.isEmpty) {
      child = Center(
        child: Text("无未读消息"),
      );
    } else {
      child = ListView.separated(
        physics: BouncingScrollPhysics(),
        itemBuilder: (c, i) {
          return MessageItem(
            data: items[i],
            onTapDown: items[i].visible.isOne
                ? () async {
                    try {
                      await MessageService.setQuestionRead(items[i].post.id);
                    } catch (e) {
                      ToastProvider.error("设置问题已读失败");
                    }
                  }
                : null,
            type: widget.type,
          );
        },
        separatorBuilder: (_, __) => Divider(
          indent: 20,
          endIndent: 20,
          thickness: 1,
          height: 3,
          color: Color(0xffacaeba),
        ),
        itemCount: items.length,
      );
    }

    return SmartRefresher(
      enablePullDown: true,
      enablePullUp: true,
      header: WaterDropHeader(),
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = Text(S.current.up_load);
          } else if (mode == LoadStatus.loading) {
            body = CupertinoActivityIndicator();
          } else if (mode == LoadStatus.failed) {
            body = Text(S.current.load_fail);
          } else if (mode == LoadStatus.canLoading) {
            body = Text(S.current.load_more);
          } else {
            body = Text(S.current.no_more_data);
          }
          return SizedBox(
            height: 55,
            child: Center(child: body),
          );
        },
      ),
      controller: _refreshController,
      onRefresh: onRefresh,
      onLoading: _onLoading,
      child: child,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class MessageItem extends StatelessWidget {
  final FeedbackMessageItem data;
  final VoidFutureCallBack onTapDown;
  final MessageType type;

  const MessageItem({Key key, this.data, this.onTapDown, this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget sender;
    switch (type) {
      case MessageType.reply:
        sender = Container(
          height: 20,
          width: (data.comment.adminName?.length ?? 3) * 17.0,
          child: Center(
            child: Text(
              "${data.comment.adminName ?? S.current.unknown_department}",
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          decoration: BoxDecoration(
              color: Color(0xff596385),
              borderRadius: BorderRadius.circular(10),
              shape: BoxShape.rectangle),
        );
        break;
      default:
        sender = Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.account_circle_outlined, size: 41),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${data.comment?.userName ?? S.current.anonymous_user}",
                      style: TextStyle(color: ColorUtil.boldLakeTextColor, fontSize: 18,fontWeight: FontWeight.bold),
                    ),
                    Text(
                      type.action,
                      style: TextStyle(color: Color(0xff434650), fontSize: 16,fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 1),
                Text(
                  data.updatedAt?.time ?? "",
                  style: TextStyle(color: Color(0xffb1b2be), fontSize: 12),
                ),
              ],
            ),
          ],
        );
    }

    Widget title = sender;

    Widget questionItem = Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(7),
        color: ColorUtil.backgroundColor,
        boxShadow: [
          BoxShadow(
              blurRadius: 5,
              color: Color.fromARGB(64, 236, 237, 239),
              offset: Offset.zero,
              spreadRadius: 3),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data.post.title,
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      color: Color(0xff363c54),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (data.post.imageUrls != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Image.network(
                      data.post.imageUrls[0],
                      fit: BoxFit.cover,
                      height: 50,
                      width: 70,
                    ),
                  ),
              ],
            ),
            // if (data.comment != null)
            //   Divider(thickness: 1, height: 15, color: Color(0xffacaeba)),
            if (data.comment != null)
              RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                text: HTML.toTextSpan(context, data.comment.content ?? "",
                    defaultTextStyle: FontManager.YaHeiRegular.copyWith(
                      color: Color(0xff363c54),
                      fontSize: 13,
                    )),
              ),
            SizedBox(height: 10),
            Row(
              children: [
                Image.asset("assets/images/account/comment.png", height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 10),
                  child: Text(
                    data.post.commentCount.toString(),
                    style: TextStyle(fontSize: 13, color: ColorUtil.grey108),
                  ),
                ),
                Image.asset("assets/images/account/thumb_up.png", height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 10),
                  child: Text(
                    data.post.likeCount.toString(),
                    style: TextStyle(fontSize: 13, color: ColorUtil.grey108),
                  ),
                ),
                Spacer(),
                Builder(
                  builder: (_) {
                    var isSolved = /*data.post.isSolved == */true;//TODO:等接口solve字段
                    return Text(
                      isSolved ? S.current.have_replied : S.current.not_reply,
                      style: TextStyle(
                          color:
                          isSolved ? Color(0xff434650) : ColorUtil.grey108,
                          fontSize: 13),
                    );
                  },
                )
              ],
            )
          ],
        ),
      ),
    );

    Widget messageWrapper;

    if (data.visible == 1) {
      messageWrapper = Badge(
        position: BadgePosition.topEnd(end: -2, top: -14),
        padding: const EdgeInsets.all(5),
        badgeContent: Text(""),
        child: questionItem,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: GestureDetector(
        onTap: () async {
          await onTapDown?.call();
          await Navigator.pushNamed(
            context,
            FeedbackRouter.detail,
            arguments: data.post,
          ).then((_) => context
              .findAncestorStateOfType<_FeedbackMessagePageState>()
              .onRefresh());
        },
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(7))
          ),
          child: Column(
            children: [
              title,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                child: messageWrapper ?? questionItem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String get time {
    var reg1 = RegExp(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}");
    var date = reg1.firstMatch(this)?.group(0) ?? "";
    var reg2 = RegExp(r"[0-9]{2}:[0-9]{2}");
    var time = reg2.firstMatch(this)?.group(0) ?? "";
    return "$date  $time";
  }
}

class CustomIndicator extends Decoration {
  const CustomIndicator({
    this.borderSide = const BorderSide(width: 2, color: Colors.white),
    this.insets = EdgeInsets.zero,
  })  : assert(borderSide != null),
        assert(insets != null);

  final BorderSide borderSide;

  final EdgeInsetsGeometry insets;

  @override
  Decoration lerpFrom(Decoration a, double t) {
    if (a is CustomIndicator) {
      return CustomIndicator(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        insets: EdgeInsetsGeometry.lerp(a.insets, insets, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  Decoration lerpTo(Decoration b, double t) {
    if (b is CustomIndicator) {
      return CustomIndicator(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        insets: EdgeInsetsGeometry.lerp(insets, b.insets, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  _UnderlinePainter createBoxPainter([VoidCallback onChanged]) {
    return _UnderlinePainter(this, onChanged);
  }

  Rect _indicatorRectFor(Rect rect, TextDirection textDirection) {
    assert(rect != null);
    assert(textDirection != null);
    final Rect indicator = insets.resolve(textDirection).deflateRect(rect);
    double wantWidth = 14;
    double cw = (indicator.left + indicator.right) / 2;

    return Rect.fromLTWH(
      cw - wantWidth / 2,
      indicator.bottom - borderSide.width,
      wantWidth,
      borderSide.width,
    );
  }

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) {
    return Path()..addRect(_indicatorRectFor(rect, textDirection));
  }
}

class _UnderlinePainter extends BoxPainter {
  _UnderlinePainter(this.decoration, VoidCallback onChanged)
      : assert(decoration != null),
        super(onChanged);

  final CustomIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size;
    final TextDirection textDirection = configuration.textDirection;
    final Rect indicator = decoration
        ._indicatorRectFor(rect, textDirection)
        .deflate(decoration.borderSide.width / 2);
    final Paint paint = decoration.borderSide.toPaint()
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(indicator.bottomLeft, indicator.bottomRight, paint);
  }
}
