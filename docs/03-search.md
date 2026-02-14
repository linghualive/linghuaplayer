# 搜索功能

> 本文档基于 pilipala 项目源码提取，描述 Bilibili 非官方搜索相关 API。

---

## 1. 热搜榜

### hotSearchList

- **用途**：获取 B 站当前热搜关键词列表
- **端点**：`GET https://s.search.bilibili.com/main/hotword`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：无

**请求示例**：

```dart
var res = await Request().get('https://s.search.bilibili.com/main/hotword');
```

**响应示例**：

```json
{
  "code": 0,
  "list": [
    {
      "keyword": "热搜关键词1",
      "show_name": "显示名称",
      "icon": "https://...",
      "position": 1,
      "word_type": 1,
      "hot_id": 12345
    },
    ...
  ],
  "exp_str": "..."
}
```

**关键说明**：
- 此接口返回格式与标准格式略有不同，数据在 `list` 而非 `data` 字段中
- 返回值可能是 JSON 字符串（需要 `json.decode`）或 Map，代码中做了兼容处理
- 数据模型：`HotSearchModel`

---

## 2. 搜索建议

### searchSuggest

- **用途**：根据用户输入实时获取搜索建议（自动补全）
- **端点**：`GET https://s.search.bilibili.com/main/suggest`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `term` | string | 是 | 用户输入的搜索词 |
| `main_ver` | string | 是 | 固定 `"v1"` |
| `highlight` | string | 是 | 高亮词，与 term 相同 |

**请求示例**：

```dart
var res = await Request().get(
  'https://s.search.bilibili.com/main/suggest',
  data: {'term': '周杰伦', 'main_ver': 'v1', 'highlight': '周杰伦'},
);
```

**响应示例**：

```json
{
  "code": 0,
  "result": {
    "tag": [
      {
        "value": "周杰伦 晴天",
        "term": "周杰伦",
        "ref": 1,
        "name": "周杰伦 晴天",
        "spid": 5
      },
      ...
    ],
    "term": "周杰伦"
  }
}
```

**关键说明**：
- 响应数据在 `result` 字段中（非标准 `data`）
- `result` 可能是 Map 或其他类型，需做类型判断
- 数据模型：`SearchSuggestModel`

---

## 3. 分类搜索

### searchByType

- **用途**：按类型搜索 B 站内容
- **端点**：`GET https://api.bilibili.com/x/web-interface/wbi/search/type`
- **是否需要登录**：否（但登录后结果更精准）
- **是否需要 WBI 签名**：是（端点路径含 `wbi`）
- **是否需要 CSRF**：否
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `search_type` | string | 是 | 搜索类型（见下表） |
| `keyword` | string | 是 | 搜索关键词 |
| `page` | int | 是 | 页码 |
| `order` | string | 否 | 排序方式 |
| `duration` | int | 否 | 时长筛选 |
| `tids` | int | 否 | 分区 ID（-1 表示全部） |

**搜索类型（SearchType）**：

| 枚举值 | type 字符串 | 说明 | 对应数据模型 |
|--------|-------------|------|-------------|
| `video` | `"video"` | 视频 | `SearchVideoModel` |
| `media_bangumi` | `"media_bangumi"` | 番剧 | `SearchMBangumiModel` |
| `live_room` | `"live_room"` | 直播间 | `SearchLiveModel` |
| `bili_user` | `"bili_user"` | 用户 | `SearchUserModel` |
| `article` | `"article"` | 专栏 | `SearchArticleModel` |

**视频排序方式（ArchiveFilterType）**：

| 值 | 说明 |
|----|------|
| `totalrank` | 默认排序（综合） |
| `click` | 播放最多 |
| `pubdate` | 最新发布 |
| `dm` | 弹幕最多 |
| `stow` | 收藏最多 |
| `scores` | 评论最多 |

**专栏排序方式（ArticleFilterType）**：

| 值 | 说明 |
|----|------|
| `totalrank` | 综合排序 |
| `pubdate` | 最新发布 |
| `click` | 最多点击 |
| `attention` | 最多喜欢 |
| `scores` | 最多评论 |

**请求示例**：

```dart
var reqData = {
  'search_type': 'video',
  'keyword': '周杰伦',
  'page': 1,
  'order': 'totalrank',
};
var res = await Request().get(
  '/x/web-interface/wbi/search/type',
  data: reqData,
);
```

**响应示例**：

```json
{
  "code": 0,
  "data": {
    "seid": "xxxx",
    "page": 1,
    "pagesize": 20,
    "numResults": 1000,
    "numPages": 50,
    "result": [
      {
        "type": "video",
        "id": 123456,
        "author": "UP主名称",
        "mid": 12345,
        "title": "<em class=\"keyword\">周杰伦</em>最新MV",
        "description": "...",
        "pic": "//i0.hdslb.com/...",
        "play": 100000,
        "danmaku": 5000,
        "duration": "4:30",
        "arcurl": "...",
        "bvid": "BVxxxxxxxxxx"
      },
      ...
    ]
  }
}
```

**关键说明**：
- 当 `numPages == 0` 时，表示无搜索结果
- 视频搜索结果中的 `title` 包含 HTML 高亮标签 `<em>`
- 会根据黑名单列表过滤 `mid` 在黑名单中的结果

---

## 4. 搜索结果计数

### searchCount

