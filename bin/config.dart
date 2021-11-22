class GenerationConfig {
  final String apiKey;
  final List<ApiConfig> apis;
  final String baseUrl;
  const GenerationConfig(this.apiKey, this.apis, this.baseUrl);

  static GenerationConfig fromMap(m, String apiKey) {
    if (!m.containsKey("baseUrl")) {
      throw Exception("baseUrl is required in config");
    }
    if (!m.containsKey("apis")) {
      throw Exception("apis is required in config");
    }
    final apis = m["apis"] as List;
    return GenerationConfig(
        apiKey, apis.map((e) => ApiConfig.fromMap(e)).toList(), m["baseUrl"]);
  }
}

class ApiConfig {
  final String endpoint;
  final ApiType type;
  final String schemaPath;
  const ApiConfig(this.endpoint, this.type, this.schemaPath);

  String getUpperName() => endpoint[0].toUpperCase() + endpoint.substring(1);

  static ApiConfig fromMap(m) {
    if (!m.containsKey("endpoint")) {
      throw Exception("endpoint is required in config.apis");
    }
    if (!m.containsKey("type")) {
      throw Exception("type is required in config.apis");
    }
    ApiType type;
    switch (m["type"]) {
      case "object":
        type = ApiType.object;
        break;
      case "list":
        type = ApiType.list;
        break;
      default:
        throw Exception("unknown api type: ${m["type"]}");
    }
    if (!m.containsKey("schema")) {
      throw Exception("schema is required in config.apis");
    }
    return ApiConfig(m["endpoint"], type, m["schema"]);
  }
}

enum ApiType { object, list }
