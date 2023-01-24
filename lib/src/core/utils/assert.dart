import 'package:unlimited_tools/src/core/exceptions/cli_exception.dart';

// ignore: avoid_positional_boolean_parameters
void cliAssert(bool condition, String message, {List<String>? instructions}) {
  if (!condition) {
    throw CLIException(message, instructions: instructions);
  }
}
