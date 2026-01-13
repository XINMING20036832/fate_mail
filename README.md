# 另一个我（Fate Mail）— Flutter Starter（MVP）

这是一个可直接拷贝进你现有 Flutter 工程的 **完整可运行 MVP**（本地模拟存储）。
你要做的就是把 zip 里的内容覆盖到工程根目录（lib/、pubspec.yaml、.github/）。

已实现（MVP）：
- ✅ 绑定：出生日期 + 时辰 + 邮箱（邮箱 24h 可改一次；出生信息 24h 内可改 1 次，之后锁定）
- ✅ 邮票钱包：6/15/30 元分别对应 1/3/10 封；支持加减与清空
- ✅ 写信消耗邮票；同一时间只允许等待 1 个决定（反撒网）
- ✅ 收到请求：可接受/拒绝；接受后进入信箱对话（本地模拟）
- ✅ UI：命运感（星云背景）+ 工业感（简洁卡片、圆角、低噪配色）
- ✅ 去掉 DEBUG 斜条：debugShowCheckedModeBanner=false
- ✅ GitHub Actions：推送 main 自动构建 APK 并上传 Artifact

注意：
- 这是 MVP 演示版：不接真实后端，不做真实匹配。你上线时再接服务器/支付校验/超时退回任务。
