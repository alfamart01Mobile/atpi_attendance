// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:atpi_attendance/cameraPage.dart';
import 'package:atpi_attendance/provider/imageProvider.dart';
import 'package:atpi_attendance/provider/userProvider.dart';
import 'package:atpi_attendance/takePhotoPage.dart';
import 'package:atpi_attendance/widget/awesomeDialog.dart';
import 'package:atpi_attendance/widget/footer.dart';
import 'package:atpi_attendance/widget/invalidLocation.dart';
import 'package:atpi_attendance/widget/loading.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_face_api/face_api.dart' as Regula;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'api/apiRequest.dart';
import 'helper/helper.dart';
import 'main.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage(
      {super.key, required this.swipeType, required this.time});

  final Map swipeType;
  final String time;
  @override
  // ignore: library_private_types_in_public_api
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  late StreamSubscription<Position> _positionStream;
  String _liveness = "none";
  var img1;
  var path;
  final TextEditingController _employeeNoController = TextEditingController();
  final audioPlayer = AssetsAudioPlayer();
  bool _isLoading = false;

  @override
  Future<void> dispose() async {
    audioPlayer
        .dispose(); // dispose of the player instance when the page is closed
    super.dispose();
    await _positionStream.cancel();
  }

  @override
  void initState() {
    super.initState();
    _getLatLog();
    initPlatformState();
    const EventChannel('flutter_face_api/event/video_encoder_completion')
        .receiveBroadcastStream()
        .listen((event) {
      var response = jsonDecode(event);
      String transactionId = response["transactionId"];
      bool success = response["success"];
    });
    scanBarcodeNormal();
  }

  Future<void> initPlatformState() async {
    Regula.FaceSDK.init().then((json) {
      var response = jsonDecode(json);
      if (!response["success"]) {
        if (kDebugMode) {
          print("Init failed: ");
        }
        if (kDebugMode) {
          print(json);
        }
      }
    });
  }

  Future scanBarcodeNormal() async {
    String barcodeScanRes;
    setState(() {
      img1 = null;
      path = null;
      _employeeNoController.text = '';
    });
    await audioPlayer.open(Audio('assets/scan-barcode.mp3'), autoStart: true);
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    if (!mounted) return;

    if ((barcodeScanRes.length == 9 || barcodeScanRes.length == 11)) {
      await audioPlayer.open(
        Audio('assets/store-scanner-beep.mp3'),
        autoStart: true,
      );
      setState(() {
        _employeeNoController.text = barcodeScanRes.substring(0, 9);
      });

      liveness();
    } else {
      await audioPlayer.open(
        Audio('assets/error-barcode.mp3'),
        autoStart: true,
      );
      setState(() {
        _employeeNoController.text = '';
      });
    }
  }

  setImage(Uint8List? imageFile) {
    setState(() {
      img1 = Image.memory(imageFile!);
    });
  }

  liveness() async {
    Regula.FaceSDK.startLiveness().then((value) {
      var result = Regula.LivenessResponse.fromJson(json.decode(value));

      if (result?.liveness == Regula.LivenessStatus.PASSED) {
        setState(() {
          _liveness = 'passed';
        });
        setImage(base64Decode(result!.bitmap!.replaceAll("\n", "")));
        setState(() {
          path = base64Decode(result.bitmap!.replaceAll("\n", ""));
        });

        submitSwipe();
      } else {
        setState(() {
          _liveness = 'failed';
        });
      }
    });
  }

  Future submitSwipe() async {
    var result = await FlutterImageCompress.compressWithList(
      path,
      quality: 30,
      rotate: 0,
    );

    setState(() {
      _isLoading = true;
    });

    var user = context.read<UserProvider>().getUserDetails();
    if (user['latitude'] == '' || user['longitude'] == '') {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: '${widget.swipeType['swipeType']} failed',
        desc: 'Invalid Geolocation.',
        btnOkOnPress: () {},
      ).show();
      return;
    }
    var res = await insertSwipe({
      'deviceID': user['deviceID'],
      'locationID': user['locationID'],
      'latitude': user['latitude'],
      'longitude': user['longitude'],
      'image': base64Encode(result),
      'employeeNo': _employeeNoController.text,
      'timeLogTypeID': widget.swipeType['swipeTypeID'].toString()
    });

    setState(() {
      _isLoading = false;
    });

    if (res['RETURN'] > 0) {
      await audioPlayer.open(Audio('assets/successfully-recognized.mp3'),
          autoStart: true);
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Successfully ${widget.swipeType['swipeType']}',
        desc: res['MESSAGE'],
        btnOkOnPress: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const MyApp()));
        },
      ).show();
    } else if (res['RETURN'] == -200) {
      // ignore: use_build_context_synchronously
      AwesomeDialog(
              context: context,
              dialogType: DialogType.error,
              animType: AnimType.rightSlide,
              title: 'Problem found!',
              desc: res['MESSAGE'],
              btnOkText: 'Resubmit',
              btnOkOnPress: () async {
                submitSwipe();
              },
              btnCancelText: 'Exit',
              btnCancelOnPress: () {})
          .show();
      return;
    } else {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: '${widget.swipeType['swipeType']} failed',
        desc: res['MESSAGE'],
        btnOkOnPress: () {},
      ).show();
    }
    return true;
  }

  Future<void> _getLatLog() async {
    final hasPermission = await handleLocationPermission(context);
    if (!hasPermission) return;
    _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    )).listen((Position position) {
      String lat = position.latitude.toString();
      String long = position.longitude.toString();
      context.read<UserProvider>().setLatLong(lat, long);
    });
  }

  void exitApp() {
    exit(0);
  }

  AwesomeDialog SuccessDialog(res) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: 'Successfully ${widget.swipeType['swipeType']}',
      desc: res['MESSAGE'],
      btnOkOnPress: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MyApp()));
      },
    )..show();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      var user = userProvider.getUserDetails();
      int locationID = user['locationID'];
      String locationCode = user['locationCode'];
      String location = user['location'];
      int isAdmin = user['isAdmin'];
      if (_isLoading) {
        return Loading(message: 'Validating facial recognition...');
      }
      // if (_latitude == '' && _longitude == '') {
      //   return InvalidLocation(onPressed: _getLatLog);
      // }

      return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const MyApp()));
              },
            ),
            title: Text('${widget.swipeType['swipeType']}'),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Employee No'),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _employeeNoController,
                              decoration: const InputDecoration(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () {
                              scanBarcodeNormal();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Photo'),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                              width: double.infinity,
                              height: 400,
                              color: const Color.fromARGB(49, 66, 66, 66),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (img1 != null)
                                      GestureDetector(
                                        onTap: () async {
                                          liveness();
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(5),
                                          width: double.infinity,
                                          height: 390,
                                          color: Colors.black12,
                                          child: Image(image: img1.image),
                                        ),
                                      )
                                  ])),
                          if (img1 == null)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: FractionalTranslation(
                                  translation: const Offset(0.0, 0.5),
                                  child: FloatingActionButton(
                                    backgroundColor: const Color.fromARGB(
                                        255, 244, 246, 248),
                                    onPressed: () async {
                                      liveness();
                                    },
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Color.fromARGB(255, 43, 42, 42),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_liveness == 'passed' &&
                          _employeeNoController.text != '')
                        Center(child: Consumer<MyImageProvider>(
                            builder: (context, myImageProvider, child) {
                          return ElevatedButton(
                            onPressed: () async {
                              submitSwipe();
                            },
                            child: const Text('Submit'),
                          );
                        }))
                      else if (_liveness == 'failed' &&
                          _employeeNoController.text != '')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                liveness();
                              },
                              child: const Text('Retry'),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              Footer(lat: user['latitude'], long: user['longitude']),
        ),
      );
    });
  }

  Future<bool> _onBackPressed() async {
    FocusScope.of(context).unfocus();
    return true;
  }
}
