library screen_adaptation;

import 'package:flutter/cupertino.dart';

class Adapt {
  static double scale = 1;
  static double MAX_WIDTH = 800;
  static double aspectRatio = 1;

  static init800(BuildContext context) {
    aspectRatio =
        MediaQuery.of(context).size.height / MediaQuery.of(context).size.width;
    if (aspectRatio > 1.68) {
      MAX_WIDTH = 800;
    } else {
      MAX_WIDTH = 1280;
    }
    scale = MAX_WIDTH / MediaQuery.of(context).size.width;
  }

  static initByWidth(BuildContext context, double width) {
    MAX_WIDTH = width;
    scale = width / MediaQuery.of(context).size.width;
  }

  static initByHeight(BuildContext context, int height) {
    final size = MediaQuery.of(context).size;
    scale = height / size.height;
  }

  static double getSize(double value) {
    return value / scale;
  }

  static double getMax() {
    return MAX_WIDTH / scale;
  }

  static double getHeight(BuildContext context){
    final totalHeight= MediaQuery.of(context).size.height;
    return totalHeight;
  }
}
