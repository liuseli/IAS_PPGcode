import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:math';
import 'waveform.dart';

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
  List<SensorStats> _statdata = [];
  CameraController _controller;
  double _stdMean = 0;
  double _alpha = 0.3;
  int _bpm = 0;
  int _k = pow(2,2);

    _toggle() {
      _initController().then((onValue) {
      setState(() {
        _toggled = true;
        _processing = false;
      });
      _updateBPM();
      _updateStdmean();
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

   _updateBPM() async {
    List<SensorValue> _values;
    double _avg;
    int _n;
    double _m;
    double _threshold;
    double _bpm;
    int _counter;
    int _previous;
    while (_toggled) {
      _values = List.from(_data);
      _avg = 0;
      _n = _values.length;
      _m = 0;
      _values.forEach((SensorValue value) {
        _avg += value.value / _n;
        if (value.value > _m) _m = value.value;
      });
      _threshold = (_m + _avg) / 2;
      _bpm = 0;
      _counter = 0;
      _previous = 0;
      for (int i = 1; i < _n; i++) {
        if (_values[i - 1].value < _threshold &&
            _values[i].value > _threshold) {
          if (_previous != 0) {
            _counter++;
            _bpm +=
                60000 / (_values[i].time.millisecondsSinceEpoch - _previous);
          }
          _previous = _values[i].time.millisecondsSinceEpoch;
        }
      }
      if (_counter > 0) {
        _bpm = _bpm / _counter;
        setState(() {
          _bpm = (1 - _alpha) * _bpm + _alpha * _bpm;
        });
      }
      await Future.delayed(Duration(milliseconds: (1000 * 50 / 30).round()));
    }
  }


  _scanImage(CameraImage image) {
    int _n = image.planes.first.bytes.length;
    double _avg =
        image.planes.first.bytes.reduce((value, element) => value + element) / _n;
    double _std = 0;
    image.planes.first.bytes.forEach((value) => 
        ((_std + pow((value - _avg),2))/_n));
    _std = sqrt(_std);

    if (_data.length >= 50) {
      _data.removeAt(0);
    }
    setState(() {
      _data.add(SensorValue(DateTime.now(), _avg));
      _statdata.add(SensorStats(DateTime.now(), _std));
    });
    Future.delayed(Duration(milliseconds: 1000 ~/ 30)).then((onValue) {
      setState(() {
        _processing = false;
      });
    });
  }

  _updateStdmean() async {
    List<SensorStats> _devs;
    int _n;
    double _m;
    while (_toggled) {
      _devs = List.from(_statdata);
      _n = _devs.length;
      _m = 0;
      _stdMean = 0;
      _devs.forEach((SensorStats std) {
        _stdMean += std.std / _n;
        if (std.std > _m) _m = std.std;
      });
      setState(() {
        _stdMean = _stdMean;
      });
      await Future.delayed(Duration(milliseconds: (1000 * 50 / 30).round()));
    }
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
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            color: Colors.red,
                            child: Center(
                              child: Text(List.from(_statdata) == null ? _k.toString() : _stdMean.round().toString()),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.red,
                            child: Center(
                              child: Text((_bpm < 0 ? _bpm.round().toString() : "--"),
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              ),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                margin: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(18),
                    ),
                    color: Colors.black),
                child: Chart(_data),
              ),
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