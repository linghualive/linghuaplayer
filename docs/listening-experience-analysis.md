# Flamekit 听歌体验分析与改进方案

## 一、现有问题分析

### 问题 1：「上一曲」行为不合理

**代码位置**: `player_controller.dart:581-587`

```dart
Future<void> skipPrevious() async {
  if (currentVideo.value != null && position.value.inSeconds > 3) {
    seekTo(Duration.zero);
  } else {
    _autoPlayNext();  // ← 问题所在
  }
}
```

**问题描述**:
- 当播放进度 <= 3 秒时，`skipPrevious` 调用的是 `_autoPlayNext()`，这意味着**按「上一曲」却播放了一首新歌**，行为与用户预期完全相反。
- 用户期望的「上一曲」是回到之前听过的歌曲，而不是随机推荐一首新歌。
- 当前没有播放历史栈的概念，所以无法真正实现「上一曲」。

**影响**: 用户无法回到上一首歌，误按「上一曲」反而会触发自动推荐，体验混乱。

---

### 问题 2：播放列表为空时的下一曲 / 上一曲行为

**代码位置**:
- `skipNext()` → `player_controller.dart:544-561`
- `_advanceNext()` → `player_controller.dart:564-579`
- `_autoPlayNext()` → `player_controller.dart:447-493`

**问题描述**:
- `skipNext()`: 当队列只剩一首歌时，清空队列 → 清空 `currentVideo` → 调用 `playRandomIfNeeded()`，这会随机搜索一首歌来播放，而不是停止。
- `_advanceNext()`: 当队列只剩一首歌时，调用 `_autoPlayNext()` 尝试播放相关音乐或发现更多歌曲。
- 用户主动点「下一曲」和歌曲自动播放完毕，应该是不同的行为，但目前 `skipNext` 在队列为空时也触发了自动推荐。

**影响**:
- 用户主动跳过最后一首歌时，期望的行为通常是停止播放，而不是突然播放一首随机歌曲。
- 自动播完最后一首歌时，衔接推荐歌曲是合理的，但整个过程没有任何提示，用户不知道播放的歌是从哪里来的。

---

### 问题 3：自动播放 (`playRandomIfNeeded`) 体验差

**代码位置**: `player_controller.dart:153-187`

```dart
Future<void> playRandomIfNeeded() async {
  if (_hasAutoPlayed || currentVideo.value != null || isLoading.value) return;
  _hasAutoPlayed = true;

  const keywords = [
    '热门歌曲', '流行音乐', '经典老歌', '华语金曲',
    '日语歌曲', '英文歌曲', '抖音热歌', '网络热歌',
  ];
  final random = Random();
  final keyword = keywords[random.nextInt(keywords.length)];
  // ...搜索并播放
}
```

**问题描述**:
- 关键词列表过于简单且固定，搜索结果完全随机，与用户的听歌品味无关。
- 已经有 DeepSeek AI 生成个性化推荐的能力（心动模式），但 `playRandomIfNeeded` 完全没有利用用户的偏好标签（`preferenceTags`）。
- `_hasAutoPlayed` 是内存级别的 flag，进入播放页就触发一次，但如果用户清空队列后再回到播放页，不会再次自动播放（`_hasAutoPlayed` 已经为 `true`），除非从 `skipNext` 调用进入时手动重置。
- 搜索结果只取前 5 个中随机一个，没有质量过滤（可能搜到非音乐内容）。

**影响**: 冷启动时自动播放的歌曲质量参差不齐，与用户品味脱节，给用户糟糕的第一印象。

---

### 问题 4：推荐歌曲重复

**涉及代码**:
- `recommendation_service.dart:23-54` — `getRecommendations()`
- `deepseek_repository.dart:130-155` — `generateSongRecommendations()`
- `heart_mode_service.dart:87-118` — `autoNext()`
- `player_controller.dart:666-691` — `_loadRelatedMusic()`

**问题描述**:

**4a. AI 推荐去重不充分**
- `generateSongRecommendations` 的 prompt 中使用 `recentPlayed` 列表告知 AI 不要推荐已听歌曲，但：
  - `recentPlayed` 只取自当前队列 (`currentQueue`)，不包含历史播放记录。
  - `recentPlayed` 限制为 `take(20)`，如果用户听了很多歌，之前的歌仍可能被重复推荐。
  - AI 并不总是遵守「不要推荐以下歌曲」的指令，同一首热门歌曲可能反复出现。
