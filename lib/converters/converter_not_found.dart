import 'package:flutter/foundation.dart';

class ConverterNotFountException<T> implements Exception {
  String message = "Error :: Cannot find converter for type $T";

  ConverterNotFountException() {
    debugPrint(message);
  }
}
