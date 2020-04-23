import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
/*import 'chart.dart';*/

class HomePage extends StatefulWidget {
  @override
  HomePageView createState() {
    return HomePageView();
  }
}

class HomePageView extends State<HomePage> {
  bool _toggled = false;
  bool _processing = false;
  List<SensorValue> _data = [];
  CameraController _controller;
    _toggle() {
      _initController().then((onValue) {
      setState(() {
        _toggled = true;
        _processing = false;
      });
    });
  }

  _untoggle() {
    _disposeController();
    setState(() {
      _toggled = false;
      _processing = false;
    });
  }

  Future<void> _initController() async {
    try {
      List _cameras = await availableCameras();
      _controller = CameraController(_cameras.first, ResolutionPreset.low);
      await _controller.initialize();
      Future.delayed(Duration(milliseconds: 500)).then((onValue) {
        _controller.flash(true);
      });
      _controller.startImageStream((CameraImage image) {
        if (!_processing) {
          setState(() {
            _processing = true;
          });
          _scanImage(image);
        }
      });
    } catch (Exception) {
      print(Exception);
    }
  }

  _disposeController() {
      _controller.dispose();
      _controller = null;
  }

  _scanImage(CameraImage image) {
    double _avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;
    if (_data.length >= 50) {
      _data.removeAt(0);
    }
    setState(() {
      _data.add(SensorValue(DateTime.now(), _avg));
    });
    Future.delayed(Duration(milliseconds: 1000 ~/ 30)).then((onValue) {
      setState(() {
        _processing = false;
      });
    });
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      color: Colors.red,
                      child: Center(
                        child: Text('HRV'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.red,
                      child: Center(
                        child: Text('BPM')
                      ),
                    ),
                  ),
                ],
              
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Text('Resp rate')
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: Text('Emotion')
                      ),
                    ),
                  ),
                ]
              )
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: _controller == null
                          ? Container()
                          : CameraPreview(_controller),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child:IconButton(
                        icon: Icon(_toggled ? Icons.favorite : Icons.favorite_border),
                        color: Colors.red,
                        iconSize: 128,
                        onPressed: () {
                        if (_toggled) {
                          _untoggle();
                        } else {
                          _toggle();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              )
            ),
          ],
        )
      ),
    );
  }
}

class SensorValue {
  final DateTime time;
  final double value;
  SensorValue(this.time, this.value);
}