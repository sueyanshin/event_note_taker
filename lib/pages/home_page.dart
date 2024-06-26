import 'package:event_note_taker/model/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../service/database_helper.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime selectedDay = DateTime.now();
  late Future<List<Event>> events;

  @override
  void initState() {
    super.initState();
    _refreshEvents();
  }

  void _refreshEvents() {
    setState(() {
      events = DatabaseHelper.instance.readEventsByDate(selectedDay);
      // events = DatabaseHelper.instance.readAllEvents();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      this.selectedDay = selectedDay;
      _refreshEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('အကြွေးစာရင်းမှတ်တမ်း'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: selectedDay,
            firstDay: DateTime.utc(2023, 3, 1),
            lastDay: DateTime.utc(2030, 3, 1),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            selectedDayPredicate: (day) {
              return isSameDay(selectedDay, day);
            },
            onDaySelected: onDaySelected,
          ),
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: events,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('An error occurred: ${snapshot.error}'));
                } else {
                  final events = snapshot.data ?? [];

                  if (events.isEmpty) {
                    return const Center(
                        child: Text('ဒီနေ့အတွက် အချက်အလက်များ မရှိပါ၊'));
                  }

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(event.name),
                                    Text(
                                      'ငွေပမာဏ: ${event.amount} ks',
                                      style:
                                          const TextStyle(color: Colors.green),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "${event.name} ကိုဖျက်မည်သေချာလား?"),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child:
                                                          const Text('Cancel')),
                                                  TextButton(
                                                      onPressed: () async {
                                                        await DatabaseHelper
                                                            .instance
                                                            .deleteEvent(
                                                                event.id!);
                                                        _refreshEvents();
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child:
                                                          const Text('Delete')),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        )),
                                    Checkbox(
                                        value: event.status,
                                        onChanged: (bool? newValue) async {
                                          if (newValue != event.status) {
                                            final updatedEvent =
                                                event.copy(status: newValue);
                                            await DatabaseHelper.instance
                                                .updateEvent(updatedEvent);
                                            _refreshEvents();
                                            if (event.status != true) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        '${event.name} က ဒီနေ့အတွက် ပေးပြီးပါပြီ။')),
                                              );
                                            }
                                          }
                                        })
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('လူအသစ်ထည့်မည်'),
          content: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'နာမည်',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  controller: _nameController,
                ),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'ငွေပမာဏ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  controller: _amountController,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final name = _nameController.text;
                  final amount = int.tryParse(_amountController.text) ?? 0;

                  if (name.isEmpty || amount <= 0) {
                    // Show an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid input')),
                    );
                    return;
                  }

                  final event = Event(
                    name: name,
                    amount: amount,
                    remark: "",
                    date: selectedDay,
                  );

                  await DatabaseHelper.instance.createEvent(event);
                  _refreshEvents();
                  _nameController.clear();
                  _amountController.clear();
                  Navigator.of(context).pop();
                } catch (e) {
                  // print('Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('An error occurred while saving the event')),
                  );
                }
              },
              child: const Text('သိမ်းမယ်'),
            ),
          ],
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
