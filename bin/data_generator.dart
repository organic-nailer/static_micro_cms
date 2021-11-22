import 'dart:io';
import 'package:http/http.dart' as http;

import 'config.dart';

Future<void> generateData(GenerationConfig config, bool dryRun) async {
  final currentDir = Directory.current.path;
  var outFile = File(currentDir + "/lib/datastore.microcms.g.dart");
  if (outFile.existsSync()) {
    // if data already exists in dry mode, skip overwriting.
    if (dryRun) return;
    outFile.deleteSync();
  }
  outFile.createSync();
  var sink = outFile.openWrite();
  sink.write("import 'types.microcms.g.dart';\n");
  sink.write("import 'package:static_micro_cms/static_micro_cms.dart';\n\n");
  final staticDataDeclarations = <String>[];
  for (var api in config.apis) {
    final privateName = "_\$${api.endpoint}Data";
    if (dryRun) {
      sink.write("const $privateName = r'';\n");
    } else {
      final res = await getMicroData(config, api.endpoint);
      sink.write("const $privateName = r'$res';\n");
    }
    final upperName = api.endpoint[0].toUpperCase() + api.endpoint.substring(1);
    final lowerName = api.endpoint[0].toLowerCase() + api.endpoint.substring(1);
    if (api.type == ApiType.object) {
      staticDataDeclarations.add(
          "static final ${upperName}MicroData ${lowerName}Data = ${upperName}MicroData.fromString($privateName);");
    } else if (api.type == ApiType.list) {
      staticDataDeclarations.add(
          "static final MicroListData<${upperName}MicroData> ${lowerName}Data = MicroListData.fromString($privateName, (raw) => ${upperName}MicroData.fromString(raw));");
    }
  }
  final dataStoreDeclaration = """
class MicroCMSDataStore {
  ${staticDataDeclarations.join("\n  ")}
}
""";
  sink.write(dataStoreDeclaration);
  sink.close();
}

Future<String> getMicroData(GenerationConfig config, String endpoint) async {
  var url = config.baseUrl + "/$endpoint";
  var res = await http
      .get(Uri.parse(url), headers: {"X-MICROCMS-API-KEY": config.apiKey});
  return res.body;
}
