import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:we_pei_yang_flutter/commons/util/font_manager.dart';
import 'package:we_pei_yang_flutter/commons/util/router_manager.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/feedback/network/post.dart';
import 'package:we_pei_yang_flutter/feedback/util/color_util.dart';
import 'package:we_pei_yang_flutter/feedback/network/feedback_service.dart';
import 'package:we_pei_yang_flutter/feedback/view/components/normal_comment_card.dart';
import 'package:we_pei_yang_flutter/feedback/view/report_question_page.dart';
import 'package:we_pei_yang_flutter/generated/l10n.dart';
import 'package:we_pei_yang_flutter/lounge/ui/widget/loading.dart';
import 'package:we_pei_yang_flutter/message/message_provider.dart';

import 'components/post_card.dart';

enum DetailPageStatus {
  loading,
  idle,
  error,
}

enum PostOrigin { home, profile, favorite, mailbox }

class DetailPage extends StatefulWidget {
  final Post post;

  DetailPage(this.post);

  @override
  _DetailPageState createState() => _DetailPageState(this.post);
}

class _DetailPageState extends State<DetailPage> {
  Post post;
  DetailPageStatus status;
  List<Floor> _commentList;
  int currentPage = 1, _totalPage = 1;

  var _refreshController = RefreshController(initialRefresh: false);

  _DetailPageState(this.post);

  _onRefresh() {
    _initPostAndComments(
      onSuccess: (comments) {
        _commentList = comments;
        _refreshController.refreshCompleted();
      },
      onFail: () {
        _refreshController.refreshFailed();
      },
    );
  }

  _onLoading() {
    if (currentPage != _totalPage) {
      currentPage++;
      _getComments(onSuccess: (comments) {
        _commentList.addAll(comments);
        _refreshController.loadComplete();
      }, onFail: () {
        _refreshController.loadFailed();
      });
    } else {
      _refreshController.loadNoData();
    }
  }

