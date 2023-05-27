import 'dart:async';
import 'dart:io';
import 'package:atpi_attendance/api/apiRegistration.dart';
import 'package:atpi_attendance/provider/userProvider.dart';
import 'package:atpi_attendance/widget/awesomeDialog.dart';
import 'package:atpi_attendance/widget/footer.dart';
import 'package:atpi_attendance/widget/invalidDevice.dart';
import 'package:atpi_attendance/widget/invalidLocation.dart';
import 'package:atpi_attendance/widget/loading.dart';
import 'package:atpi_attendance/widget/swipeButton.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:provider/provider.dart';
import 'package:atpi_attendance/provider/imageProvider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:atpi_attendance/attendancePage.dart';
import 'package:atpi_attendance/registrationPage.dart';
import 'api/apiRequest.dart';
import 'helper/helper.dart';

List swipeTypes = [
  {'swipeTypeID': 1, 'swipeType': '1st IN'},
  {'swipeTypeID': 2, 'swipeType': 'Lunch OUT'},
  {'swipeTypeID': 3, 'swipeType': 'Lunch IN'},
  {'swipeTypeID': 4, 'swipeType': 'Break OUT'},
  {'swipeTypeID': 5, 'swipeType': 'Break IN'},
  {'swipeTypeID': 6, 'swipeType': 'Final OUT'},
];

Future<void> main() async {
  await dotenv.load(fileName: "assets/.env", mergeWith: {
    // 'TEST_VAR': '5',
  });

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyImageProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAS AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'TAS AI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _currentTime = DateTime.now();
  late List<CameraDescription> cameras;
  String? _deviceId;
  late DateTime currentBackPressTime;
  late StreamSubscription<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    _getLatLog();
    setDeviceDetails();
    getCameras();
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  Future<void> getCameras() async {
    cameras = await availableCameras();
  }

  void _getDeviceInfo() async {
    String? deviceId;
    final user = context.read<UserProvider>().getUserDetails();
    if (user['locationID'] > 0) {
      return;
    }

    try {
      deviceId = await PlatformDeviceId.getDeviceId;
    } on PlatformException {
      deviceId = 'Failed to get deviceId.';
    }

    if (!mounted) return;

    setState(() {
      _deviceId = deviceId;
      _isLoading = true;
    });

    var res = await getDeviceInfo({'deviceID': deviceId});

    setState(() {
      _isLoading = false;
    });

    if (!context.mounted) return;

    if (res['RETURN'] > 0) {
      if (res['data'].length > 0) {
        context.read<UserProvider>().setDevice(deviceId!);
        context.read<UserProvider>().setLocation(
            res['data'][0]['Location_ID'],
            res['data'][0]['LocationCode'],
            res['data'][0]['Location'],
            res['data'][0]['isAdmin']);
        return;
      }

      AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Device not yet register',
          desc: 'Device ID: $_deviceId',
          btnOkText: 'Copy Device ID',
          btnOkOnPress: () async {
            await Clipboard.setData(ClipboardData(text: deviceId));
            // ignore: use_build_context_synchronously
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Device ID copied!'),
            ));
          },
          btnCancelText: 'Exit',
          btnCancelOnPress: () {
            exit(0);
          }).show();
    } else {
      httpErrorDialog(
          context, 'Problem found!', res['MESSAGE'], setDeviceDetails, exitApp);
    }
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

  void setDeviceDetails() {
    _getDeviceInfo();
  }

  @override
  void dispose() async {
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
      int isAdmin = user['isAdmin'];
      if (_isLoading) return Loading(message: 'Loading...');
      if (locationID == 0) return InvalidDevice(onPressed: setDeviceDetails);
      // if (_latitude == '' && _longitude == '') {
      //   return InvalidLocation(onPressed: _getLatLog);
      // }

      return WillPopScope(
        onWillPop: () async {
          await SystemNavigator.pop();
          return true;
        },
        child: Scaffold(
          key: scaffoldKey,
          appBar: AppBar(
              title: Text(
                  '${widget.title} ${DateFormat('hh:mm:ss a').format(_currentTime)}'),
              actions: isAdmin != 1
                  ? []
                  : [
                      IconButton(
                        icon: const Icon(Icons.add_card_outlined),
                        onPressed: () async {
                          context.read<MyImageProvider>().setImgPath("");
                          await availableCameras().then((value) =>
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const RegistrationPage())));
                        },
                      ),
                    ]),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text('[$locationCode] $location',
                    style: const TextStyle(
                        fontSize: 20, // set the font size to 20
                        color: Colors.blueAccent)),
              ),
              Expanded(
                  child: GridView.count(
                      crossAxisCount: 2,
                      children: List.generate(swipeTypes.length, (index) {
                        return SwipeButton(swipeTypes[index], context);
                      }))),
            ],
          ),
          bottomNavigationBar:
              Footer(lat: user['latitude'], long: user['longitude']),
        ),
      );
    });
  }
}
