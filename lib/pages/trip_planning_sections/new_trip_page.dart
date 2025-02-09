// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_const_literals_to_create_immutables, unused_import, must_be_immutable, unnecessary_import, non_constant_identifier_names, prefer_final_fields, use_super_parameters, avoid_print

import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:voyager/components/explore_section/places.dart';
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
  List<String> collaborators;
  bool? isManual;
  String? budget;
  NewTrip(
      {Key? key,
      required this.locationSelected,
      required this.StartDate,
      required this.EndDate,
      required this.isManual,
      this.tripmateKind,
      this.tripPreferences,
      required this.budget,
      required this.collaborators})
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
      List<String> collaborators,
      List<String>? tripPreferences,
      String? tripmateKind,
      String? budget,
      bool? isManual) async {
    await tripRef.set({
      'title': title,
      'startDate': startDate,
      'endDate': endDate,
      'location': location,
      'creator': creator,
      'collaborators': collaborators,
      'isManual': isManual,
      'tripPreferences': tripPreferences,
      'tripmateKind': tripmateKind,
      'budget':budget,
    });
    await FirebaseFirestore.instance
        .collection("users")
        .doc(_firebaseauth.currentUser?.uid)
        .update({
      'trips': FieldValue.arrayUnion([
        {'tripId': tripId.toString(), 'isBookmarked': false}
      ]),
    }).then((_) {
      print("Trip ID added to user's document successfully!");
    }).catchError((error) {
      print("Failed to add trip ID to user's document: $error");
    });
    FirebaseStorage.instance
        .ref()
        .child("trips/$tripId")
        .child('.placeholder')
        .putData(Uint8List(0));
  }

  void updateTitle(String title) async {
    await tripRef.update({
      'title': title,
    });
  }

  void deleteTrip() async {
    try {
      for (int index = 0; index < widget.collaborators.length; index++) {
        final DocumentReference user =
            db.collection("users").doc(widget.collaborators[index]);
        await user.update({
          'trips': FieldValue.arrayRemove([
            {'tripId': tripId, 'isBookmarked': false}
          ]),
        });
      }
      await tripRef.delete();
      // final destination = FirebaseStorage.instance.ref().child("trips/{$tripId}");
      // await destination.delete();
    } catch (error) {
      print(error);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _HeadingTextController.text = widget.locationSelected!;
    tripRef = db.collection("trips").doc();
    addTripToFirestore(
      widget.locationSelected,
      widget.StartDate,
      widget.EndDate,
      widget.locationSelected,
      _firebaseauth.currentUser?.uid,
      [_firebaseauth.currentUser!.uid],
      widget.tripPreferences,
      widget.tripmateKind,
      widget.budget,
      widget.isManual,
    );
    tripId = tripRef.id;
  }

  late StreamSubscription<DocumentSnapshot> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _subscription = tripRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        String title = snapshot['title'];
        if (title != _HeadingTextController.text) {
          setState(() {
            _HeadingTextController.text = title;
          });
        }
      }
    }, onError: (error) {
      print("Stream Subscription Error: $error");
    });
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
              child: CachedNetworkImage(
                imageUrl: placeImgURL[widget.locationSelected] as String,
                fit: BoxFit.cover,
              ),
            ),
          if (_tabController.index == 0)
            SafeArea(
              child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              deleteTrip();
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )),
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
                      onEditingComplete: () {
                        updateTitle(_HeadingTextController.text);
                        FocusManager.instance.primaryFocus?.unfocus();
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
              curve: Curves.easeInOut,
              duration: Duration(milliseconds: 600),
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
                      child: IndexedStack(
                        index: _tabController.index,
                        children: [
                          OverviewTrips(
                            tripRef: tripRef,
                          ),
                          ExploreTrips(
                            place: widget.locationSelected as String,
                          ),
                          ItineraryTrips(
                            startDate: widget.StartDate,
                            endDate: widget.EndDate,
                            location: widget.locationSelected,
                            tripId: tripId,
                            budget: widget.budget,
                            tripPreferences: widget.tripPreferences,
                            tripMateKind: widget.tripmateKind,
                            isManual: widget.isManual,
                          ),
                          ExpensesTrips(
                            tripId: tripId,
                          ),
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
