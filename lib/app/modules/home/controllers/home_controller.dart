import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;

class HomeController extends GetxController {
  late final Stream<AccelerometerEvent> accelerometerStream;
  var angle = 0.0.obs;
  var hasError = false.obs;
  var xValue = 0.0.obs;
  var yValue = 0.0.obs;
  var shouldPlay = true.obs;
  var isOverlayOn = false.obs;
  var isOverlayPermissionGranted = Rxn<bool>();
  final box = GetStorage('ThemeData');

  @override
  void onInit() {
    super.onInit();
    accelerometerStream = accelerometerEventStream();
    fetchPermissionValue();
    listenAccelerometerStream();
    getAndSetStoredTheme();
  }

  Future<void> getAndSetStoredTheme() async {
    final overlayData = box.read('isOverlayOn');
    if (overlayData != null) {
      isOverlayOn.value = overlayData;
    }
  }

  fetchPermissionValue() async {
    isOverlayPermissionGranted.value = await FlutterOverlayWindow.isPermissionGranted();
  }

  void listenAccelerometerStream() {
    accelerometerStream.listen(
      (event) {
        findAngle(currentCoordinates: event);
      },
      onError: (error) {
        hasError.value = true;
      },
      cancelOnError: true,
    );
  }

  void findAngle({required AccelerometerEvent currentCoordinates}) {
    xValue.value -= currentCoordinates.x * 0.03;
    yValue.value -= currentCoordinates.y * 0.03;
    xValue.value = xValue.value.clamp(-math.pi / 2, math.pi / 2);
    yValue.value = yValue.value.clamp(-math.pi / 2, math.pi / 2);
    if (xValue.value == 0.0) {
      angle.value = 0;
      return;
    }
    final newValue = -math.atan2(currentCoordinates.y, currentCoordinates.x) - (math.pi / 2);
    var a = -5 < newValue && newValue < -1 ? newValue + (math.pi) : newValue;
    angle.value = a.clamp(-1.05, 1.05);
  }

  void alterPlayPauseValue() {
    shouldPlay.value = !shouldPlay.value;
  }

  Future<void> handleOverlay() async {
    if (await FlutterOverlayWindow.isPermissionGranted()) {
      if (!isOverlayOn.value) {
        isOverlayOn.value = true;
        await box.write('isOverlayOn', true);
        await FlutterOverlayWindow.showOverlay(
          enableDrag: false,
          flag: OverlayFlag.clickThrough,
          alignment: OverlayAlignment.bottomCenter,
        );
      } else {
        isOverlayOn.value = false;
        await box.write('isOverlayOn', false);
        await FlutterOverlayWindow.closeOverlay();
        isOverlayOn.refresh();
      }
    } else {
      await FlutterOverlayWindow.requestPermission();
    }
  }
}
