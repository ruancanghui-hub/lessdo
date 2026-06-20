# LessDo 1.0 — App Store Connect 填表手册

> **用途**：上传 App Store 时，按 Connect 界面顺序逐项复制粘贴。  
> **工程路径**：`source/src`  
> **版本**：`1.0.0` · 构建号 `pubspec.yaml` 中 `+N`（当前 `1.0.0+1`）  
> **更新**：2026-06-17

上传前运行：

```bash
cd source/src
./tool/prepare_app_store_upload.sh
```

详细合规说明见同目录 `APP_STORE_SUBMISSION.md`。

---

## 一、创建 App（首次）

| 字段 | 填写值 |
|------|--------|
| 平台 | iOS |
| 名称 | LessDo |
| 主要语言 | English (U.S.) |
| Bundle ID | `com.nightelf.lessdo` |
| SKU | `lessdo-ios-1.0` |
| 用户访问权限 | 完全访问权限 |

---

## 二、App 信息（App Information）

| 字段 | 值 |
|------|-----|
| 名称 | LessDo |
| 副标题 | Tasks, reminders and focus |
| 主要类别 | Productivity（效率） |
| 次要类别 | Utilities（工具） |
| 内容版权 | 不含第三方受版权保护内容（广告由 Google 提供） |
| 年龄分级 | 见 **第七节** |
| 价格 | 免费 |

### 链接（必填）

| 字段 | URL |
|------|-----|
| 隐私政策 URL | `https://ruancanghui-hub.github.io/lessdo/privacy.html` |
| 支持 URL | `https://ruancanghui-hub.github.io/lessdo/support.html` |
| 营销 URL | **留空** |

支持邮箱（Connect 账户 / 联系用）：`lessdo.support@nightelf.dev`

---

## 三、版本 1.0.0 — 构建

| 字段 | 值 |
|------|-----|
| 版本号 | `1.0.0` |
| 构建 | 在 Connect 中选择已上传的 Archive（构建号须大于历史构建） |
| 最低系统 | iOS 16.0 |
| 设备 | iPhone + iPad |

**上传构建：**

```bash
open ios/Runner.xcworkspace
# Runner → Any iOS Device → Product → Archive → Distribute → App Store Connect
```

每次重新上传前，在 `pubspec.yaml` 递增构建号，例如 `1.0.0+2`。

**加密合规（Archive 上传时）：**

- 是否使用加密？→ 是（HTTPS）
- 是否豁免？→ **是**（仅标准 HTTPS / 系统 API，无自研加密）
- 选 **None of the algorithms mentioned above** 或等价豁免项

---

## 四、此版本的新增内容（What's New）

**English (U.S.)**

```text
Initial release of LessDo 1.0 — local tasks, reminders, focus timers, and optional biometric lock.
```

**简体中文**

```text
LessDo 1.0 首次发布 — 本地待办、提醒、专注计时，以及可选的生物识别锁。
```

---

## 五、英文元数据（English U.S.）

### 推广文本（Promotional Text，可选，170 字内）

```text
A calm, private way to capture tasks and make focused progress.
```

### 描述（Description）

```text
LessDo is a calm, private place for everything you need to remember.

Capture tasks quickly, organize them into flexible lists, schedule local reminders, and make focused progress with pomodoro, countdown, or count-up timers. Grocery lists keep shopping items easy to scan, while Today and overdue views help you see what matters now.

Everything in version 1.0 stays on your device. There is no account and no publisher analytics or tracking. Optional Face ID or Touch ID lock adds another layer of privacy. App open ads are shown through Google AdMob when you launch or return to the app.

Highlights:

- Fast task capture with dates and reminders
- Custom and grocery lists
- Today, overdue, and completed task views
- Pomodoro, countdown, and count-up focus modes
- Optional local notifications
- Optional biometric lock
- English and Simplified Chinese
- iPhone and iPad layouts
```

### 关键词（Keywords，100 字符内，逗号分隔）

```text
todo,tasks,reminders,focus,pomodoro,checklist,planner,grocery,timer
```

### 版权

```text
Copyright © 2026 nightelf
```

---

## 六、简体中文元数据

### 推广文本

```text
清爽、私密地记录任务，并专注完成真正重要的事情。
```

### 描述

```text
LessDo 是一个安静、私密的待办与专注空间。

快速记录任务，用灵活清单整理事项，设置本地提醒，并通过番茄钟、倒计时或正计时保持专注。购物清单让采购内容更易浏览，今天与逾期视图帮助你看清当前最重要的事情。

1.0 版本的内容全部保存在你的设备上。无需账户，也没有发布者侧的分析或跟踪。你还可以选择使用 Face ID 或 Touch ID 锁定应用。应用启动或回到前台时会通过 Google AdMob 展示开屏广告。

主要功能：

- 快速记录任务、日期与提醒
- 自定义清单与购物清单
- 今天、逾期和已完成任务视图
- 番茄钟、倒计时和正计时专注模式
- 可选的本地通知
- 可选的生物识别锁
- 简体中文与英文
- 适配 iPhone 和 iPad
```

### 关键词

```text
待办,任务,提醒,专注,番茄钟,清单,计划,购物,计时器
```

---

## 七、年龄分级（Age Rating）

在问卷中建议：

| 类别 | 答案 |
|------|------|
| 暴力、色情、亵渎、毒品、赌博、恐怖、医疗等 | **无 / 否** |
| 不受限制的网络访问 | **否** |
| 聊天 / 社交 | **否** |
| 用户生成内容（对外展示） | **否** |
| **广告（Advertising）** | **是** — Google AdMob 开屏广告 |
| 年龄保证 | **否** |

预期分级：**4+**

---

