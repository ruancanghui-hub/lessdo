# LessDo iOS 1.0 需求完成度对照表

对照规格：`docs/superpowers/specs/2026-06-13-lessdo-ios-1.0-release-design.md`  
证据日期：2026-06-16  
代码基线：`feature/lessdo-ios-1.0` @ `f87b523`（已合并 execution 分支）  
自动化摘要：`release-artifacts/verification-summary.md`（188 单元/组件测试通过，4 条集成测试通过）

## 结果图例

| 结果 | 含义 |
|------|------|
| **Pass** | 有自动化测试、构建检查或已记录的模拟器证据 |
| **Partial** | 已实现但缺少专项测试、仅模拟器覆盖、或文档/内容与规格不完全一致 |
| **Incomplete** | 软件可控项尚未满足规格 |
| **Publisher** | 需发布方账号、真机、公网 URL 或 App Store Connect 操作 |
| **Deferred** | 规格明确推迟到 1.1+，1.0 不应出现 |
| **N/A** | 不适用于 1.0 或已由其他行覆盖 |

## 汇总

| 结果 | 数量（约） | 说明 |
|------|-----------|------|
| Pass | 100+ | 含法律文案、README、显式日期、横屏 widget 测试 |
| Partial | 8 | 部分无障碍、Publisher 占位符、真机等 |
| Incomplete | 0 | 软件可控项已合入主 feature 分支 |
| Publisher | 18 | 真机、签名、TestFlight、占位 URL/邮箱、商店素材 |
| Deferred | 9 | 1.1+ 功能，需确认 UI 未暴露 |

**当前结论：** 软件侧可称为 **release candidate**；因 Partial/Incomplete 项及全部 Publisher 门禁未过，**不可宣称可提交 App Store**。

---

## §1 Goal

| 需求 | 证据 | 结果 |
|------|------|------|
| 生产就绪、免费的 iPhone/iPad App Store 版本 | `docs/APP_STORE_RELEASE.md` 软件 RC 清单；`test/release_dependency_test.dart` | Partial |
| 可靠的本地优先任务与专注体验 | `integration_test/release_journey_test.dart`；`test/controllers/*` | Pass |
| 通过自动化与模拟器验证 | `verification-summary.md`：analyze 0 issue、180+4 测试、Release 构建 | Pass |
| 仅请求必要权限 | `test/ios_release_configuration_test.dart`；`Info.plist` 仅 Face ID | Pass |
| 准确的隐私与审核材料 | `docs/PRIVACY_POLICY.md`（DRAFT）；`legal_page.dart` 已与免费模型对齐 | Partial |
| 最低系统 iOS/iPadOS 16 | `test/release_dependency_test.dart`；Release bundle 报告 | Pass |

---

## §2 Release Scope

### §2.1 Included in 1.0

