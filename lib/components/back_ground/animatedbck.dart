// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:voyager/utils/colors.dart';
import 'package:voyager/utils/constants.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: animatedBck(),
  ));
}

class animatedBck extends StatefulWidget {
  animatedBck({Key? key}) : super(key: key);

  @override
  State<animatedBck> createState() => _animatedBckState();
}

class _animatedBckState extends State<animatedBck>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          color: themeProvider.themeMode == ThemeMode.dark
              ? darkColorScheme.background
              : lightColorScheme.background,
        ),
      ),
    );
  }
}
