import 'package:flutter/material.dart';
import 'package:dosifi_flutter/presentation/widgets/calendar/dosifi_calendar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // MainShellScreen provides Scaffold/AppBar; this screen only renders the calendar content
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: DosifiCalendar(),
      ),
    );
  }
}
