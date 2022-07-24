import 'dart:async';

import 'package:dragablegridview_tag/dragablegridview_tag.dart';
import 'package:dragablegridview_tag/dragablegridviewbin.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vibration/vibration.dart';

typedef CreateChild = Widget Function(int position);
typedef EditChangeListener();
typedef DeleteIconClickListener = void Function(int index);

typedef UnActivateClick = void Function(int index);
typedef AnimatedClick = void Function(double index);

///准备修改的大纲：3.要适配2-3个文字
class DragAbleGridView<T extends DragAbleGridViewBin> extends StatefulWidget {
  final CreateChild child;
  final List<T> itemBins;

  ///GridView一行显示几个child
  final int crossAxisCount;

  ///为了便于计算 Item之间的空隙都用crossAxisSpacing
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  //cross-axis to the main-axis
  final double childAspectRatio;

  ///编辑开关控制器，可通过点击按钮触发编辑
  final EditSwitchController? editSwitchController;

  ///长按触发编辑状态，可监听状态来改变编辑按钮（编辑开关 ，通过按钮触发编辑）的状态
  final EditChangeListener? editChangeListener;
  final bool isOpenDragAble;
  final int animationDuration;
  final int longPressDuration;
  final bool? isHideDeleteIcon;

  ///固定前几个标签
  final int? fixedNum;

  ///GridView 左右外边距
  final double? sideMargin;

  ///删除按钮
  final Widget? deleteIcon;
  final DeleteIconClickListener? deleteIconClickListener;

  /// 标签未激活时的点击 一般做点击跳转处理
  final UnActivateClick? unActivateClick;

  /// 两个GridView 中间的距离
  final double? middleHight;

  // 删除后的item
  final List<T> deleteItemBins;

  /// 动画回调
  final AnimatedClick? animatedClick;

  DragAbleGridView({
    required this.child,
    required this.itemBins,
    required this.deleteItemBins,
    this.crossAxisCount: 4,
    this.childAspectRatio: 1.0,
    this.mainAxisSpacing: 0.0,
    this.crossAxisSpacing: 0.0,
    this.editSwitchController,
    this.editChangeListener,
    this.isOpenDragAble: false,
    this.animationDuration: 400,
    this.longPressDuration: 800,
    this.deleteIcon,
    this.deleteIconClickListener,
    this.isHideDeleteIcon: true,
    this.fixedNum: 0,
    this.sideMargin: 0,
    this.unActivateClick,
    this.animatedClick,
    this.middleHight: 0,
  }) : assert(
          child != null,
          itemBins != null,
        );

  @override
  State<StatefulWidget> createState() {
    return new DragAbleGridViewState<T>();
  }
}

