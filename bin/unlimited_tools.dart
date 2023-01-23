import 'dart:io';

import 'package:unlimited_tools/unlimited_tools.dart';

void main(List<String> arguments) async {
  try {
    if (arguments.isEmpty) {
      print('pls provide command, available commands: genAssetsRef');
    } else {
      if (arguments[0] == 'genAssetsRef') {
        await AssetsRefGenerator().generate();
      } else {
        print('unknown command: ${arguments[0]}');
      }
    }
  } on CLIException catch (e) {
    print(e);
    print('instructions:');
    e.instructions?.forEach(print);
  }
  exit(0);
}
