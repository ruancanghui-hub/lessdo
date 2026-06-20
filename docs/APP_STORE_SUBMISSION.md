# LessDo 1.0 App Store 提审资料包

> **用途**：上传 App Store Connect 时，按本文逐项复制填写。  
> **版本**：`1.0.0` · 构建号见 `pubspec.yaml` 的 `+N`（每次上传前递增）  
> **最后核对**：2026-06-17（含 Google AdMob 开屏广告）

---

## 一、提审前必做（阻塞项）

按顺序执行，全部通过后再 Archive：

```bash
cd source/src
./tool/prepare_app_store_upload.sh
./tool/verify_ios_release.sh   # 可选，完整发布门禁
```

| # | 检查项 | 状态 / 操作 |
|---|--------|-------------|
| 1 | Bundle ID 为 `com.nightelf.lessdo` | 已配置 |
| 2 | 隐私政策 URL 可访问且**内容与 App 一致（含 AdMob）** | `https://ruancanghui-hub.github.io/lessdo/privacy.html` — **推送 `docs/privacy.html` 后再提交** |
| 3 | 支持 URL 可访问、邮箱正确 | `https://ruancanghui-hub.github.io/lessdo/support.html` · `lessdo.support@nightelf.dev` |
| 4 | 应用描述 / 应用内隐私 / 公开隐私页 / App Privacy **四处关于广告的表述一致** | 见下文 §6 |
| 5 | 构建号大于 App Store Connect 已有构建 | 修改 `pubspec.yaml` 如 `1.0.0+2` |
| 6 | 截图已放入 `docs/app_store_connect/screenshots/` | 见 §12 |
| 7 | TestFlight 真机验证完成 | 见 §11 |

### 已修复的合规风险（请勿回退）

| 风险 | 说明 |
|------|------|
| 公开隐私页写「无广告」但 App 有 AdMob | 已更新 `docs/privacy.html`，**须 push 到 GitHub** |
| 支持页邮箱错误（`lessdo.support.dev`） | 已修正；`apply_publisher_contact.sh` 已修复 `@` 替换 bug |
| App Privacy 仍填「不收集任何数据」 | 须按 §6 声明 **Google 第三方广告** 数据 |
| 年龄分级「无广告」与事实不符 | 须选 **含第三方广告**，见 §7 |
| 审核备注未说明开屏广告 | 使用 `docs/app_store_connect/review-notes.txt` |

---

## 二、App Store Connect — 创建应用

| 字段 | 填写值 |
|------|--------|
| 平台 | iOS |
| 名称 | LessDo |
| 主要语言 | English (U.S.) |
| Bundle ID | `com.nightelf.lessdo` |
| SKU | `lessdo-ios-1.0` |
| 用户访问权限 | 完全访问权限 |

---

## 三、版本信息

| 字段 | 值 |
|------|-----|
| 版本号 | `1.0.0` |
| 构建号 | `pubspec.yaml` 中 `+` 后数字（每次上传 +1） |
| 最低系统 | iOS 16.0 |
| 设备 | iPhone + iPad |
| 价格 | 免费 |
| 主要类别 | Productivity（效率） |
| 次要类别 | Utilities（工具） |
| 版权 | `Copyright © 2026 nightelf` |

### 此版本的新增内容（What's New）

**English (U.S.)**

```text
Initial release of LessDo 1.0 — local tasks, reminders, focus timers, and optional biometric lock.
```

**简体中文**

```text
LessDo 1.0 首次发布 — 本地待办、提醒、专注计时，以及可选的生物识别锁。
```

---

## 四、元数据（复制粘贴）

完整文案见：

- English：`docs/app_store_connect/en-US.txt`
- 简体中文：`docs/app_store_connect/zh-Hans.txt`

### 关键 URL

| 字段 | URL |
|------|-----|
| 隐私政策 | `https://ruancanghui-hub.github.io/lessdo/privacy.html` |
| 支持 URL | `https://ruancanghui-hub.github.io/lessdo/support.html` |
| 营销 URL | 留空 |
| 支持邮箱 | `lessdo.support@nightelf.dev` |

### 英文关键词（Keywords，100 字符内）

```text
todo,tasks,reminders,focus,pomodoro,checklist,planner,grocery,timer
```

### 中文关键词

```text
待办,任务,提醒,专注,番茄钟,清单,计划,购物,计时器
```

---

## 五、AdMob 配置（与审核相关）

| 项目 | 值 |
|------|-----|
| AdMob App ID | `ca-app-pub-1210970407399902~1651813383` |
| 开屏广告单元 | `ca-app-pub-1210970407399902/9742322322` |
| 展示时机 | 冷启动、从后台回前台 |
| Face ID 锁定 | 解锁成功后再展示 |
| ATT / IDFA | **未使用**（无 `NSUserTrackingUsageDescription`） |
| Debug 构建 | Google 官方测试广告单元 |
| Release / TestFlight | 上述正式单元 |

审核员会在启动时看到开屏广告，属预期行为，已在审核备注中说明。

---

## 六、App 隐私（App Privacy）— 逐步填写