## 八、App 隐私（App Privacy）— 逐步填写

> 参考：[Google AdMob iOS 数据披露](https://developers.google.com/admob/ios/privacy/data-disclosure)

### 8.1 总览

| 问题 | 答案 |
|------|------|
| 是否从此 App 收集数据？ | 发布者：**否**；第三方 AdMob：**是** |
| 是否用于跟踪（Tracking）？ | **否**（无 ATT 弹窗） |
| 隐私政策 URL | `https://ruancanghui-hub.github.io/lessdo/privacy.html` |
| 隐私选择 URL | 不适用，留空 |

### 8.2 第三方 Google AdMob 需勾选的数据类型

用途均选 **Third-Party Advertising**，**不与用户关联**，**不用于 Tracking**：

| 数据类型 | 子类型 |
|----------|--------|
| Location | Coarse Location |
| Identifiers | Device ID |
| Usage Data | Product Interaction |
| Usage Data | Advertising Data |
| Diagnostics | Crash Data |
| Diagnostics | Performance Data |

### 8.3 发布者不收集（勿勾选）

Contact Info、Health、Financial Info、Precise Location、Sensitive Info、Contacts、User Content、Browsing History、Search History、Purchases 等。

---

## 九、AdMob（与审核相关，Connect 外配置）

| 项目 | 值 |
|------|-----|
| AdMob App ID | `ca-app-pub-1210970407399902~1651813383` |
| 开屏广告单元 | `ca-app-pub-1210970407399902/9742322322` |
| 展示时机 | 冷启动、回前台 |
| Face ID | 解锁后再展示 |
| ATT / IDFA | **未使用** |

---

## 十、审核备注（Notes for Review）

**英文，整段粘贴到 App Review Information：**

```text
LessDo 1.0 is a free, local-first task and focus app with no account. Task data stays on the device only.

Advertising: Google AdMob app open ads may appear when the app launches or returns to the foreground. If Face ID / Touch ID lock is enabled, the ad is shown only after successful unlock. LessDo does not request App Tracking Transparency (no IDFA prompt). TestFlight / App Store builds use the production AdMob unit; Xcode debug builds use Google test ad units.

Notification permission is requested only after a user schedules or retries a reminder. Biometric authentication is optional under Settings > Privacy. Biometric data is processed by iOS and is not available to the app.

To test URL actions:

lessdo://x-callback-url/create?content=Review%20task
lessdo://x-callback-url/open?list=Inbox

No review account, server configuration, or special hardware is required.
A physical device is recommended to verify notification delivery, biometrics, and ad presentation.

Support: lessdo.support@nightelf.dev
Privacy: https://ruancanghui-hub.github.io/lessdo/privacy.html
```

| 字段 | 值 |
|------|-----|
| 登录 / 演示账号 | **不需要** |
| 联系信息 | `lessdo.support@nightelf.dev` |

---

## 十一、截图

每种语言 **1–10 张**，须来自 **TestFlight / Release 真机 UI**：

| # | 设备 | 内容 |
|---|------|------|
| 1 | iPhone 6.9" | Today + 快速添加 |
| 2 | iPhone 6.9" | 清单 / 购物清单 |
| 3 | iPhone 6.9" | 任务详情 + 提醒 |
| 4 | iPhone 6.9" | 专注计时 |
| 5 | iPhone 6.9" | 设置（隐私与外观） |
| 6 | iPad 13" | 侧栏自适应布局 |

保存目录：

```text
source/src/docs/app_store_connect/screenshots/{iphone-6.9,ipad-13}/{en,zh}/
```

**注意**：截图与描述勿写「完全无广告」。

---

## 十二、Connect 其他选项

| 项目 | 选择 |
|------|------|
| 价格 | 免费 |
| 应用内购买 | 无 |
| 订阅 | 无 |
| 儿童类别（Kids Category） | 否 |
| 出口合规 | 按 Archive 问卷，选豁免 |
| Game Center | 否 |

---

## 十三、提交前核对清单

```
[ ] prepare_app_store_upload.sh 全部通过
[ ] pubspec 构建号已递增（若重新上传）
[ ] Archive 已上传并在 Connect 中 Processing 完成
[ ] 中英文描述、关键词、What's New 已粘贴
[ ] 隐私 / 支持 URL 浏览器打开为 200，含 AdMob 说明
[ ] App 隐私已声明 Google AdMob 第三方数据（§八）
[ ] 年龄分级：广告 = 是（§七）
[ ] 审核备注已粘贴（§十）
[ ] 截图已上传（iPhone + iPad，各语言）
[ ] TestFlight 真机：开屏广告、Face ID、通知、深链接
[ ] 点击「提交以供审核」
```

---

## 十四、TestFlight 真机快测

- [ ] 全新安装 → 引导页 → 空 Inbox
- [ ] 冷启动 / 回前台有开屏广告
- [ ] Face ID 开启：先解锁再出广告
- [ ] 创建提醒时才请求通知权限
- [ ] 任务增删改、专注模式、中英文
- [ ] 深链接 `lessdo://x-callback-url/create?content=Test`
- [ ] 设置 → 隐私政策含 AdMob

---

## 十五、相关文件

| 文件 | 说明 |
|------|------|
| **本文** | Connect 填表复制粘贴 |
| `APP_STORE_SUBMISSION.md` | 合规详解与拒审对策 |
| `app_store_connect/en-US.txt` | 英文源文本 |
| `app_store_connect/zh-Hans.txt` | 中文源文本 |
| `app_store_connect/review-notes.txt` | 审核备注源文本 |
| `publisher_contact.yaml` | 邮箱 / URL / Bundle ID |
| `GITHUB_PAGES.md` | 公开页部署说明 |