- `RecommendationService.getRecommendations()` 虽然有 `seenIds` 集合做去重，但只是对当前批次内去重，不跨批次去重。

**4b. 相关推荐 (`_loadRelatedMusic`) 重复严重**
- 对于网易云歌曲：使用歌曲标题作为搜索关键词（`video.title`），搜索结果天然就会包含同名歌曲的不同版本，或标题相近的歌曲。
- 对于 B 站歌曲：使用 `getRelatedVideos` API，B 站推荐算法本身就可能返回相似内容。
- 相关推荐列表没有与当前队列做交叉去重（虽然在 `_autoPlayNext` 中有去重，但 UI 展示时没有）。

**4c. 网易云搜索的结构性重复**
- 网易云搜索 `searchSongs(keyword: video.title)` 只排除了 `s.id != video.id`（排除完全相同的歌），但同一首歌可能有多个版本（原版、Live 版、翻唱版），它们的 `id` 不同但本质是同一首歌。

**影响**: 用户在相关推荐列表和心动模式中反复看到/听到相同的歌曲，推荐质量感知差。

---

### 问题 5：队列数据结构设计导致的体验问题

**代码位置**: `player_controller.dart:246-270`（`_addToQueue`）、`564-579`（`_advanceNext`）

**问题描述**:
- 当前的队列设计是把「正在播放」的歌曲放在 `queue[0]`，`currentIndex` 始终为 0。
- `_advanceNext` 的逻辑是：取 `queue[1]`，删除它，再插入到 `queue[0]`。这意味着播放完的歌曲会一直留在队列尾部，但下一首歌被移到了最前面，导致队列顺序在播放过程中被打乱。
- `skipNext` 则是直接删除 `queue[0]`，播放完的歌曲从队列中消失，无法再回头听。

**影响**:
- 顺序播放时队列顺序会被打乱（`_advanceNext` 不断把歌曲移到头部）。
- 播放过的歌曲要么消失（`skipNext`），要么被移到队尾（`_advanceNext`），没有明确的「已播放/未播放」分界线。
- 无法实现真正的「上一曲」功能。

---

## 二、改进方案

### 方案 1：实现真正的「上一曲」— 播放历史栈

**核心思路**: 引入一个播放历史栈 (`playHistory`)，记录播放过的歌曲，使「上一曲」能够回到之前听过的歌。

**具体改动**:

1. 在 `PlayerController` 中新增：
   ```dart
   final playHistory = <QueueItem>[].obs;  // 播放历史栈
   static const _maxHistorySize = 50;       // 历史上限
   ```

2. 每当播放一首新歌时（`playFromSearch`、`playAt`、`_advanceNext`、`skipNext`），将当前歌曲推入 `playHistory`。

3. 重写 `skipPrevious`：
   ```dart
   Future<void> skipPrevious() async {
     if (position.value.inSeconds > 3) {
       // 播放超过3秒，回到歌曲开头
       seekTo(Duration.zero);
       return;
     }
     if (playHistory.isNotEmpty) {
       // 回到上一首歌
       final previous = playHistory.removeLast();
       // 将当前歌放回队列头部
       // 播放 previous
     } else {
       // 没有历史，回到歌曲开头
       seekTo(Duration.zero);
     }
   }
   ```

**预期效果**: 用户按「上一曲」可以真正回到之前听过的歌，行为符合所有主流音乐播放器的习惯。

---

### 方案 2：区分「用户主动跳过」和「自然播完」的行为

**核心思路**: 用户主动点击下一曲/上一曲时，行为应该更保守（队列为空则停止）；歌曲自然播完时，才触发自动推荐。

**具体改动**:

1. `skipNext`（用户主动跳过）：
   - 队列有下一首 → 播放下一首
   - 队列为空 → **停止播放**，显示提示「播放列表已播完」，而不是自动随机推荐
   - 可选：提供一个「继续发现」按钮让用户主动触发推荐

2. `_playNext` / `_advanceNext`（自然播完）：
   - 保持现有的自动推荐逻辑
   - 但增加 Toast 提示「已为你自动推荐」，让用户知道发生了什么

