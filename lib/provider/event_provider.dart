import 'package:event_note_taker/model/event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventProvider = StateNotifierProvider<EventNotifier, List<Event>>((ref) {
  return EventNotifier();
});

class EventNotifier extends StateNotifier<List<Event>> {
  EventNotifier() : super([]);

  void addEvent(Event event) {
    state = [...state, event];
  }

  void removeEvent(Event event) {
    state = state.where((e) => e != event).toList();
  }
}
