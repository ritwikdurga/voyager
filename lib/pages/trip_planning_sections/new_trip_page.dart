// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_const_literals_to_create_immutables, unused_import, must_be_immutable, unnecessary_import, non_constant_identifier_names, prefer_final_fields, use_super_parameters, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:voyager/pages/explore_sections/explore_page.dart';
import 'package:voyager/pages/trip_planning_sections/main_tab_sections/expenses.dart';
import 'package:voyager/pages/trip_planning_sections/main_tab_sections/explore.dart';
import 'package:voyager/pages/trip_planning_sections/main_tab_sections/itinerary.dart';
import 'package:voyager/pages/trip_planning_sections/main_tab_sections/overview.dart';
import 'package:voyager/pages/trip_planning_sections/trips_form_input/tripmate_kind_input.dart';
import 'package:voyager/utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewTrip extends StatefulWidget {
  String? locationSelected;
  DateTime? StartDate;
  DateTime? EndDate;
  String? tripmateKind;
  List<String>? tripPreferences;
  bool? isManual;
  NewTrip(
      {Key? key,
      required this.locationSelected,
      required this.StartDate,
      required this.EndDate,
      required this.isManual,
      this.tripmateKind,
      this.tripPreferences})
      : super(key: key);
  @override
  State<NewTrip> createState() => _NewTripState();
}

class _NewTripState extends State<NewTrip> with TickerProviderStateMixin {
  final db = FirebaseFirestore.instance;
  List<Item>? notes;
  late String tripId;
  late DocumentReference tripRef;
  final _firebaseauth = FirebaseAuth.instance;
  late TabController _tabController;
  double screenHeight = 0;
  TextEditingController _HeadingTextController = TextEditingController();
  void addTripToFirestore(
      String? title,
      DateTime? startDate,
      DateTime? endDate,
      String? location,
      String? creator,
      List<String?> collaborators,
      List<String>? tripPreferences,
      String? tripmateKind,
      bool? isManual) async {
    await tripRef.collection("attachments").doc("notes").set({});
    await tripRef.collection("attachments").doc("flightTickets").set({});
    await tripRef.collection("attachments").doc("trainTickets").set({});
    await tripRef.collection("attachments").doc("busTickets").set({});
    await tripRef.collection("attachments").doc("carTickets").set({});
    await tripRef.collection("attachments").doc("images").set({});
    await tripRef.set({
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'creator': creator,
      'collaborators': collaborators,
      'isManual': isManual,
      'tripPreferences': tripPreferences,
      'notes': notes,
      'tripmateKind': tripmateKind,
    });
    tripId = tripRef.id;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(_firebaseauth.currentUser?.uid)
        .update({
      'trips': FieldValue.arrayUnion([tripId]),
    }).then((_) {
      print("Trip ID added to user's document successfully!");
    }).catchError((error) {
      print("Failed to add trip ID to user's document: $error");
    });
  }

  void updateTitle(String title) async {
    await tripRef.update({
      'title': title,
    });
  }

  @override
  void initState() {
    super.initState();
    tripRef = db.collection("trips").doc();
    addTripToFirestore(
        widget.locationSelected,
        widget.StartDate,
        widget.EndDate,
        widget.locationSelected,
        _firebaseauth.currentUser?.uid,
        [_firebaseauth.currentUser?.uid],
        widget.tripPreferences,
        widget.tripmateKind,
        widget.isManual);
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _HeadingTextController.text = widget.locationSelected!;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (_tabController.index == 0)
            SizedBox(
              height: screenHeight / 3,
              width: double.infinity,
              child: Image.asset(
                'assets/images/a.png',
                fit: BoxFit.cover,
              ),
            ),
          if (_tabController.index == 0)
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: TextField(
                      controller: _HeadingTextController,
                      style: TextStyle(
                        color: Colors.white,
                        // Changed color to black for better visibility
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ProductSans',
                        fontSize: 40,
                      ),
                      textAlign: TextAlign.center,
                      onChanged: (newValue) {
                        updateTitle(newValue);
                      },
                      decoration: null,
                    ),
                  ),
                  Text(
                    '${DateFormat('dd MMM').format(widget.StartDate!)}-${DateFormat('dd MMM').format(widget.EndDate!)}',
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
                top: _tabController.index == 0 ? screenHeight / 3 - 20 : 30),
            child: AnimatedSize(
              curve: Curves.easeIn,
              duration: Duration(milliseconds: 300),
              child: Container(
                height: _tabController.index == 0
                    ? 2 * screenHeight / 3 + 20
                    : screenHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.black
                            : Colors.white,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: TabBar(
                          controller: _tabController,
                          dividerColor:
                              themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.black
                                  : Colors.white,
                          tabs: [
                            buildTab(Iconsax.information),
                            buildTab(Iconsax.search_normal),
                            buildTab(Iconsax.map),
                            buildTab(Iconsax.dollar_circle),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          OverviewTrips(
                            tripRef: tripRef,
                          ),
                          ExploreTrips(),
                          ItineraryTrips(
                              startDate: widget.StartDate,
                              endDate: widget.EndDate),
                          ExpensesTrips(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTab(IconData icon) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white30,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 30,
      ),
    );
  }
}
