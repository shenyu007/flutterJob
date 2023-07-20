import 'dart:async';

import 'package:c2hw_utils/log/utils_log.dart';
import 'package:c2hw_utils/size/screen_adaptation.dart';
import 'package:c2hw_utils/storage/shared_preferences.dart';
import 'package:c2hw_utils/toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aixue_stu/data/http/http_post.dart';
import 'package:aixue_stu/res/colors.dart' as EttColor;
import 'package:aixue_stu/res/txt_style.dart';
import 'package:aixue_stu/view/view_loadview.dart';
import 'dart:convert' as convert;

///微信登录注册账号
class OtherLoginRegistPage extends StatefulWidget {
  var data;

  OtherLoginRegistPage({this.data});

  @override
  OtherLoginRegistState createState() => OtherLoginRegistState();
}

class OtherLoginRegistState extends State<OtherLoginRegistPage> {
  LoadController loadController;
  bool pwdIsShow = false;
  bool newPwdIsShow = false;
  Timer countdownTimer;
  var seconds = 0;

  String open_id;
  String nickName;

  TextEditingController userName = TextEditingController(); //手机号
  TextEditingController childName = TextEditingController(); //邀请码
  TextEditingController invCode = TextEditingController(); //邀请码

  @override
  void initState() {
    super.initState();
    _initData();
    open_id = widget.data["open_id"];
    nickName = widget.data["nickName"];
    CLogUtils.logD("${open_id}====${nickName}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            tooltip: 'back',
            color: Colors.black,
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            '选择身份',
            style: TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.bold,
                fontSize: Adapt.getSize(44)),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                  decoration:
                      BoxDecoration(color: Color(EttColor.EttColors.page_bg)),
                  child: Column(
                    children: [
                      // Container(height: Adapt.getSize(32)),
                      Container(
                        decoration:
                            BoxDecoration(color: Color(EttColor.EttColors.white)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: Adapt.getSize(32),
                                height: Adapt.getSize(105)),
                            Text(
                              "用户名",
                              style: TxtStyle.normal,
                            ),
                            Container(width: Adapt.getSize(40)),
                            Expanded(
                              child: Container(
                                child: TextField(
                                  controller: userName,
                                  style: TxtStyle.small_black,
                                  maxLines: 1,
                                  // inputFormatters: [LengthLimitingTextInputFormatter(11), FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                      hintText: "请输入用户名",
                                      hintStyle: TxtStyle.small_gray_light,
                                      border: InputBorder.none),
                                  onChanged: (v) {
                                    setState(() {
                                      print(v);
                                    });
                                  },
                                ),
                              ),
                            ),
                            Container(width: Adapt.getSize(32)),
                          ],
                        ),
                      ),
                      Container(height: Adapt.getSize(2)),
                      Container(
                        decoration:
                            BoxDecoration(color: Color(EttColor.EttColors.white)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: Adapt.getSize(32),
                                height: Adapt.getSize(105)),
                            Text(
                              "姓名",
                              style: TxtStyle.normal,
                            ),
                            Container(width: Adapt.getSize(74)),
                            Expanded(
                              child: Container(
                                child: TextField(
                                  controller: childName,
                                  style: TxtStyle.small_black,
                                  maxLines: 1,
                                  decoration: InputDecoration(
                                      hintText: "请输入孩子姓名",
                                      hintStyle: TxtStyle.small_gray_light,
                                      border: InputBorder.none),
                                  onChanged: (v) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                            Container(width: Adapt.getSize(32)),
                          ],
                        ),
                      ),
                      Container(height: Adapt.getSize(2)),
                      Container(
                        decoration:
                            BoxDecoration(color: Color(EttColor.EttColors.white)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                                width: Adapt.getSize(32),
                                height: Adapt.getSize(105)),
                            Text(
                              "邀请码",
                              style: TxtStyle.normal,
                            ),
                            Container(width: Adapt.getSize(40)),
                            Expanded(
                              child: Container(
                                child: TextField(
                                  controller: invCode,
                                  style: TxtStyle.small_black,
                                  maxLines: 1,
                                  decoration: InputDecoration(
                                      hintText: "请输入邀请码",
                                      hintStyle: TxtStyle.small_gray_light,
                                      border: InputBorder.none),
                                  onChanged: (v) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                            Container(width: Adapt.getSize(32)),
                          ],
                        ),
                      ),
                      Container(
                          width: Adapt.getSize(736),
                          height: Adapt.getSize(102),
                          margin: EdgeInsets.fromLTRB(Adapt.getSize(40),
                              Adapt.getSize(164), Adapt.getSize(40), 0),
                          child: FlatButton(
                            color: Colors.blue,
                            minWidth: double.infinity,
                            highlightColor: Colors.blue[700],
                            colorBrightness: Brightness.dark,
                            splashColor: Colors.grey,
                            child: Text(
                              "开启爱学",
                              style: TxtStyle.normal_white,
                            ),
                            disabledColor: Colors.blue[300],
                            disabledTextColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Adapt.getSize(60))),
                            onPressed: (userName.text != "" &&
                                    childName.text != "" &&
                                    invCode.text != "")
                                ? () => {band()}
                                : null,
                          )),
                    ],
                  )),
            ),
            LoadView(loadController),
          ],
        ));
  }

  _initData() async {
    loadController = LoadController();
    setState(() {});
  }

  /// 确认绑定
  band() {
    loadController.setVisible(true);
    HttpPost.otherLoginRegisterParent(
        childName.text,
        invCode.text,
        userName.text,
        open_id,
        nickName,
        (result) => {loadController.setVisible(false),success(result)},
        (error, code, msg) => {
              loadController.setVisible(false),
              Toast.show(msg),
            });
  }

  success(result) {
    var jsonResponse = convert.jsonDecode(result);
    int code = jsonResponse["code"];
    String msg = jsonResponse["msg"];
    if(code == 1){
      SharedPrefsUtils.putString("userName", userName.text);
      Navigator.pushReplacementNamed(context, '/page_home_parent');
    }else{
      Toast.show(msg);
    }
  }
}
