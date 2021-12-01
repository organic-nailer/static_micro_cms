import 'dart:convert';

class MicroListData {
  final List contents;
  final int totalCount;
  final int offset;
  final int limit;

  const MicroListData(this.contents, this.totalCount, this.offset, this.limit);

  static MicroListData fromString(String rawData) {
    final m = jsonDecode(rawData);
    return MicroListData(
        m["contents"] as List, m["totalCount"], m["offset"], m["limit"]);
  }
}
