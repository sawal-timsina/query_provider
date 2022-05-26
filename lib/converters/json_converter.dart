import 'converter.dart';
import 'converter_not_found.dart';

typedef JsonFactory = Function(Map<String, dynamic> json);

typedef ListFactory = Function(
    List<dynamic> list, Map<Type, JsonFactory> jsonFactories);

class JsonResponseConverter implements ResponseConverter {
  final Map<Type, JsonFactory> _jsonFactories;
  final Map<Type, ListFactory> _listFactories;

  JsonResponseConverter(this._jsonFactories, this._listFactories);

  R _decodeMap<R>(Map<String, dynamic> values) {
    final jsonFactory = _jsonFactories[R];
    if (jsonFactory == null) {
      throw ConverterNotFountException<R>();
    }
    return jsonFactory(values);
  }

  R _decodeList<R>(List values) {
    final jsonFactory = _listFactories[R];
    if (jsonFactory == null) {
      throw ConverterNotFountException<R>();
    }
    return jsonFactory(values, _jsonFactories);
  }

  dynamic _decode<R>(entity) {
    if (entity is Iterable) {
      return _decodeList<R>(entity as List<dynamic>);
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
