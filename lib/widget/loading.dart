import 'dart:io';

import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final String message;
  Loading({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
          alignment: Alignment.center,
          child: Container(
            color: const Color.fromARGB(255, 204, 200, 200).withOpacity(0.5),
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            )),
          )),
    );
  }
}
