// ignore_for_file: prefer_const_constructors, avoid_init_to_null, no_leading_underscores_for_local_identifiers, prefer_const_literals_to_create_immutables

import 'package:customizable_counter/customizable_counter.dart';
import 'package:date_time_picker_selector/date_time_picker_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:voyager/components/search_section/calender_picker.dart';
import 'package:voyager/components/search_section/date_section.dart';
import 'package:voyager/utils/constants.dart';

class FormForOneWay extends StatefulWidget {
  final Function(List<TicketData>?) onTicketAdded;
  FormForOneWay({super.key, required this.onTicketAdded});

  @override
  State<FormForOneWay> createState() => _FormForOneWayState();
}

class _FormForOneWayState extends State<FormForOneWay> {
  bool areTextFieldsFilled() {
    bool allFilled = true;
    allFilled &= fromAirportcontroller.text.isNotEmpty;
    allFilled &= toAirportcontroller.text.isNotEmpty;
    for (var controller in intermediateAirportController) {
      allFilled &= controller.text.isNotEmpty;
    }
    allFilled &= selectedDepartureDates.every((date) => date != null);
    allFilled &= selectedArrivalDates.every((date) => date != null);
    allFilled &= selectedDepartureTimes.every((time) => time != null);
    allFilled &= selectedArrivalTimes.every((time) => time != null);
    allFilled &= FlightOperators.every((operater) => operater != null);
    allFilled &= FlightNumbers.every((number) => number != null);
    allFilled &= Prices.every((price) => price != null);
    return allFilled;
  }

