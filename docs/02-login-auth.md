# 登录与鉴权

> 本文档基于 pilipala 项目源码提取，描述 Bilibili 非官方 API 的登录与鉴权流程。

## 总览

项目支持三种登录方式：

| 方式 | 入口函数 | 适用场景 |
|------|----------|----------|
| QR 码扫码登录 | `getWebQrcode` → `queryWebQrcodeStatus` | 推荐方式，无需手机号 |
| 短信验证码登录 | `sendWebSmsCode` → `loginInByWebSmsCode` | Web 端手机登录 |
| 密码登录 | `getWebKey` → `loginInByWebPwd` | Web 端密码登录 |

所有登录方式登录成功后，统一调用 `LoginUtils.confirmLogin()` 完成后续处理。

---

## 1. 人机验证（前置步骤）

短信登录和密码登录都需要先完成极验（GeeTest）人机验证。

### 获取验证码参数

- **用途**：获取极验验证码的初始化参数
- **端点**：`GET https://passport.bilibili.com/x/passport-login/captcha?source=main_web`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：无（source 已包含在 URL 中）

**响应示例**：

```json
{
  "code": 0,
  "data": {
    "type": "geetest",
    "token": "xxxxxxxxxx",
    "geetest": {
      "challenge": "xxxxxxxxxx",
      "gt": "xxxxxxxxxx"
    },
    "tencent": null
  }
}
```

**关键说明**：
- 返回的 `token`、`geetest.challenge`、`geetest.gt` 用于初始化极验 SDK
- 用户完成验证后，SDK 回调返回 `geetest_validate`、`geetest_seccode`、`geetest_challenge`
- 这些值在后续的发送短信/密码登录请求中使用

---

## 2. QR 码扫码登录

### 2.1 生成二维码

- **用途**：获取登录二维码的 URL 和 key
- **端点**：`GET https://passport.bilibili.com/x/passport-login/web/qrcode/generate`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：无

**响应示例**：

```json
{
  "code": 0,
  "data": {
    "url": "https://passport.bilibili.com/h5/login/scan?navhide=1&qrcode_key=xxxxx&from=",
    "qrcode_key": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }
}
```

| 返回字段 | 类型 | 说明 |
|----------|------|------|
| `url` | string | 二维码内容 URL，用于生成二维码图片 |
| `qrcode_key` | string | 二维码的唯一标识，用于轮询状态 |

### 2.2 轮询登录状态

- **用途**：轮询检查二维码是否已被扫描确认
- **端点**：`GET https://passport.bilibili.com/x/passport-login/web/qrcode/poll`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `qrcode_key` | string | 是 | 二维码生成时返回的 key |

**响应示例**（扫码成功）：

```json
{
  "code": 0,
  "data": {
    "code": 0,
    "url": "https://passport.bilibili.com/...",
    "refresh_token": "xxxxxx",
    "timestamp": 1234567890,
    "message": ""
  }
}
```

**轮询状态码（`data.code`）**：

| code | 说明 |
|------|------|
| 0 | 扫码登录成功 |
| 86038 | 二维码已失效 |
| 86090 | 已扫码，等待确认 |
| 86101 | 未扫码 |

**关键说明**：
- 客户端每秒轮询一次，总计 180 秒超时
- 超时后自动重新生成二维码
- 登录成功后（`data.code == 0`），调用 `LoginUtils.confirmLogin()` 完成后续流程

---

## 3. 短信验证码登录

### 3.1 发送短信验证码

- **用途**：向手机号发送登录验证码
- **端点**：`POST https://passport.bilibili.com/x/passport-login/web/sms/send`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**（FormData）：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `cid` | int | 是 | 国际区号，中国大陆为 86 |
| `tel` | int | 是 | 手机号 |
| `source` | string | 是 | 固定 `"main_web"` |
| `token` | string | 是 | 人机验证 token |
| `challenge` | string | 是 | 极验 challenge |
| `validate` | string | 是 | 极验 validate |
| `seccode` | string | 是 | 极验 seccode |

**响应示例**：

```json
{
  "code": 0,
  "data": {
    "captcha_key": "xxxxxxxxxxxxxxxxxxxxxxxx",
    "is_new": false
  }
}
```

**关键说明**：
- 返回的 `captcha_key` 需要在下一步验证码登录时使用
- 发送后开始 60 秒倒计时，期间不可重复发送

### 3.2 验证码登录

