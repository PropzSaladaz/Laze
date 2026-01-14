import 'package:flutter/material.dart';
import 'package:laze/utils/result.dart';

// Represents a closure with 0 args, returning a type T
typedef CommandFunction0<T> = Future<Result<T>> Function();
typedef CommandFunction1<T, A> = Future<Result<T>> Function(A arg);
typedef CommandFunction2<T, A, B> = Future<Result<T>> Function(A arg1, B arg2);

/// Wrapper around async functions to ease ViewModel's implementation
abstract class AsyncCommand<T> extends ChangeNotifier {
  bool _isRunning = false;
  Result<T>? _result;

  // Getters
  bool get running => _isRunning;
  bool get completed => _result is Ok;
  bool get error => _result is Error;
  Result<T>? get result => _result;

  Future<void> _execute(CommandFunction0<T> function) async {
    // ensure the action isn't running multiple times
    if (_isRunning) return;

    _isRunning = true;
    _result = null;
    notifyListeners();

    try {
      _result = await function();
    }
    finally {
      _isRunning = false;
      notifyListeners();
    }
  }
}

class AsyncCommand0<T> extends AsyncCommand<T> {
  final CommandFunction0<T> _command;

  AsyncCommand0(this._command);

  Future<void> execute() async {
    await _execute(_command);
  }
}

class AsyncCommand1<T, A> extends AsyncCommand<T> {
  final CommandFunction1<T, A> _command;

  AsyncCommand1(this._command);

  Future<void> execute(A argument) async {
    await _execute(() => _command(argument));
  }
}


class AsyncCommand2<T, A, B> extends AsyncCommand<T> {
  final CommandFunction2<T, A, B> _command;

  AsyncCommand2(this._command);

  Future<void> execute(A argument1, B argument2) async {
    await _execute(() => _command(argument1, argument2));
  }
}