3. `skipPrevious`（用户上一曲）：
   - 参照方案 1 实现历史栈
   - 没有历史时回到歌曲开头，**不触发自动推荐**

---

### 方案 3：改进自动播放质量

**核心思路**: 利用已有的用户偏好系统提升自动播放的个性化程度。

**具体改动**:

1. **改进 `playRandomIfNeeded`**：
   ```dart
   Future<void> playRandomIfNeeded() async {
     // 优先使用用户的偏好标签
     final tags = _storage.preferenceTags;
     if (tags.isNotEmpty) {
       // 使用 RecommendationService 获取个性化推荐
       final recService = Get.find<RecommendationService>();
       final songs = await recService.getRecommendations(tags: tags);
       if (songs.isNotEmpty) {
         await playFromSearch(songs.first);
         // 将其余歌曲加入队列
         for (int i = 1; i < songs.length; i++) {
           await addToQueueSilent(songs[i]);
         }
         return;
       }
     }
     // 回退到现有的随机逻辑（作为兜底）
   }
   ```

2. **利用播放历史改进推荐**：
   - 将 `StorageService` 中的播放历史传给 `recentPlayed` 参数，避免推荐刚听过的歌。

3. **添加质量过滤**：
   - 复用 `RecommendationService._isQualityResult()` 对 `playRandomIfNeeded` 的搜索结果进行过滤，避免搜到非音乐内容。

---

### 方案 4：解决推荐歌曲重复

**4a. 全局去重机制**

1. 在 `PlayerController` 或 `RecommendationService` 中维护一个**会话级别的已推荐歌曲集合**：
   ```dart
   final _recommendedIds = <String>{};  // 存储 uniqueId
   ```

2. 每次推荐时：
   - 将播放历史 + 当前队列 + 已推荐集合中的歌曲全部传给 `recentPlayed`。
   - 过滤掉结果中已在集合内的歌曲。

3. 在 `getRecommendations` 返回结果后，将新歌曲的 ID 加入集合。

**4b. 相关推荐去重**

1. `_loadRelatedMusic` 过滤掉当前队列中已有的歌曲：
   ```dart
   final queueIds = queue.map((q) => q.video.uniqueId).toSet();
   final filtered = results.where((s) => !queueIds.contains(s.uniqueId)).toList();
   relatedMusic.assignAll(filtered);
   ```

2. 对网易云搜索结果做**标题相似度去重**：
   - 对标题进行标准化（去除空格、括号内容如「Live版」「翻唱」等）
   - 使用标准化后的标题做去重

**4c. 改进 AI 推荐 prompt**

在 `generateSongRecommendations` 的 prompt 中强化去重指令：
- 明确说明「每首歌只推荐一个版本，不要推荐同一首歌的不同版本（Live、翻唱、伴奏等）」
- 增加多样性指令：「每位歌手最多推荐2首歌，确保歌手多样性」

**4d. 增加标题模糊匹配去重**

在 `RecommendationService` 中添加标题相似度检查：
```dart
bool _isSimilarTitle(String a, String b) {
  final normalA = _normalizeTitle(a);
  final normalB = _normalizeTitle(b);
  return normalA == normalB;
}

String _normalizeTitle(String title) {
  return title
    .replaceAll(RegExp(r'\(.*?\)'), '')  // 去括号
    .replaceAll(RegExp(r'【.*?】'), '')    // 去方括号
    .replaceAll(RegExp(r'\s+'), '')        // 去空格
    .toLowerCase();
}
```

---

### 方案 5：重构队列数据结构

**核心思路**: 将 `currentIndex` 改为真正的索引指针，不再每次都把歌曲移到 `queue[0]`。

**具体改动**:

1. `currentIndex` 成为队列中的真正位置指针，不再固定为 0。
2. `_advanceNext`: `currentIndex++` 而不是移动元素。
3. `skipPrevious`: `currentIndex--` 即可回到上一首。
4. 新增的歌曲添加到 `currentIndex` 之后（即插入到「待播放」区域）。
5. `currentIndex` 之前的元素即为已播放历史，替代方案 1 中的独立历史栈。