> 参考：[Google AdMob iOS 数据披露](https://developers.google.com/admob/ios/privacy/data-disclosure)  
> **不要**再选「No, we do not collect data from this app」作为唯一答案。

### 6.1 总览

| 问题 | 答案 |
|------|------|
| 发布者（LessDo）是否从此 App 收集数据？ | **否** — 任务内容仅存设备 |
| 第三方合作伙伴是否收集数据？ | **是** — Google AdMob（Google Mobile Ads SDK） |
| 是否用于跟踪用户（Tracking）？ | **否** — 未集成 ATT，未声明 Tracking |
| 隐私政策 URL | 见 §四 |

### 6.2 第三方（Google AdMob）需声明的数据类型

在 App Store Connect → App Privacy → **Edit Data Types**，为 **Third-Party Advertising**（第三方广告）勾选下列类型，并按 Google 文档确认用途（以下为 LessDo 1.0 推荐填写，最终以 Connect 界面选项为准）：

| 数据类型 | 子类型 | 用途 | 是否与用户关联 | 是否用于跟踪 |
|----------|--------|------|----------------|--------------|
| Location | Coarse Location | Third-Party Advertising | 否 | 否 |
| Identifiers | Device ID | Third-Party Advertising | 否 | 否 |
| Usage Data | Product Interaction | Third-Party Advertising | 否 | 否 |
| Usage Data | Advertising Data | Third-Party Advertising | 否 | 否 |
| Diagnostics | Crash Data | Third-Party Advertising | 否 | 否 |
| Diagnostics | Performance Data | Third-Party Advertising | 否 | 否 |

说明：

- Google SDK 可能通过 IP 估算粗略位置、收集设备标识符与广告交互数据。
- LessDo **不会**把任务标题、清单名称等用户内容发给 Google。
- 若 Connect 界面与上表选项措辞略有不同，以 **Google 官方披露 + 实际 SDK 隐私清单** 为准。

### 6.3 发布者不收集的数据（无需勾选）

Contact Info、Health、Financial Info、Precise Location、Sensitive Info、Contacts、User Content、Browsing History、Search History、Purchases 等 — **LessDo 发布者不收集**。

### 6.4 与应用内 / 网页隐私政策的一致性

以下位置均已说明 AdMob 开屏广告，提交前请确认一致：

- App Store 描述（`en-US.txt` / `zh-Hans.txt`）
- 应用内：设置 → 法律信息 → 隐私政策（`lib/legal/legal_content.dart`）
- 公开页：`docs/privacy.html`（GitHub Pages Folder: `/docs`）
- 本文 §6

---

## 七、年龄分级

在 App Store Connect 年龄分级问卷中：

| 类别 | 建议答案 |
|------|----------|
| 暴力、色情、亵渎、毒品、赌博、恐怖、医疗等 | **无 / 否** |
| 不受限制的网络访问 | **否** |
| 聊天 / 社交 | **否** |
| 用户生成内容（对外展示） | **否** |
| **广告（Advertising）** | **是** — 含 Google AdMob 第三方开屏广告 |
| 年龄保证机制 | **否** |

预期分级：**4+**（以 Connect 计算结果为准）。

---

## 八、出口合规 / 加密

Archive 上传时：

| 问题 | 答案 |
|------|------|
| 是否使用加密？ | 是（HTTPS，系统标准加密） |
| 是否属于豁免类别？ | **是** — 仅使用标准 HTTPS / Apple 系统 API，无自研加密 |
| 在 Connect 中 | 通常选 **None of the algorithms mentioned above** / 使用标准加密且符合豁免 |

LessDo 不含自定义加密实现；AdMob 网络请求走系统 TLS。

---

## 九、其他 Connect 选项

| 项目 | 建议 |
|------|------|
| 内容版权 | 应用不含第三方受版权保护内容（广告由 Google 提供） |
| 政府 / 出口管制 | 按开发者账号实际情况如实填写 |
| 登录 / 演示账号 | **不需要** — 无账号系统 |
| 儿童类别（Kids Category） | **否** |
| 应用内购买 | **无** |
| 订阅 | **无** |

---

## 十、审核备注（Notes for Review）

**直接粘贴** `docs/app_store_connect/review-notes.txt`：

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

---

## 十一、构建上传

```bash
open ios/Runner.xcworkspace
```

1. Scheme：**Runner**
2. Destination：**Any iOS Device**
3. **Product → Archive**
4. **Distribute App → App Store Connect → Upload**
5. 等待处理完成后，在版本中选中该构建

上传前在 `pubspec.yaml` 递增构建号，例如：

```yaml
version: 1.0.0+2
```

---

## 十二、截图要求

每种语言 **1–10 张**，须来自**最终 TestFlight 构建**的真实 UI：

| # | 设备 | 内容 |
|---|------|------|
| 1 | iPhone 6.9" | Today + 快速添加 |
| 2 | iPhone 6.9" | 清单 / 购物清单 |
| 3 | iPhone 6.9" | 任务详情 + 本地提醒 |
| 4 | iPhone 6.9" | 专注计时 |
| 5 | iPhone 6.9" | 设置（隐私与外观） |
| 6 | iPad 13" | 侧栏自适应布局 |

目录结构：

```bash
mkdir -p docs/app_store_connect/screenshots/{iphone-6.9,ipad-13}/{en,zh}
```

**注意**：截图不要承诺「完全无广告」；可展示任务主流程，广告无需专门截图。

---

## 十三、TestFlight 真机验证清单

提交审核前在 TestFlight 构建上确认：

- [ ] 全新安装 → 引导页 → 空 Inbox
- [ ] 冷启动出现开屏广告（Release 构建）
- [ ] 切后台再回前台出现开屏广告
- [ ] 开启 Face ID 后：先解锁，再出现广告
- [ ] 创建 / 编辑 / 完成 / 删除任务与清单
- [ ] 首次创建提醒时才请求通知权限
- [ ] 通知在锁屏 / 杀进程后仍能触发（真机）
- [ ] Face ID 成功 / 取消 / 失败流程
- [ ] 专注模式后台与重启
- [ ] 中英文、大号文字、横竖屏（iPhone + iPad）
- [ ] 深链接 `lessdo://x-callback-url/create?content=Test`
- [ ] 设置内隐私政策文案含 AdMob 说明
- [ ] 无订阅、无 IAP、无「升级 Pro」入口

---

## 十四、GitHub Pages 部署

公开页源码在 `docs/privacy.html`、`docs/support.html`。配置见 **`docs/GITHUB_PAGES.md`**。

**GitHub Pages 设置（lessdo 仓库）：**

| 项 | 值 |
|----|-----|
| Branch | `main`（或你的发布分支） |
| Folder | **`/docs`**（GitHub 不支持 `/docs/hosted`） |

推送后确认：

- `https://ruancanghui-hub.github.io/lessdo/privacy.html` → 200，含 AdMob
- `https://ruancanghui-hub.github.io/lessdo/support.html` → 200

```bash
git push   # 包含 docs/privacy.html 等
./tool/prepare_app_store_upload.sh
```

---

## 十五、提交前最终核对（Printable）

```
[ ] prepare_app_store_upload.sh 通过
[ ] pubspec 构建号已递增
[ ] Archive 已上传并在 Connect 中 Processing 完成
[ ] 中英文描述、关键词、推广文本已粘贴
[ ] 隐私 / 支持 URL 可访问且内容与 App 一致
[ ] App Privacy 已声明 Google AdMob 第三方数据
[ ] 年龄分级已选「含广告」
[ ] 审核备注已粘贴（含 AdMob + 深链接）
[ ] 截图已上传（iPhone + iPad，各语言）
[ ] TestFlight 真机清单已完成
[ ] 无 DRAFT 标记（policy_published: true）
[ ] 点击「提交以供审核」
```

---

## 十六、常见拒审原因与对策

| 拒审原因 | 对策 |
|----------|------|
| 隐私标签与 App 行为不符 | 按 §6 声明 AdMob；公开隐私页与 App 内文案一致 |
| 描述写「无广告」但实际有广告 | 已改描述；检查截图与推广文本 |
| 支持 URL / 隐私 URL 无效或邮箱错误 | 部署 GitHub Pages；验证 §十四 |
| 审核找不到功能 | 在审核备注提供深链接与操作路径 |
| 通知 / Face ID 用途不清 | 审核备注已说明；权限仅在用户操作后请求 |
| 元数据暗示 IAP / 订阅 | 1.0 免费无 IAP，法律文案已对齐 |
| Guideline 4.0 Design | 确保截图来自当前构建，UI 与提交版本一致 |

---

## 十七、相关文件索引

| 文件 | 用途 |
|------|------|
| **本文** `docs/APP_STORE_SUBMISSION.md` | 提审总资料包 |
| `docs/app_store_connect/en-US.txt` | 英文元数据 |
| `docs/app_store_connect/zh-Hans.txt` | 中文元数据 |
| `docs/app_store_connect/review-notes.txt` | 审核备注 |
| `docs/APP_STORE_METADATA.md` | 元数据 + 隐私 + 分级详表 |
| `docs/APP_STORE_RELEASE.md` | 发布总清单 |
| `docs/APP_STORE_CONNECT_UPLOAD.md` | 上传步骤摘要 |
| `docs/publisher_contact.yaml` | 邮箱 / URL / Bundle ID |
| `docs/GITHUB_PAGES.md` | GitHub Pages 文件夹配置 |
| `docs/privacy.html` / `docs/support.html` | 公开页源码（Pages Folder: `/docs`） |
| `tool/prepare_app_store_upload.sh` | 上传前自检 |
| `tool/apply_publisher_contact.sh` | 同步发布方配置 |

---

## 十八、AdMob 控制台（上架后）

| 项目 | 操作 |
|------|------|
| 应用状态 | 确认 iOS 应用已关联 Bundle ID `com.nightelf.lessdo` |
| 广告单元 | 开屏单元 `ca-app-pub-1210970407399902/9742322322` 已启用 |
| 政策 | 遵守 [AdMob 政策](https://support.google.com/admob/answer/6128543) |
| 无效流量 | 不要用激励手段诱导点击广告 |
