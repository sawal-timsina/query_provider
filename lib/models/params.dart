abstract class Params {
  Map<String, dynamic> toJson();

  Params clone();

  @override
  bool operator ==(Object other) {
    if (other is Params) {
      final thisJson = toJson();
      final oJson = other.toJson();
      return thisJson.keys.every((key) => oJson[key] == thisJson[key]);
    }
    return false;
  }

  @override
  int get hashCode => toJson().hashCode;
}