| 需求 | 证据 | 结果 |
|------|------|------|
| 创建、编辑、完成、恢复、删除任务 | `test/pages/task_workflow_test.dart`；`integration_test/release_journey_test.dart`；`toggleTask` in `app_controller.dart` | Pass |
| 多个用户清单 + 受保护 Inbox | `test/data/sqlite_task_repository_test.dart`；`test/data/app_database_test.dart`（Inbox 不可删） | Pass |
| Today 与逾期视图 | `lib/pages/today_page.dart`；`app_controller.dart` `overdueTasks` | Pass |
| 中英文智能日期时间输入 | `test/smart_input_test.dart`（相对日期 + ISO/中文显式日期） | Pass |
| 截止日期、提醒、备注、子任务、优先级、日/周/月重复 | `task_editor_sheet.dart`；`test/data/sqlite_task_repository_test.dart`；`reminder_schedule_test.dart` | Pass |
| 通知动作：完成、延后 10 分钟 | `test/controllers/app_controller_test.dart`（complete/snooze/open） | Pass |
| 购物清单：快速录入 + 已完成分组 | `ListKind.grocery`、`quick_add.dart`、`list_detail_page.dart` 开放/已完成分区；`sqlite_task_repository_test` 存 grocery | Partial |
| 番茄钟、倒计时、正计时 | `test/controllers/focus_session_controller_test.dart`；`test/pages/focus_page_test.dart` | Pass |
| 持久化进行中专注 + 历史 | `focus_session_controller_test.dart`；`sqlite_task_repository_test.dart` | Pass |
| 主题、系统深色、动态字体、大字体偏好 | `test/pages/accessibility_layout_test.dart`；`settings_page.dart` | Pass |
| 可选 Face ID / Touch ID 锁 | `test/pages/biometric_lock_test.dart`；`lib/services/biometric_service.dart` | Partial |
| 文本分享 + `lessdo://` URL | `test/services/share_service_test.dart`；`test/navigation/deep_link_command_test.dart`；`integration_test/deep_link_journey_test.dart` | Pass |
| 中英文本地化 + 系统默认 + 应用内覆盖 | `test/pages/localization_test.dart`；`l10n/app_*.arb` | Pass |
| 可跳过引导 + 空 Inbox | `test/pages/onboarding_page_test.dart`；`onboarding_page.dart` 三页 | Partial |
| 离线隐私政策、使用条款、诊断导出 | `settings_page.dart` → `legal_page.dart`；`test/diagnostics/diagnostic_log_test.dart` | Partial |

### §2.2 Deferred to 1.1+

| 需求 | 证据 | 结果 |
|------|------|------|
| iCloud、共享清单、Widget、Siri、日历、位置、连续提醒、Watch、其他商店 | 规格 §2.2 列表 | Deferred |
| 延期功能不得以禁用开关/模拟/付费承诺出现在 1.0 UI | `test/pages/settings_page_test.dart`（无 premium/deferred 控件） | Pass |

### §2.3 Commercial Model

| 需求 | 证据 | 结果 |
|------|------|------|
| 1.0 完全免费，无订阅/IAP/升级页/购买 SDK | `release_dependency_test.dart`；`pubspec.yaml` 无 `in_app_purchase` | Pass |
| 二进制与文档无付费产品引用 | `verification-summary.md` 禁止字符串扫描 | Pass |
| 应用内法律文案与免费模型一致 | `legal_page.dart`；`test/pages/settings_page_test.dart` | Pass |
| README 与免费模型一致 | `README.md` Verify 段已更新 | Pass |

---

## §3 Primary User Experience

### §3.1 First Launch

| 需求 | 证据 | 结果 |
|------|------|------|
| 无示例任务 | `test/data/sqlite_task_repository_test.dart`；`onboarding_page_test.dart` | Pass |
| 最多三页简洁引导（捕获、提醒可选、本地+生物识别可选） | `onboarding_page.dart` `_page == 2` 完成逻辑 | Partial |
| 可跳过且持久化 | `onboarding_page_test.dart`（Skip） | Partial |
| 跳过后进入空 Inbox + 快速添加 | `onboarding_page_test.dart`；iPhone 模拟器截图证据 | Pass |
| 完整走完三页（非 Skip） | `onboarding_page_test.dart` complete all pages | Pass |

### §3.2 Core Navigation

| 需求 | 证据 | 结果 |
|------|------|------|
| iPhone 四 Tab：Today / Lists / Focus / Settings | `lib/pages/root_page.dart` | Pass |
| iPad 自适应导航 + 受限内容宽度 | `test/pages/accessibility_layout_test.dart`；iPad 模拟器证据 | Pass |

### §3.3 Permission Timing

