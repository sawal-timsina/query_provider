import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rxdart/rxdart.dart' show BehaviorSubject;

import '../converters/converter_not_found.dart';
import '../models/query_object.dart';
import '../types.dart' show MutationFunction;

class MutationProvider<Res extends dynamic, ReqData extends dynamic,
    ResData extends dynamic> {
  bool _enabled = true;

  ResData Function(Res)? select;

  final BehaviorSubject<MutationObject<ResData>> _data = BehaviorSubject();

  final MutationFunction<Res, ReqData> _queryFn;

  void Function(ResData data)? onSuccess;
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

  Future mutate([ReqData? data]) async {
    if (_enabled) {
      _data.add(MutationObject<ResData>(
        isLoading: true,
        isError: false,
        isSuccess: false,
        data: _data.hasValue ? _data.value.data : null,
      ));

      try {
        final res = await _queryFn(data);
        final parsedData = select != null ? select!(res) : res;

        _data.add(MutationObject<ResData>(
          isLoading: false,
          isError: false,
          isSuccess: true,
          data: parsedData,
        ));

        if (onSuccess != null) onSuccess!(parsedData);
      } on Exception catch (e) {
        _data.add(MutationObject<ResData>(
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
