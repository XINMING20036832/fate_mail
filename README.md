# Fate Mail (宿命信箱) — Flutter Starter (MVP)

这是一个“可直接拷贝进 Flutter 工程”的 MVP 代码包（不需要你先把业务想完）。
它实现了最小闭环页面与本地模拟数据，并预留了后端 API 接口位置。

## 你需要什么环境
- Flutter SDK（建议最新稳定版）
- Android Studio（装 Android SDK）或 VS Code（推荐）
  - 说明：不是 Visual Studio（那个是 C# 的大 IDE），而是 **VS Code** 更适合 Flutter。

## 运行方式（最快）
1) 新建一个 Flutter 工程（只需一次）
   - 打开命令行进入你的工作目录
   - 执行：
     flutter create fate_mail
2) 把本压缩包里的内容复制进工程
   - 用本包的 `lib/` 覆盖你工程里的 `lib/`
   - 把本包的 `pubspec.yaml` 里 `dependencies:` 部分合并到你工程的 `pubspec.yaml`
3) 安装依赖并运行
   flutter pub get
   flutter run

## 当前内置的 MVP 流程（本地模拟）
- 绑定命运坐标：生日 + 时辰（子丑寅卯…亥）
- 首页：显示命运坐标、邮票余额
- 写信：模板 + 限字 + 禁外联（手机号/链接/微信关键词）
- 支付：模拟购买邮票（6元/张）
- 发起请求：进入“等待对方决定”
- 收信卡：接受/拒绝（接受才可读）
- 信箱：慢信（简单频率提示）

## 后端对接（你腾讯云2G服务器）
在 `lib/services/api.dart` 里我给了清晰的接口函数：
- login/bindProfile
- buyStamps
- createRequest / listPending / listIncoming
- acceptRequest / rejectRequest
- listMailbox / sendMail
- report / blockUser

你把 `ApiService.baseUrl` 改成你的域名（HTTPS），然后逐步把本地模拟替换为真实请求即可。

## 注意
这是 starter，不是最终生产版。你要上架前一定要补：
- 隐私政策 URL、用户协议
- 拉黑/举报真正生效（后端封禁）
- 72小时超时自动退回邮票（后端定时任务）
