# HTTP 基础架构

> 本文档基于 pilipala 项目源码提取，描述 Bilibili 非官方 API 的 HTTP 请求基础设施。

## 1. Base URL 列表

| 常量名 | URL | 用途 |
|--------|-----|------|
| `baseUrl` | `https://www.bilibili.com` | B站主站，Cookie 来源域 |
| `apiBaseUrl` | `https://api.bilibili.com` | 主 API 域名（默认 baseUrl） |
| `tUrl` | `https://api.vc.bilibili.com` | 动态/私信/消息 API |
| `appBaseUrl` | `https://app.bilibili.com` | 移动端 APP API |
| `liveBaseUrl` | `https://api.live.bilibili.com` | 直播 API |
| `passBaseUrl` | `https://passport.bilibili.com` | 登录/鉴权 API |
| `messageBaseUrl` | `https://message.bilibili.com` | 系统消息 API |
| `bangumiBaseUrl` | `https://bili.meark.me` | 番剧代理（港澳台解锁） |

> 源码位置：`lib/http/constants.dart`

## 2. Dio 客户端配置

> 源码位置：`lib/http/init.dart` — `Request._internal()`

```dart
BaseOptions options = BaseOptions(
  baseUrl: HttpString.apiBaseUrl,           // 默认 https://api.bilibili.com
  connectTimeout: Duration(milliseconds: 12000),  // 连接超时 12s
  receiveTimeout: Duration(milliseconds: 12000),  // 接收超时 12s
  headers: {},
);
```

### 关键配置

- **Cookie 持久化**：使用 `PersistCookieJar`（`cookie_jar` 包），存储在本地文件系统，`ignoreExpires: true` 忽略过期
- **拦截器**：`ApiInterceptor`（自定义）+ `LogInterceptor`（日志）+ `CookieManager`（Cookie 管理）
- **响应转换**：`BackgroundTransformer`，在后台线程解析 JSON
- **状态码校验**：除 2xx 外，还允许 302/304/307/400/401/403/404 等特殊状态码通过（用于处理重定向等场景）
- **POST 默认 Content-Type**：`application/x-www-form-urlencoded`
- **代理支持**：可通过设置开启系统代理 `PROXY host:port`

## 3. 请求头设置

> 源码位置：`lib/http/init.dart` — `setOptionsHeaders()`

登录后会设置以下请求头：

| Header | 值 | 说明 |
|--------|-----|------|
| `x-bili-mid` | 用户 mid | 当前登录用户的数字 ID |
| `x-bili-aurora-eid` | `genAuroraEid(mid)` | Aurora 加密 EID（见下文） |
| `env` | `prod` | 环境标识 |
| `app-key` | `android64` | 客户端标识 |
| `x-bili-aurora-zone` | `sh001` | 区域标识 |
| `referer` | `https://www.bilibili.com/` | 防盗链 Referer |
| `cookie` | Cookie 字符串 | 由 CookieJar 拼接 |

### User-Agent

根据场景切换不同 UA：

- **移动端 (mob)**
  - iOS: `Mozilla/5.0 (iPhone; CPU iPhone OS 14_5 like Mac OS X) AppleWebKit/605.1.15 ...`
  - Android: `Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 ...`
- **桌面端 (pc)**
  - `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 ...`

## 4. CSRF Token 获取

> 源码位置：`lib/http/init.dart` — `getCsrf()`

CSRF Token 从 Cookie 中的 `bili_jct` 字段提取：

```dart
static Future<String> getCsrf() async {
  List<Cookie> cookies = await cookieManager.cookieJar
      .loadForRequest(Uri.parse(HttpString.apiBaseUrl));
  String token = '';
  if (cookies.where((e) => e.name == 'bili_jct').isNotEmpty) {
    token = cookies.firstWhere((e) => e.name == 'bili_jct').value;
  }
  return token;
}
```

**使用场景**：所有 POST 请求（点赞、投币、收藏、发送弹幕等）都需要在请求体中携带 `csrf` 参数。

## 5. BUVID 生成与激活

### 5.1 BUVID 生成算法

> 源码位置：`lib/http/login.dart` — `buvid()` 和 `lib/utils/login.dart` — `LoginUtils.buvid()`

```
1. 生成 6 段随机十六进制数（模拟 MAC 地址）
2. 将 MAC 地址用 ":" 连接后做 MD5 哈希
3. 取 MD5 结果的第 2、12、22 位字符
4. 拼接为 "XY" + 3位字符 + 完整MD5
```

