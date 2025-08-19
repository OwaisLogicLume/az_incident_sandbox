class Utils {
  Utils._();

  static final _instance = Utils._();

  factory Utils() => _instance;

  int stationSortCallback(String a, String b) {
    String alphaPartA = RegExp(r'[A-Za-z]+').firstMatch(a)?.group(0) ?? '';
    String alphaPartB = RegExp(r'[A-Za-z]+').firstMatch(b)?.group(0) ?? '';

    int alphaComparison = alphaPartA.compareTo(alphaPartB);
    if (alphaComparison != 0) {
      return alphaComparison;
    }

    int numValueA = int.tryParse(a.substring(alphaPartA.length)) ?? 0;
    int numValueB = int.tryParse(b.substring(alphaPartB.length)) ?? 0;

    return numValueA.compareTo(numValueB);
  }
}
