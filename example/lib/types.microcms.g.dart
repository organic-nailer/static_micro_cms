import 'dart:convert';
import 'package:static_micro_cms/static_micro_cms.dart';

abstract class ProfileCustomField {}

class ProfileCustom_field1MicroData implements ProfileCustomField {
  final String? hoge;
  const ProfileCustom_field1MicroData(
    this.hoge);

  static ProfileCustom_field1MicroData fromMap(Map<String, dynamic> m) {
    return ProfileCustom_field1MicroData(
      m['hoge']
    );
  }
}

class ProfileMicroData extends MicroObjectData {
  final String text_field_;
  final String? text_area_;
  final String? rich_editor_;
  final MicroImageData? image_;
  final DateTime? date_;
  final bool? boolean_;
  final double? number_;
  final ProfileCustom_field1MicroData? cuuustom1;
  const ProfileMicroData(
      this.text_field_,
      this.text_area_,
      this.rich_editor_,
      this.image_,
      this.date_,
      this.boolean_,
      this.number_,
      this.cuuustom1,
      DateTime createdAt,
      DateTime updatedAt,
      DateTime publishedAt,
      DateTime revisedAt)
      : super(createdAt, updatedAt, publishedAt, revisedAt);

  static ProfileMicroData fromString(String rawData) {
    final m = jsonDecode(rawData);
    return ProfileMicroData(
        m['text_field_'],
        m['text_area_'],
        m['rich_editor_'],
        m.containsKey('image_') ? MicroImageData.fromMap(m['image_']) : null,
        m.containsKey('date_') ? DateTime.parse(m['date_']) : null,
        m['boolean_'],
        m['number_'],
        m.containsKey('cuuustom1') ? ProfileCustom_field1MicroData.fromMap(m['cuuustom1']) : null,
        DateTime.parse(m["createdAt"]),
        DateTime.parse(m["updatedAt"]),
        DateTime.parse(m["publishedAt"]),
        DateTime.parse(m["revisedAt"]));
  }
}


