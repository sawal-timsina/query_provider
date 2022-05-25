import 'converter.dart';
import 'converter_not_found.dart';

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

typedef ListFactory<T> = T Function(List<dynamic> list);

class JsonResponseConverter implements ResponseConverter {
  final Map<dynamic, JsonFactory> _jsonFactories = {};

  JsonResponseConverter(
    Map<Type, JsonFactory> jsonFactories,
  ) {
    for (var e in jsonFactories.keys) {
      _jsonFactories[e.toString()] = jsonFactories[e]!;
    }
  }

  R _decodeMap<R>(Map<String, dynamic> values) {
    final jsonFactory = _jsonFactories[R];
    if (jsonFactory == null) {
      throw ConverterNotFountException<R>();
    }
    return jsonFactory(values);
  }

  R _decodeList<R>(List values) {
    final jsonFactory = _jsonFactories[R];
    if (jsonFactory == null) {
      throw ConverterNotFountException<R>();
    }
    return values.map((e) => jsonFactory(e)) as R;
  }

  dynamic _decode<R>(entity) {
    if (entity is Iterable) {
      return _decodeList<R>(entity as List);
    }

    if (entity is Map) {
      return _decodeMap<R>(entity as Map<String, dynamic>);
    }

    return entity;
  }

  @override
  dynamic convert<ResultType>(dynamic data) {
    return _decode<ResultType>(data);
  }
}
