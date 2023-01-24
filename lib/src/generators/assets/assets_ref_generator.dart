// ignore_for_file: avoid_print

import 'dart:io';

import 'package:sprintf/sprintf.dart';
import 'package:unlimited_things_dart/unlimited_things_dart.dart';
import 'package:unlimited_tools/src/core/utils/assert.dart';
import 'package:unlimited_tools/src/processes/dart_format.dart';

class AssetsRefGenerator {
  static const assetsFieldTemplate = '\tstatic const %s = %s;';
  static const encoder = DartEncoder.withIndent('\t');

  late final String filePath;
  late Directory assetsRoot;
  late final String fileTemplate;
  final List<String>? foldersAsList;
  final List<String>? foldersAsMap;
  final bool useDoubleQuotes;

  AssetsRefGenerator({
    String path = 'lib/assets_ref.dart',
    String className = 'AssetsRef',
    Directory? assetsRoot,
    AssetsType assetsType = AssetsType.mixin,
    this.foldersAsList,
    this.foldersAsMap,
    this.useDoubleQuotes = false,
  }) {
    this.assetsRoot = assetsRoot ?? Directory('assets');
    cliAssert(this.assetsRoot.existsSync(), 'no assets folder', instructions: [
      'create assets folder: ${this.assetsRoot.path}',
      'add assets to assets folder',
      'run command again',
    ]);
    this.assetsRoot = this.assetsRoot.absolute;

    filePath = path.pathEncoded;

    fileTemplate = '''
/// Generated by unlimited_tools on %s
${assetsType.value} ${className.pascalCase} {
%s
}
''';
  }

  Future<void> generate() async {
    final nameAndPath = <String, dynamic>{};
    final listSync =
        assetsRoot.listSync(recursive: true).whereType<Directory>();
    for (final folder in listSync) {
      final folderPath = folder.path.replaceAll(Platform.pathSeparator, '/');
      if (foldersAsList?.any(folderPath.endsWith) ?? false) {
        nameAndPath.addAll(_getListFieldFromFolder(folder));
      } else if (foldersAsMap?.any(folderPath.endsWith) ?? false) {
        nameAndPath.addAll(_getMapFieldFromFolder(folder));
      } else {
        nameAndPath.addAll(_getFieldsFromFolder(folder));
      }
    }
    nameAndPath.addAll(_getFieldsFromFolder(assetsRoot));
    final fields = nameAndPath.entries.map(
      (e) {
        var convert = encoder.convert(e.value);
        if (useDoubleQuotes) {
          convert = convert.replaceAll("'", '"');
        }
        return sprintf(
          assetsFieldTemplate,
          [
            e.key,
            convert,
          ],
        );
      },
    );
    final fieldsResult = fields.join('\n');
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsStringSync(sprintf(fileTemplate, [
        DateTime.now().toUtc(),
        fieldsResult,
      ]));
    print("don't forget add refs to pubspec.yml");
    await runDartFormat([File(filePath)]);
  }

  Map<String, List<String>> _getListFieldFromFolder(Directory folder) {
    final result = <String, List<String>>{};
    final listSync = folder.listSync().whereType<File>();
    final assetName = (folder.path
            .substring(assetsRoot.path.length + 1)
            .replaceAll(Platform.pathSeparator, '/'))
        .camelCase;
    final files = <String>[];
    for (final file in listSync) {
      final filePath = file.path
          .substring(assetsRoot.parent.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      files.add(filePath);
    }
    result[assetName] = files;
    return result;
  }

  Map<String, String> _getFieldsFromFolder(Directory folder) {
    final result = <String, String>{};
    final listSync = folder.listSync().whereType<File>();
    for (final file in listSync) {
      final filePath = file.path
          .substring(assetsRoot.parent.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      var assetName = (file.path
              .substring(assetsRoot.path.length + 1)
              .replaceAll(Platform.pathSeparator, '_'))
          .camelCase;
      assetName = assetName.substring(0, assetName.lastIndexOf('.'));
      result[assetName] = filePath;
    }
    return result;
  }

  Map<String, Map<String, String>> _getMapFieldFromFolder(Directory folder) {
    final result = <String, Map<String, String>>{};
    final listSync = folder.listSync().whereType<File>();
    final assetName = (folder.path
            .substring(assetsRoot.path.length + 1)
            .replaceAll(Platform.pathSeparator, '/'))
        .camelCase;
    final files = <String, String>{};
    for (final file in listSync) {
      final filePath = file.path
          .substring(assetsRoot.parent.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      var fileName = file.path.split(Platform.pathSeparator).last;
      fileName = fileName.substring(0, fileName.lastIndexOf('.'));
      files[fileName] = filePath;
    }
    result[assetName] = files;
    return result;
  }
}

enum AssetsType {
  classType('class'),
  mixin('mixin'),
  abstractClass('abstract class'),
  ;

  final String value;

  const AssetsType(this.value);

  @override
  String toString() => value;

  static AssetsType fromString(String? value) {
    if (value == null) {
      return AssetsType.mixin;
    }
    final type = values
        .firstWhereOrNull<AssetsType>((e) => e.name == value.toLowerCase());
    return type ?? AssetsType.mixin;
  }
}
