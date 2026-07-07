abstract final class SwimIqQuotes {
  static const personalBests = [
    '"The water doesn\'t know your age — it only knows your effort."',
    '"Every PB starts with showing up when it\'s hard."',
    '"Champions are built one rep, one race, one brave moment at a time."',
    '"Your fastest self is waiting on the other side of consistent work."',
  ];

  static const goals = [
    '"A goal without a plan is just a wish — write it, train it, race it."',
    '"Dream big, split smart, finish strong."',
  ];

  static const trainingLog = [
    '"Log the work. Trust the process. Let the times tell the story."',
  ];

  static String pickFor(String swimmer, List<String> pool) {
    if (pool.isEmpty) return '';
    return pool[swimmer.hashCode.abs() % pool.length];
  }
}
