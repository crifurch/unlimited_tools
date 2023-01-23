class CLIException implements Exception {
  final List<String>? instructions;
  final String? message;

  CLIException(
    this.message, {
    this.instructions,
  });

  @override
  String toString() => message!;
}
