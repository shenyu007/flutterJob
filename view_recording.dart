import 'dart:async';
import 'dart:io';

import 'package:aixue_stu/func/event_bus.dart';
import 'package:aixue_stu/func/utils/ImagesAnim.dart';
import 'package:aixue_stu/res/txt_style.dart';
import 'package:c2hw_utils/log/utils_log.dart';
import 'package:c2hw_utils/size/screen_adaptation.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'dart:convert' as convert;
import 'package:permission_handler/permission_handler.dart';

typedef OnVoiceListener = Function(String path, int time);
//录音控件
class RecordingView extends StatefulWidget {
  OnVoiceListener listener;
  RecordController recordController;

  RecordingView2(this.listener, this.recordController);

  @override
  State<StatefulWidget> createState() {
    return RecordingState(recordController);
  }
}

class RecordingState extends State<RecordingView2>
    with TickerProviderStateMixin {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  // 注册监听器，订阅 eventbus
  var eventBusFn;

  Duration currentTime;
  AndroidDeviceInfo androidInfo;

  init() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if(Platform.isAndroid){
      androidInfo = await deviceInfo.androidInfo;
    }
  }

  // AudioPlayer audioPlayer = AudioPlayer();
  Duration playingTime;
  Map<int, Image> imageCaches = {
    1: Image.asset(
      "static/images/base_activity_voice_record_1.png",
      gaplessPlayback: true,
    ),
    2: Image.asset(
      "static/images/base_activity_voice_record_2.png",
      gaplessPlayback: true,
    ),
    3: Image.asset(
      "static/images/base_activity_voice_record_3.png",
      gaplessPlayback: true,
    ),
    4: Image.asset(
      "static/images/base_activity_voice_record_4.png",
      gaplessPlayback: true,
    ),
    5: Image.asset(
      "static/images/base_activity_voice_record_5.png",
      gaplessPlayback: true,
    )
  };

  ///默认隐藏状态
  bool isVoiceState = true;

  bool isLoading = true;
  AnimationController controller;
  Animation animation, borderAnimation, fontAnimation;
  int count = 3;

  void setVisible(bool visible) {
    check();
  }

  check() async {
    if (Platform.isAndroid) {
      if (androidInfo.version.sdkInt >= 23) {
        if (await Permission.microphone.request().isGranted) {
          CLogUtils.logD("获得了存储授权");
          startRecord();
          setState(() {});
        } else {
          CLogUtils.logD("没有获得存储授权");
          // await[Permission.microphone].request();
          return;
        }
      } else {
        startRecord();
        setState(() {});
      }
    } else {
      startRecord();
      if(mounted)
      setState(() {});
    }
  }

  RecordController recordController;

  RecordingState(RecordController controller) {
    controller.initController(this);
    this.recordController = controller;
  }

  @override
  void initState() {
    super.initState();
    print("RecordingView===============");
    init();
    eventBusFn = eventBus.on<EventFn>().listen((event) {
      if (event.obj != null) {
        if (event.obj["voiceTime"] != null) {
          print("刷新时间： ${event.obj}");
          int index = event.obj["voiceTime"];
          if (index != null) {
            currentTime = Duration(seconds: index);
            if (mounted) {
              setState(() {});
            }
          }
        } else if (event.obj["setVideoEnd"] != null) {
          print("录音完成---： ${event.obj["setVideoEnd"]}");
          getVoiceSuccess(event.obj["setVideoEnd"]);
        }
      }
    });

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.reverse();
        }
        if (status == AnimationStatus.dismissed) {
          if (count > 1) {
            count--;
            controller.forward();
          } else {
            // Navigator.pop(context);
            isLoading = false;
            _init();
          }
        }
      });
    _init();

    animation = Tween(begin: 0.0, end: 75.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.ease,
      ),
    );
    fontAnimation = Tween(begin: 20.0, end: 20.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.ease,
      ),
    );

    borderAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(75.0),
      end: BorderRadius.circular(75.0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.ease,
    ));
  }

  startRecord() {
    isVoiceState = false;
    isLoading = false;
    print("录音开始： ${imageCaches.length}");
  }

  @override
  void dispose() {
    print("销毁---------");
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1,
      child: GestureDetector(
        onTap: () {
          isVoiceState ? _start() : _stop();
        },
        child: Container(
          // width: Adapt.getSize(300),
          // height: Adapt.getSize(300),
          padding: EdgeInsets.all(Adapt.getSize(30)),
          margin: EdgeInsets.all(Adapt.getSize(30)),
          decoration: const BoxDecoration(
            // color: Colors.red,
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "${getTime(currentTime)}",
                style: const TextStyle(color: Colors.blue),
              ),
              Container(
                margin: EdgeInsets.only(
                    top: Adapt.getSize(20), bottom: Adapt.getSize(20)),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius:
                      BorderRadius.all(Radius.circular(Adapt.getSize(200))),
                ),
                child: isVoiceState
                    ? Image.asset(
                        "static/images/base_activity_voice_record_1.png",
                        gaplessPlayback: true,
                        width: 100,
                        height: 100,
                      )
                    : ImagesAnim(imageCaches, 100, 100, Colors.transparent),
              ),
              Text(
                "${isVoiceState ? "点击开始" : "点击完成录制"}",
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _init() async {
    isVoiceState = true;
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.AAC);

        CLogUtils.logD("(${_recorder == null})====$customPath");

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine
        setState(() {
          _current = current;
          CLogUtils.logD("${_current.duration.inSeconds}--------");
          if(_current.duration.inSeconds != 0){
            currentTime = _current.duration;
          }
          _currentStatus = current.status;
          print(_currentStatus);
        });
        // _start();
      } else {
        Scaffold.of(context).showSnackBar(
            new SnackBar(content: new Text("You must accept permissions")));
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    isVoiceState = false;
    setState(() {});
    if (io.Platform.isAndroid) {
      MethodChannel nativeChannel = MethodChannel("com.ett.flutter/native");
      Future future = nativeChannel.invokeMethod("startVoice");
      future.then((value) => {
            print("======---====接收到的参数： ${value}"),
            if (value != null && value)
              {_currentStatus = RecordingStatus.Recording, setState(() {})}
          });
      return;
    }

    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);
      setState(() {
        _current = recording;
      });

      const tick = const Duration(milliseconds: 50);
      Timer.periodic(tick, (Timer t) async {
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);
        if (mounted) {
          setState(() {
            _current = current;
            currentTime = _current.duration;
            _currentStatus = _current.status;
            if (_current.duration >= const Duration(minutes: 10)) {
              _stop();
            }
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  getTime(Duration time) {
    if (time == null) {
      return "";
    }
    return "${time.inMinutes % 60 >= 10 ? time.inMinutes % 60 : "0${time.inMinutes % 60}"}:"
        "${(time.inSeconds % 60 >= 10) ? time.inSeconds % 60 : "0${time.inSeconds % 60}"}";
  }

  _resume() async {
    isVoiceState = false;
    await _recorder.resume();
    setState(() {});
  }

  _pause() async {
    isVoiceState = true;
    await _recorder.pause();
    setState(() {});
  }

  _stop() async {
    isVoiceState = true;
    CLogUtils.logD("录音完成");
    currentTime = null;
    setState(() {

    });
    if (io.Platform.isAndroid) {
      CLogUtils.logD("录音完成===");
      MethodChannel nativeChannel = MethodChannel("com.ett.flutter/native");
      Future future = nativeChannel.invokeMethod("stopVoice");
      future.then((value) => {
            CLogUtils.logD("======---====接收到的参数： ${value}"),
            getVoiceSuccess(value)
            // widget.listener(result.path, result.duration.inSeconds);
          });

      return;
    }

    if (_recorder != null) {
      var result = await _recorder.stop();
      print("Stop recording: ${result.path}");
      print("Stop recording: ${result.duration.inSeconds}");
      // File file = widget.localFileSystem.file(result.path);
      // print("File length: ${await file.length()}");
      if (mounted) {
        setState(() {
          _current = result;
          _currentStatus = _current.status;
        });
      }
      widget.listener(result.path, result.duration.inSeconds);
    }

  }

  getVoiceSuccess(result) {
    isVoiceState = true;
    var jsonResponse = convert.jsonDecode(result);
    String path = jsonResponse["path"];
    int time = jsonResponse["time"];
    widget.listener(path, time);
  }
}

class RecordController {
  RecordingState loadState;
  bool visible = false;

  void initController(State<RecordingView2> loadState) {
    this.loadState = loadState;
  }

  void setVisible(bool visible) {
    this.visible = visible;
    if (loadState != null) {
      loadState.setVisible(visible);
    }
  }

  void stop() {
    if (loadState != null) {
      loadState._stop();
    }
  }
}