伪代码：
```
mac = 6个随机hex段，用":"连接    // 例: "a1:b2:c3:d4:e5:f6"
md5Str = MD5(mac)                 // 32位hex
buvid = "XY" + md5Str[2] + md5Str[12] + md5Str[22] + md5Str
```

另一种生成方式（`generateBuvid`）：
```
uuid = UUID_v4去掉横线 + UUID_v4去掉横线   // 64位hex
buvid = "XY" + uuid前35位大写
```

### 5.2 BUVID 获取（从服务端）

> 源码位置：`lib/http/init.dart` — `getBuvid()`

优先从 Cookie 中读取 `buvid3`，若不存在则请求服务端：

- **端点**：`GET https://api.bilibili.com/x/frontend/finger/spi`
- **返回**：`data.b_3` 即为 buvid3

### 5.3 BUVID 激活

> 源码位置：`lib/http/init.dart` — `buvidActivate()`

激活流程：
1. 请求 `https://space.bilibili.com/1/dynamic` 获取页面 HTML
2. 从 HTML 中提取 `<meta name="spm_prefix" content="...">` 的值
3. 生成随机 payload（模拟 PNG 数据的 base64）
4. POST 到 `/x/internal/gaia-gateway/ExClimbWuzhi`，Content-Type 为 `application/json`

```json
{
  "payload": "{\"3064\":1,\"39c8\":\"<spmPrefix>.fp.risk\",\"3c43\":{\"adca\":\"Linux\",\"bfe9\":\"<rand_png_end_last50>\"}}"
}
```

## 6. WBI 签名算法