```
queue: [已播放1, 已播放2, ▶正在播放, 待播放1, 待播放2]
                           ↑ currentIndex = 2
```

**优势**:
- 自然支持上一曲/下一曲
- 队列顺序不被打乱
- 已播放歌曲自然保留在队列中
- 与主流音乐播放器的队列模型一致

**注意**: 这是一个较大的重构，涉及队列相关的所有方法（`_addToQueue`、`playAt`、`reorderQueue`、`removeFromQueue`、`skipNext`、`_advanceNext`、`clearQueue`），需要仔细测试。

---

## 三、优先级建议

| 优先级 | 方案 | 理由 |
|--------|------|------|
| P0 | 方案 1 — 播放历史栈 | 「上一曲」调用 `_autoPlayNext` 是明显 bug，用户体验严重受损 |
| P0 | 方案 2 — 区分主动跳过和自然播完 | 主动跳过时随机推荐令用户困惑，是核心交互缺陷 |
| P1 | 方案 4 — 推荐去重 | 重复推荐降低产品品质感，且改动相对集中 |
| P1 | 方案 3 — 改进自动播放 | 冷启动体验很重要，决定用户第一印象 |
| P2 | 方案 5 — 重构队列 | 改动范围大，但能从根本上解决上一曲/下一曲和队列顺序问题 |

---

## 四、实施建议

建议按以下顺序实施：

1. **先修复 `skipPrevious` 的 bug**（方案 1 简化版）：即使不实现完整的历史栈，至少把 `_autoPlayNext()` 改为 `seekTo(Duration.zero)` 或者直接停止，避免「上一曲→随机推荐新歌」的荒谬行为。

2. **修改 `skipNext` 队列为空时的行为**（方案 2）：队列为空时停止播放而不是随机推荐。

3. **添加推荐去重逻辑**（方案 4）：从 prompt 优化 + 标题模糊匹配两个方向同时改进。

4. **改进 `playRandomIfNeeded`**（方案 3）：优先使用用户偏好标签进行推荐。

5. **评估是否需要重构队列**（方案 5）：如果方案 1-4 实施后体验已经明显改善，可以推迟此项；如果仍有不满意的地方，再做彻底重构。

---

## 五、已完成的改动

### 修改的文件

1. **`lib/modules/player/player_controller.dart`**
   - 新增 `playHistory` 播放历史栈（最多 50 首）和 `_pushToHistory()` 方法
   - 修复 `skipPrevious`: 从历史栈回到上一首歌，而不是调用 `_autoPlayNext`
   - 修复 `skipNext`: 队列为空时停止播放并提示「播放列表已播完」，而不是随机推荐
   - 修复 `_advanceNext`: 播完的歌曲移入历史栈，从队列中移除
   - 修复 `playAt`: 当前歌曲移入历史栈，从队列中移除，避免队列膨胀
   - 修复 `_addToQueue`: 新歌替换当前歌时，旧歌先入历史栈
   - `_autoPlayNext` 成功时显示 Toast「已为你自动推荐」
   - `clearQueue` 同时清空历史栈
   - `_loadRelatedMusic`: 过滤掉队列中已有的歌曲；网易云改为按歌手搜索 + 标题模糊去重
   - `playRandomIfNeeded`: 优先使用用户偏好标签 + `RecommendationService` 个性化推荐，关键词搜索作为兜底
   - 新增 `_normalizeTitle` 标题标准化方法用于模糊去重

2. **`lib/data/services/recommendation_service.dart`**
   - 新增 `_sessionRecommendedIds` 会话级去重集合，避免跨批次推荐重复歌曲
   - 新增 `_normalizeTitle` 标题标准化方法
   - `getRecommendations` 增加三层去重：会话级 ID 去重 → 批次内 ID 去重 → 标题模糊去重

3. **`lib/data/repositories/deepseek_repository.dart`**
   - 优化 `generateSongRecommendations` prompt: 每首歌只推荐原版、每位歌手最多2首、确保多样性
   - 优化 `generateRandomSongRecommendations` prompt: 同上规则

4. **`lib/modules/player/services/heart_mode_service.dart`**
   - `autoNext` 方法：`recentPlayed` 改为合并当前队列 + 持久化播放历史（最多 30 条），提升去重效果
