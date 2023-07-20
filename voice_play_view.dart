import 'dart:io';

import 'package:aixue_stu/func/ett_event.dart';
import 'package:aixue_stu/func/utils/random_utils.dart';
import 'package:aixue_stu/func/utils/view_seek.dart';
import 'package:aixue_stu/value/init_app.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:c2hw_utils/log/utils_log.dart';
import 'package:c2hw_utils/size/screen_adaptation.dart';
import 'package:flutter/material.dart';

typedef IsCancleListener = Function(bool isCancle);

///语音播放条
class VoicePlayView extends StatefulWidget {
  final String path; //路劲
  final int time; //时间
  final bool islocal; //是否是本地地址
  final bool isCancleButton; //是否存在取消按钮，默认不存在
  final IsCancleListener listener; //取消监听
  double width;
  double height;

  VoicePlayView({
    this.path,
    this.time,
    this.islocal,
    this.isCancleButton = false,
    this.listener,
    this.width,
    this.height,
  });

  @override
  State<StatefulWidget> createState() => VoicePlayState();
}

class VoicePlayState extends State<VoicePlayView> {
  SeekController bodySeekController;
  AudioPlayer audioPlayer;
  bool isPlaying = false;
  var eventBusFn;
  var tag;

  String path; //路劲
  int time; //时间
  bool islocal; //是否是本地地址
  bool isCancleButton; //是否存在取消按钮，默认不存在
  IsCancleListener listener; //取消监听
  double width;
  double height;
  @override
  void didUpdateWidget(covariant VoicePlayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.path != widget.path){
      path = widget.path;
      time = widget.time;
      initSeekBar();
      _initVoice();
    }
  }

  @override
  void initState() {
    super.initState();
    path = widget.path;
    time = widget.time;
    initSeekBar();
    _initVoice();
    tag = "${DateTime.now().millisecondsSinceEpoch}" + RandomUtils.getTag();

    eventBusFn = EventBusUtil.listen<VideoPlayEvent>((event) {
      if (tag != event.TAG) {
        _pause();
      }
    });

    eventBusFn = EventBusUtil.listen<OnPauseEvent>((event) {
      _pause();
    });
    eventBusFn = EventBusUtil.listen<OnNewPageEvent>((event) {
      _pause();
    });
  }

  initSeekBar() {
    bodySeekController = SeekController(
        backgroundColor: Colors.white54,
        progressColor: Colors.white,
        textColor: Colors.white,
        textSize: InitSetting.isPortrait ? Adapt.getSize(24) : Adapt.getSize(12),
        onPanDown: (value) {
          audioPlayer.pause();
        },
        onPanEnd: (value) {
          audioPlayer.seek(
              new Duration(seconds: (value * bodySeekController.max).toInt()));
          audioPlayer.resume();
        },
        onTapUp: (value) {
          audioPlayer.seek(
              new Duration(seconds: (value * bodySeekController.max).toInt()));
          audioPlayer.resume();
        });
  }

  _pause() async {
    if(audioPlayer == null){
      return;
    }
    int result = await audioPlayer.pause();
    isPlaying = result != 1;
    setState(() {});
  }

  _initVoice() async {
    audioPlayer = AudioPlayer();
    audioPlayer.setUrl(path, isLocal: widget.islocal);

    bodySeekController.max = time.toDouble();

    audioPlayer.onDurationChanged.listen((Duration d) {
      if (bodySeekController != null) {
        if (bodySeekController.max != d.inSeconds.toDouble()) {
          bodySeekController.max = d.inSeconds.toDouble();
          bodySeekController.updateState();
        }
      }
    });

    audioPlayer.onPlayerStateChanged.listen((state) {
      if (audioPlayer == null) {
        return;
      }
      if (state == PlayerState.PLAYING) {
        isPlaying = true;
      } else if (state == PlayerState.PAUSED) {
        isPlaying = false;
      } else if (state == PlayerState.STOPPED) {
        isPlaying = false;
      } else if (state == PlayerState.COMPLETED) {
        if(!Platform.isAndroid){
          _initVoice();
        }
        if (bodySeekController != null) {
          bodySeekController.value = bodySeekController.max;
          bodySeekController.updateState();
        }
        isPlaying = false;
      }
      setState(() {});
    });

    audioPlayer.onAudioPositionChanged.listen((p) async {
      print("当前播放时长： ${p.inMilliseconds}");
      if (bodySeekController != null) {
        bodySeekController.value = p.inSeconds.toDouble();
        bodySeekController.updateState();
      }
    });
    audioPlayer.onPlayerError.listen((msg) {
      CLogUtils.logE('audioPlayer error : $msg');
    });
  }

  _playVoice() async {
    int result = await audioPlayer.resume();
    EventBusUtil.fire(VideoPlayEvent(tag));
    isPlaying = result == 1;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          height: widget.height != null ? widget.height : 45,
          padding: EdgeInsets.only(
              left: Adapt.getSize(20), right: Adapt.getSize(20)),
          margin: EdgeInsets.all(Adapt.getSize(20)),
          decoration: new BoxDecoration(
            //背景
            color: Colors.lightBlue,
            //设置四周圆角 角度 这里的角度应该为 父Container height 的一半
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
            //设置四周边框
            // border: new Border.all(width: 1, color: Colors.red),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (!isPlaying) {
                    _playVoice();
                  } else {
                    _pause();
                  }
                },
                child: Icon(
                  (isPlaying) ? Icons.pause : Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
              ),
              // child: Text(isPlaying ? "暂停" : "播放")),
              Container(
                width: widget.width != null ? widget.width : Adapt.getSize(400),
                margin: EdgeInsets.only(left: Adapt.getSize(10),right: Adapt.getSize(20)),
                child: SeekView(bodySeekController),
              )
            ],
          )),
      widget.isCancleButton
          ? IconButton(
              icon: Icon(
                Icons.cancel_rounded,
                color: Colors.grey,
              ),
              onPressed: () => {
                    widget.listener(true),
                    if (isPlaying)
                      {
                        audioPlayer.pause(),
                      },
                    initSeekBar(),
                    setState(() {}),
                  })
          : Container()
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    eventBusFn.cancel();
    if (isPlaying) {
      audioPlayer.stop();
    }
    if (audioPlayer != null) {
      audioPlayer.release();
      audioPlayer = null;
    }
  }
}
