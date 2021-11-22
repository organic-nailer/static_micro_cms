import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:http/http.dart' as http;

import 'config.dart';
import 'data_generator.dart';
import 'type_generator.dart';

void main(List<String> args) async {
  final dryRun = args.contains("--dry");
  // get api key
  dotenv.load();
  final apiKey = dotenv.env["API_KEY"];
  if (apiKey == null) {
    throw Exception("API_KEY doesn't exist in .env");
  }
  // load pubspec.yaml
  var myDir = Directory.current;
  FileSystemEntity? config;
  await for (var file in myDir.list()) {
    if (file.uri.pathSegments.last == "pubspec.yaml") {
      config = file;
      break;
    }
  }
  if (config == null) {
    throw Exception("pubspec.yaml is missing");
  }

  // get config
  final configYaml = await File(config.path).readAsString();
  final configMap = loadYaml(configYaml) as Map;
  if (!configMap.containsKey("static_micro_cms")) {
    throw Exception("config not found");
  }
  final generatorConfig =
      GenerationConfig.fromMap(configMap["static_micro_cms"], apiKey);

  // generate classes from schema
  await generateTypes(generatorConfig);

  print("class generated!");

  await generateData(generatorConfig, dryRun);

  print("data generated!");
}

Future<String> getMicroData(GenerationConfig config, String endpoint) async {
  var url = config.baseUrl + "/$endpoint";
  var res = await http
      .get(Uri.parse(url), headers: {"X-MICROCMS-API-KEY": config.apiKey});
  return res.body;
}
