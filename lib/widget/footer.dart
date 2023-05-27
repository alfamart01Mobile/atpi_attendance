import 'dart:io';

import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final String lat;
  final String long;
  Footer({required this.lat, required this.long});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 50.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: [
                const Icon(Icons.location_pin),
                const SizedBox(
                    width: 5), // Add some space between the icon and text
                Text(lat),
                const Text(' | ',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
                Text(
                  long,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
