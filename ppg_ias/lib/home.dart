/*import 'package:camera/camera.dart';*/
import 'package:flutter/material.dart';
/*import 'package:wakelock/wakelock.dart';*/
/*import 'chart.dart';*/

class HomePage extends StatefulWidget {
  @override
  HomePageView createState() {
    return HomePageView();
  }
}

class HomePageView extends State<HomePage> {
  bool _toggled = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: IconButton(
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
    );
  }
  _toggle() {
  setState(() {
    _toggled = true;
  });
}

_untoggle() {
  setState(() {
    _toggled = false;
  });
}
}