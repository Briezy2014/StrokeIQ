/// USA Swimming motivational standard tiers (slowest → fastest cutoff).
enum StandardLevel {
  b('B', 1),
  bb('BB', 2),
  a('A', 3),
  aa('AA', 4),
  aaa('AAA', 5),
  aaaa('AAAA', 6);

  const StandardLevel(this.label, this.rank);

  final String label;
  final int rank;

  static StandardLevel? fromLabel(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().toUpperCase();
    for (final level in StandardLevel.values) {
      if (level.label == normalized) {
        return level;
      }
    }
    return null;
  }

  StandardLevel? get next {
    final nextRank = rank + 1;
    for (final level in StandardLevel.values) {
      if (level.rank == nextRank) {
        return level;
      }
    }
    return null;
  }

  StandardLevel? get previous {
    final previousRank = rank - 1;
    for (final level in StandardLevel.values) {
      if (level.rank == previousRank) {
        return level;
      }
    }
    return null;
  }
}
