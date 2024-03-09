// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../utils/constants.dart';

class SocialAuth extends StatelessWidget {
  final Function()? onPressGoogle;
  final Function()? onPressApple;

  const SocialAuth({
    super.key,
    required this.onPressGoogle,
    required this.onPressApple,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                spreadRadius: 4,
                blurRadius: 5,
                offset: Offset(0, 0), // changes position of shadow
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressGoogle,
            icon: Icon(
              Ionicons.logo_google,
              size: 45,
              color: kGreenColor,
            ),
          ),
        ),
        const SizedBox(width: 30),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                spreadRadius: 4,
                blurRadius: 5,
                offset: Offset(0, 0), // changes position of shadow
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressApple,
            icon: Icon(
              Ionicons.logo_apple,
              size: 45,
              color: kGreenColor,
            ),
          ),
        ),
      ],
    );
  }
}