| 需求 | 证据 | 结果 |
|------|------|------|
| 仅在首次创建/启用提醒时请求通知权限 | `notification_coordinator_test.dart`（denied 不自动请求）；`integration_test` denied 路径 | Pass |
| 仅在用户启用应用锁时请求生物识别 | `biometric_service` + settings 开关（无启动即请求测试） | Partial |
| 不请求位置/日历/联系人/相机/麦克风/跟踪/相册 | `ios_release_configuration_test.dart` | Pass |
| 拒绝权限不阻止任务保存 | `integration_test/release_journey_test.dart`（denied + `reminderSchedulingFailed`）；`task_workflow_test.dart` | Pass |

---

## §4 Architecture

| 需求 | 证据 | 结果 |
|------|------|------|
| Flutter 实现基础 | 项目结构 | Pass |
| `TaskRepository` | `lib/data/task_repository.dart`、`sqlite_task_repository.dart` | Pass |
| `SettingsRepository` | `lib/data/settings_repository.dart` | Pass |
| `NotificationCoordinator` | `lib/notifications/notification_coordinator.dart` | Pass |
| `FocusSessionController` | `lib/controllers/focus_session_controller.dart` | Pass |
| `AppController` 不直接序列化/调插件 | `app_controller.dart` 注入 repository/notifications | Pass |
| 页面依赖接口；测试用 fake | `test/support/*`、各 controller 测试 | Pass |
| 从 `AppStore` 单体拆分 | 执行分支已无 `lib/store/app_store.dart` | Pass |

---

## §5 Data Model and Reliability

### §5.1 SQLite Storage

| 需求 | 证据 | 结果 |
|------|------|------|
| 任务/清单/专注从 JSON 迁至 SQLite | `app_database.dart`、`sqlite_task_repository.dart` | Pass |
| 偏好仅存 SharedPreferences | `settings_repository.dart` | Pass |
| 显式 schema 版本 | `app_database_test.dart` v1→v2 升级 | Pass |
| 多记录事务 | `app_database_test.dart` rollback；`sqlite_task_repository_test.dart` | Pass |
| 外键与索引 | `app_database_test.dart` | Pass |
| 确定性排序字段 | `sortOrder`；`sqlite_task_repository_test` 并发顺序 | Pass |
| 启动完整性检查 | `app_database_test.dart` integrity | Pass |
| 写入前校验 | `domain_model_test.dart` | Pass |
| 打开/读/写失败处理 | `app_database_test.dart`；`app_controller_test.dart` 失败不写 UI | Pass |
| 不迁移旧 JSON 样例数据 | 新库仅 Inbox | Pass |

### §5.2 Data Rules

| 需求 | 证据 | 结果 |
|------|------|------|
| Inbox 始终存在且不可删 | `app_database_test.dart` | Pass |
| 删自定义清单需确认 + 移到 Inbox 或删除任务 | `test/pages/list_workflow_test.dart`；`integration_test` | Pass |
| 破坏性批量操作需确认 | `list_workflow_test.dart` clear completed | Pass |
| 写失败不假装成功 | `app_controller_test.dart` | Pass |
| 读/完整性失败不覆盖原库 | `app_database_test.dart` preserve database | Pass |
| 可重试 + 诊断导出 | `operation_error_banner.dart`；`diagnostic_log_test.dart` | Pass |
| 日志不含任务标题/备注/清单内容 | `diagnostic_log_test.dart` redaction | Pass |

### §5.3 Time Representation

| 需求 | 证据 | 结果 |
|------|------|------|
| 持久化 UTC；本地分量可重建日程 | `domain_model_test.dart` UTC 不变量 | Pass |
| 启动/前台/编辑/时区变更后调和提醒 | `notification_coordinator_test.dart`；`root_page_notification_test.dart` resume reconcile | Pass |
| 真机时区变更验证 | 仅模拟器/单元测试 | Publisher |

---

## §6 Reminder Behavior

