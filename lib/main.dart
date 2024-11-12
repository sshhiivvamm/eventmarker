import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Event Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
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
  late Map<DateTime, bool>
      _events; // Map to store events (true for Yes, false for No)
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _events = {}; // Initialize the event map
    _selectedDate = DateTime.now(); // Default to today's date
  }

  // Normalize the DateTime to ignore the time part
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Function to show the event dialog and update color
  void _showEventDialog(DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              "Mark Event on ${selectedDate.toLocal().toString().split(' ')[0]}"),
          content: const Text("Do you want to mark this date with an event?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  _events[_normalizeDate(selectedDate)] =
                      false; // No event, red
                });
                Navigator.of(context).pop();
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _events[_normalizeDate(selectedDate)] =
                      true; // Yes event, green
                });
                Navigator.of(context).pop();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  // Helper function to check if a date is selected
  bool isEventMarked(DateTime date) {
    return _events
        .containsKey(_normalizeDate(date)); // Compare only the date part
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Calendar'),
      ),
      body: Column(
        children: <Widget>[
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) =>
                isSameDay(day, _selectedDate), // Check if the day is selected
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              _showEventDialog(
                  selectedDay); // Show the event dialog when a day is selected
            },
            calendarStyle: const CalendarStyle(
              // Customize the default appearance
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: Colors.white),
              defaultTextStyle: TextStyle(color: Colors.black),
              outsideDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
            onPageChanged: (focusedDay) {
              _selectedDate = focusedDay; // Keep track of the selected day
            },
            // Use calendarBuilders to customize the individual days
            calendarBuilders: CalendarBuilders(
              todayBuilder: (context, date, focusedDay) {
                bool isEvent = _events.containsKey(_normalizeDate(date));
                bool isYesEvent =
                    isEvent && _events[_normalizeDate(date)] == true;
                bool isNoEvent =
                    isEvent && _events[_normalizeDate(date)] == false;

                BoxDecoration decoration = const BoxDecoration();
                TextStyle textStyle = const TextStyle(color: Colors.black);

                // Set decoration and text style based on the event type
                if (isYesEvent) {
                  decoration = const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  );
                  textStyle = const TextStyle(color: Colors.white);
                } else if (isNoEvent) {
                  decoration = const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  );
                  textStyle = const TextStyle(color: Colors.white);
                }

                // Return a custom day widget with the modified decoration
                return Container(
                  margin: const EdgeInsets.all(4),
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
    );
  }
}
