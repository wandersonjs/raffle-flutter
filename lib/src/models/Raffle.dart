class Raffle {
  late int index;
  late int number;
  late String buyer;
  late String sponsor;

  Raffle(
      {required this.index,
      required this.number,
      required this.buyer,
      required this.sponsor});

  Raffle.fromJSON(Map<String, dynamic> jsonMap) {
    this.index = jsonMap['index'];
    this.number = jsonMap['number'];
    this.buyer = jsonMap['buyer'] ?? jsonMap['buyer'];
    this.sponsor = jsonMap['sponsor'] ?? jsonMap['sponsor'];
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'number': number,
      'buyer': buyer,
      'sponsor': sponsor
    };
  }

  Map toMap() {
    Map map = new Map();
    map['number'] = number;
    map['buyer'] = buyer;
    map['sponsor'] = sponsor;
    return map;
  }
}
