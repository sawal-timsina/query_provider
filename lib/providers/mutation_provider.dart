import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

import '../converters/converter_not_found.dart';
import '../models/query_object.dart';

class MutationProvider<Res extends dynamic, Data extends dynamic> {
  bool _enabled = true;

  dynamic Function(Res)? select;

  final BehaviorSubject<MutationObject<Res>> _data = BehaviorSubject();

  final Future<Res> Function(Data? data) _queryFn;

  void Function(dynamic data)? onSuccess;
  void Function(Exception error)? onError;

  MutationProvider(
    this._queryFn, {
    this.onSuccess,
    this.onError,
    this.select,
    bool enabled = true,
  }) {
    _enabled = enabled;
  }

  Future mutate(Data? data) async {
    if (_enabled) {
      _data.add(MutationObject(
        isLoading: true,
        isError: false,
        isSuccess: false,
        data: _data.hasValue ? _data.value.data : null,
      ));

      try {
        final res = await _queryFn(data);
        final parsedData =
            select != null ? select!(res) : res;

        _data.add(MutationObject(
          isLoading: false,
          isError: false,
          isSuccess: true,
          data: parsedData,
        ));

        if (onSuccess != null) onSuccess!(parsedData!);
      } on Exception catch (e) {
        _data.add(MutationObject(
          isLoading: false,
          isError: true,
          isSuccess: false,
          data: null,
        ));
        debugPrint(e is ConverterNotFountException ? e.message : e.toString());

        if (onError != null) onError!(e);
      }
    }
  }
}