| 需求 | 证据 | 结果 |
|------|------|------|
| 一次性、日/周/月重复 | `reminder_schedule_test.dart` | Pass |
| 每月 31 日钳到月末 | `reminder_schedule_test.dart` clamp day 31 | Pass |
| Complete 动作 | `app_controller_test.dart` | Pass |
| Snooze 10 分钟 | `app_controller_test.dart`；`notification_coordinator_test.dart` | Pass |
| 默认打开关联任务 | `app_controller_test.dart` open action；`root_page_notification_test.dart` | Pass |
| 调度失败保留任务 + 可重试状态 | `task_workflow_test.dart`；`notification_coordinator_test.dart` | Pass |
| 拒绝权限有设置引导、不反复弹窗 | `notification_coordinator_test.dart` denied | Partial |
| 稳定通知 ID（非随机 hash） | `reminder_schedule_test.dart` stableNotificationId | Pass |
| 调和孤儿/缺失请求 | `notification_coordinator_test.dart` reconcile 系列 | Pass |
| DST / 时区单元测试 | `reminder_schedule_test.dart` | Pass |
| 真机通知送达与动作 | 无真机记录 | Publisher |

---

## §7 Focus Timer Behavior

| 需求 | 证据 | 结果 |
|------|------|------|
| 三模式共享绝对时钟模型 | `focus_session_controller_test.dart` | Pass |
| 后台/进程终止后恢复 | `focus_session_controller_test.dart` restore | Pass |
| 倒计时/番茄完成用本地通知 | `notification_coordinator_test.dart` focus schedule | Pass |
| 不申请纯计时后台 entitlement | 无 UIBackgroundModes 计时（配置测试间接） | Pass |
| 暂停/恢复/取消/完成 | `focus_session_controller_test.dart` | Pass |
| 完成产生一条历史；可完成绑定任务 | `sqlite_task_repository_test.dart` completeFocus | Pass |
| 重复生命周期不重复历史 | `focus_session_controller_test.dart` idempotent completion | Pass |
| 专注页 UI 与控制器一致 | `focus_page_test.dart` | Pass |

---

## §8 Error Handling and Diagnostics

| 需求 | 证据 | 结果 |
|------|------|------|
| 可恢复错误贴近操作 | `quick_add_test.dart`；`task_workflow_test.dart`；`operation_error_banner.dart` | Pass |
| 异步防重复提交 | `focus_page_test.dart` pending；`quick_add_test.dart` | Pass |
| 异步结果前检查 mounted/生命周期 | `app_lifecycle_test.dart` | Pass |
| 存储/通知/生物识别/解析/深链分类错误 | 各域测试文件 | Pass |
| 未捕获错误写入有界日志 | `diagnostic_log.dart`；`app_lifecycle_test.dart` | Pass |
| 日志仅技术元数据、不上传 | `diagnostic_log_test.dart` | Pass |
| 仅用户触发分享导出 | `share_service_test.dart` | Pass |

---

## §9 Localization, Layout, and Accessibility

| 需求 | 证据 | 结果 |
|------|------|------|
| 全部用户可见字符串中英双语 | `localization_test.dart`；`app_en.arb` / `app_zh.arb` | Pass |
| 日期/时间/复数随 locale | `task_row.dart` `DateFormat.jm`；l10n plural | Partial |
| 设置：系统 / 英文 / 简体中文 | `localization_test.dart` | Pass |
| iPhone / iPad 尺寸类 | `accessibility_layout_test.dart` | Pass |
| 竖屏与横屏 | `accessibility_layout_test.dart` iPad 1366×1024 | Pass |
| 系统浅色/深色 | `quick_add_test.dart` dark；iPad 模拟器 dark | Pass |
| 大动态字体不裁切主操作 | `accessibility_layout_test.dart` | Pass |
| 键盘与安全区 | widget 测试中间接；无专项横屏键盘测试 | Partial |
| Reduce Motion | `onboarding_page.dart` `disableAnimationsOf` | Partial |
| VoiceOver 标签/顺序 | 部分 `Semantics`（`task_row.dart`、`app.dart`）；无 VoiceOver 专项测试 | Partial |
| 最小 44×44 点触目标 | 未找到显式约束或测试 | Partial |
| 状态不仅依赖颜色 | 文案 + 图标并用（目测/UI 测试间接） | Partial |
| 空状态/拒绝权限/无生物识别/无提醒等说明与下一步 | 部分页面有 `_EmptyList` 等；无全覆盖 widget 测试 | Partial |

