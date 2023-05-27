import 'package:atpi_attendance/provider/imageProvider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const CameraPage({super.key, required this.cameras});

  @override
  // ignore: library_private_types_in_public_api
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    getCameras();
  }

  Future<void> getCameras() async {
    final cam = widget.cameras?.last;

    controller = CameraController(
      cam!,
      ResolutionPreset.high,
    );

    await controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    final scale = 1 /
        (controller.value.aspectRatio *
            MediaQuery.of(context).size.aspectRatio);
    return Scaffold(
      body: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Stack(children: <Widget>[
          CameraPreview(controller),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          XFile image = await controller.takePicture();
          context.read<MyImageProvider>().setImgPath(image.path);
          Navigator.pop(context);
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
