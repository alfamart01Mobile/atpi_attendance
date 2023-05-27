import 'package:atpi_attendance/provider/imageProvider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class TakePhotoPage extends StatefulWidget {
  final List<CameraDescription>? cameras;
  const TakePhotoPage({super.key, required this.cameras});

  @override
  // ignore: library_private_types_in_public_api
  _TakePhotoPageState createState() => _TakePhotoPageState();
}

class _TakePhotoPageState extends State<TakePhotoPage> {
  late var _image1;
  late var _image2;

  Future<void> _pickImage1() async {
    final ImagePicker picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image1 = image;
    });
  }

  Future<void> _pickImage2() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      _image2 = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Image Picker App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
    );
  }
}