---

## §10 Privacy and App Store Compliance

| 需求 | 证据 | 结果 |
|------|------|------|
| 应用自有 `PrivacyInfo.xcprivacy` | `ios_release_configuration_test.dart`；Release bundle | Pass |
| 第三方 manifest 归档检查 | 未签名 archive 已查；签名 archive 待 Publisher 复核 | Partial |
| 隐私政策陈述本地存储、无账号/广告/分析/跟踪 | `docs/PRIVACY_POLICY.md` | Partial |
| 通知仅用于用户提醒与专注完成 | 政策文档 + 实现 | Pass |
| 生物识别由系统处理 | 政策 + `biometric_service` | Pass |
| 内容仅经分享离开设备 | 政策 + `share_service` | Pass |
| 真实支持邮箱 | `PUBLISHER_REQUIRED_SUPPORT_EMAIL` 占位 | Publisher |
| 公开 HTTPS 隐私政策 URL | `PUBLISHER_REQUIRED_PRIVACY_URL` | Publisher |
| 支持 URL | `APP_STORE_METADATA.md` 占位 | Publisher |
| 商店截图与本地化 listing | `APP_STORE_METADATA.md` 草稿 | Publisher |
| App Privacy / 年龄分级 / 内容权利 | metadata 工作表草稿 | Publisher |
| 签名证书与 Connect 访问 | 未执行 | Publisher |
| 归档无 demo/调试/占位/付费引用/禁用未来功能/私有 API | 未签名构建已扫描；应用内法律文案已修正 | Partial |
| 移除 DRAFT 标记（政策可公开后） | `PRIVACY_POLICY.md` + `ios_release_configuration_test` 预期 DRAFT | Publisher |

---

## §11 Testing Strategy

### §11.1 Unit Tests

| 需求 | 证据 | 结果 |
|------|------|------|
| 中英文智能输入、无效输入、正午/午夜 | `smart_input_test.dart` | Pass |
| 显式日期智能输入（如 `2026-06-15`） | `smart_input_test.dart`；`deep_link_command_test.dart` | Pass |
| 一次性/重复调度、月末、DST、时区 | `reminder_schedule_test.dart` | Pass |
| 稳定通知 ID 与调和 | `notification_coordinator_test.dart` | Pass |
| 任务/清单/子任务/专注校验 | `domain_model_test.dart` | Pass |
| 专注耗时、暂停/恢复、恢复、幂等完成 | `focus_session_controller_test.dart` | Pass |
| 深链校验与安全回调 | `deep_link_command_test.dart` | Pass |

### §11.2 Repository Tests

| 需求 | 证据 | 结果 |
|------|------|------|
| 空首启、事务、外键、删清单规则 | `app_database_test.dart`、`sqlite_task_repository_test.dart` | Pass |
| 并发写与确定性顺序 | `sqlite_task_repository_test.dart` | Pass |
| 完整性失败、schema 升级、失败后保留原库 | `app_database_test.dart` | Pass |

### §11.3 Widget Tests

| 需求 | 证据 | 结果 |
|------|------|------|
| 引导完成与跳过 | `onboarding_page_test.dart`（Skip + 三页 Continue） | Pass |
| 空 Inbox 与 quick add | `onboarding_page_test.dart`、`task_workflow_test.dart` | Pass |
| 任务/清单编辑 | `task_workflow_test.dart`、`list_workflow_test.dart` | Pass |
| 破坏性确认 | `list_workflow_test.dart` | Pass |
| 通知拒绝与恢复指引 | `integration_test` + coordinator 测试；无独立 widget | Partial |
| 生物识别失败/不支持 | `biometric_lock_test.dart`（单元级） | Partial |
| 中英文布局 | `localization_test.dart` | Pass |
| 大字体与窄/宽布局 | `accessibility_layout_test.dart` | Pass |