- **用途**：使用短信验证码完成登录
- **端点**：`POST https://passport.bilibili.com/x/passport-login/web/login/sms`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**（FormData）：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `cid` | int | 是 | 国际区号，86 |
| `tel` | int | 是 | 手机号 |
| `code` | int | 是 | 短信验证码 |
| `source` | string | 是 | 固定 `"main_mini"` |
| `keep` | int | 是 | 固定 0 |
| `captcha_key` | string | 是 | 发送短信时返回的 key |
| `go_url` | string | 是 | 登录后跳转 URL，固定 `https://www.bilibili.com` |

**响应示例**：

```json
{
  "code": 0,
  "data": {
    "is_new": false,
    "status": 0,
    "url": "",
    "token_info": { ... }
  }
}
```

---

## 4. 密码登录

### 4.1 获取 RSA 公钥

- **用途**：获取密码加密所需的 RSA 公钥和盐值（hash）
- **端点**：`GET https://passport.bilibili.com/x/passport-login/web/key`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `disable_rcmd` | int | 否 | 固定 0 |
| `local_id` | string | 否 | BUVID |

**响应示例**：

```json
{
  "code": 0,
  "data": {
    "hash": "xxxxxxxx",
    "key": "-----BEGIN PUBLIC KEY-----\nMIGfMA0GCS...\n-----END PUBLIC KEY-----\n"
  }
}
```

| 返回字段 | 类型 | 说明 |
|----------|------|------|
| `hash` | string | 密码盐值（rhash），需拼接在密码前 |
| `key` | string | RSA 公钥（PEM 格式） |

### 4.2 Web 端密码登录

- **用途**：使用用户名密码登录
- **端点**：`POST https://passport.bilibili.com/x/passport-login/web/login`
- **是否需要登录**：否
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**（FormData）：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `username` | int | 是 | 手机号 |
| `password` | string | 是 | RSA 加密后的密码（Base64） |
| `keep` | int | 是 | 固定 0 |
| `token` | string | 是 | 人机验证 token |
| `challenge` | string | 是 | 极验 challenge |
| `validate` | string | 是 | 极验 validate |
| `seccode` | string | 是 | 极验 seccode |
| `source` | string | 是 | 固定 `"main-fe-header"` |
| `go_url` | string | 是 | 固定 `https://www.bilibili.com` |

**密码加密流程**：

```dart
// 1. 获取 RSA 公钥和 hash
var webKeyRes = await LoginHttp.getWebKey();
String rhash = webKeyRes['data']['hash'];
String key = webKeyRes['data']['key'];

// 2. 解析 PEM 公钥
dynamic publicKey = RSAKeyParser().parse(key);

// 3. 加密: RSA(rhash + 明文密码) → Base64
String passwordEncrypted = Encrypter(RSA(publicKey: publicKey))
    .encrypt(rhash + password)
    .base64;
```

**响应示例**（成功）：

```json
{
  "code": 0,
  "data": {
    "status": 0,
    "url": "",
    "token_info": { ... }
  }
}
```

**关键说明**：
- `data.status == 0` 表示登录成功
- `data.status != 0` 可能需要安全验证（如设备验证），返回 `data.data.url` 供 WebView 打开

### 4.3 APP 端密码登录

- **用途**：APP 端使用用户名密码登录
- **端点**：`POST https://passport.bilibili.com/x/passport-login/oauth2/login`
- **请求参数**：

| 参数名 | 类型 | 必须 | 说明 |
|--------|------|------|------|
| `username` | string | 是 | 手机号 |
| `password` | string | 是 | RSA 加密后的密码（Base64） |
| `local_id` | string | 是 | BUVID |
| `disable_rcmd` | string | 是 | 固定 `"0"` |

---

## 5. 登录后处理

### 5.1 confirmLogin 流程

> 源码位置：`lib/utils/login.dart` — `LoginUtils.confirmLogin()`

登录成功后的完整处理流程：

```
1. SetCookie.onSet()
   ├── 从 WebView 读取所有 Cookie
   ├── 保存到 PersistCookieJar（baseUrl + apiBaseUrl + tUrl 三个域名）
   └── 更新 Dio 请求头中的 cookie 字符串

2. UserHttp.userInfo()
   ├── 请求 /x/web-interface/nav 获取用户信息
   └── 验证 data.isLogin == true

3. 本地缓存
   └── userInfoCache.put('userInfoCache', result['data'])

4. UI 状态刷新
   ├── HomeController.updateLoginStatus(true)
   ├── HomeController.userFace = 用户头像
   ├── MediaController.mid = 用户mid
   ├── MineController.userLogin = true
   ├── DynamicsController.userLogin = true
   └── MediaController.userLogin = true
```

### 5.2 Cookie 同步

> 源码位置：`lib/utils/cookie.dart`

`SetCookie.onSet()` 负责将 WebView 中的 Cookie 同步到 Dio 的 CookieJar：