class DragAbleGridViewState<T extends DragAbleGridViewBin>
    extends State<DragAbleGridView>
    with TickerProviderStateMixin
    implements DragAbleViewListener {
  var physics = new ScrollPhysics();
  double? screenWidth;
  double? screenHeight;

  ///在拖动过程中Item position 的位置记录
  List<int>? itemPositions;

  ///下面4个变量具体看onTapDown（）方法里面的代码，有具体的备注
  double itemWidth = 0.0;
  double itemHeight = 0.0;
  double itemWidthChild = 0.0;
  double itemHeightChild = 0.0;

  ///下面2个变量具体看onTapDown（）方法里面的代码，有具体的备注
  double blankSpaceHorizontal = 0.0;
  double blankSpaceVertical = 0.0;
  double xBlankPlace = 0.0;
  double yBlankPlace = 0.0;

  Animation<double>? animation; //排序移动的动画
  Animation<double>? animation1; //拖拽后的归位动画
  Animation<double>? animation2; //点击tag (添加和删除) 位移的动画

  AnimationController? controller;
  AnimationController? controller1;
  AnimationController? controller2;

  int? startPosition;
  int? endPosition;
  bool isRest = false;

  ///覆盖超过1/5则触发动画，宽和高只要有一个满足就可以触发
  //double areaCoverageRatio=1/5;
  Timer? timer;
  bool isRemoveItem = false;
  bool isHideDeleteIcon = true;
  Future? _future;
  double xyDistance = 0.0;
  double yDistance = 0.0;
  double xDistance = 0.0;
  //拖拽的 index
  int? drawIndex;
  //删除index
  int? deleteIndex;

  @override
  void initState() {
    super.initState();
    isHideDeleteIcon = widget.isHideDeleteIcon ?? true;
    widget.editSwitchController?.dragAbleGridViewState = this;

    controller = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this);

    animation = new Tween(begin: 0.0, end: 1.0).animate(controller!)
      ..addListener(() {
        T offsetBin;
        int childWidgetPosition;

        if (isRest) {
          if (startPosition! > endPosition!) {
            for (int? i = endPosition; i! < startPosition!; i++) {
              childWidgetPosition = itemPositions![i];
              offsetBin = widget.itemBins[childWidgetPosition] as T;
              //图标向右 下移动
              if ((i + 1) % widget.crossAxisCount == 0) {
                offsetBin.lastTimePositionX = -(screenWidth! - itemWidth) * 1 +
                    offsetBin.lastTimePositionX;
                offsetBin.lastTimePositionY =
                    (itemHeight + widget.mainAxisSpacing) * 1 +
                        offsetBin.lastTimePositionY;
              } else {
                offsetBin.lastTimePositionX =
                    (itemWidth + widget.crossAxisSpacing) * 1 +
                        offsetBin.lastTimePositionX;
              }
            }
          } else {
            for (int? i = startPosition! + 1; i! <= endPosition!; i++) {
              childWidgetPosition = itemPositions![i];
              offsetBin = widget.itemBins[childWidgetPosition] as T;
              //图标向左 上移动
              if (i % widget.crossAxisCount == 0) {
                offsetBin.lastTimePositionX = (screenWidth! - itemWidth) * 1 +
                    offsetBin.lastTimePositionX;
                offsetBin.lastTimePositionY =
                    -(itemHeight + widget.mainAxisSpacing) * 1 +
                        offsetBin.lastTimePositionY;
              } else {
                offsetBin.lastTimePositionX =
                    -(itemWidth + widget.crossAxisSpacing) * 1 +
                        offsetBin.lastTimePositionX;
              }
            }
          }
          return;
        }
        double animationValue = animation!.value;

        //此代码和上面的代码一样，但是不能提成方法调用 ，已经测试调用方法不会生效
        //startPosition大于endPosition表明目标位置在上方，图标需要向后退一格
        if (startPosition! > endPosition!) {
          for (int? i = endPosition; i! < startPosition!; i++) {
            childWidgetPosition = itemPositions![i];
            offsetBin = widget.itemBins[childWidgetPosition] as T;
            //图标向左 下移动；如果图标处在最右侧，那需要向下移动一层，移动到下一层的最左侧，（开头的地方）
            if ((i + 1) % widget.crossAxisCount == 0) {
              setState(() {
                offsetBin.dragPointX =
                    -xyDistance * animationValue + offsetBin.lastTimePositionX;
                offsetBin.dragPointY =
                    yDistance * animationValue + offsetBin.lastTimePositionY;
              });
            } else {
              setState(() {
                //↑↑↑如果图标不是处在最右侧，只需要向右移动即可
                offsetBin.dragPointX =
                    xDistance * animationValue + offsetBin.lastTimePositionX;
              });
            }
          }
        }
        //当目标位置在下方时 ，图标需要向前前进一个
        else {
          for (int i = startPosition! + 1; i <= endPosition!; i++) {
            childWidgetPosition = itemPositions![i];
            offsetBin = widget.itemBins[childWidgetPosition] as T;
            //图标向右 上移动；如果图标处在最左侧，那需要向上移动一层
            if (i % widget.crossAxisCount == 0) {
              setState(() {
                offsetBin.dragPointX =
                    xyDistance * animationValue + offsetBin.lastTimePositionX;
                offsetBin.dragPointY =
                    -yDistance * animationValue + offsetBin.lastTimePositionY;
              });
            } else {
              setState(() {
                //↑↑↑如果图标不是处在最左侧，只需要向左移动即可
                offsetBin.dragPointX =
                    -xDistance * animationValue + offsetBin.lastTimePositionX;
              });
            }
          }
        }
      });
    animation?.addStatusListener((animationStatus) {
      if (animationStatus == AnimationStatus.completed) {
        setState(() {});
        isRest = true;
        controller?.reset();
        isRest = false;

        if (isRemoveItem) {
          isRemoveItem = false;
          itemPositions!.removeAt(startPosition!);
          onPanEndEvent(startPosition!, isRemove: true);
        } else {
          int dragPosition = itemPositions![startPosition!];
          itemPositions?.removeAt(startPosition!);
          itemPositions?.insert(endPosition!, dragPosition);
          //手指未抬起来（可能会继续拖动），这时候end的位置等于Start的位置
          startPosition = endPosition;
        }
      } else if (animationStatus == AnimationStatus.forward) {}
    });
    _initItemPositions();
    _tagUpdateAnimate();
    _homingAnimate();
  }

  ///被拖拽的 tag 归位动画
  _homingAnimate() {
    controller1 = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this);

    animation1 = new Tween(begin: 0.0, end: 1.0).animate(controller1!)
      ..addListener(() {
        double animatevalue = animation1!.value;

        setState(() {
          if ((drawIndex! / 4).floor() == (endPosition! / 4).floor()) {
            widget.itemBins[drawIndex!].dragPointX =
                (widget.itemBins[drawIndex!].dragPointX +
                    (-widget.itemBins[endPosition!].dragPointX *
                                (drawIndex! - endPosition!).abs() -
                            (widget.itemBins[drawIndex!].dragPointX)) *
                        animatevalue);

            widget.itemBins[drawIndex!].dragPointY =
                (widget.itemBins[drawIndex!].dragPointY +
                    (-widget.itemBins[endPosition!].dragPointY *
                                (drawIndex! - endPosition!).abs() -
                            (widget.itemBins[drawIndex!].dragPointY)) *
                        animatevalue);
          } else {
            // Y轴移动 moveY 行
            var moveY = (drawIndex! / 4).floor() - (endPosition! / 4).floor();
            // X轴移动 moveX 列
            var moveX = -((drawIndex! - (4 * moveY)) - endPosition!);

            widget.itemBins[drawIndex!].dragPointX = (widget
                    .itemBins[drawIndex!].dragPointX +
                (xDistance * moveX - (widget.itemBins[drawIndex!].dragPointX)) *
                    animatevalue);

            widget.itemBins[drawIndex!].dragPointY =
                (widget.itemBins[drawIndex!].dragPointY +
                    (-yDistance * moveY -
                            (widget.itemBins[drawIndex!].dragPointY)) *
                        animatevalue);
          }
        });
      });

    animation1?.addStatusListener((animationStatus) {
      if (animationStatus == AnimationStatus.completed) {
        controller1?.reset();
        setState(() {
          List<T> itemBi = [];
          T bin;
          for (int i = 0; i < itemPositions!.length; i++) {
            bin = widget.itemBins[itemPositions![i]] as T;
            bin.dragPointX = 0.0;
            bin.dragPointY = 0.0;
            bin.lastTimePositionX = 0.0;
            bin.lastTimePositionY = 0.0;
            itemBi.add(bin);
          }
          widget.itemBins.clear();
          widget.itemBins.addAll(itemBi);
          _initItemPositions();
        });
      }
    });
  }

  ///点击tag (添加和删除) 位移的动画
  void _tagUpdateAnimate() {
    controller2 = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this);

    animation2 = new Tween(begin: 0.0, end: 1.0).animate(controller2!)
      ..addListener(() {
        double animatevalue = animation2!.value;
        setState(() {
          var deletePosition = widget.deleteItemBins.length;

          //初始位置
          int sumY = (widget.itemBins.length / 4).ceil(); //总行数
          int Y = ((deleteIndex! + 1) / 4).ceil(); //第几行
          int X = deleteIndex! % 4 + 1; //第几列

          //目标位置
          int delx = (deletePosition % 4) + 1; //第几列
          int dely = ((deletePosition + 1) / 4).ceil(); //第几行

          if (widget.isOpenDragAble) {
            // 移动到删除的位置 向下移动

            //偏移坐标，相对于 可拖动YX 的
            int pX = delx - X;
            int pY = sumY - Y + dely;

            //判断是否少一行
            var h = widget.itemBins.length % 4;
            if (h == 1) {
              pY = sumY - Y + dely - 1;
            }

            double moveX = pX * xDistance;
            double moveY =
                (pY * yDistance + widget.middleHight! - widget.mainAxisSpacing);

            widget.itemBins[deleteIndex!].dragPointX =
                widget.itemBins[deleteIndex!].dragPointX +
                    (moveX - widget.itemBins[deleteIndex!].dragPointX) *
                        animatevalue;
            widget.itemBins[deleteIndex!].dragPointY =
                widget.itemBins[deleteIndex!].dragPointY +
                    (moveY - widget.itemBins[deleteIndex!].dragPointY) *
                        animatevalue;
          } else {
            // 向上移动

            //偏移坐标
            int pX = delx - X;
            int pY = Y;

            // 偏移距离
            double moveX = pX * xDistance;
            double moveY =
                (pY * yDistance + widget.middleHight! - widget.mainAxisSpacing);

            widget.itemBins[deleteIndex!].dragPointX =
                widget.itemBins[deleteIndex!].dragPointX +
                    (moveX - widget.itemBins[deleteIndex!].dragPointX) *
                        animatevalue;
            widget.itemBins[deleteIndex!].dragPointY =
                widget.itemBins[deleteIndex!].dragPointY -
                    (moveY + widget.itemBins[deleteIndex!].dragPointY) *
                        animatevalue;
          }
        });
      });
    animation2?.addStatusListener((animationStatus) {
      if (animationStatus == AnimationStatus.completed) {
        controller2?.reset();
        if (isRemoveItem) {
          widget.deleteIconClickListener!(deleteIndex!);
        }
      }
    });
  }

  void _initItemPositions() {
    itemPositions = [];
    for (int i = 0; i < widget.itemBins.length; i++) {
      itemPositions?.add(i);
    }
  }

  @override
  void didUpdateWidget(DragAbleGridView<DragAbleGridViewBin> oldWidget) {
    if (itemPositions?.length != widget.itemBins.length) {
      _initItemPositions();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Size screenSize = MediaQuery.of(context).size;
    screenWidth = screenSize.width - 40;
    screenHeight = screenSize.height;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.sideMargin!),
      child: GridView.builder(
        clipBehavior: Clip.none,
        physics: physics,
        scrollDirection: Axis.vertical,
        itemCount: widget.itemBins.length,
        shrinkWrap: true,
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: widget.childAspectRatio,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing),
        itemBuilder: (BuildContext contexts, int index) {
          if (index >= widget.fixedNum!) {
            return DragAbleContentView(
              isOpenDragAble: widget.isOpenDragAble,
              screenHeight: screenHeight!,
              screenWidth: screenWidth!,
              isHideDeleteIcon: isHideDeleteIcon,
              controller: controller!,
              longPressDuration: widget.longPressDuration,
              index: index,
              dragAbleGridViewBin: widget.itemBins[index],
              dragAbleViewListener: this,
              unActivateClick: widget.unActivateClick,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  widget.child(index),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Offstage(
                      offstage: isHideDeleteIcon,
                      child:
                          widget.deleteIcon ?? Container(height: 0, width: 0),
                    ),
                  )
                ],
              ),
            );
          } else {
            return Center(
              child: GestureDetector(
                onTap: isHideDeleteIcon == true
                    ? () {
                        widget.unActivateClick == null
                            ? null
                            : widget.unActivateClick!(index);
                      }
                    : null,
                child: widget.child(index),
              ),
            );
          }
        },
      ),
    );
  }

  ///如果item的大小都不一样大，那每次拖动前都必须计算item的相关尺寸
  @override
  void getWidgetsSize(DragAbleGridViewBin pressItemBin) {
    if (itemWidth == 0) {
      //获取 不 带边框的Container的宽度
      itemWidth = pressItemBin.containerKey.currentContext!
          .findRenderObject()!
          .paintBounds
          .size
          .width;
    }
    if (itemHeight == 0) {
      itemHeight = pressItemBin.containerKey.currentContext!
          .findRenderObject()!
          .paintBounds
          .size
          .height;
    }

    if (itemWidthChild == 0) {
      //获取  带边框 的Container的宽度，就是可见的Item视图的宽度
      itemWidthChild = pressItemBin.containerKeyChild.currentContext!
          .findRenderObject()!
          .paintBounds
          .size
          .width;
    }
    if (itemHeightChild == 0) {
      itemHeightChild = pressItemBin.containerKeyChild.currentContext!
          .findRenderObject()!
          .paintBounds
          .size
          .height;
    }

    if (blankSpaceHorizontal == 0) {
      //获取 不带边框  和它的子View （带边框 的Container）左右两边的空白部分的宽度
      blankSpaceHorizontal = (itemWidth - itemWidthChild) / 2;
    }

    if (blankSpaceVertical == 0) {
      blankSpaceVertical = (itemHeight - itemHeightChild) / 2;
    }

    if (xBlankPlace == 0) {
      //边框和父布局之间的空白部分  +  gridView Item之间的space   +  相邻Item边框和父布局之间的空白部分
      //所以 一个View和相邻View空白的部分计算如下 ，也就是说大于这个值 两个Item则能相遇叠加
      xBlankPlace = blankSpaceHorizontal * 2 + widget.crossAxisSpacing;
    }

    if (yBlankPlace == 0) {
      yBlankPlace = blankSpaceVertical * 2 + widget.mainAxisSpacing;
    }

    if (xyDistance == 0) {
      xyDistance = screenWidth! - itemWidth;
    }

    if (yDistance == 0) {
      yDistance = itemHeight + widget.mainAxisSpacing;
    }

    if (xDistance == 0) {
      xDistance = itemWidth + widget.crossAxisSpacing;
    }
  }

  int geyXTransferItemCount(int index, double xBlankPlace, double dragPointX) {
    //最大边界 和 最小边界
    //double maxBoundWidth = itemWidthChild * (1-areaCoverageRatio);
    //double minBoundWidth = itemWidthChild * areaCoverageRatio;

    //是否越过空白间隙，未越过则表示在原地，或覆盖自己原位置的一部分，未拖动到其他Item上，或者已经拖动过多次现在又拖回来了；越过则有多种情况
    if (dragPointX.abs() > xBlankPlace) {
      if (dragPointX > 0) {
        //↑↑↑表示移动到自己原位置的右手边
        return checkXAxleRight(index, xBlankPlace, dragPointX);
      } else {
        //↑↑↑表示移动到自己原位置的左手边
        return checkXAxleLeft(index, xBlankPlace, dragPointX);
      }
    } else {
      //↑↑↑连一个空白的区域都未越过 肯定是呆在自己的原位置，返回index
      return 0;
    }
  }

  ///当被拖动到自己位置右侧时
  int checkXAxleRight(int index, double xBlankPlace, double dragPointX) {
    double aSection = xBlankPlace + itemWidthChild;

    double rightTransferDistance = dragPointX.abs() + itemWidthChild;
    //计算左右边框的余数
    double rightBorder = rightTransferDistance % aSection;
    double leftBorder = dragPointX.abs() % aSection;

    //与2个item有粘连时，计算占比多的就是要目标位置
    if (rightBorder < itemWidthChild && leftBorder < itemWidthChild) {
      if (itemWidthChild - leftBorder > rightBorder) {
        //left占比多，那左侧未将要动画的目标位置
        return (dragPointX.abs() / aSection).floor();
      } else {
        //right占比多
        return (rightTransferDistance / aSection).floor();
      }
    } else if (rightBorder > itemWidthChild && leftBorder < itemWidthChild) {
      //left粘连，右边的边框在空白区域
      return (dragPointX.abs() / aSection).floor();
    } else if (rightBorder < itemWidthChild && leftBorder > itemWidthChild) {
      //right粘连，左侧的边框在空白区域
      return (rightTransferDistance / aSection).floor();
    } else {
      //左右两边均没有粘连时，说明左右两边处于空白区域，返回0即可
      return 0;
    }
  }

  ///X轴方向上，当被拖动到自己位置左侧时
  int checkXAxleLeft(int index, double xBlankPlace, double dragPointX) {
    double aSection = xBlankPlace + itemWidthChild;

    double leftTransferDistance = dragPointX.abs() + itemWidthChild;

    //计算左右边框的余数
    double leftBorder = leftTransferDistance % aSection;
    double rightBorder = dragPointX.abs() % aSection;

    //与2个item有粘连时，计算占比多的就是要目标位置
    if (rightBorder < itemWidthChild && leftBorder < itemWidthChild) {
      if (itemWidthChild - rightBorder > leftBorder) {
        //right占比多，那右侧为将要动画的目标位置
        return -(dragPointX.abs() / aSection).floor();
      } else {
        //left占比多
        return -(leftTransferDistance / aSection).floor();
      }
    } else if (rightBorder > itemWidthChild && leftBorder < itemWidthChild) {
      //left粘连，右边的边框在空白区域
      return -(leftTransferDistance / aSection).floor();
    } else if (rightBorder < itemWidthChild && leftBorder > itemWidthChild) {
      //right粘连，左侧的边框在空白区域
      return -(dragPointX.abs() / aSection).floor();
    } else {
      //左右两边均没有粘连时，说明左右两边处于空白区域，返回0即可
      return 0;
    }
  }

  ///计算Y轴方向需要移动几个Item
  /// 1. 目标拖动距离拖动不满足， 2. 拖动到其他Item的，3. 和任何Item都没有粘连，5.和多个item有重叠 等4种情况
  /// 还要考虑一点就是 虽然Y轴不满足1/5--4/5覆盖率，但是X轴满足
  int geyYTransferItemCount(int index, double yBlankPlace, double dragPointY) {
    //最大边界 和 最小边界
    //double maxBoundHeight = itemHeightChild * (1-areaCoverageRatio);
    //double minBoundHeight = itemHeightChild * areaCoverageRatio;

    //上下边框是否都满足 覆盖1/5--4/5高度的要求
    //bool isTopBoundLegitimate = topBorder > minBoundHeight && topBorder < maxBoundHeight;
    //bool isBottomBoundLegitimate = bottomBorder > minBoundHeight && bottomBorder < maxBoundHeight;

    //是否越过空白间隙，未越过则表示在原地，或覆盖自己原位置的一部分，未拖动到其他Item上，或者已经拖动过多次现在又拖回来了；越过则有多种情况
    if (dragPointY.abs() > yBlankPlace) {
      //↑↑↑越过则有多种情况↓↓↓
      if (dragPointY > 0) {
        //↑↑↑表示拖动的Item现在处于原位置之下
        return checkYAxleBelow(index, yBlankPlace, dragPointY);
      } else {
        //↑↑↑表示拖动的Item现在处于原位置之上
        return checkYAxleAbove(index, yBlankPlace, dragPointY);
      }
    } else {
      //↑↑↑未越过 返回index
      return index;
    }
  }

  ///Y轴上当被拖动到原位置之上时，计算拖动了几行
  int checkYAxleAbove(int index, double yBlankPlace, double dragPointY) {
    double aSection = yBlankPlace + itemHeightChild;

    double topTransferDistance = dragPointY.abs() + itemHeightChild;

    //求下边框的余数，余数小于itemHeightChild，表示和下面的item覆盖，余数大于itemHeightChild，表示下边框处于空白的区域
    double topBorder = (topTransferDistance) % aSection;
    //求上边框的余数 ，余数小于itemHeightChild，表示和上面的Item覆盖 ，余数大于itemHeightChild，表示上边框处于空白区域
    double bottomBorder = dragPointY.abs() % aSection;

    if (topBorder < itemHeightChild && bottomBorder < itemHeightChild) {
      //↑↑↑同时和2和item覆盖（上下边框均在覆盖区域）
      if (itemHeightChild - bottomBorder > topBorder) {
        //↑↑↑粘连2个  要计算哪个占比多,topBorder越小 覆盖面积越大  ，bottomBorder越大  覆盖面积越大;
        //下边框占比叫较大
        return index -
            (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
      } else {
        //↑↑↑上边框占比大
        return index -
            (topTransferDistance / aSection).floor() * widget.crossAxisCount;
      }
    } else if (topBorder > itemHeightChild && bottomBorder < itemHeightChild) {
      //↑↑↑下边框在覆盖区,上边框在空白区域。
      return index -
          (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
    } else if (topBorder < itemHeightChild && bottomBorder > itemHeightChild) {
      //↑↑↑上边框在覆盖区域,下边框在空白区域
      return index -
          (topTransferDistance / aSection).floor() * widget.crossAxisCount;
    } else {
      //和哪个Item都没有覆盖，上下边框都在空白的区域。返回Index即可
      return index;
    }
  }

  /// 还要考虑一点就是 虽然Y轴不满足1/5--4/5覆盖率，但是X轴满足，所以返回的时候同时返回目标index 和 是否满足Y的覆盖条件
  int checkYAxleBelow(int index, double yBlankPlace, double dragPointY) {
    double aSection = yBlankPlace + itemHeightChild;

    double bottomTransferDistance = dragPointY.abs() + itemHeightChild;

    //求下边框的余数，余数小于itemHeightChild，表示和下面的item覆盖，余数大于itemHeightChild，表示下边框处于空白的区域
    double bottomBorder = bottomTransferDistance % aSection;
    //求上边框的余数 ，余数小于itemHeightChild，表示和上面的Item覆盖 ，余数大于itemHeightChild，表示上边框处于空白区域
    double topBorder = dragPointY.abs() % aSection;

    if (bottomBorder < itemHeightChild && topBorder < itemHeightChild) {
      //↑↑↑同时和2和item覆盖（上下边框均在覆盖区域）
      if (itemHeightChild - topBorder > bottomBorder) {
        //↑↑↑粘连2个  要计算哪个占比多,topBorder越小 覆盖面积越大  ，bottomBorder越大  覆盖面积越大;
        //↑↑↑上面占比大
        return index +
            (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
      } else {
        //↑↑↑下面占比大
        return index +
            (bottomTransferDistance / aSection).floor() * widget.crossAxisCount;
      }
    } else if (topBorder > itemHeightChild && bottomBorder < itemHeightChild) {
      //↑↑↑下边框在覆盖区 , 上边框在空白区域
      return index +
          (bottomTransferDistance / aSection).floor() * widget.crossAxisCount;
    } else if (topBorder < itemHeightChild && bottomBorder > itemHeightChild) {
      //topBorder<itemHeightChild
      //↑↑↑上边框在覆盖区域 ,下边框在空白区域
      return index +
          (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
    } else {
      //↑↑↑和哪个Item都没有覆盖，上下边框都在空白的区域。返回Index即可
      return index;
    }
  }

  ///停止滑动时，处理是否需要动画等
  @override
  void onFingerPause(int index, double dragPointX, double dragPointY,
      DragUpdateDetails updateDetail) async {
    int y = geyYTransferItemCount(index, yBlankPlace, dragPointY);
    int x = geyXTransferItemCount(index, xBlankPlace, dragPointX);

    //2.动画正在进行时不能进行动画 3. 计算错误时，终点坐标小于或者大于itemBins.length时不能动画
    if (x + y >= widget.fixedNum!) {
      if (endPosition != x + y &&
          !controller!.isAnimating &&
          x + y < widget.itemBins.length &&
          x + y >= 0 &&
          widget.itemBins[index].dragAble) {
        endPosition = x + y;
        _future = controller!.forward();
      }
    }
  }

  ///拖动结束后，根据 itemPositions 里面的排序，将itemBins重新排序
  ///并重新初始化 itemPositions
  @override
  void onPanEndEvent(index, {isRemove = false}) async {
    widget.itemBins[index].dragAble = false;
    if (controller!.isAnimating) {
      await _future;
    }

    if (!isRemove) {
      drawIndex = index;
      controller1!.forward();
    } else {
      setState(() {
        List<T> itemBi = [];
        T bin;
        for (int i = 0; i < itemPositions!.length; i++) {
          bin = widget.itemBins[itemPositions![i]] as T;
          bin.dragPointX = 0.0;
          bin.dragPointY = 0.0;
          bin.lastTimePositionX = 0.0;
          bin.lastTimePositionY = 0.0;
          itemBi.add(bin);
        }
        widget.itemBins.clear();
        widget.itemBins.addAll(itemBi);
        _initItemPositions();
      });
    }
  }

  //点击删除tag
  @override
  void onTapDelete(int index) {
    if (!isRemoveItem) {
      deleteIndex = index;

      controller2!.forward();

      startPosition = index;
      endPosition = widget.itemBins.length - 1;
      getWidgetsSize(widget.itemBins[index]);

      isRemoveItem = true;
      _future = controller!.forward();

      if (widget.isOpenDragAble) {
        //底部向上移动 Tag 向下移动
        var h = widget.itemBins.length % 4;
        if (h == 1) {
          widget.animatedClick!(-yDistance);
        }
      } else {
        //底部向下移动 Tag 向上移动
        var deletePosition = widget.deleteItemBins.length;
        //目标位置
        int delx = (deletePosition % 4) + 1; //第几列
        if (delx == 1) {
          widget.animatedClick!(yDistance);
        }
      }
    }
  }

  ///外部使用EditSwitchController控制编辑状态
  ///当调用该方法时 将GridView Item上的删除图标的状态取非 来改变状态
  void changeDeleteIconState() {
    setState(() {
      isHideDeleteIcon = !isHideDeleteIcon;
    });
  }

  @override
  void onTapDown(int index) {
    endPosition = index;
  }

  @override
  double getItemHeight() {
    return itemHeight;
  }

  @override
  double getItemWidth() {
    return itemWidth;
  }

  @override
  void onPressSuccess(int index) {
    setState(() {
      startPosition = index;
      if (widget.editChangeListener != null && isHideDeleteIcon == true) {
        widget.editChangeListener!();
      }
      isHideDeleteIcon = false;
    });
  }
}

class DragAbleContentView<T extends DragAbleGridViewBin>
    extends StatefulWidget {
  final Widget child;
  final bool isOpenDragAble;
  final double screenWidth, screenHeight;
  final bool isHideDeleteIcon;
  final AnimationController controller;
  final int longPressDuration;
  final int index;
  final T dragAbleGridViewBin;
  final DragAbleViewListener dragAbleViewListener;
  final UnActivateClick? unActivateClick;

  DragAbleContentView({
    required this.child,
    required this.isOpenDragAble,
    required this.screenHeight,
    required this.screenWidth,
    required this.isHideDeleteIcon,
    required this.controller,
    required this.longPressDuration,
    required this.index,
    required this.dragAbleGridViewBin,
    required this.dragAbleViewListener,
    this.unActivateClick,
  });

  @override
  State<StatefulWidget> createState() {
    return DragAbleContentViewState<T>();
  }
}

class DragAbleContentViewState<T extends DragAbleGridViewBin>
    extends State<DragAbleContentView<T>> with SingleTickerProviderStateMixin {
  Timer? timer;
  bool isDelete = true;

  AnimationController? controller;
  Animation<double>? animation;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);
    animation = new Tween(begin: 1.0, end: 1.1).animate(controller!);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isOpenDragAble
          ? (detail) {
              handleOnTapDownEvent(detail);
            }
          : null,
      onPanUpdate: widget.isOpenDragAble
          ? (updateDetail) {
              handleOnPanUpdateEvent(updateDetail);
            }
          : null,
      onPanEnd: widget.isOpenDragAble
          ? (upDetail) {
              isDelete = true;
              controller!.reverse();
              handleOnPanEndEvent(widget.index);
            }
          : null,
      onTapUp: widget.isOpenDragAble
          ? (tapUpDetails) {
              controller!.reverse();
              handleOnTapUp();
            }
          : (e) {
              widget.dragAbleViewListener.onTapDelete(widget.index);
            },
      child: new Offstage(
        offstage: widget.dragAbleGridViewBin.offstage,
        child: new Container(
          alignment: Alignment.center,
          key: widget.dragAbleGridViewBin.containerKey,
          child: new OverflowBox(
              maxWidth: widget.screenWidth,
              maxHeight: widget.screenHeight,
              alignment: Alignment.center,
              child: new Center(
                child: ScaleTransition(
                  scale: animation!,
                  child: Container(
                    key: widget.dragAbleGridViewBin.containerKeyChild,
                    transform: new Matrix4.translationValues(
                        widget.dragAbleGridViewBin.dragPointX,
                        widget.dragAbleGridViewBin.dragPointY,
                        0.0),
                    child: widget.child,
                  ),
                ),
              )),
        ),
      ),
    );
  }

  void handleOnPanEndEvent(int index) {
    T pressItemBin = widget.dragAbleGridViewBin;
    pressItemBin.isLongPress = false;
    if (!pressItemBin.dragAble) {
      pressItemBin.dragPointY = 0.0;
      pressItemBin.dragPointX = 0.0;
    } else {
      widget.dragAbleGridViewBin.dragAble = false;
      widget.dragAbleViewListener.onPanEndEvent(index);
    }
  }

  void handleOnTapUp() {
    T pressItemBin = widget.dragAbleGridViewBin;
    pressItemBin.isLongPress = false;
    if (!widget.isHideDeleteIcon) {
      setState(() {
        pressItemBin.dragPointY = 0.0;
        pressItemBin.dragPointX = 0.0;
      });
      if (isDelete) {
        widget.dragAbleViewListener.onTapDelete(widget.index);
      }
    } else {
      widget.unActivateClick == null
          ? null
          : widget.unActivateClick!(widget.index);
    }
    isDelete = true;
  }

  void handleOnPanUpdateEvent(DragUpdateDetails updateDetail) {
    T pressItemBin = widget.dragAbleGridViewBin;
    pressItemBin.isLongPress = false;
    if (pressItemBin.dragAble) {
      double deltaDy = updateDetail.delta.dy;
      double deltaDx = updateDetail.delta.dx;

      double dragPointY = pressItemBin.dragPointY += deltaDy;
      double dragPointX = pressItemBin.dragPointX += deltaDx;

      if (widget.controller.isAnimating) {
        return;
      }
      bool isMove = deltaDy.abs() > 0.0 || deltaDx.abs() > 0.0;

      if (isMove) {
        if (timer != null && timer!.isActive) {
          timer?.cancel();
        }
        setState(() {});
        timer = new Timer(new Duration(milliseconds: 1), () {
          widget.dragAbleViewListener.onFingerPause(
              widget.index, dragPointX, dragPointY, updateDetail);
        });
      }
    }
  }

  void handleOnTapDownEvent(TapDownDetails detail) {
    T pressItemBin = widget.dragAbleGridViewBin;
    widget.dragAbleViewListener.getWidgetsSize(pressItemBin);

    if (!widget.isHideDeleteIcon) {
      //获取控件在屏幕中的y坐标
      double ss = pressItemBin.containerKey.currentContext!
          .findRenderObject()!
          .getTransformTo(null)
          .getTranslation()
          .y;
      double aa = pressItemBin.containerKey.currentContext!
          .findRenderObject()!
          .getTransformTo(null)
          .getTranslation()
          .x;

      // //计算手指点下去后，控件应该偏移多少像素
      // double itemHeight = widget.dragAbleViewListener.getItemHeight();
      // double itemWidth = widget.dragAbleViewListener.getItemWidth();
      // pressItemBin.dragPointY = detail.globalPosition.dy - ss - itemHeight / 2;
      // pressItemBin.dragPointX = detail.globalPosition.dx - aa - itemWidth / 2;
    }

    //标识长按事件开始
    pressItemBin.isLongPress = true;
    //将可拖动标识置为false；（dragAble 为 true时 控件可拖动 ，暂时置为false  等达到长按时间才视为需要拖动）
    pressItemBin.dragAble = false;
    widget.dragAbleViewListener.onTapDown(widget.index);
    _handLongPress();
  }

  ///自定义长按事件，只有长按800毫秒 才能触发拖动
  void _handLongPress() async {
    await Future.delayed(new Duration(milliseconds: widget.longPressDuration));
    if (widget.dragAbleGridViewBin.isLongPress) {
      setState(() {
        widget.dragAbleGridViewBin.dragAble = true;
        isDelete = false;
        //震动
        Vibration.vibrate(duration: 1);
        controller!.forward();
      }); //吸附效果  SetState不能删除
      widget.dragAbleViewListener.onPressSuccess(widget.index);
    }
  }
}

abstract class DragAbleViewListener<T extends DragAbleGridViewBin> {
  void getWidgetsSize(T pressItemBin);
  void onTapDown(int index);
  void onTapDelete(int index);
  void onFingerPause(int index, double dragPointX, double dragPointY,
      DragUpdateDetails updateDetail);
  void onPanEndEvent(int index);
  double getItemHeight();
  double getItemWidth();
  void onPressSuccess(int index);
}
