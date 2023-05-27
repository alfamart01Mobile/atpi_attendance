import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:atpi_attendance/CameraPage.dart';
import 'package:atpi_attendance/provider/imageProvider.dart';
import 'package:atpi_attendance/provider/userProvider.dart';
import 'package:atpi_attendance/widget/awesomeDialog.dart';
import 'package:atpi_attendance/widget/footer.dart';
import 'package:atpi_attendance/widget/invalidDevice.dart';
import 'package:atpi_attendance/widget/loading.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:geolocator/geolocator.dart';

import 'api/apiRequest.dart';
import 'helper/helper.dart';
import 'main.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  late StreamSubscription<Position> _positionStream;
  final TextEditingController _employeeNoController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  StreamSubscription<Position>? _positionStreamSubscription;

  final audioPlayer = AssetsAudioPlayer();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _getLatLog();
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    if (barcodeScanRes.length == 9 || barcodeScanRes.length == 11) {
      await audioPlayer.open(Audio('assets/store-scanner-beep.mp3'),
          autoStart: true);
      setState(() {
        _employeeNoController.text = barcodeScanRes.substring(0, 9);
      });
      getEmpDetails();
    } else {
      await audioPlayer.open(Audio('assets/error-barcode.mp3'),
          autoStart: true);

      setState(() {
        _employeeNoController.text = '';
      });
    }
  }

  Future getEmpDetails() async {
    setState(() {
      _isLoading = true;
    });

    var res = await getEmployee(
        {'employeeNo': _employeeNoController.text, 'deviceID': '0'});

    setState(() {
      _isLoading = false;
    });

    if (res['RETURN'] > 0) {
      if (res['data'].length > 0) {
        setState(() {
          _employeeNameController.text = res['data'][0]['FullName'];
          _positionController.text = res['data'][0]['Position'];
        });
      } else {
        // ignore: use_build_context_synchronously
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Invalid Employee',
          desc: 'Employee not exist.',
          btnOkOnPress: () async {},
          btnCancelText: 'Close',
          btnCancelOnPress: () {
            scanBarcodeNormal();
          },
          btnOkText: 'Retry',
        ).show();
      }
      return;
    } else if (res['RETURN'] == -200) {
      // ignore: use_build_context_synchronously
      httpErrorDialog(
          context, 'Problem found!', res['MESSAGE'], getEmpDetails, exitApp);
      return;
    } else {
      // ignore: use_build_context_synchronously
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Invalid Employee',
        desc: 'Employee not exist.',
        btnOkOnPress: () {},
      ).show();
      return;
    }
  }

  Future submitRegister(path) async {
    String title = "Invalid form";
    String message = "";

    var user = context.read<UserProvider>().getUserDetails();

    if (_employeeNoController.text == '') {
      message = "Employee No is required.";
    } else if (_employeeNameController.text == '') {
      message = "Invalid employee";
    } else if (path == '') {
      message = "Please take a photo";
    }

    if (message != "") {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: title,
        desc: message,
        btnOkColor: Colors.red,
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    File rotatedImageFile = await FlutterExifRotation.rotateImage(path: path);
    var result = await FlutterImageCompress.compressWithFile(
      rotatedImageFile.path,
      quality: 30,
      rotate: 0,
    );

    var res = await insertEmployeeRegister({
      'deviceID': user['deviceID'],
      'locationID': user['locationID'],
      'latitude': user['latitude'],
      'longitude': user['longitude'],
      'image': base64Encode(result!.toList()),
      'employeeNo': _employeeNoController.text,
    });

    setState(() {
      _isLoading = false;
    });

    if (res['RETURN'] > 0) {
      // ignore: use_build_context_synchronously
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.rightSlide,
        title: 'Successfully Registered',
        desc: res['MESSAGE'],
        btnOkOnPress: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const MyApp()));
        },
      ).show();
      return;
    } else if (res['RETURN'] == -200) {
      // ignore: use_build_context_synchronously
      httpErrorDialog(
          context, 'Problem found!', res['MESSAGE'], submitHandler, exitApp);
      return;
    } else {
      // ignore: use_build_context_synchronously
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.rightSlide,
        title: 'Registration failed',
        desc: res['MESSAGE'],
        btnOkOnPress: () {},
      ).show();
      return;
    }
  }

  void submitHandler() {
    var path = context.read<MyImageProvider>().imgPath;
    submitRegister(path);
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

  @override
  Future<void> dispose() async {
    audioPlayer
        .dispose(); // dispose of the player instance when the page is closed
    super.dispose();
    await _positionStream.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(builder: (context, userProvider, child) {
      var user = userProvider.getUserDetails();
      int locationID = user['locationID'];
      String locationCode = user['locationCode'];
      String location = user['location'];

      if (_isLoading) return Loading(message: 'Loading...');

      return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const MyApp()));
              },
            ),
            title: const Text('Employee Face Registration'),
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
                      const Text('Full name'),
                      TextField(
                        controller: _employeeNameController,
                        decoration: const InputDecoration(),
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),
                      const Text('Position'),
                      TextField(
                        controller: _positionController,
                        decoration: const InputDecoration(),
                        readOnly: true,
                      ),
                      const SizedBox(height: 20),
                      const Text('Photo'),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                              width: double.infinity,
                              height: 350,
                              color: const Color.fromARGB(49, 66, 66, 66),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (context
                                            .watch<MyImageProvider>()
                                            .imgPath !=
                                        '')
                                      GestureDetector(
                                        onTap: () async {
                                          await availableCameras().then(
                                              (value) => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (_) =>
                                                          CameraPage(
                                                            cameras: value,
                                                          ))));
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(5),
                                          width: double.infinity,
                                          height: 340,
                                          color: Colors.black12,
                                          child: Image(
                                            image: FileImage(File(
                                              context
                                                  .watch<MyImageProvider>()
                                                  .imgPath,
                                            )),
                                            fit: BoxFit.fitWidth,
                                          ),
                                        ),
                                      )
                                  ])),
                          if (context.watch<MyImageProvider>().imgPath == '')
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: FractionalTranslation(
                                  translation: const Offset(0.0, 0.5),
                                  child: FloatingActionButton(
                                    backgroundColor: const Color.fromARGB(
                                        255, 244, 246, 248),
                                    onPressed: () async {
                                      await availableCameras()
                                          .then((value) => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => CameraPage(
                                                        cameras: value,
                                                      ))));
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
                      Center(child: Consumer<MyImageProvider>(
                          builder: (context, myImageProvider, child) {
                        return ElevatedButton(
                          onPressed: () async {
                            submitHandler();
                          },
                          child: const Text('Submit'),
                        );
                      })),
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