```dart
// 同步三个域名的 Cookie
var cookies = await WebviewCookieManager().getCookies(HttpString.baseUrl);
await Request.cookieManager.cookieJar
    .saveFromResponse(Uri.parse(HttpString.baseUrl), cookies);

// 同步到 apiBaseUrl 和 tUrl...

// 更新请求头
Request.dio.options.headers['cookie'] = cookieString;
```

---

## 6. 会话维持

### 6.1 关键 Cookie

| Cookie 名 | 用途 |
|-----------|------|
| `bili_jct` | CSRF Token，POST 请求必需 |
| `buvid3` | 设备标识 |
| `SESSDATA` | 会话标识，维持登录状态 |
| `DedeUserID` | 用户 mid |

### 6.2 CSRF 使用

所有写操作（POST）都需要在请求体中携带 `csrf` 参数：

```dart
var res = await Request().post(
  '/x/web-interface/archive/like',
  data: {
    'bvid': bvid,
    'like': 1,
    'csrf': await Request.getCsrf(),  // 从 bili_jct Cookie 获取
  },
);
```

### 6.3 access_key

用于 APP 端 API 鉴权，通过 302 重定向从第三方回调 URL 中提取：

```
回调 URL: https://www.mcbbs.net/...?access_key=xxx&mid=xxx
提取: access_key 和 mid
缓存: localCache.put('accessKey', {'mid': mid, 'value': accessKey})
```

使用场景（APP 端推荐列表）：

```dart
var res = await Request().get(Api.recommendListApp, data: {
  'appkey': Constants.appKey,
  'access_key': localCache.get('accessKey')['value'] ?? '',
  // ...
});
```

---

## 7. 获取当前用户信息

### userInfo

- **用途**：获取当前登录用户的基本信息
- **端点**：`GET https://api.bilibili.com/x/web-interface/nav`
- **是否需要登录**：是
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：无

**关键说明**：此接口同时也是获取 WBI Keys 的来源（`data.wbi_img`）。

### userStatOwner

- **用途**：获取当前用户的统计数据（关注数、粉丝数等）
- **端点**：`GET https://api.bilibili.com/x/web-interface/nav/stat`
- **是否需要登录**：是
- **是否需要 WBI 签名**：否
- **是否需要 CSRF**：否
- **请求参数**：无

---

## 8. 登录数据模型

> 源码位置：`lib/models/login/index.dart`

### CaptchaDataModel

```dart
class CaptchaDataModel {
  String? type;      // 验证类型，通常为 "geetest"
  String? token;     // 验证 token
  GeetestData? geetest;  // 极验参数
  Tencent? tencent;  // 腾讯验证（备用）
  String? validate;  // 验证结果（回调后赋值）
  String? seccode;   // 安全码（回调后赋值）
}
```

### GeetestData

```dart
class GeetestData {
  String? challenge;  // 极验 challenge
  String? gt;         // 极验 gt 标识
}
```

---

## 9. 完整登录流程图

### QR 码登录

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  生成二维码   │────→│  展示二维码给用户  │────→│  每秒轮询状态     │
│  qrCodeApi   │     │  qrcode_key      │     │  loginInByQrcode │
└─────────────┘     └──────────────────┘     └────────┬────────┘
                                                       │ code==0
                                              ┌────────▼────────┐
                                              │  confirmLogin    │
                                              │  同步Cookie+刷新UI│
                                              └─────────────────┘
```

### 短信验证码登录

```
┌───────────┐     ┌──────────────┐     ┌──────────────┐     ┌───────────────┐
│ getCaptcha │────→│ 极验人机验证  │────→│ sendWebSmsCode│────→│loginInByWebSms│
│ 获取验证参数 │     │ 用户完成验证  │     │ 发送短信验证码 │     │ Code 验证码登录 │
└───────────┘     └──────────────┘     └──────────────┘     └───────┬───────┘
                                                                     │ success
                                                            ┌────────▼────────┐
                                                            │  confirmLogin    │
                                                            └─────────────────┘
```

### 密码登录

```
┌───────────┐     ┌──────────────┐     ┌──────────┐     ┌──────────────────┐
│ getCaptcha │────→│ 极验人机验证  │────→│ getWebKey │────→│ loginInByWebPwd  │
│ 获取验证参数 │     │ 用户完成验证  │     │ 获取RSA公钥│     │ RSA加密密码+登录 │
└───────────┘     └──────────────┘     └──────────┘     └────────┬─────────┘
                                                                  │ success
                                                         ┌────────▼────────┐
                                                         │  confirmLogin    │
                                                         └─────────────────┘
```
