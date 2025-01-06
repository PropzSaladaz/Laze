// sealed makes it impossible for other files to declare classes inheriting Result.
// this makes the Result's number of childs finite, allowing us to use it in switch
// statements:
// switch(res) {
//  case Ok(value): ...
//  case Error(exception): ...
// }
sealed class Result<T> {
  const Result();

  factory Result.ok(T value) => Ok(value);

  factory Result.error(Exception error) => Error(error);

  // method to convert result into Ok
  Ok<T> get asOk => this as Ok<T>;

  // mehtod to convert result into Error
  Error<T> get asError => this as Error<T>;
}


class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => "Result<$T>.ok($value)";
}


class Error<T> extends Result<T> {
  const Error(this.error);

  final Exception error;

  @override
  String toString() => 'Result<$T>.error($error)';
}