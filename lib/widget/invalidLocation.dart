import 'dart:io';

import 'package:flutter/material.dart';

class InvalidLocation extends StatelessWidget {
  final VoidCallback onPressed;
  InvalidLocation({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Container(
          height: 200,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Image(
                  image: AssetImage('assets/app_icon.png'),
                ),
              ),
              const Text(
                'Failed to get relocation.',
                style: TextStyle(
                    color: Color.fromARGB(255, 12, 12, 12), fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      exit(0);
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 248, 250, 252)),
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                          color: Color.fromARGB(255, 12, 12, 12), fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 248, 250, 252)),
                    ),
                    child: const Text(
                      'Reload',
                      style: TextStyle(
                          color: Color.fromARGB(255, 12, 12, 12), fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
