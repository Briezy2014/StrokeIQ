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

  static const meetResults = [
    '"Every meet is a chance to show coaches what you\'ve built in practice."',
    '"Race with confidence — the clock remembers effort."',
    '"College recruiters watch consistency across meets, not just one swim."',
  ];

  static const videoLab = [
    '"Film doesn\'t lie — use it to sharpen what you feel in the water."',
    '"One honest video review can unlock your next breakthrough."',
  ];

  static const addSession = [
    '"Today\'s session is tomorrow\'s personal best."',
    '"Champions log the work others skip."',
  ];

  static const usaStandards = [
    '"Know your cuts. Chase your next letter. Earn your place on the wall."',
  ];

  static const recruiting = [
    '"Your passport tells coaches who you are before they ever meet you."',
    '"Grades, goals, and grit — recruiters notice athletes who show all three."',
  ];

  static String pickFor(String swimmer, List<String> pool) {
    if (pool.isEmpty) return '';
    return pool[swimmer.hashCode.abs() % pool.length];
  }
}