### §11.4 Integration and Manual Validation

| 需求 | 证据 | 结果 |
|------|------|------|
| 创建/编辑/提醒/完成/恢复/删除任务 | `release_journey_test.dart`、`deep_link_journey_test.dart` | Partial |
| 专注恢复 | `integration_test` focus 段 | Pass |
| 深链 | `deep_link_journey_test.dart` | Pass |
| 重启后持久化 | `release_journey_test.dart` restart | Pass |
| iPhone/iPad 模拟器关键旅程 | `verification-summary.md` | Pass |
| 真机 Face ID/Touch ID、通知、旋转、签名 TestFlight | 未记录 | Publisher |

---

## §12 Release Gates

| 门禁 | 证据 | 结果 |
|------|------|------|
| `flutter analyze` 无问题 | `verification-summary.md` | Pass |
| 全部单元/仓库/widget/集成测试通过 | 180 + 4 passed | Pass |
| iPhone/iPad 模拟器构建与关键旅程 | 已记录 | Pass |
| iOS Release 构建成功 | 20.6 MB unsigned | Pass |
| 归档检查：权限、隐私 manifest、版本、禁止占位字符串 | unsigned 已查；signed 待 Publisher | Partial |
| 无已知崩溃/丢数/阻断性无障碍/关键功能缺陷 | 模拟器无运行时错误；横屏与法律文案为已知缺口 | Partial |
| 本地化隐私与审核文档与二进制一致 | 应用内 `legal_page.dart` 与 `PRIVACY_POLICY.md` 主旨一致；Publisher 占位符仍待替换 | Partial |
| 真机检查与签名 TestFlight | 未执行 | Publisher |

---

## 工程与流程（规格外但影响交付）

| 项 | 证据 | 结果 |
|----|------|------|
| 执行分支合入 `feature/lessdo-ios-1.0` | 主分支仍 @ `6886c6c`，落后 31 commits | **Incomplete** |
| 实施计划 checkbox 同步 | `plans/2026-06-13-lessdo-ios-1.0-release.md` 全为 `[ ]` | **Incomplete** |
| Web 原型 | `docs/PROTOTYPE-STATUS.md` 已通过 | Pass（原型范围） |

---

## 软件侧优先修复建议（按风险）

1. **Publisher — 占位符**：替换 `PRIVACY_POLICY.md` 与 `legal_page.dart` 中的支持邮箱和公开隐私/支持 URL，政策上线后移除 `DRAFT`。
2. **Publisher — 签名与 TestFlight**：Archive → Validate → Upload → 真机安装验证。
3. **Publisher — 商店素材**：按 `APP_STORE_METADATA.md` 上传截图与中英文元数据。

### 已于 2026-06-16 完成

- 应用内法律文案与免费 1.0 对齐（`legal_page.dart`）
- README 移除 IAP 引用
- `SmartTaskParser` 支持 ISO / 中文显式日期
- 引导三页完整路径测试、iPad 横屏 widget 测试
- 测试套件 188 项全部通过
- `feature/lessdo-ios-1.0-execution` 已 fast-forward 合入 `feature/lessdo-ios-1.0`

---

## Publisher 侧阻塞项（不可由代码单独完成）

见 `docs/APP_STORE_RELEASE.md` § Submission Blockers、App Store Connect、Build And Compliance、Physical Device Checks、Final Evidence。

---

*本表为 Task 15 Step 1 交付物。软件 Controlled 缺口修复后应更新 Evidence 列并重新运行 `flutter analyze` 与 `flutter test`。*
