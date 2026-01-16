enum EventCardType {
  gainCredits,
  loseCredits,
  moveForward,
  moveBackward,
  // potentially 'loseTurn' in future
}

class EventCard {
  final String id;
  final String title;
  final String description;
  final EventCardType type;
  final int value; // Generic value: Amount of credits or number of steps

  const EventCard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
  });
}
