import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Event Calendar',
      home: const CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, bool> _events;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _events = {};
    _selectedDate = DateTime.now();
    _loadEvents();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day); // Ignore the time part
  }

  _loadEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? eventsString = prefs.getString('events');
    if (eventsString != null) {
      try {
        Map<String, dynamic> eventsMap = json.decode(eventsString);
        setState(() {
          _events = eventsMap.map((key, value) {
            DateTime date = DateTime.parse(key);
            return MapEntry(date, value);
          });
        });
      } catch (e) {
        print("Failed to load events: $e");
      }
    }
  }

  _saveEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> eventsMap = _events.map((key, value) {
      return MapEntry(key.toIso8601String(), value);
    });
    String eventsString = json.encode(eventsMap);
    await prefs.setString('events', eventsString);
  }

  // Make sure isEventMarked is a function
  bool isEventMarked(DateTime date) {
    return _events
        .containsKey(_normalizeDate(date)); // Use normalized date comparison
  }

  void _showEventDialog(DateTime selectedDate) {
    bool eventMarked = isEventMarked(selectedDate);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(eventMarked
              ? "Modify Event on ${selectedDate.toLocal().toString().split(' ')[0]}"
              : "Mark Event on ${selectedDate.toLocal().toString().split(' ')[0]}"),
          content: const Text("Do you want to modify this date's event?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  _events[_normalizeDate(selectedDate)] =
                      false; // Mark as No event
                });
                _saveEvents();
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  foregroundColor: MaterialStateProperty.all(Colors.white)),
              child: const Text("No Event"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _events[_normalizeDate(selectedDate)] =
                      true; // Mark as Yes event
                });
                _saveEvents();
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green),
                  foregroundColor: MaterialStateProperty.all(Colors.white)),
              child: const Text("Event"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _events.remove(_normalizeDate(selectedDate)); // Reset event
                });
                _saveEvents();
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.grey),
                  foregroundColor: MaterialStateProperty.all(Colors.white)),
              child: const Text("Reset Event"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        backgroundColor: Colors.tealAccent,
        title: const Text('Event Calendar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
                _showEventDialog(selectedDay);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(blurRadius: 4, color: Colors.orange.shade700)
                  ],
                ),
                todayTextStyle: const TextStyle(color: Colors.white),
                selectedDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                defaultTextStyle: const TextStyle(color: Colors.black),
                outsideDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              onPageChanged: (focusedDay) {
                _selectedDate = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, focusedDay) {
                  bool isEvent = _events.containsKey(_normalizeDate(date));
                  bool isYesEvent =
                      isEvent && _events[_normalizeDate(date)] == true;
                  bool isNoEvent =
                      isEvent && _events[_normalizeDate(date)] == false;

                  BoxDecoration decoration = BoxDecoration();
                  TextStyle textStyle = const TextStyle(color: Colors.black);

                  if (isYesEvent) {
                    decoration = BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.green.shade600)
                      ],
                    );
                    textStyle = const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold);
                  } else if (isNoEvent) {
                    decoration = BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.red.shade600)
                      ],
                    );
                    textStyle = const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold);
                  }

                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: decoration,
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: textStyle,
                      ),
                    ),
                  );
                },
                todayBuilder: (context, date, focusedDay) {
                  bool isEvent = _events.containsKey(_normalizeDate(date));
                  bool isYesEvent =
                      isEvent && _events[_normalizeDate(date)] == true;
                  bool isNoEvent =
                      isEvent && _events[_normalizeDate(date)] == false;

                  BoxDecoration decoration = BoxDecoration();
                  TextStyle textStyle = const TextStyle(color: Colors.black);

                  if (date.day == DateTime.now().day &&
                      date.month == DateTime.now().month &&
                      date.year == DateTime.now().year) {
                    decoration = BoxDecoration(
                      color: Colors.yellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.yellow.shade700)
                      ],
                    );
                    textStyle = const TextStyle(color: Colors.black);
                  }

                  if (isYesEvent) {
                    decoration = BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    );
                  } else if (isNoEvent) {
                    decoration = BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: decoration,
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: textStyle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
