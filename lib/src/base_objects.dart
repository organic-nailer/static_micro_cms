import 'dart:convert';

abstract class MicroObjectData {
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime publishedAt;
  final DateTime revisedAt;
  const MicroObjectData(
      this.createdAt, this.updatedAt, this.publishedAt, this.revisedAt);
}

abstract class MicroListItem extends MicroObjectData {
  final String id;
  const MicroListItem(this.id, DateTime createdAt, DateTime updatedAt,
      DateTime publishedAt, DateTime revisedAt)
      : super(createdAt, updatedAt, publishedAt, revisedAt);
}

class MicroListData<T extends MicroListItem> {
  final List<T> contents;
  final int totalCount;
  final int offset;
  final int limit;

  const MicroListData(this.contents, this.totalCount, this.offset, this.limit);

  static MicroListData<E> fromString<E extends MicroListItem>(
      String rawData, E Function(String raw) contentGen) {
    final m = jsonDecode(rawData);
    return MicroListData(
        (m["contents"] as List).map((e) => contentGen(jsonEncode(e))).toList(),
        m["totalCount"],
        m["offset"],
        m["limit"]);
  }
}

class MicroImageData {
  final String url;
  final int height;
  final int width;
  const MicroImageData(this.url, this.height, this.width);

  static MicroImageData fromMap(Map<String, dynamic> m) {
    return MicroImageData(m["url"], m["height"], m["width"]);
  }
}
