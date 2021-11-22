import 'dart:convert';
import 'dart:io';

import 'config.dart';

Future<void> generateTypes(GenerationConfig config) async {
  final currentDir = Directory.current.path;
  var outFile = File(currentDir + "/lib/types.microcms.g.dart");
  if (outFile.existsSync()) {
    outFile.deleteSync();
  }
  outFile.createSync();
  var sink = outFile.openWrite();
  // write import
  sink.write("import 'dart:convert';\n");
  sink.write("import 'package:static_micro_cms/static_micro_cms.dart';\n\n");
  for (var api in config.apis) {
    final schemaJson =
        await File("$currentDir/${api.schemaPath}").readAsString();
    final schemaData = jsonDecode(schemaJson);
    final customFields = (schemaData["customFields"] as List)
        .map((e) => CustomFieldData.fromMap(e, api.getUpperName()))
        .toList();
    if (customFields.isNotEmpty) {
      sink.write(createCustomDeclarations(customFields, api.getUpperName()));
    }
    final fields = (schemaData["apiFields"] as List)
        .map((e) => ApiFieldData.fromMap(e, customFields, api.getUpperName()))
        .toList();
    if (api.type == ApiType.object) {
      sink.write(createObjectDataDeclaration(fields, api.endpoint));
      sink.write("\n\n");
    } else {
      sink.write(createListDataDeclaration(fields, api.endpoint));
      sink.write("\n\n");
    }
  }
  sink.close();
}

String createCustomDeclarations(List<CustomFieldData> data, String prefix) {
  final title = prefix;
  var result = "abstract class ${title}CustomField {}\n\n";

  for (var field in data) {
    const base = """
class {{fieldTitle}} implements {{title}}CustomField {
  {{declaration}}
  const {{fieldTitle}}(
    {{argument}});

  static {{fieldTitle}} fromMap(Map<String, dynamic> m) {
    return {{fieldTitle}}(
      {{fromMap}}
    );
  }
}

""";
    result += base
        .replaceAll("{{title}}", title)
        .replaceAll("{{fieldTitle}}", field.getClassName())
        .replaceFirst("{{declaration}}",
            field.fields.map((e) => e.getDeclarationText()).join("\n  "))
        .replaceFirst("{{argument}}",
            field.fields.map((e) => e.getArgumentText()).join(",\n    "))
        .replaceFirst("{{fromMap}}",
            field.fields.map((e) => e.getFromMapText()).join(",\n      "));
  }
  return result;
}

String createObjectDataDeclaration(List<ApiFieldData> data, String endpoint) {
  final title = endpoint[0].toUpperCase() + endpoint.substring(1);
  const base = """
class {{title}}MicroData extends MicroObjectData {
  {{declaration}}
  const {{title}}MicroData(
      {{argument}},
      DateTime createdAt,
      DateTime updatedAt,
      DateTime publishedAt,
      DateTime revisedAt)
      : super(createdAt, updatedAt, publishedAt, revisedAt);

  static {{title}}MicroData fromString(String rawData) {
    final m = jsonDecode(rawData);
    return {{title}}MicroData(
        {{fromMap}},
        DateTime.parse(m["createdAt"]),
        DateTime.parse(m["updatedAt"]),
        DateTime.parse(m["publishedAt"]),
        DateTime.parse(m["revisedAt"]));
  }
}
""";
  return base
      .replaceAll("{{title}}", title)
      .replaceAll("{{declaration}}",
          data.map((e) => e.getDeclarationText()).join("\n  "))
      .replaceFirst("{{argument}}",
          data.map((e) => e.getArgumentText()).join(",\n      "))
      .replaceFirst("{{fromMap}}",
          data.map((e) => e.getFromMapText()).join(",\n        "));
}

String createListDataDeclaration(List<ApiFieldData> data, String endpoint) {
  final title = endpoint[0].toUpperCase() + endpoint.substring(1);
  const base = """
class {{title}}MicroData extends MicroListItem {
  {{declaration}}
  const {{title}}MicroData(
      {{argument}},
      String id,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime publishedAt,
      DateTime revisedAt)
      : super(id, createdAt, updatedAt, publishedAt, revisedAt);

  static {{title}}MicroData fromString(String rawData) {
    final m = jsonDecode(rawData);
    return {{title}}MicroData(
        {{fromMap}},
        m["id"],
        DateTime.parse(m["createdAt"]),
        DateTime.parse(m["updatedAt"]),
        DateTime.parse(m["publishedAt"]),
        DateTime.parse(m["revisedAt"]));
  }
}
""";
  return base
      .replaceAll("{{title}}", title)
      .replaceAll("{{declaration}}",
          data.map((e) => e.getDeclarationText()).join("\n  "))
      .replaceFirst("{{argument}}",
          data.map((e) => e.getArgumentText()).join(",\n      "))
      .replaceFirst("{{fromMap}}",
          data.map((e) => e.getFromMapText()).join(",\n        "));
}

