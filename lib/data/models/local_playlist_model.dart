import 'package:uuid/uuid.dart';

import 'search/search_video_model.dart';

class LocalPlaylist {
  final String id;
  final String name;
  final String coverUrl;
  final String description;
  final String creatorName;
  final String sourceTag; // 'bilibili' | 'netease' | 'qqmusic' | 'local'
  final String? remoteId;
  final List<Map<String, dynamic>> tracksJson;
  final int createdAt;
  final int updatedAt;

  LocalPlaylist({
    required this.id,
    required this.name,
    this.coverUrl = '',
    this.description = '',
    this.creatorName = '',
    required this.sourceTag,
    this.remoteId,
    this.tracksJson = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocalPlaylist.create({
    required String name,
    String description = '',
    String sourceTag = 'local',
    String coverUrl = '',
    String creatorName = '',
    String? remoteId,
    List<Map<String, dynamic>> tracksJson = const [],
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return LocalPlaylist(
      id: const Uuid().v4(),
      name: name,
      coverUrl: coverUrl,
      description: description,
      creatorName: creatorName,
      sourceTag: sourceTag,
      remoteId: remoteId,
      tracksJson: tracksJson,
      createdAt: now,
      updatedAt: now,
    );
  }

  List<SearchVideoModel> get tracks =>
      tracksJson.map((e) => SearchVideoModel.fromJson(e)).toList();

  int get trackCount => tracksJson.length;

  LocalPlaylist copyWith({
    String? name,
    String? coverUrl,
    String? description,
    String? creatorName,
    String? sourceTag,
    String? remoteId,
    List<Map<String, dynamic>>? tracksJson,
    int? updatedAt,
  }) {
    return LocalPlaylist(
      id: id,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      creatorName: creatorName ?? this.creatorName,
      sourceTag: sourceTag ?? this.sourceTag,
      remoteId: remoteId ?? this.remoteId,
      tracksJson: tracksJson ?? this.tracksJson,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coverUrl': coverUrl,
      'description': description,
      'creatorName': creatorName,
      'sourceTag': sourceTag,
      'remoteId': remoteId,
      'tracksJson': tracksJson,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory LocalPlaylist.fromJson(Map<String, dynamic> json) {
    return LocalPlaylist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? '',
      sourceTag: json['sourceTag'] as String? ?? 'local',
      remoteId: json['remoteId'] as String?,
      tracksJson: (json['tracksJson'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      createdAt: json['createdAt'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }
}
