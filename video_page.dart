import 'dart:async';

import 'package:aixue_stu/data/http/http_get.dart';
import 'package:aixue_stu/func/event_bus.dart';
import 'package:aixue_stu/value/init_app.dart';
import 'package:c2hw_utils/log/utils_log.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videoplayer/video_player.dart';
import 'chewie_player.dart';
//视频播放控件
class PageVideo extends StatefulWidget {
  PageVideo(
    this.url, //播放地址
    {
    this.title = 'Chewie Demo',
    this.isCanSlide,
    this.startAt,
    this.endAt,
    this.placeholderUrl,
    this.allowFullScreen = true,
    this.resId,
  });

  final String title;
  String url; //播放地址
  bool isCanSlide = false; //是否可以拖动快进，默认可以拖动
  Duration startAt;
  Duration endAt;
  String placeholderUrl;
  bool allowFullScreen = true;
  int resId;

  @override
  State<StatefulWidget> createState() {
    return VideoState();
  }
}

class VideoState extends State<PageVideo> {
  TargetPlatform _platform;
  VideoPlayerController _videoPlayerController1;
  VideoPlayerController _videoPlayerController2;
  ChewieController _chewieController;

  // 注册监听器，订阅 eventbus
  StreamSubscription eventBusFn;

  @override
  void initState() {
    super.initState();
    CLogUtils.logD("初始化视频：=================${widget.placeholderUrl}");
    eventBusFn = eventBus.on<EventFn>().listen((event) {
      CLogUtils.logD("刷新播放进度： ${event.obj}");
      int videoTime = event.obj["videoTime"];
      CLogUtils.logD("刷新播放进度====： ${videoTime}");

      HttpGet.updateVoiceTime(videoTime, "${widget.resId}", "3");
    });
    initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController1.position.then((value) => {
          CLogUtils.logD("${value.inMilliseconds}-------------"),
          eventBus.fire(EventFn({"time": value.inMilliseconds}))
        });

    _videoPlayerController1?.dispose();
    _videoPlayerController2?.dispose();
    _chewieController?.dispose();
    CLogUtils.logD("dispose视频：=================");
    eventBusFn.cancel();
    CLogUtils.logD("dispose视频：=================------------------");
    super.dispose();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController1 = VideoPlayerController.network(widget.url);
    // ..initialize().then((value) => setState(() {}));
    // _videoPlayerController2 = VideoPlayerController.network(widget.url);
    await Future.wait([
      _videoPlayerController1.initialize().then((value) => {
            CLogUtils.logD("进度=============${_videoPlayerController1.value.duration.inMilliseconds}"),
            setState(() {}),
          }),
      // _videoPlayerController2.initialize().then((value) => setState(() {})),
    ]);

    _chewieController = ChewieController(
        allowFullScreen: widget.allowFullScreen,
        videoPlayerController: _videoPlayerController1,
        autoPlay: false,
        //显示视频后立即播放
        looping: false,
        //视频是否应循环播放
        isCanSlide: widget.isCanSlide,
        //是否可以拖动快进
        // aspectRatio: 7 / 4,
        startAt: widget.startAt ?? Duration(),
        //开始播放时间
        endAt: widget.endAt ?? _videoPlayerController1.value.duration,
        //结束播放时间
        allowPlaybackSpeedChanging: false,
        //是否显示倍速播放按钮，默认显示
        allowMuting: false,
        //定义是否应显示静音控件
        // customControls: CcMaterialControls(),
        deviceOrientationsAfterFullScreen: [InitSetting.isPortrait ? DeviceOrientation.portraitUp : DeviceOrientation.landscapeLeft],
        placeholder: Image(
          width: double.infinity,
          height: double.infinity,
          image: NetworkImage(widget.placeholderUrl),
        ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      width: double.infinity,
      height: 400,
      child: Center(
        child: _chewieController != null && _chewieController.videoPlayerController.value.initialized
            ? Chewie(
                controller: _chewieController,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                  ),
                  SizedBox(height: 20),
                  Text('加载中...'),
                ],
              ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TargetPlatform>('_platform', _platform));
  }
}
