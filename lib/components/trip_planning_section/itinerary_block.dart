// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, curly_braces_in_flow_control_structures, unused_local_variable, unused_field, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:voyager/pages/trip_planning_sections/main_tab_sections/normalmap.dart';
import 'package:voyager/services/data_comparator.dart';
import 'package:voyager/utils/constants.dart';
import 'package:http/http.dart' as http;

import '../../map_section/normal__map_page.dart';

class BlockIti extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String tripId;
  final bool isManual;
  String? tripMateKind;
  List<String>? tripPreferences;
  String? budget;
  final List<String> suggestions;
  BlockIti(
      {super.key,
      this.budget,
      this.tripMateKind,
      this.tripPreferences,
      required this.suggestions,
      required this.startDate,
      required this.endDate,
      required this.location,
      required this.isManual,
      required this.tripId});
  @override
  State<BlockIti> createState() => _BlockItiState();
}

class _BlockItiState extends State<BlockIti>
    with AutomaticKeepAliveClientMixin {
  List<BlockData> blockDataList = [];
  late Stream<DocumentSnapshot> _dataStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dataStream = FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.tripId)
        .snapshots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void updateBlocDataInFirebase() async {
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .update({
        'blockData': blockDataList.map((data) => data.toMap()).toList()
      });
      print('Block data updated successfully!');
    } catch (e) {
      print('Error updating block data: $e');
    }
  }

  Future<void> getItinary() async {
    String param1 = widget.tripPreferences?.join(',') ?? '';
    int length = widget.endDate!.difference(widget.startDate!).inDays + 1;
    String param4;
    if (widget.tripMateKind == "Going solo") {
      param4 = "Individual";
    } else if (widget.tripMateKind == "Partner") {
      param4 = "Family";
    } else if (widget.tripMateKind == "Friends") {
      param4 = "Friends";
    } else if (widget.tripMateKind == "Family") {
      param4 = "Family";
    } else {
      param4 = "";
    }

    var params = {
      'param1': param1,
      'param2': length.toString(),
      'param3': double.parse(widget.budget!).toInt().toString(),
      'param4': param4,
      'param5': 'Yes',
      'param6': widget.location.toString().toLowerCase(),
    };
    var url = Uri.parse('http://$using:8000');

    var response = await http.get(url.replace(queryParameters: params));

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      List<BlockData> blockDataListGen = [];

      for (int i = 0; i < length; i++) {
        DateTime currentDate = widget.startDate.add(Duration(days: i));
        if (responseBody.containsKey(i.toString())) {
          List<String> locations =
              List<String>.from(responseBody[i.toString()]);
          blockDataListGen
              .add(BlockData(date: currentDate, locations: locations));
        } else {
          blockDataListGen.add(BlockData(date: currentDate, locations: []));
        }
      }

      setState(() {
        blockDataList = blockDataListGen;
        updateBlocDataInFirebase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Center(
                child: Text(
                  'Itinnerary Generated Successfully',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'ProductSans',
                  ),
                ),
              ),
            ),
          );
        }
      });
    } else {
      print(response.body);
      print('Request failed with status: ${response.statusCode}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: _dataStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading");
        }
        if (!snapshot.hasData) {
          return const Text("No data available");
        }
        var data = snapshot.data;
        List<BlockData> blockDataListNew = [];
        try {
          if (data?['blockData'] != null) {
            blockDataListNew = List<BlockData>.from(data?['blockData'].map(
                (item) => BlockData(
                    date: DateTime.parse(item['date']),
                    locations: item['locations'])));
          } else {
            throw Exception('blockData is null or not available');
          }
        } catch (e) {
          print(e);
          for (var i = 0;
              i <= widget.endDate.difference(widget.startDate).inDays;
              i++) {
            blockDataListNew.add(BlockData(
                date: widget.startDate.add(Duration(days: i)), locations: []));
          }
        }
        if (!areBlockDataListsEqual(blockDataListNew, blockDataList)) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            setState(() {
              blockDataList.clear();
              blockDataList.addAll(blockDataListNew);
            });
          });
        }
        final themeProvider = Provider.of<ThemeProvider>(context);
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (!widget.isManual)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_fix_normal,
                        color: kGreenColor,
                        size: 18.0,
                      ),
                      GestureDetector(
                        onTap: () {
                          getItinary();
                        },
                        child: Text(
                          'Autofill Itinerary',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'ProductSans',
                            color: kGreenColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(
                  height: 10,
                ),
                for (int i = 0; i < blockDataList.length; i++)
                  Slidable(
                    endActionPane: ActionPane(
                      motion: ScrollMotion(),
                      extentRatio: 0.42,
                      children: [
                        SlidableAction(
                          onPressed: (BuildContext context) {
                            _onDeleteBlock(blockDataList[i]);
                          },
                          label: 'Delete',
                          icon: Icons.delete,
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ],
                    ),
                    child: BlockWidget(
                      suggestions: widget.suggestions,
                      startDate: widget.startDate,
                      endDate: widget.endDate,
                      blockDataList: blockDataList,
                      callbackUpdateFunc: updateBlocDataInFirebase,
                      indx: i,
                      loc: widget.location,
                      onDelete: () {
                        setState(() {
                          blockDataList.remove(blockDataList[i]);
                          updateBlocDataInFirebase();
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onDeleteBlock(BlockData blockData) {
    setState(() {
      blockDataList.remove(blockData);
      updateBlocDataInFirebase();
    });
  }
}

class BlockData {
  final DateTime date;
  List<dynamic> locations;
  BlockData({required this.date, required this.locations});

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'locations': locations,
    };
  }

  factory BlockData.fromMap(Map<String, dynamic> map) {
    return BlockData(
      date: DateTime.parse(map['date']),
      locations: List<String>.from(map['locations']),
    );
  }
}

class BlockWidget extends StatefulWidget {
  final void Function() callbackUpdateFunc;
  final List<BlockData> blockDataList;
  final int indx;
  late BlockData blockData;
  final VoidCallback onDelete;
  final DateTime startDate;
  final DateTime endDate;
  final String loc;
  final List<String> suggestions;
  BlockWidget({
    required this.suggestions,
    required this.callbackUpdateFunc,
    required this.blockDataList,
    required this.indx,
    required this.onDelete,
    required this.startDate,
    required this.endDate,
    required this.loc,
    super.key,
  });
  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Map<String, Map<String, dynamic>> _locationInfoDataMap = {};
  late TextEditingController _locationController;
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  String apiKey = dotenv.env['KEY']!;

  Future<Map<String, double>> getLatAndLongForLoc(String loc) async {
    var params = {
      'param2': loc.toUpperCase(),
      'param1': widget.loc.toLowerCase(),
    };
    var url = Uri.parse('http://$using:8000/getloc');
    var response = await http.get(url.replace(queryParameters: params));
    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);
      print(responseBody);

      var latitude = double.parse(responseBody['latitude'].toString());
      var longitude = double.parse(responseBody['longitude'].toString());

      return {'latitude': latitude, 'longitude': longitude};
    } else {
      print(response.body);
      print('Request failed with status: ${response.statusCode}.');
      return {'latitude': 0.0, 'longitude': 0.0};
    }
  }

  Future<Map<String, dynamic>> fetchLocationData(String loc) async {
    if (_locationInfoDataMap.containsKey(loc)) {
      return _locationInfoDataMap[loc]!;
    } else {
      try {
        final firestoreData = await FirebaseFirestore.instance
            .collection('locations')
            .doc(loc)
            .get();
        if (firestoreData.exists) {
          final data = firestoreData.data()!;
          _locationInfoDataMap[loc] = data;
          return data;
        } else {
          final model = GenerativeModel(
            model: 'gemini-pro',
            apiKey: dotenv.env['GEMINI']!,
          );
          final content = [
            Content.text(
                'Provide the "rating", "description","address", and "timings" of $loc, ${widget.loc} in HH MM format as a string in JSON map format')
          ];
          final response = await model.generateContent(content);
          final responseText = response.text!;
          print(responseText);
          final trimmedResponse = responseText.substring(
              responseText.indexOf('{'), responseText.lastIndexOf('}') + 1);
          final jsonResponseMap = json.decode(trimmedResponse);

          final latLong = await getLatAndLongForLoc(loc);
          final latitude = latLong['latitude'];
          final longitude = latLong['longitude'];

          jsonResponseMap['latitude'] = latitude;
          jsonResponseMap['longitude'] = longitude;

          _locationInfoDataMap[loc] = jsonResponseMap;
          return jsonResponseMap;
        }
      } catch (e) {
        print('Error fetching location data: $e');
        rethrow;
      }
    }
  }

  Future<String> getAddress(String longitude, String latitude) async {
    String endpoint =
        'https://api.mapbox.com/search/geocode/v6/reverse?access_token=$apiKey&longitude=$longitude&latitude=$latitude';
    try {
      var response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print(data);
        print(data['features'][0]['properties']['full_address']);
        String address = data['features'][0]['properties']['full_address'];
        return address;
      } else {
        throw Exception('Failed to load suggestions');
      }
    } catch (e) {
      print('Error: $e');
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    widget.blockData = widget.blockDataList[widget.indx];
    _locationController = TextEditingController();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500), // Adjust duration as needed
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    // getAddress();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _removeLocation(String location) {
    setState(() {
      widget.blockData.locations.remove(location);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    if (widget.blockDataList.isNotEmpty) {
      widget.blockData = widget.blockDataList[widget.indx];
    }
    return AnimatedSize(
      alignment: Alignment.topCenter,
      duration: Duration(milliseconds: 750), // Adjust duration as needed
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
                if (_expanded) {
                  _controller.forward();
                } else {
                  _controller.reverse();
                }
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              padding: EdgeInsets.all(20.0),
              margin: EdgeInsets.symmetric(vertical: 5.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade400,
                  width: 5.0,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: Text(
                  DateFormat('dd MMM yyyy')
                      .format(widget.blockData.date)
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 18.0,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.righteous().fontFamily,
                  ),
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            for (var location in widget.blockData.locations) ...[
              buildLocationInfoWidget(themeProvider, location),
            ],
            SizedBox(height: 10.0),
            AddLocationWidget(
              callbackFunc: widget.callbackUpdateFunc,
              locations: widget.suggestions,
              blockUpd: BlockUpd,
            ),
          ],
        ],
      ),
    );
  }

  Widget buildLocationInfoWidget(ThemeProvider themeProvider, String loc) {
    return FutureBuilder<Map<String, dynamic>>(
      future: fetchLocationData(loc),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          var data = snapshot.data!;
          if (_locationInfoDataMap.containsKey(loc)) {
            var existingData = _locationInfoDataMap[loc]!;
            existingData.addAll(data);
          } else {
            _locationInfoDataMap[loc] = data;
          }
          return _buildLocationInfoWidgetWithData(themeProvider, loc, data);
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildLocationInfoWidgetWithData(
      ThemeProvider themeProvider, String location, Map<String, dynamic> data) {
    var description = data['description'] ?? 'N/A';
    var rating = data['rating'] ?? 'N/A';
    var timings = data['timings'] ?? 'N/A';
    var address = data['address'] ?? 'N/A';
    var longitude = data['longitude'];
    var latitude = data['latitude'];

    return Container(
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.symmetric(vertical: 5.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: kGreenColor,
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on),
              SizedBox(width: 10.0),
              Text(
                location,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.deepOrange[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _removeLocation(location),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.blueAccent),
              SizedBox(width: 10.0),
              Text(
                timings ?? "N/A",
                style: TextStyle(
                  fontSize: 14.0,
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.grey.shade400
                      : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Row(
            children: [
              Icon(Icons.star, color: Colors.blueAccent),
              SizedBox(width: 10.0),
              Text(
                rating.toString(),
                style: TextStyle(
                  fontSize: 14.0,
                  color: themeProvider.themeMode == ThemeMode.dark
                      ? Colors.grey.shade400
                      : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10.0),
              Icon(
                Ionicons.logo_google,
                size: 15,
                color: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 10.0),
          Text(
            description ?? "N/A",
            style: TextStyle(
              fontSize: 16.0,
              fontFamily: 'ProductSans',
              fontWeight: FontWeight.bold,
              color: themeProvider.themeMode == ThemeMode.dark
                  ? Colors.grey.shade400
                  : Colors.grey[700],
            ),
          ),
          SizedBox(height: 10.0),
          buildAddressWidget(themeProvider, address),
          SizedBox(height: 10.0),
          buildDirectionWidgets(location, latitude, longitude),
        ],
      ),
    );
  }

  Widget buildAddressWidget(ThemeProvider themeProvider, String address) {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.blueAccent),
        SizedBox(width: 10.0),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              address,
              style: TextStyle(
                fontSize: 14.0,
                color: themeProvider.themeMode == ThemeMode.dark
                    ? Colors.grey.shade400
                    : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDirectionWidgets(
      String title, double latitude, double longitude) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () async {
              List<Map<String, double>> coordinates = [];

              for (var location in widget.blockData.locations) {
                var data = await fetchLocationData(location);
                var latitude = data['latitude'];
                var longitude = data['longitude'];
                if (latitude != null && longitude != null) {
                  coordinates
                      .add({'latitude': latitude, 'longitude': longitude});
                }
              }
              print(coordinates.toList());
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MarkingMap(coordinatesList: coordinates),
                ),
              );
            },
            child: Text(
              'View on Map',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.deepOrange[500],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 10.0),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final availableMaps = await MapLauncher.installedMaps;
              print(availableMaps);

              if (availableMaps.isNotEmpty) {
                try {
                  await availableMaps.first.showMarker(
                    coords: Coords(latitude, longitude),
                    title: title,
                  );
                } catch (e) {
                  print('Error showing marker: $e');
                }
              } else {
                print('No maps available');
              }
            },
            child: Text(
              'Get Directions',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.deepOrange[500],
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void BlockUpd(String location) {
    setState(() {
      widget.blockData.locations.add(location);
    });
  }

  // List<String> getFilteredSuggestions(String text) {
  //   return widget.suggestions
  //       .where((suggestion) =>
  //           suggestion.toLowerCase().contains(text.toLowerCase()))
  //       .toList();
  // }

  // bool isListViewVisible = false;
  // String selectedLoc = '';
  // Widget buildAddLocationWidget(Function callbackFunc) {
  //   return Padding(
  //     padding: const EdgeInsets.all(8.0),
  //     child: Column(
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: TextField(
  //                 controller: _locationController,
  //                 decoration: InputDecoration(
  //                   hintText: 'Add a location',
  //                   focusedBorder: OutlineInputBorder(
  //                     borderSide: BorderSide(color: Colors.blue),
  //                     borderRadius: BorderRadius.circular(10.0),
  //                   ),
  //                   enabledBorder: OutlineInputBorder(
  //                     borderSide: BorderSide(color: Colors.grey),
  //                     borderRadius: BorderRadius.circular(10.0),
  //                   ),
  //                   contentPadding: EdgeInsets.symmetric(horizontal: 15.0),
  //                 ),
  //                 onTap: () {
  //                   setState(() {
  //                     isListViewVisible = true;
  //                   });
  //                 },
  //                 onChanged: (value) {
  //                   setState(() {});
  //                 },
  //               ),
  //             ),
  //             IconButton(
  //               icon: Icon(Icons.add),
  //               onPressed: () {
  //                 FocusManager.instance.primaryFocus?.unfocus();
  //                 if (_locationController.text.isNotEmpty) {
  //                   setState(() {
  //                     widget.blockData.locations.add(_locationController.text);
  //                     callbackFunc();
  //                     _locationController.clear();
  //                   });
  //                 } else {
  //                   FocusManager.instance.primaryFocus?.unfocus();
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     SnackBar(
  //                       backgroundColor: kRedColor,
  //                       content: Center(
  //                         child: Text(
  //                           'Please enter a location',
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             fontFamily: 'ProductSans',
  //                             color: Colors.white,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   );
  //                 }
  //               },
  //             ),
  //           ],
  //         ),
  //         if (isListViewVisible)
  //           SizedBox(
  //             height: 200,
  //             child: Stack(
  //               children: [
  //                 ListView.builder(
  //                   itemCount:
  //                       getFilteredSuggestions(_locationController.text).length,
  //                   itemBuilder: (context, index) {
  //                     final suggestion = getFilteredSuggestions(
  //                         _locationController.text)[index];
  //                     return ListTile(
  //                       title: Row(
  //                         children: [
  //                           Text(suggestion),
  //                         ],
  //                       ),
  //                       onTap: () {
  //                         setState(() {
  //                           _locationController.text = suggestion;
  //                           selectedLoc = _locationController.text;
  //                           isListViewVisible = false;
  //                           FocusManager.instance.primaryFocus?.unfocus();
  //                         });
  //                       },
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }
}

class AddLocationWidget extends StatefulWidget {
  final Function callbackFunc;
  final List<String> locations;
  final void Function(String) blockUpd;

  AddLocationWidget(
      {required this.callbackFunc,
      required this.locations,
      required this.blockUpd});

  @override
  _AddLocationWidgetState createState() => _AddLocationWidgetState();
}

class _AddLocationWidgetState extends State<AddLocationWidget> {
  final TextEditingController _locationController = TextEditingController();
  bool isListViewVisible = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Add a location',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 15.0),
                  ),
                  onTap: () {
                    setState(() {
                      isListViewVisible = true;
                    });
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (_locationController.text.isNotEmpty) {
                    setState(() {
                      //widget.locations.add(_locationController.text);
                      widget.blockUpd(_locationController.text);
                      widget.callbackFunc();
                      _locationController.clear();
                    });
                  } else {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: kRedColor,
                        content: Center(
                          child: Text(
                            'Please enter a location',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'ProductSans',
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          if (isListViewVisible)
            LocationSuggestions(
              locationController: _locationController,
              suggestions: widget.locations,
              callback: (String suggestion) {
                setState(() {
                  _locationController.text = suggestion;
                  isListViewVisible = false;
                  FocusManager.instance.primaryFocus?.unfocus();
                });
              },
            ),
        ],
      ),
    );
  }
}

class LocationSuggestions extends StatelessWidget {
  final TextEditingController locationController;
  final Function(String) callback;
  List<String> suggestions;

  LocationSuggestions({
    required this.locationController,
    required this.callback,
    required this.suggestions,
  });

  List<String> getFilteredSuggestions(String text) {
    return suggestions
        .where((suggestion) =>
            suggestion.toLowerCase().contains(text.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: getFilteredSuggestions(locationController.text).length,
        itemBuilder: (context, index) {
          final suggestion =
              getFilteredSuggestions(locationController.text)[index];
          return ListTile(
            title: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(suggestion),
                ],
              ),
            ),
            onTap: () {
              callback(suggestion);
            },
          );
        },
      ),
    );
  }
}
