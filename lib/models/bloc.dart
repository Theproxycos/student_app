import 'dart:async';
import 'validator.dart';
import 'package:rxdart/rxdart.dart';

class Bloc with Validators implements BaseBloc {
  final _emailController = BehaviorSubject<String>();
  final _passwordController = BehaviorSubject<String>();

  Function(String) get emailChanged => _emailController.sink.add;
  Function(String) get passwordChanged => _passwordController.sink.add;

  Stream<String> get email => _emailController.stream.transform(emailValidator);
  Stream<String> get password =>
      _passwordController.stream.transform(passwordValidator);

  Stream<bool> get submitCheck =>
      Rx.combineLatest2(email, password, (email, password) => true);

  void submit() {
    print("Form submitted");
  }

  @override
  void dispose() {
    _emailController.close();
    _passwordController.close();
  }
}

abstract class BaseBloc {
  void dispose();
}