  void _showErrorSnackbar(String Error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kRedColor,
        // Change the background color of the snackbar
        content: Center(
          child: Text(
            Error,
            style: TextStyle(
              fontSize: 16, // Change the font size as needed
              fontFamily: 'ProductSans', // Change the font family as needed
              color: Colors.white, // Change the text color
            ),
          ),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDatePickerDialog(
      BuildContext context, bool Arrival, Function(DateTime?) setDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return SizedBox(
          height: 300,
          child: AlertDialog(
            backgroundColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.black
                : Colors.white,
            surfaceTintColor: themeProvider.themeMode == ThemeMode.dark
                ? Colors.black
                : Colors.white,
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (Arrival) {
                    setDate(null);
                  } else {
                    setDate(null);
                  }
                },
                child: Text('Clear'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Select'),
              ),
            ],
            content: DatePicker(
              onDateSelected: (date) {
                setDate(date);
              },
            ),
          ),
        );
      },
    );
  }

  bool isListViewVisibleForDeparture = false;
  bool isListViewVisibleForArrival = false;
  TextEditingController fromAirportcontroller = TextEditingController();
  TextEditingController toAirportcontroller = TextEditingController();
  List<TextEditingController> DepartutureTimesController = [
    TextEditingController()
  ];
  List<TextEditingController> ArrivalTimesController = [
    TextEditingController()
  ];

  int stopCount = 0;
  List<TicketData> ticketsData = [
    TicketData(
      fromAirport: '',
      toAirport: '',
      topText: '',
      bottomText: '',
      price: '0',
      isLastItem: false,
      passengers: 0,
      duration: '',
      flightNumber: '',
      flightOperator: '',
      fromDate: '',
      toDate: '',
      fromTime: '',
      toTime: '',
      note: '',
    ),
  ];
  List<DateTime?> selectedDepartureDates = [null];
  List<DateTime?> selectedArrivalDates = [null];
  List<String?> selectedDepartureTimes = [null];
  List<String?> selectedArrivalTimes = [null];

  Map<String, String>? selectedFromAirport;
  Map<String, String>? selectedToAirport;
  List<Map<String, String>?> selectedIntermediateAirports = [];
  List<TextEditingController> intermediateAirportController = [];
  List<bool> isVisibleforIntermediateAirports = [];
  List<TextEditingController> FlightOperator = [TextEditingController()];
  List<String?> FlightOperators = [null];
  List<TextEditingController> FlightNumber = [TextEditingController()];
  List<String?> FlightNumbers = [null];
  List<TextEditingController> Price = [TextEditingController()];
  List<String?> Prices = [null];

  List<Map<String, String>> getFilteredAirports(String searchText) {
    return Airports.where((airport) {
      final String code = airport['code'] ?? '';
      final String name = airport['name'] ?? '';
      final String place = airport['place'] ?? '';
      return code.toLowerCase().contains(searchText.toLowerCase()) ||
          name.toLowerCase().contains(searchText.toLowerCase()) ||
          place.toLowerCase().contains(searchText.toLowerCase());
    }).toList();
  }

  String calculateDuration(DateTime? departureDate, String? departureTime,
      DateTime? arrivalDate, String? arrivalTime) {
    if (departureDate == null ||
        arrivalDate == null ||
        departureTime == null ||
        arrivalTime == null) {
      return '';
    }
    DateTime departureDateTime = DateTime(
        departureDate.year,
        departureDate.month,
        departureDate.day,
        int.parse(departureTime.split(':')[0]),
        int.parse(departureTime.split(':')[1]));
    DateTime arrivalDateTime = DateTime(
        arrivalDate.year,
        arrivalDate.month,
        arrivalDate.day,
        int.parse(arrivalTime.split(':')[0]),
        int.parse(arrivalTime.split(':')[1]));
    Duration duration = arrivalDateTime.difference(departureDateTime);
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    String formattedDuration = '${hours}h ${minutes}m';
    return formattedDuration;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back_ios,
            size: 20,
          ),
        ),
        title: Text(
          'Add Your Flight Journey',
          style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Number of Stops',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Spacer(),
                      CustomizableCounter(
                        borderWidth: 1,
                        showButtonText: false,
                        count: 0,
                        step: 1,
                        minCount: 0,
                        incrementIcon: Icon(
                          Icons.add,
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        decrementIcon: Icon(
                          Icons.remove,
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                        onCountChange: (count) {
                          for (int i = stopCount; i < count.toInt(); i++) {
                            ticketsData.add(TicketData(
                              fromAirport: '',
                              toAirport: '',
                              topText: '',
                              bottomText: '',
                              price: '0',
                              isLastItem: false,
                              passengers: 0,
                              duration: '',
                              flightNumber: '',
                              flightOperator: '',
                              fromDate: '',
                              toDate: '',
                              fromTime: '',
                              toTime: '',
                              note: '',
                            ));
                            selectedDepartureDates.add(null);
                            selectedArrivalDates.add(null);
                            selectedDepartureTimes.add(null);
                            selectedArrivalTimes.add(null);
                            selectedIntermediateAirports.add(null);
                            intermediateAirportController
                                .add(TextEditingController());
                            isVisibleforIntermediateAirports.add(false);
                            FlightOperator.add(TextEditingController());
                            FlightOperators.add(null);
                            FlightNumber.add(TextEditingController());
                            FlightNumbers.add(null);
                            Price.add(TextEditingController());
                            DepartutureTimesController.add(
                                TextEditingController());
                            ArrivalTimesController.add(TextEditingController());
                            Prices.add(null);
                          }
                          for (int i = stopCount; i > count.toInt(); i--) {
                            ticketsData.removeLast();
                            selectedDepartureDates.removeLast();
                            selectedArrivalDates.removeLast();
                            selectedDepartureTimes.removeLast();
                            selectedArrivalTimes.removeLast();
                            selectedIntermediateAirports.removeLast();
                            intermediateAirportController.removeLast();
                            isVisibleforIntermediateAirports.removeLast();
                            FlightOperator.removeLast();
                            FlightOperators.removeLast();
                            FlightNumbers.removeLast();
                            Price.removeLast();
                            DepartutureTimesController.removeLast();
                            ArrivalTimesController.removeLast();
                            Prices.removeLast();
                          }
                          setState(() {
                            stopCount = count.toInt();
                          });
                        },
                        onIncrement: (count) {},
                        onDecrement: (count) {},
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 0.8 * screenWidth,
                            child: TextField(
                              controller: fromAirportcontroller,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.near_me,
                                ),
                                hintText: 'From',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: themeProvider.themeMode ==
                                            ThemeMode.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: kGreenColor,
                                  ),
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  isListViewVisibleForDeparture = true;
                                });
                              },
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isListViewVisibleForDeparture)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          height: 200,
                          child: Stack(
                            children: [
                              ListView.builder(
                                itemCount: getFilteredAirports(
                                        fromAirportcontroller.text)
                                    .length,
                                itemBuilder: (context, index) {
                                  final airport = getFilteredAirports(
                                      fromAirportcontroller.text)[index];
                                  return ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth: 0.8 * screenWidth),
                                    child: ListTile(
                                      title: SizedBox(
                                        width: 0.8 * screenWidth,
                                        child: Row(
                                          children: [
                                            Text('${airport['code']}'),
                                            SizedBox(width: 5),
                                            ConstrainedBox(
                                                constraints: BoxConstraints(
                                                    maxWidth:
                                                        0.65 * screenWidth),
                                                child: Text(
                                                  '${airport['name']}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ))
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          fromAirportcontroller.text =
                                              airport['name'] ?? '';
                                          isListViewVisibleForDeparture = false;
                                          selectedFromAirport = airport;
                                          if (stopCount == 0) {
                                            if (selectedToAirport != null &&
                                                toAirportcontroller.text ==
                                                    fromAirportcontroller
                                                        .text) {
                                              _showErrorSnackbar(
                                                  'The From Airport cannot be equal to To Airport');
                                              selectedFromAirport = null;
                                              fromAirportcontroller.clear();
                                            }
                                          } else {
                                            if (selectedToAirport != null &&
                                                toAirportcontroller.text ==
                                                    fromAirportcontroller
                                                        .text) {
                                              _showErrorSnackbar(
                                                  'The From Airport cannot be equal to To Airport');
                                              selectedFromAirport = null;
                                              fromAirportcontroller.clear();
                                            }
                                            for (int i = 0;
                                                i < stopCount;
                                                i++) {
                                              if (selectedIntermediateAirports[
                                                          i] !=
                                                      null &&
                                                  intermediateAirportController[
                                                              i]
                                                          .text ==
                                                      fromAirportcontroller
                                                          .text) {
                                                _showErrorSnackbar(
                                                    'The From Airport cannot be equal to Intermediate Airport ${i + 1}');
                                                selectedFromAirport = null;
                                                fromAirportcontroller.clear();
                                                break;
                                              }
                                            }
                                          }
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 0.8 * screenWidth,
                          child: TextField(
                            controller: toAirportcontroller,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.location_on,
                              ),
                              hintText: 'To',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color:
                                      themeProvider.themeMode == ThemeMode.dark
                                          ? Colors.white
                                          : Colors.black,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: kGreenColor,
                                ),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                isListViewVisibleForArrival = true;
                              });
                            },
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    if (isListViewVisibleForArrival)
                      SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            ListView.builder(
                              itemCount:
                                  getFilteredAirports(toAirportcontroller.text)
                                      .length,
                              itemBuilder: (context, index) {
                                final airport = getFilteredAirports(
                                    toAirportcontroller.text)[index];
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: 0.8 * screenWidth),
                                  child: ListTile(
                                    title: SizedBox(
                                      width: 0.8 * screenWidth,
                                      child: Row(
                                        children: [
                                          Text('${airport['code']}'),
                                          SizedBox(width: 5),
                                          ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxWidth: 0.65 * screenWidth),
                                              child: Text(
                                                '${airport['name']}',
                                                overflow: TextOverflow.ellipsis,
                                              ))
                                        ],
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        toAirportcontroller.text =
                                            airport['name'] ?? '';
                                        isListViewVisibleForArrival = false;
                                        selectedToAirport = airport;
                                        if (stopCount == 0) {
                                          if (selectedFromAirport != null &&
                                              toAirportcontroller.text ==
                                                  fromAirportcontroller.text) {
                                            _showErrorSnackbar(
                                                'The From Airport cannot be equal to To Airport');
                                            selectedToAirport = null;
                                            toAirportcontroller.clear();
                                          }
                                        } else {
                                          if (selectedFromAirport != null &&
                                              toAirportcontroller.text ==
                                                  fromAirportcontroller.text) {
                                            _showErrorSnackbar(
                                                'The From Airport cannot be equal to To Airport');
                                            selectedToAirport = null;
                                            toAirportcontroller.clear();
                                          }
                                          if (selectedToAirport != null) {
                                            for (int i = 0;
                                                i < stopCount;
                                                i++) {
                                              if (selectedIntermediateAirports[
                                                          i] !=
                                                      null &&
                                                  intermediateAirportController[
                                                              i]
                                                          .text ==
                                                      toAirportcontroller
                                                          .text) {
                                                _showErrorSnackbar(
                                                    'The To Airport cannot be equal to Intermediate Airport ${i + 1}');
                                                selectedToAirport = null;
                                                toAirportcontroller.clear();
                                                break;
                                              }
                                            }
                                          }
                                        }
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                ListView.builder(
                  itemCount: stopCount + 1,
                  shrinkWrap: true,
                  physics: ClampingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 0, 20, 0),
                      child: Column(
                        children: [
                          if (index != 0)
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 0.8 * screenWidth,
                                        child: TextField(
                                          controller:
                                              intermediateAirportController[
                                                  index - 1],
                                          decoration: InputDecoration(
                                            prefixIcon: Icon(
                                              Icons.near_me,
                                            ),
                                            hintText:
                                                'Intermediate Airport $index',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color:
                                                    themeProvider.themeMode ==
                                                            ThemeMode.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: kGreenColor,
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              isVisibleforIntermediateAirports[
                                                  index - 1] = true;
                                            });
                                          },
                                          onChanged: (value) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isVisibleforIntermediateAirports[index - 1])
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: SizedBox(
                                      height: 200,
                                      child: Stack(
                                        children: [
                                          ListView.builder(
                                            itemCount: getFilteredAirports(
                                                    intermediateAirportController[
                                                            index - 1]
                                                        .text)
                                                .length,
                                            itemBuilder: (context, index1) {
                                              final airport = getFilteredAirports(
                                                  intermediateAirportController[
                                                          index - 1]
                                                      .text)[index1];
                                              return ConstrainedBox(
                                                constraints: BoxConstraints(
                                                    maxWidth:
                                                        0.8 * screenWidth),
                                                child: ListTile(
                                                  title: SizedBox(
                                                    width: 0.8 * screenWidth,
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                            '${airport['code']}'),
                                                        SizedBox(width: 5),
                                                        ConstrainedBox(
                                                            constraints: BoxConstraints(
                                                                maxWidth: 0.65 *
                                                                    screenWidth),
                                                            child: Text(
                                                              '${airport['name']}',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ))
                                                      ],
                                                    ),
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      intermediateAirportController[
                                                                  index - 1]
                                                              .text =
                                                          airport['name'] ?? '';
                                                      isVisibleforIntermediateAirports[
                                                          index - 1] = false;
                                                      selectedIntermediateAirports[
                                                          index - 1] = airport;
                                                      FocusManager
                                                          .instance.primaryFocus
                                                          ?.unfocus();
                                                    });
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                if (stopCount == 0)
                                  Text(
                                    'Departure Date',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                else
                                  Text(
                                    'Departure Date for flight ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                Spacer(),
                                if (selectedDepartureDates[index] != null)
                                  DateDisplayer(
                                    Date: selectedDepartureDates[index]!
                                        .day
                                        .toString(),
                                    Day: selectedDepartureDates[index]!.weekday,
                                    month: selectedDepartureDates[index]!.month,
                                    Year: selectedDepartureDates[index]!
                                        .year
                                        .toString(),
                                    valid: true,
                                  )
                                else
                                  DateDisplayer(
                                    Date: 'Month',
                                    Day: 0,
                                    month: 0,
                                    Year: '',
                                    valid: false,
                                  ),
                                IconButton(
                                  icon: Icon(Icons.calendar_month),
                                  onPressed: () {
                                    _showDatePickerDialog(context, false,
                                        (DateTime? date) {
                                      setState(() {
                                        selectedDepartureDates[index] = date;
                                        if (index > 0 &&
                                            selectedArrivalDates[index - 1] !=
                                                null) {
                                          if (selectedDepartureDates[index]!
                                              .isBefore(selectedArrivalDates[
                                                  index - 1]!)) {
                                            Navigator.of(context).pop();
                                            _showErrorSnackbar(
                                                'The Departure Date for flight ${index + 1} should be after the Arrival date for flight $index');
                                            selectedDepartureDates[index] =
                                                null;
                                          }
                                        }
                                        if (selectedDepartureDates[index] !=
                                            null) {
                                          if (selectedArrivalDates[index] !=
                                              null) {
                                            if (selectedArrivalDates[index]!
                                                .isBefore(
                                                    selectedDepartureDates[
                                                        index]!)) {
                                              if (stopCount > 0) {
                                                Navigator.of(context).pop();
                                                _showErrorSnackbar(
                                                    'The Departure Date for flight ${index + 1} should be before the Arrival date for flight ${index + 1}');
                                              } else {
                                                Navigator.of(context).pop();
                                                _showErrorSnackbar(
                                                    'The Departure Date should be before the Arrival date');
                                              }
                                              selectedDepartureDates[index] =
                                                  null;
                                            }
                                          }
                                        }
                                      });
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                if (stopCount == 0)
                                  Text(
                                    'Arrival Date',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                else
                                  Text(
                                    'Arrival Date for flight ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                Spacer(),
                                if (selectedArrivalDates[index] != null)
                                  DateDisplayer(
                                    Date: selectedArrivalDates[index]!
                                        .day
                                        .toString(),
                                    Day: selectedArrivalDates[index]!.weekday,
                                    month: selectedArrivalDates[index]!.month,
                                    Year: selectedArrivalDates[index]!
                                        .year
                                        .toString(),
                                    valid: true,
                                  )
                                else
                                  DateDisplayer(
                                    Date: 'Month',
                                    Day: 0,
                                    month: 0,
                                    Year: '',
                                    valid: false,
                                  ),
                                IconButton(
                                  icon: Icon(Icons.calendar_month),
                                  onPressed: () {
                                    _showDatePickerDialog(context, true,
                                        (DateTime? date) {
                                      setState(() {
                                        selectedArrivalDates[index] = date;
                                        if (index < stopCount - 1 &&
                                            selectedDepartureDates[index + 1] !=
                                                null) {
                                          if (selectedDepartureDates[index + 1]!
                                              .isBefore(selectedArrivalDates[
                                                  index]!)) {
                                            Navigator.of(context).pop();
                                            _showErrorSnackbar(
                                                'The Departure Date for flight ${index + 2} should be after the Arrival date for flight ${index + 1}');
                                            selectedArrivalDates[index] = null;
                                          }
                                        }
                                        if (selectedArrivalDates[index] !=
                                            null) {
                                          if (selectedDepartureDates[index] !=
                                              null) {
                                            if (selectedArrivalDates[index]!
                                                .isBefore(
                                                    selectedDepartureDates[
                                                        index]!)) {
                                              if (stopCount > 0) {
                                                Navigator.of(context).pop();
                                                _showErrorSnackbar(
                                                    'The Departure Date for flight ${index + 1} should be before the Arrival date for flight ${index + 1}');
                                              } else {
                                                Navigator.of(context).pop();
                                                _showErrorSnackbar(
                                                    'The Departure Date should be before the Arrival date');
                                              }
                                              selectedArrivalDates[index] =
                                                  null;
                                            }
                                          }
                                        }
                                      });
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                if (stopCount == 0)
                                  Text(
                                    'Departure Time',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                else
                                  Text(
                                    'Departure Time for flight ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                Spacer(),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 30, 0),
                                  child: SizedBox(
                                    width: 80,
                                    child: DateTimePicker(
                                      type: DateTimePickerType.time,
                                      controller:
                                          DepartutureTimesController[index],
                                      onChanged: (val) {
                                        setState(() {
                                          selectedDepartureTimes[index] = val;
                                          if (selectedArrivalDates[index] ==
                                                  null ||
                                              selectedDepartureDates[index] ==
                                                  null) {
                                            selectedDepartureTimes[index] =
                                                null;
                                            DepartutureTimesController[index]
                                                .clear();
                                            if (stopCount == 0) {
                                              _showErrorSnackbar(
                                                  'Please select the Departure and Arrival Dates before selecting the Departure time');
                                            } else {
                                              _showErrorSnackbar(
                                                  'Please select the Departure and Arrival Dates for flight ${index + 1} before selecting the Departure time');
                                            }
                                          } else {
                                            if (selectedDepartureDates[index] ==
                                                    selectedArrivalDates[
                                                        index] &&
                                                selectedArrivalTimes[index] !=
                                                    null) {
                                              if (DateTime.parse(
                                                          "2024-04-03 ${selectedArrivalTimes[index]!}:00")
                                                      .compareTo(DateTime.parse(
                                                          "2024-04-03 ${selectedDepartureTimes[index]!}:00")) <=
                                                  0) {
                                                selectedDepartureTimes[index] =
                                                    null;
                                                DepartutureTimesController[
                                                        index]
                                                    .clear();
                                                _showErrorSnackbar(
                                                    'The Departure Time must be before the Arrival time');
                                              }
                                            }
                                            if (selectedDepartureTimes[index] !=
                                                null) {
                                              if (index > 0 &&
                                                  selectedArrivalDates[
                                                          index - 1] !=
                                                      null &&
                                                  selectedArrivalDates[
                                                          index - 1] ==
                                                      selectedDepartureDates[
                                                          index]) {
                                                if (selectedArrivalTimes[
                                                        index - 1] !=
                                                    null) {
                                                  debugPrint('hi');
                                                  if (DateTime.parse(
                                                              "2024-04-03 ${selectedArrivalTimes[index - 1]!}:00")
                                                          .compareTo(DateTime.parse(
                                                              "2024-04-03 ${selectedDepartureTimes[index]!}:00")) >
                                                      0) {
                                                    selectedDepartureTimes[
                                                        index] = null;
                                                    DepartutureTimesController[
                                                            index]
                                                        .clear();
                                                    _showErrorSnackbar(
                                                        'The Departure Time for flight ${index + 1} must be after the Arrival time $index');
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        });
                                      },
                                      validator: (val) {
                                        return null;
                                      },
                                      onSaved: (val) {},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                if (stopCount == 0)
                                  Text(
                                    'Arrival Time',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                else
                                  Text(
                                    'Arrival Time for flight ${index + 1}',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                Spacer(),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 0, 30, 0),
                                  child: SizedBox(
                                    width: 80,
                                    child: DateTimePicker(
                                      type: DateTimePickerType.time,
                                      controller: ArrivalTimesController[index],
                                      onChanged: (val) {
                                        setState(() {
                                          selectedArrivalTimes[index] = val;
                                          if (selectedArrivalDates[index] ==
                                                  null ||
                                              selectedDepartureDates[index] ==
                                                  null) {
                                            selectedArrivalTimes[index] = null;
                                            ArrivalTimesController[index]
                                                .clear();
                                            if (stopCount == 0) {
                                              _showErrorSnackbar(
                                                  'Please select the Departure and Arrival Dates before selecting the Arrival time');
                                            } else {
                                              _showErrorSnackbar(
                                                  'Please select the Departure and Arrival Dates for flight ${index + 1} before selecting the Arrival time');
                                            }
                                          } else {
                                            if (selectedDepartureDates[index] ==
                                                    selectedArrivalDates[
                                                        index] &&
                                                selectedDepartureTimes[index] !=
                                                    null) {
                                              if (DateTime.parse(
                                                          "2024-04-03 ${selectedArrivalTimes[index]!}:00")
                                                      .compareTo(DateTime.parse(
                                                          "2024-04-03 ${selectedDepartureTimes[index]!}:00")) <=
                                                  0) {
                                                selectedArrivalTimes[index] =
                                                    null;
                                                ArrivalTimesController[index]
                                                    .clear();
                                                _showErrorSnackbar(
                                                    'The Departure Time must be before the Arrival time');
                                              }
                                            }
                                            if (selectedArrivalTimes[index] !=
                                                null) {
                                              if (index < stopCount - 1 &&
                                                  selectedDepartureDates[
                                                          index + 1] !=
                                                      null &&
                                                  selectedDepartureDates[
                                                          index + 1] ==
                                                      selectedArrivalDates[
                                                          index]) {
                                                if (selectedDepartureTimes[
                                                        index + 1] !=
                                                    null) {
                                                  if (DateTime.parse(
                                                              "2024-04-03 ${selectedDepartureTimes[index + 1]!}:00")
                                                          .compareTo(DateTime.parse(
                                                              "2024-04-03 ${selectedArrivalTimes[index]!}:00")) >
                                                      0) {
                                                    selectedArrivalTimes[
                                                        index] = null;
                                                    ArrivalTimesController[
                                                            index]
                                                        .clear();
                                                    _showErrorSnackbar(
                                                        'The Departure Time for flight ${index + 2} must be after the Arrival time ${index + 1}');
                                                  }
                                                }
                                              }
                                            }
                                          }
                                        });
                                      },
                                      validator: (val) {
                                        print(val);
                                        return null;
                                      },
                                      onSaved: (val) {},
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(18.0, 20, 18, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 0.8 * screenWidth,
                                  child: TextField(
                                    controller: FlightOperator[index],
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.flight,
                                      ),
                                      hintText: stopCount == 0
                                          ? 'Flight Operator'
                                          : 'Flight Operator for ${index + 1}',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: themeProvider.themeMode ==
                                                  ThemeMode.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: kGreenColor,
                                        ),
                                      ),
                                    ),
                                    onTap: () {},
                                    onChanged: (value) {
                                      setState(() {
                                        FlightOperators[index] = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(18.0, 10, 18, 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 0.8 * screenWidth,
                                  child: TextField(
                                    controller: FlightNumber[index],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            signed: true, decimal: true),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(5),
                                    ],
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.numbers,
                                      ),
                                      hintText: stopCount == 0
                                          ? 'Flight Number'
                                          : 'Flight Number for ${index + 1}',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: themeProvider.themeMode ==
                                                  ThemeMode.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: kGreenColor,
                                        ),
                                      ),
                                    ),
                                    onEditingComplete: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                    onTap: () {},
                                    onChanged: (value) {
                                      setState(() {
                                        FlightNumbers[index] = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18.0, 10, 18, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 0.8 * screenWidth,
                                  child: TextField(
                                    controller: Price[index],
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            signed: true, decimal: true),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(5),
                                    ],
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Iconsax.dollar_circle,
                                      ),
                                      hintText: stopCount == 0
                                          ? 'Flight Price'
                                          : 'Flight Price for ${index + 1}',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: themeProvider.themeMode ==
                                                  ThemeMode.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: kGreenColor,
                                        ),
                                      ),
                                    ),
                                    onEditingComplete: () {
                                      FocusScope.of(context).unfocus();
                                    },
                                    onTap: () {},
                                    onChanged: (value) {
                                      setState(() {
                                        Prices[index] = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                          color: Colors.grey[800],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Text('Add To Trip',
                              style: TextStyle(
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ),
                    onTap: () {
                      if (areTextFieldsFilled()) {
                        for (int i = 0; i <= stopCount; i++) {
                          TicketData newTicket = TicketData(
                            fromAirport: i == 0
                                ? selectedFromAirport!['name']!
                                : selectedIntermediateAirports[i - 1]!['name']!,
                            toAirport: i == stopCount
                                ? selectedToAirport!['name']!
                                : selectedIntermediateAirports[i]!['name']!,
                            topText: i == 0
                                ? selectedFromAirport!['code']!
                                : selectedIntermediateAirports[i - 1]!['code']!,
                            bottomText: i == stopCount
                                ? selectedToAirport!['code']!
                                : selectedIntermediateAirports[i]!['code']!,
                            price: Prices[i]!,
                            isLastItem: false,
                            passengers: 0,
                            duration: calculateDuration(
                                selectedDepartureDates[i],
                                selectedDepartureTimes[i],
                                selectedArrivalDates[i],
                                selectedArrivalTimes[i]),
                            flightNumber: FlightNumbers[i]!,
                            flightOperator: FlightOperators[i]!,
                            fromDate: DateFormat('dd MMM')
                                .format(selectedDepartureDates[i]!),
                            toDate: DateFormat('dd MMM')
                                .format(selectedArrivalDates[i]!),
                            fromTime: selectedDepartureTimes[i]!,
                            toTime: selectedArrivalTimes[i]!,
                          );
                          ticketsData[i] = newTicket;
                        }
                        widget.onTicketAdded(ticketsData);
                        Navigator.pop(context);
                      } else {
                        _showErrorSnackbar(
                            'Please fill all fields to add to trip');
                      }
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TicketData {
  final String fromAirport;
  final String toAirport;
  final String topText;
  final String bottomText;
  final String price;
  final bool isLastItem;
  final int passengers;
  final String duration;
  final String flightNumber;
  final String flightOperator;
  final String fromDate;
  final String toDate;
  final String fromTime;
  final String toTime;
  String? note;

  TicketData({
    required this.fromAirport,
    required this.toAirport,
    required this.topText,
    required this.bottomText,
    required this.price,
    required this.isLastItem,
    required this.passengers,
    required this.duration,
    required this.flightNumber,
    required this.flightOperator,
    required this.fromDate,
    required this.toDate,
    required this.fromTime,
    required this.toTime,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromAirport': fromAirport,
      'toAirport': toAirport,
      'topText': topText,
      'bottomText': bottomText,
      'price': price,
      'isLastItem': isLastItem,
      'passengers': passengers,
      'duration': duration,
      'flightNumber': flightNumber,
      'flightOperator': flightOperator,
      'fromDate': fromDate,
      'toDate': toDate,
      'fromTime': fromTime,
      'toTime': toTime,
      'note': note,
    };
  }

  factory TicketData.fromJSON(Map<String, dynamic> json) {
    return TicketData(
      fromAirport: json['fromAirport'],
      toAirport: json['toAirport'],
      topText: json['topText'],
      bottomText: json['bottomText'],
      price: json['price'],
      isLastItem: json['isLastItem'],
      passengers: json['passengers'],
      duration: json['duration'],
      flightNumber: json['flightNumber'],
      flightOperator: json['flightOperator'],
      fromDate: json['fromDate'],
      toDate: json['toDate'],
      fromTime: json['fromTime'],
      toTime: json['toTime'],
      note: json['note'],
    );
  }
}
