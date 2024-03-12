// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:provider/provider.dart";
import "package:voyager/components/destinations_expanded.dart";
import "package:voyager/utils/colors.dart";
import "package:voyager/utils/constants.dart";

class PopDestExp extends StatefulWidget {
  const PopDestExp({super.key});

  @override
  State<PopDestExp> createState() => _PopDestExpState();
}

class _PopDestExpState extends State<PopDestExp> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Popular Destinations'),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? darkColorScheme.background
            : lightColorScheme.background,
      ),
      body: SingleChildScrollView(
        child: SafeArea(
            child: Column(
          children: [
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
            destExp(screenWidth: screenWidth),
            SizedBox(height: 10),
          ],
        )),
      ),
    );
  }
}