- **用途**：获取各类型搜索结果的总数
- **端点**：`GET https://api.bilibili.com/x/web-interface/wbi/search/all/v2`
- **是否需要登录**：否
- **是否需要 WBI 签名**：是
- **是否需要 CSRF**：否
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `keyword` | string | 是 | 搜索关键词 |
| `web_location` | double | 是 | 固定 `333.999` |
| `wts` | string | 是 | WBI 签名时间戳（自动生成） |
| `w_rid` | string | 是 | WBI 签名值（自动生成） |

**请求示例**：

```dart
Map<String, dynamic> data = {
  'keyword': '周杰伦',
  'web_location': 333.999,
};
Map params = await WbiSign().makSign(data);
var res = await Request().get('/x/web-interface/wbi/search/all/v2', data: params);
```

**响应示例**：

```json
{
  "code": 0,
  "data": {
    "result": {
      "video": { "numResults": 1000 },
      "media_bangumi": { "numResults": 5 },
      "live_room": { "numResults": 10 },
      "bili_user": { "numResults": 50 },
      "article": { "numResults": 30 }
    }
  }
}
```

**关键说明**：数据模型为 `SearchAllModel`。

---

## 5. AV/BV 转 CID

### ab2c

- **用途**：将 AV 号或 BV 号转换为 CID（视频分 P 的内容 ID，播放前必须获取）
- **端点**：`GET https://api.bilibili.com/x/player/pagelist`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `aid` | int | 二选一 | AV 号 |
| `bvid` | string | 二选一 | BV 号 |

**请求示例**：

```dart
var res = await Request().get('/x/player/pagelist', data: {'bvid': 'BV1xx411c7mD'});
int cid = res.data['data'].first['cid'];
```

**响应示例**：

```json
{
  "code": 0,
  "data": [
    {
      "cid": 123456789,
      "page": 1,
      "from": "vupload",
      "part": "分P标题",
      "duration": 300,
      "vid": "",
      "weblink": "",
      "dimension": { "width": 1920, "height": 1080, "rotate": 0 },
      "first_frame": "https://..."
    }
  ]
}
```

**关键说明**：
- 返回数组，每个元素对应一个分 P
- 通常取 `data[0]['cid']` 即可获得第一个分 P 的 CID
- `ab2cWithPic` 变体还会返回 `first_frame`（首帧图片 URL）

---

## 6. 番剧信息

### bangumiInfo

- **用途**：通过 seasonId 或 epId 获取番剧/影视的详细信息
- **端点**：`GET https://api.bilibili.com/pgc/view/web/season`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `season_id` | int | 二选一 | 番剧 seasonId |
| `ep_id` | int | 二选一 | 单集 epId |

**请求示例**：

```dart
var res = await Request().get('/pgc/view/web/season', data: {'season_id': 12345});
```

**响应示例**：

```json
{
  "code": 0,
  "result": {
    "season_id": 12345,
    "title": "番剧名称",
    "cover": "https://...",
    "evaluate": "简介...",
    "episodes": [
      {
        "ep_id": 67890,
        "title": "第1话",
        "cid": 111222333,
        "aid": 444555666,
        "bvid": "BVxxxxxxxxxx",
        "cover": "https://..."
      }
    ],
    "stat": {
      "views": 10000000,
      "danmakus": 500000,
      "coins": 100000
    }
  }
}
```

**关键说明**：
- 注意数据在 `result` 字段中而非 `data`（番剧接口特有）
- 数据模型：`BangumiInfoModel`
- 每个 episode 包含 `cid`，可直接用于获取播放流

---

## 7. 默认搜索词

### searchDefault

- **用途**：获取搜索框的默认占位搜索词
- **端点**：`GET https://api.bilibili.com/x/web-interface/wbi/search/default`
- **是否需要登录**：否
- **是否需要 WBI 签名**：是
- **是否需要 CSRF**：否
- **请求参数**：WBI 签名参数（`wts` + `w_rid`）

**关键说明**：此接口在项目中定义但未被直接调用为独立方法。

---

## 8. 搜索流程总结

### 典型搜索播放流程

```
用户输入关键词
    │
    ├──→ searchSuggest()       获取搜索建议（实时）
    │
    ├──→ hotSearchList()       展示热搜榜（首页）
    │
    └──→ searchByType()        执行搜索
            │
            ├── type=video     视频结果列表
            │     │
            │     └──→ ab2c()  获取 CID
            │           │
            │           └──→ videoUrl()  获取播放流（见 04-playback.md）
            │
            ├── type=live_room     直播间结果
            ├── type=bili_user     用户结果
            ├── type=media_bangumi 番剧结果
            │     │
            │     └──→ bangumiInfo()  获取番剧详情+分集CID
            │
            └── type=article       专栏结果
```

### 搜索到播放的最短路径

```dart
// 1. 搜索视频
var searchRes = await SearchHttp.searchByType(
  searchType: SearchType.video,
  keyword: '周杰伦 晴天',
  page: 1,
);

// 2. 获取第一个结果的 BV 号
String bvid = searchRes['data'].list[0].bvid;

// 3. 获取 CID
int cid = await SearchHttp.ab2c(bvid: bvid);

// 4. 获取播放流 URL（见 04-playback.md）
var playUrl = await VideoHttp.videoUrl(bvid: bvid, cid: cid);
```
