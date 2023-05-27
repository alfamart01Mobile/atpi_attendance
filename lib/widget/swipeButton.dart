import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../attendancePage.dart';

Widget SwipeButton(Map swipeType, context) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: ElevatedButton(
      onPressed: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AttendancePage(swipeType: swipeType, time: '10:16 AM')),
        );
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
            const Color.fromARGB(255, 248, 250, 252)),
      ),
      child: Text(
        swipeType['swipeType'],
        style: const TextStyle(
            color: Color.fromARGB(255, 12, 12, 12), fontSize: 16),
      ),
    ),
  );
}
