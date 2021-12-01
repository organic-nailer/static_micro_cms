import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'micro_list_data.dart';

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
  sink.write("import 'dart:convert';\n");
  sink.write("import 'types.microcms.g.dart';\n\n");
  final staticDataDeclarations = <String>[];
  for (var api in config.apis) {
    final privateName = "_\$${api.endpoint}Data";
    if (dryRun) {
      sink.write("const $privateName = r'';\n");
    } else {
      final res = await getMicroData(config, api.endpoint);
      final String serialized;
      if (api.type == ApiType.list) {
        var parsed = MicroListData.fromString(res);
        // get all contents
        final contentList = parsed.contents;
        var offset = parsed.limit;
        while (offset < parsed.totalCount) {
          final pageRes =
              await getMicroData(config, api.endpoint, offset: offset);
          parsed = MicroListData.fromString(pageRes);
          contentList.addAll(parsed.contents);
          offset += parsed.limit;
        }
        serialized = jsonEncode(contentList);
      } else {
        serialized = res;
      }
      sink.write("const $privateName = r'$serialized';\n");
    }
    final upperName = api.endpoint[0].toUpperCase() + api.endpoint.substring(1);
    final lowerName = api.endpoint[0].toLowerCase() + api.endpoint.substring(1);
    if (api.type == ApiType.object) {
      staticDataDeclarations.add(
          "static final ${upperName}MicroData ${lowerName}Data = ${upperName}MicroData.fromString($privateName);");
    } else if (api.type == ApiType.list) {
      staticDataDeclarations.add(
          "static final List<${upperName}MicroData> ${lowerName}Data = (jsonDecode($privateName) as List).map((e) => ${upperName}MicroData.fromString(jsonEncode(e))).toList();");
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

Future<String> getMicroData(GenerationConfig config, String endpoint,
    {int? offset}) async {
  var url = config.baseUrl + "/$endpoint";
  var uri = Uri.parse(url);
  if (offset != null) {
    uri = uri.replace(queryParameters: {"offset": "$offset"});
  }
  var res = await http.get(uri, headers: {"X-MICROCMS-API-KEY": config.apiKey});
  return res.body;
}
