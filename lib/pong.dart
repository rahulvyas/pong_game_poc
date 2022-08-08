import 'package:flutter/material.dart';
import 'package:flutter_fft/flutter_fft.dart';
import './ball.dart';
import './bat.dart';
import 'dart:math';

enum Direction { up, down, left, right }

class Pong extends StatefulWidget {
  @override
  _PongState createState() => _PongState();
}

class _PongState extends State<Pong> with SingleTickerProviderStateMixin {
  double increment = 5;

  Direction vDir = Direction.down;
  Direction hDir = Direction.right;

  Animation<double> animation;
  AnimationController controller;

  double width;
  double height;
  double posX = 0;
  double posY = 0;

  double batWidth = 0;
  double batHeight = 0;
  double batPosition = 0;

  double randX = 1;
  double randY = 1;

  int score = 0;

  //FFT
  double frequency;
  String note;
  int octave;
  bool isRecording;

  FlutterFft flutterFft = FlutterFft();

  // bool showDialog = false;

  double randomNumber() {
    //this is a number between 0.5 and 1.5;
    var ran = new Random();
    int myNum = ran.nextInt(101);
    return (50 + myNum) / 100;
  }

  void showMessage(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Game Over'),
            content: Text('Would you like to play again?'),
            actions: <Widget>[
              FlatButton(
                child: Text('Yes'),
                onPressed: () {
                  setState(() {
                    posX = 300;
                    posY = 300;
                    score = 0;
                  });
                  Navigator.of(context).pop();
                  controller.repeat();
                },
              ),
              FlatButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                  dispose();
                },
              )
            ],
          );
        });
  }

  _initialize() async {
    print("Starting recorder...");
    // print("Before");
    // bool hasPermission = await flutterFft.checkPermission();
    // print("After: " + hasPermission.toString());

    // Keep asking for mic permission until accepted
    while (!(await flutterFft.checkPermission())) {
      flutterFft.requestPermission();
      // IF DENY QUIT PROGRAM
    }

    // await flutterFft.checkPermissions();
    await flutterFft.startRecorder();
    print("Recorder started...");
    setState(() => isRecording = flutterFft.getIsRecording);

    flutterFft.onRecorderStateChanged.listen((data) {
      // print("Changed state, received: $data");
      setState(
        () {
          frequency = data[1] as double;
        },
      );
      flutterFft.setNote = note;
      flutterFft.setFrequency = frequency;
      flutterFft.setOctave = octave;
      //print("Octave: ${octave.toString()}");
      print("frequency: ${frequency.toStringAsFixed(2)}");
      if (frequency > 740 && frequency < 940) {
        batPosition = ((frequency - 740) * 300 / 200);
        print("batPosition SHOULD BE $batPosition");
      }
    }, onError: (err) {
      print("Error: $err");
    }, onDone: () => {print("Isdone")});
  }

  @override
  void initState() {
    isRecording = flutterFft.getIsRecording;
    frequency = flutterFft.getFrequency;
    note = flutterFft.getNote;
    octave = flutterFft.getOctave;
    posX = 300;
    posY = 300;
    controller = AnimationController(
      duration: const Duration(minutes: 10000),
      vsync: this,
    );
    animation = Tween<double>(begin: 0, end: 100).animate(controller);
    animation.addListener(() {
      safeSetState(() {
        (hDir == Direction.right)
            ? posY += ((increment * randY).round())
            : posY -= ((increment * randY).round());
        (vDir == Direction.down)
            ? posX += ((increment * randX).round())
            : posX -= ((increment * randX).round());
      });
      checkBorders();
    });
    controller.forward();
    super.initState();
    _initialize();
  }

  void checkBorders() {
    double diameter = 50;
    /* print("posX $posX");
    print("posY $posY");
    print("hDir $hDir");
    print("vDir $vDir"); */
    if (posY <= batWidth && hDir == Direction.left) {
      print("posX $posX");
      print("posX - height ${posX + batPosition - (diameter / 2)}");
      print("batPos $height");

      if ((posX + batPosition - (diameter / 2)) > height &&
          (posX + batPosition - (diameter / 2)) < (height + batHeight)) {
        hDir = Direction.right;
        randY = randomNumber();
        safeSetState(() {
          score++;
        });
      } else {
        // controller.stop();
        // showMessage(context);
      }
    }
    if (posY >= width - diameter && hDir == Direction.right) {
      hDir = Direction.left;
      randY = randomNumber();
    }
    //check the bat position as well
    if (posX >= height - diameter && vDir == Direction.down) {
      //check if the bat is here, otherwise loose
      // if (posX >= (batPosition - diameter) &&
      //     posX <= (batPosition + batWidth + diameter)) {
      vDir = Direction.up;
      randX = randomNumber();
      // safeSetState(() {
      //   score++;
      // });
      // } else {
      // controller.stop();
      // showMessage(context);
      // }
    }
    if (posX <= 0 && vDir == Direction.up) {
      vDir = Direction.down;
      randX = randomNumber();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      height = constraints.maxHeight;
      width = constraints.maxWidth;
      batWidth = 20;
      batHeight = height / 5;

      return Stack(
        children: <Widget>[
          Positioned(
              top: 0, right: 24, child: Text('Score: ' + score.toString())),
          Positioned(child: Ball(), top: posX, left: posY),
          Positioned(
              bottom: batPosition,
              left: 0,
              child: GestureDetector(
                  onVerticalDragUpdate: (DragUpdateDetails update) {
                    if (batPosition > 0 && batPosition <= (height * 4) / 5) {
                      moveBat(update);
                    } else {
                      batPosition = batPosition >= (height * 4) / 5
                          ? (height * 4) / 5
                          : 1;
                    }
                  },
                  child: Bat(batWidth, batHeight))),
        ],
      );
    });
  }

  void moveBat(DragUpdateDetails update) {
    safeSetState(() {
      print(batPosition);
      //print(update.delta.dy);
      batPosition -= update.delta.dy;
      // print(batPosition);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void safeSetState(Function function) {
    // we call the dispose() method on an object, the object is no longer usable.
    // Any subsequent call will raise an error. To prevent getting errors in our app,
    // we can create a method that, prior to calling the setState() method,
    // will check whether the controller is still mounted and the controller is active
    if (mounted && controller.isAnimating) {
      setState(() {
        function();
      });
    }
  }
}