  @override
  void initState() {
    super.initState();
    status = DetailPageStatus.loading;
    _commentList = [];
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      /// 如果是从通知栏点进来的
      if (post == null) {
        _initPostAndComments(onSuccess: (comments) {
          _commentList.addAll(comments);
          setState(() {
            status = DetailPageStatus.idle;
          });
        }, onFail: () {
          setState(() {
            status = DetailPageStatus.error;
          });
        });
      } else {
        _getComments(onSuccess: (comments) {
          _commentList.addAll(comments);
          setState(() {
            status = DetailPageStatus.idle;
          });
        }, onFail: () {
          setState(() {
            status = DetailPageStatus.idle;
          });
        });
      }
    });
  }

  // 逻辑有点问题
  _initPostAndComments({Function(List<Floor>) onSuccess, Function onFail}) {
    _initPost(onFail).then((success) {
      if (success) {
        _getComments(
          onSuccess: onSuccess,
          onFail: onFail,
          current: 1,
        );
      }
    });
  }

  Future<bool> _initPost([Function onFail]) async {
    bool success = false;
    await FeedbackService.getPostById(
      id: post.id,
      onResult: (Post p) {
        post = p;
        Provider.of<MessageProvider>(context, listen: false)
            .setFeedbackQuestionRead(p.id);
        success = true;
      },
      onFailure: (e) {
        ToastProvider.error(e.error.toString());
        success = false;
        onFail?.call();
        return;
      },
    );
    return success;
  }

  _getComments(
      {Function(List<Floor>) onSuccess, Function onFail, int current}) {
    FeedbackService.getComments(
      id: post.id,
      page: current ?? currentPage,
      onSuccess: (comments, totalFloor) {
        _totalPage = (totalFloor / 10).floor();
        onSuccess?.call(comments);
        setState(() {});
      },
      onFailure: (e) {
        ToastProvider.error(e.error.toString());
        onFail?.call();
      },
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (status == DetailPageStatus.loading) {
      if (post == null) {
        body = Center(child: Loading());
      } else {
        body = ListView(
          children: [
            PostCard.detail(
              post,
              onLikePressed: (isLike, likeCount) {
                post.isLike = isLike;
                post.likeCount = likeCount;
              },
              onFavoritePressed: (isFav) {
                post.isFav = isFav;
              },
            ),
            SizedBox(
              height: 100,
              child: Center(child: Loading()),
            )
          ],
        );
      }
    } else if (status == DetailPageStatus.idle) {
      Widget mainList = ListView.builder(
        itemCount: _commentList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return PostCard.detail(
              post,
              onLikePressed: (isLike, likeCount) {
                post.isLike = isLike;
                post.likeCount = likeCount;
              },
              onFavoritePressed: (isCollect) {
                post.isFav = isCollect;
              },
            );
          }
          index--;
          ///TODO:由于新接口的官方回复和普通回复合在一起了，暂时不知道怎么处理，于是先把以前的删掉了，官方需要用—
          ///_officialCommentList,点赞注释了
          var data = _commentList[index];
          return NCommentCard(
            comment: data,
            commentFloor: index + 1,
            // likeSuccessCallback: (isLiked, count) {
            //   data.isLiked = isLiked;
            //   data.likeCount = count;
            // },
          );
        },
      );

      mainList = Expanded(
        child: SmartRefresher(
          physics: BouncingScrollPhysics(),
          controller: _refreshController,
          header: ClassicHeader(),
          footer: ClassicFooter(),
          enablePullDown: true,
          onRefresh: _onRefresh,
          enablePullUp: true,
          onLoading: _onLoading,
          child: mainList,
        ),
      );

      var inputField = CommentInputField(postId: post.id);

      body = Column(
        children: [mainList, inputField],
      );
    } else {
      body = Center(child: Text("error!", style: FontManager.YaHeiRegular));
    }

    var menuButton = IconButton(
      icon: Icon(Icons.more_horiz, size: 25, color: ColorUtil.boldTextColor),
      splashRadius: 20,
      onPressed: () {
        showMenu(
          context: context,

          /// 左侧间隔1000是为了离左面尽可能远，从而使popupMenu贴近右侧屏幕
          /// MediaQuery...top + kToolbarHeight是状态栏 + AppBar的高度
          // TODO 高度还需要 MediaQuery.of(context).padding.top 吗？
          position: RelativeRect.fromLTRB(1000, kToolbarHeight, 0, 0),
          items: <PopupMenuItem<String>>[
            new PopupMenuItem<String>(
              value: '举报',
              child: new Text(
                '举报',
                style: FontManager.YaHeiRegular.copyWith(
                  fontSize: 13,
                  color: ColorUtil.boldTextColor,
                ),
              ),
            ),
          ],
        ).then((value) {
          if (value == "举报") {
            Navigator.pushNamed(context, FeedbackRouter.report,
                arguments: ReportPageArgs(widget.post.id,true));
          }
        });
      },
    );

    var appBar = AppBar(
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: ColorUtil.mainColor),
        onPressed: () => Navigator.pop(context, post),
      ),
      actions: [menuButton],
      title: Text(
        S.current.feedback_detail,
        style: FontManager.YaHeiRegular.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: ColorUtil.boldTextColor,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      brightness: Brightness.light,
    );

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, post);
        return true;
      },
      child: Scaffold(
        appBar: appBar,
        body: body,
      ),
    );
  }
}

var shareChannel = MethodChannel("com.twt.service/share");

class CommentInputField extends StatefulWidget {
  final int postId;

  const CommentInputField({Key key, this.postId}) : super(key: key);

  @override
  _CommentInputFieldState createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  var _textEditingController = TextEditingController();
  String _commentLengthIndicator = '0/200';
  var _focusNode = FocusNode();

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget inputField = TextField(
      focusNode: _focusNode,
      controller: _textEditingController,
      maxLength: 200,
      decoration: InputDecoration(
        counterText: '',
        hintText: S.current.feedback_write_comment,
        suffix: Text(
          _commentLengthIndicator,
          style: FontManager.YaHeiRegular.copyWith(
            fontSize: 14,
            color: ColorUtil.lightTextColor,
          ),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(kToolbarHeight / 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        fillColor: ColorUtil.searchBarBackgroundColor,
        filled: true,
        isDense: true,
      ),
      onChanged: (text) {
        _commentLengthIndicator = '${text.characters.length}/200';
        setState(() {});
      },
      enabled: true,
      minLines: 1,
      maxLines: 10,
    );

    inputField = Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: inputField,
      ),
    );

    Widget commitButton = IconButton(
      icon: Icon(Icons.send),
      onPressed: () async {
        _focusNode.unfocus();
        if (_textEditingController.text.isNotEmpty) {
          _sendComment();
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [inputField, commitButton],
      ),
    );
  }

  _sendComment() {
    FeedbackService.sendComment(
      id: widget.postId,
      content: _textEditingController.text,
      onSuccess: () {
        _textEditingController.text = '';
        setState(() => _commentLengthIndicator = '0/200');
        // TODO: 暂时没想到什么好的办法来更新评论
        ToastProvider.success("评论成功");
      },
      onFailure: (e) => ToastProvider.error(
        e.error.toString(),
      ),
    );
  }
}