class ApiFieldData {
  final String fieldId;
  final String name;
  final ApiKind kind;
  final bool required;
  final List<CustomFieldData> useCustomField;
  final String prefix;
  const ApiFieldData(this.fieldId, this.name, this.kind, this.required,
      this.useCustomField, this.prefix);

  String nullableText() {
    return required ? "" : "?";
  }

  String getDeclarationText() {
    switch (kind) {
      case ApiKind.text:
      case ApiKind.textArea:
      case ApiKind.richEditor:
        return "final String${nullableText()} $fieldId;";
      case ApiKind.media:
        return "final MicroImageData${nullableText()} $fieldId;";
      case ApiKind.date:
        return "final DateTime${nullableText()} $fieldId;";
      case ApiKind.boolean:
        return "final bool${nullableText()} $fieldId;";
      case ApiKind.number:
        return "final double${nullableText()} $fieldId;";
      case ApiKind.custom:
        return "final ${useCustomField[0].getClassName()}${nullableText()} $fieldId;";
      case ApiKind.repeater:
        return "final List<${prefix}CustomField>${nullableText()} $fieldId;";
    }
  }

  String getArgumentText() {
    return "this.$fieldId";
  }

  String getFromMapText() {
    switch (kind) {
      case ApiKind.text:
      case ApiKind.textArea:
      case ApiKind.richEditor:
      case ApiKind.boolean:
      case ApiKind.number:
        return "m['$fieldId']";
      case ApiKind.media:
        return required
            ? "MicroImageData.fromMap(m['$fieldId'])"
            : "m.containsKey('$fieldId') ? MicroImageData.fromMap(m['$fieldId']) : null";
      case ApiKind.date:
        return required
            ? "DateTime.parse(m['$fieldId'])"
            : "m.containsKey('$fieldId') ? DateTime.parse(m['$fieldId']) : null";
      case ApiKind.custom:
        return required
            ? "${useCustomField[0].getClassName()}.fromMap(m['$fieldId'])"
            : "m.containsKey('$fieldId') ? ${useCustomField[0].getClassName()}.fromMap(m['$fieldId']) : null";
      case ApiKind.repeater:
        return required
            ? "(m['$fieldId'] as List).map((e) => ${useCustomField[0].getClassName()}.fromMap(e)).toList()"
            : "m.containsKey('$fieldId') ? (m['$fieldId'] as List).map((e) => ${useCustomField[0].getClassName()}.fromMap(e)).toList() : null";
    }
  }

  static ApiFieldData fromMap(Map<String, dynamic> m,
      List<CustomFieldData> customFields, String prefix) {
    final kind = _getKind(m["kind"]);
    final useCustomField = <CustomFieldData>[];
    if (kind == ApiKind.custom) {
      final createdAt = m["customFieldCreatedAt"] as String;
      final targetField =
          customFields.firstWhere((e) => e.createdAt == createdAt);
      useCustomField.add(targetField);
    }
    if (kind == ApiKind.repeater) {
      final createdAtList = m["customFieldCreatedAtList"] as List;
      for (var createdAt in createdAtList) {
        final targetField =
            customFields.firstWhere((e) => e.createdAt == createdAt);
        useCustomField.add(targetField);
      }
    }
    return ApiFieldData(m["fieldId"], m["name"], kind, m["required"] == true,
        useCustomField, prefix);
  }

  static ApiKind _getKind(String raw) {
    switch (raw) {
      case "text":
        return ApiKind.text;
      case "textArea":
        return ApiKind.textArea;
      case "richEditor":
        return ApiKind.richEditor;
      case "media":
        return ApiKind.media;
      case "date":
        return ApiKind.date;
      case "boolean":
        return ApiKind.boolean;
      case "number":
        return ApiKind.number;
      case "custom":
        return ApiKind.custom;
      case "repeater":
        return ApiKind.repeater;
    }
    throw Exception("unsupported field kind: $raw");
  }
}

enum ApiKind {
  text,
  textArea,
  richEditor,
  media,
  date,
  boolean,
  number,
  //select,
  custom,
  repeater
}

class CustomFieldData {
  final String prefix;
  final String createdAt;
  final String fieldId;
  final List<ApiFieldData> fields;
  const CustomFieldData(this.prefix, this.createdAt, this.fieldId, this.fields);

  String getClassName() =>
      prefix + fieldId[0].toUpperCase() + fieldId.substring(1) + "MicroData";

  static CustomFieldData fromMap(Map<String, dynamic> m, String prefix) {
    return CustomFieldData(
        prefix,
        m["createdAt"],
        m["fieldId"],
        (m["fields"] as List)
            .map((e) => ApiFieldData.fromMap(e, [], prefix))
            .toList());
  }
}
