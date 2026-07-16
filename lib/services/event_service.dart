import '../data/models/event_model.dart';

class EventService {
  final List<EventModel> _events = [];

  Future<List<EventModel>> getEvents() async {
    return _events;
  }

  Future<void> createEvent(EventModel event) async {
    _events.add(event);
  }

  Future<EventModel> getEventById(String id) async {
    return _events.firstWhere((e) => e.id == id);
  }
}