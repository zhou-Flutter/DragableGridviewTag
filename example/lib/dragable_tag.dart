import 'package:example/color_tools.dart';
import 'package:flutter/material.dart';
import 'package:dragablegridview_tag/dragablegridview_tag.dart';

class GridviewTag extends StatefulWidget {
  GridviewTag({Key? key}) : super(key: key);
  @override
  State<GridviewTag> createState() => _GridviewTagState();
}

class _GridviewTagState extends State<GridviewTag> {
  var editSwitchController = EditSwitchController();
  List<ItemBin> itemBins = [];
  List<ItemBin> deleteItemBins = [];
  String actionTxtEdit = "编辑";
  String actionTxtComplete = "完成";
  String? actionTxt;
  final List<String> heroes = [
    "鲁班",
    "虞姬",
    "甄姬",
    "黄盖黄盖",
    "张飞",
    "关羽",
    "刘备",
    "曹操",
    "赵云",
    "孙策",
    "庄周",
  ];
  final List<String> deleteHeroes = [
    "廉颇",
    "后裔",
    "妲己",
    "荆轲",
  ];
  @override
  void initState() {
    super.initState();
    actionTxt = actionTxtEdit;
    for (var heroName in heroes) {
      itemBins.add(ItemBin(heroName));
    }
    for (var heroName in deleteHeroes) {
      deleteItemBins.add(ItemBin(heroName));
    }
  }

  void changeActionState() {
    if (actionTxt == actionTxtEdit) {
      setState(() {
        actionTxt = actionTxtComplete;
      });
    } else {
      setState(() {
        actionTxt = actionTxtEdit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("你好")),
      body: DragableGridViewTag(
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2,
        crossAxisCount: 4,
        fixedNum: 3,
        sideMargin: 20,
        itemBins: itemBins,
        deleteItemBins: deleteItemBins,
        editSwitchController: editSwitchController,
        isOpenDragAble: true,
        animationDuration: 400, //milliseconds
        longPressDuration: 600, //milliseconds
        middleHight: 50,
        middleChild: middleChild(),
        deleteIcon: iconView(Icons.remove),
        addIcon: iconView(Icons.add),
        topEditChild: topEdit(),
        child: (int position) {
          return itemTag(itemBins[position].data);
        },
        deleteChild: (int position) {
          return itemTag(deleteItemBins[position].data);
        },
        unActivateClick: (e) {
          print("点击跳转");
        },
        editChangeListener: () {
          changeActionState();
        },
      ),
    );
  }

  ///middleHight 要和 middleChild 的高相等,不然计算错误 动画会错位
  Widget middleChild() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text("更多频道"),
        ],
      ),
    );
  }

  Widget itemTag(data) {
    return Container(
      alignment: Alignment.center,
      width: 75,
      height: 35,
      decoration: BoxDecoration(
        color: Color.fromARGB(192, 235, 232, 232),
        borderRadius: BorderRadius.all(Radius.circular(3.0)),
      ),
      child: Text(
        data,
        style: TextStyle(
          fontSize: 15.0,
          color: Colors.black54,
        ),
      ),
    );
  }

  //添加删除 icon
  Widget iconView(icon) {
    return Container(
      height: 15,
      width: 15,
      decoration: BoxDecoration(
          color: HexColor.fromHex("#BEBEBE"),
          borderRadius: BorderRadius.circular(50)),
      child: Center(
        child: Icon(
          icon,
          size: 15,
          color: Colors.white,
        ),
      ),
    );
  }

  //顶部编辑
  Widget topEdit() {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 25),
      height: 50,
      child: Row(
        children: [
          Text(
            "我的频道",
            style: TextStyle(fontSize: 15),
          ),
          Spacer(),
          GestureDetector(
            child: Text(
              actionTxt!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.blue,
              ),
            ),
            onTap: () {
              changeActionState();
              editSwitchController.editStateChanged();
              actionTxt == "编辑" ? saveList() : null;
            },
          )
        ],
      ),
    );
  }

  void saveList() {
    for (var item in itemBins) {
      item.data;
      print(item.data);
    }
    print("------");
    for (var item in deleteItemBins) {
      print(item.data);
    }
  }
}