> 源码位置：`lib/utils/wbi_sign.dart`
>
> 参考文档：[bilibili-API-collect/wbi.md](https://github.com/SocialSisterYi/bilibili-API-collect/blob/master/docs/misc/sign/wbi.md)

WBI 签名用于部分 GET 请求的参数防篡改校验，会在请求参数中添加 `wts`（时间戳）和 `w_rid`（签名）。

### 6.1 获取 img_key 和 sub_key

- **端点**：`GET https://api.bilibili.com/x/web-interface/nav`
- **返回路径**：`data.wbi_img.img_url` 和 `data.wbi_img.sub_url`
- **提取**：从 URL 中提取文件名（去掉路径和扩展名）作为 key

```
img_url: "https://i0.hdslb.com/bfs/wbi/7cd084941338484aae1ad9425b84077c.png"
→ imgKey: "7cd084941338484aae1ad9425b84077c"

sub_url: "https://i0.hdslb.com/bfs/wbi/4932caff0ff746eab6f01bf08b70ac45.png"
→ subKey: "4932caff0ff746eab6f01bf08b70ac45"
```

**缓存策略**：本地缓存 wbiKeys，每天更新一次（按日期判断）。

### 6.2 mixinKeyEncTab 打乱表

用于对 `imgKey + subKey` 进行字符重排：

```
[46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35,
 27, 43, 5, 49, 33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13,
 37, 48, 7, 16, 24, 55, 40, 61, 26, 17, 0, 1, 60, 51, 30, 4,
 22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36, 20, 34, 44, 52]
```

### 6.3 getMixinKey

```
输入: orig = imgKey + subKey  (64字符)
处理: 按 mixinKeyEncTab 的索引顺序重新排列字符
输出: 取前32位作为 mixinKey
```

### 6.4 encWbi 签名流程

```
1. 向原始参数中添加 wts = 当前Unix时间戳（秒）
2. 按参数名（key）字典序排序
3. 对每个参数的 key 和 value 做 URL 编码
4. 过滤 value 中的特殊字符: ! ' ( ) *
5. 用 & 连接所有 key=value 对，得到 queryStr
6. 计算 w_rid = MD5(queryStr + mixinKey)
7. 返回 { wts: "时间戳", w_rid: "签名值" }
```

### 6.5 完整使用示例

```dart
// 需要 WBI 签名的请求
Map<String, dynamic> data = {
  'cid': cid,
  'bvid': bvid,
  'qn': 80,
  'fnval': 4048,
  'fourk': 1,
};
Map params = await WbiSign().makSign(data);
// params 现在包含原始参数 + wts + w_rid
var res = await Request().get('/x/player/wbi/playurl', data: params);
```

### 6.6 需要 WBI 签名的 API

| API 路径 | 用途 |
|----------|------|
| `/x/player/wbi/playurl` | 获取视频播放流 URL |
| `/x/web-interface/wbi/search/type` | 分类搜索 |
| `/x/web-interface/wbi/search/all/v2` | 搜索结果计数 |
| `/x/web-interface/wbi/search/default` | 默认搜索词 |
| `/x/space/wbi/acc/info` | 用户空间信息 |
| `/x/space/wbi/arc/search` | 用户投稿搜索 |
| `/x/web-interface/view/conclusion/get` | AI 总结 |

> 判断方法：API 路径中包含 `wbi` 的端点通常需要 WBI 签名。

## 7. AV/BV 号互转算法

> 源码位置：`lib/utils/id_utils.dart`

### 7.1 常量

```dart
XOR_CODE  = 23442827791579
MASK_CODE = 2251799813685247
MAX_AID   = 1 << 51
BASE      = 58
data      = "FcwAPNKTMug3GV5Lj7EJnHpWsx4tb8haYeviqBz6rkCy12mUSDQX9RdoZf"
```

### 7.2 AV → BV

```
1. 初始化 12 位字符数组 ['B','V','1','0','0','0','0','0','0','0','0','0']
2. tmp = (MAX_AID | aid) ^ XOR_CODE
3. 从末尾开始，对 tmp 反复取模 58，映射到 data 字符表
4. 交换位置 3↔9, 4↔7
5. 拼接得到 BV 号
```

### 7.3 BV → AV

```
1. 交换位置 3↔9, 4↔7
2. 去掉前3位 "BV1"
3. 按 data 字符表做 58 进制转换
4. 结果 = (tmp & MASK_CODE) ^ XOR_CODE
```

### 7.4 匹配工具

`matchAvorBv(input)` 支持从任意字符串中正则提取 AV/BV 号：
- BV 号：`/[bB][vV][0-9A-Za-z]{10}/`
- AV 号：`/[aA][vV]\d+/`

## 8. Aurora EID 生成

> 源码位置：`lib/utils/id_utils.dart` — `genAuroraEid()`

```dart
static String? genAuroraEid(int uid) {
  if (uid == 0) return null;
  String uidString = uid.toString();
  List<int> resultBytes = List.generate(
    uidString.length,
    (i) => uidString.codeUnitAt(i) ^ "ad1va46a7lza".codeUnitAt(i % 12),
  );
  String auroraEid = base64Url.encode(resultBytes);
  auroraEid = auroraEid.replaceAll(RegExp(r'=*$'), '');
  return auroraEid;
}
```

算法：将 UID 字符串的每个字符与密钥 `"ad1va46a7lza"` 循环异或，然后做 Base64URL 编码，去掉末尾的 `=` 填充。

## 9. 应用常量

> 源码位置：`lib/common/constants.dart`

| 常量 | 值 | 说明 |
|------|----|------|
| `appKey` | `4409e2ce8ffd12b8` | TV 端 appKey |
| `appSec` | `59b43e04ad6965f34319062b478f83dd` | TV 端 appSec |
| `thirdSign` | `04224646d1fea004e79606d3b038c84a` | 第三方签名 |
| `thirdApi` | `https://www.mcbbs.net/template/mcbbs/image/special_photo_bg.png` | 第三方回调地址（用于提取 access_key） |

> 移动端 Android appKey 为 `27eb53fc9058f8c3`（代码注释中提到，未使用）。

## 10. 通用响应格式

所有 API 返回 JSON，格式统一为：

```json
{
  "code": 0,
  "message": "0",
  "ttl": 1,
  "data": { ... }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | int | 状态码，0 表示成功 |
| `message` | string | 状态消息 |
| `ttl` | int | 固定为 1 |
| `data` | object/array | 实际数据 |

项目中的统一处理模式：

```dart
if (res.data['code'] == 0) {
  return {'status': true, 'data': res.data['data']};
} else {
  return {'status': false, 'data': [], 'msg': res.data['message']};
}
```

## 11. access_key 提取

> 源码位置：`lib/http/interceptor.dart`

在响应拦截器中，当收到 302 重定向且目标地址为 `https://www.mcbbs.net` 时，从 URL 参数中提取 `access_key` 和 `mid`，缓存到本地：

```dart
if (response.statusCode == 302) {
  final locations = response.headers['location']!;
  if (locations.first.startsWith('https://www.mcbbs.net')) {
    final uri = Uri.parse(locations.first);
    final accessKey = uri.queryParameters['access_key'];
    final mid = uri.queryParameters['mid'];
    localCache.put(LocalCacheKey.accessKey, {'mid': mid, 'value': accessKey});
  }
}
```

`access_key` 用于 APP 端 API 的鉴权（如推荐视频列表）。
