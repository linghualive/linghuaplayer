class GenreCategory {
  final String name;
  final String icon;
  final List<String> tags;

  const GenreCategory({
    required this.name,
    required this.icon,
    required this.tags,
  });
}

const kGenreCategories = <GenreCategory>[
  GenreCategory(
    name: '语种',
    icon: '🌍',
    tags: ['华语', '粤语', '欧美', '日语', '韩语', '法语', '西班牙语', '纯音乐'],
  ),
  GenreCategory(
    name: '风格',
    icon: '🎵',
    tags: [
      'R&B', '流行', '摇滚', '民谣', '电子', '说唱', '古风', '爵士',
      '轻音乐', '金属', 'Funk', 'City Pop', '蓝调', 'Indie', '朋克',
      '嘻哈', '灵魂乐', '新世纪',
    ],
  ),
  GenreCategory(
    name: '情绪/场景',
    icon: '🎭',
    tags: [
      '深夜', '治愈', '运动', '学习', '通勤', '放松',
      '伤感', '甜蜜', '怀旧', '激昂', '安静', '派对',
    ],
  ),
];

/// All built-in tags flattened into a single set for quick lookup.
final kBuiltInTags = <String>{
  for (final c in kGenreCategories) ...c.tags,
};
