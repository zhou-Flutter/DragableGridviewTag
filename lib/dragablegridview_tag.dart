import 'package:dragablegridview_tag/dragablegridview_flutter.dart';
import 'package:dragablegridview_tag/dragablegridviewbin.dart';
import 'package:dragablegridview_tag/single_touch_recognizer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

typedef CreateChild = Widget Function(int position);
typedef UnActivateClick = void Function(int index);
typedef EditChangeListener();

class DragableGridViewTag extends StatefulWidget {
  ///交叉轴每行间距
  final double crossAxisSpacing;

  ///主轴每行间距
  final double mainAxisSpacing;

  ///item的宽高比
  final double childAspectRatio;

  ///主轴一行的数量
  final int crossAxisCount;

  ///前几个 tag 固定
  final int fixedNum;

  /// tag
  final List<ItemBin> itemBins;

  ///GridView 左右外边距
  final double? sideMargin;

  /// 是否打开拖动
  final bool isOpenDragAble;

  ///动画时长
  final int animationDuration;

  /// 长按时长
  final int longPressDuration;

  /// 删除按钮
  final Widget? deleteIcon;

  ///编辑开关控制器，可通过点击按钮触发编辑
  final EditSwitchController? editSwitchController;

  ///未激活点击 一般做跳转处理
  final UnActivateClick? unActivateClick;

  /// child Widget
  final CreateChild child;

  /// 删除 Tag Widget
  final CreateChild deleteChild;

  /// 长按触发编辑状态，可监听状态来改变编辑按钮（编辑开关 ，通过按钮触发编辑）的状态
  final EditChangeListener? editChangeListener;

  /// 删除的tag
  final List<ItemBin> deleteItemBins;

  ///顶部编辑 按钮
  final Widget? topEditChild;

  ///中间view 的高
  final double? middleHight;

  /// 中间的view
  final Widget? middleChild;

  /// tag 右上角的添加icon
  final Widget? addIcon;

  DragableGridViewTag({
    required this.child,
    required this.deleteChild,
    required this.itemBins,
    required this.deleteItemBins,
    this.crossAxisCount: 4,
    this.childAspectRatio: 1.0,
    this.mainAxisSpacing: 0.0,
    this.crossAxisSpacing: 0.0,
    this.sideMargin: 0,
    this.fixedNum: 0,
    this.isOpenDragAble: false,
    this.animationDuration: 400,
    this.longPressDuration: 800,
    this.deleteIcon,
    this.editSwitchController,
    this.unActivateClick,
    this.editChangeListener,
    this.topEditChild,
    this.middleHight: 0,
    this.middleChild,
    this.addIcon,
    Key? key,
  }) : super(key: key);

  @override
  State<DragableGridViewTag> createState() => _DragableGridViewTagState();
}

class _DragableGridViewTagState extends State<DragableGridViewTag>
    with SingleTickerProviderStateMixin {
  /// 控制中间的view 和 底部view 的上下移动的动画
  late final AnimationController _controller;

  late Animation<double> animation;

  var offsetY = 0.0; //偏移量
  var offsetEnd = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this);
    animation = Tween(begin: 0.0, end: 1.0).animate(_controller)
      ..addListener(() {
        double animateValue = animation.value;
        setState(() {
          offsetY = offsetY + (offsetEnd - offsetY) * animateValue;
        });
      });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        offsetY = 0;
        setState(() {});
      }
    });
  }

  //开始位置动画
  setAnimate(e) {
    offsetEnd = e;
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SingleTouchRecognizerWidget(
      child: Column(
        children: [
          widget.topEditChild ?? Container(),
          DragAbleGridView(
            mainAxisSpacing: widget.mainAxisSpacing,
            crossAxisSpacing: widget.crossAxisSpacing,
            childAspectRatio: widget.childAspectRatio,
            crossAxisCount: widget.crossAxisCount,
            fixedNum: widget.fixedNum,
            sideMargin: widget.sideMargin,
            itemBins: widget.itemBins,
            deleteItemBins: widget.deleteItemBins,
            editSwitchController: widget.editSwitchController,
            isOpenDragAble: widget.isOpenDragAble,
            animationDuration: widget.animationDuration, //milliseconds
            longPressDuration: widget.longPressDuration, //milliseconds
            deleteIcon: widget.deleteIcon,
            middleHight: widget.middleHight,
            deleteIconClickListener: (e) {
              widget.deleteItemBins.add(ItemBin(widget.itemBins[e].data));
              setState(() {});
            },
            unActivateClick: widget.unActivateClick,
            child: widget.child,
            editChangeListener: widget.editChangeListener,
            animatedClick: (e) {
              setAnimate(e);
            },
          ),
          Container(
            transform: Matrix4.translationValues(0, offsetY, 0),
            child: Column(
              children: [
                widget.middleChild ?? Container(),
                DragAbleGridView(
                  mainAxisSpacing: widget.mainAxisSpacing,
                  crossAxisSpacing: widget.crossAxisSpacing,
                  childAspectRatio: widget.childAspectRatio,
                  crossAxisCount: widget.crossAxisCount,
                  sideMargin: widget.sideMargin,
                  itemBins: widget.deleteItemBins,
                  deleteItemBins: widget.itemBins,
                  middleHight: widget.middleHight,
                  isHideDeleteIcon: false,
                  isOpenDragAble: false,
                  animationDuration: widget.animationDuration, //milliseconds
                  longPressDuration: widget.longPressDuration, //milliseconds
                  deleteIcon: widget.addIcon,
                  deleteIconClickListener: (e) {
                    widget.itemBins.add(ItemBin(widget.deleteItemBins[e].data));
                    setState(() {});
                  },
                  child: widget.deleteChild,
                  animatedClick: (e) {
                    setAnimate(e);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ItemBin extends DragAbleGridViewBin {
  String data;
  ItemBin(this.data);
  @override
  String toString() {
    return 'ItemBin{data: $data, dragPointX: $dragPointX, dragPointY: $dragPointY, lastTimePositionX: $lastTimePositionX, lastTimePositionY: $lastTimePositionY, containerKey: $containerKey, containerKeyChild: $containerKeyChild, isLongPress: $isLongPress, dragAble: $dragAble}';
  }
}

class EditSwitchController {
  DragAbleGridViewState? dragAbleGridViewState;

  void editStateChanged() {
    dragAbleGridViewState!.changeDeleteIconState();
  }
}
