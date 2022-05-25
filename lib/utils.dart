extension Flatten on List {
  List flatten() {
    final shapeCheck = checkArray(this);
    if (!shapeCheck) throw Exception('Uneven array dimension');
    var result = [];
    for (var i = 0; i < length; i++) {
      for (var j = 0; j < this[i].length; j++) {
        result.add(this[i][j]);
      }
    }
    return result;
  }
}

bool _isList(list) => list is List;

bool checkArray(List list) {
  bool isAllList = false;
  for (var i = 0; i < list.length; i++) {
    isAllList = _isList(list[i]);
  }
  return isAllList;
}
