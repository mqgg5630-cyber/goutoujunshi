# 恋爱告白信、久识情书与相关 Skills 清单

生成日期：2026-10-04

## 调研范围

本清单面向两个问题：

1. 是否已有“恋爱告白信 / 情书 / 相识很久后表达心意”相关的 Agent Skills；
2. 哪些开源项目可作为“数字情书、表白网页、纪念日长信、久识转关系表达”的素材参考。

检索方式包括：

- `npx skills find love-letter / love letter / confession / romance / relationship debrief`；
- skills.sh 页面检索；
- GitHub 仓库检索：`love letter generator`、`confession letter`、`topic:love-letter`、`topic:valentine`、`topic:romantic`、`will you be my valentine` 等。

结论：**专门针对“久识告白信 / 情书写作”的高安装量 Agent Skill 很少**。更成熟的做法是把“情书写作”蒸馏为狗头军师的一个子能力：先判断关系与风险，再生成低压、具体、可拒绝、可后续跟进的表达文本。

---

## A. 相关 Agent Skills 清单

| 优先级 | Skill / 仓库 | 安装量与星标 | 可借鉴点 | 注意事项 |
| --- | --- | ---: | --- | --- |
| A | `bennoloeffler/maude-claude-vunds-plugins` / `love-letter` | love-letter 12 installs；仓库约 0 stars | 命中“love-letter”关键词，可作为专门情书 skill 的轻量样例 | 安装量与星标都低，不宜直接依赖；更适合看结构 |
| A | `wordflowlab/novel-writer-skills` / `romance-novel-conventions` | 422 installs；仓库约 262 stars | 言情叙事的情感铺垫、关键转折、表白与承诺节奏 | 偏小说创作；用于真实告白时必须去戏剧化、去套路化 |
| A | `yixiajack/dating-master-skill` / `dating-master` | 35 installs；仓库约 16 stars | 基于语用学、依恋和信号博弈做恋爱洞察，可辅助判断该不该写信 | 不是情书生成器；需要结合真实关系证据 |
| B | `yixiajack/love-gto` / `love-gto` | 12 installs；仓库约 8 stars | 把关系问题拆成可判断、可操作、可循环决策 | 适合做“是否表白、怎么保留后路”的决策层 |
| B | `geeks-accelerator/in-bed-ai` | 188 total installs；仓库约 25 stars | dating / love / flirting / romance 等社交互动主题 | 偏平台/API 与互动，不是告白信写作；要避开轻浮或过度撩拨 |
| B | `rami-maalouf/skills` / `relationship-debrief` | 103 total installs；relationship-debrief 3 installs；仓库约 2 stars | 关系复盘、沟通总结；可用于写信前整理“我们一路怎么走来” | 安装量很低，只作为思路参考 |
| B | `lovstudio/skills` / `lov-human-writing`、`lov-writing-style` 等 | 4.5K total installs；仓库约 71 stars | 人味写作、风格迁移、语气润色可辅助去 AI 腔 | 不是恋爱专项；需要狗头军师的关系边界判断兜底 |
| C | `cnwu16/vedic-astro-skills` / `vedic-love` | 705 total installs；vedic-love 100 installs；仓库约 926 stars | 可作为仪式感、象征语言和自我叙事参考 | 占星不作为事实判断依据；最多当娱乐或象征表达 |

### 检索空白

`npx skills find love-letter`、`love letter`、`confession`、`romance`、`relationship debrief` 在本次运行中均返回“no skills found”。因此清单采用 skills.sh 页面与 GitHub 搜索补全。

---

## B. GitHub 开源项目参考清单

这些不是 Agent Skills，但可作为“表白网页 / 数字情书 / 纪念日交互”的设计参考。

| 星标 | 仓库 | 方向 | 可借鉴点 | 注意事项 |
| ---: | --- | --- | --- | --- |
| 447 | https://github.com/saurabhnemade/will-you-be-my-valentine | Valentine 互动网页 | 简单、易改、传播性强 | 注意不要把“不能拒绝”的交互当作严肃告白 |
| 237 | https://github.com/byquangthanh/valentine.github.io | Will you be my valentine 页面 | 轻量静态页面 | 适合做节日邀请，不适合久识深情长信 |
| 114 | https://github.com/CodeKageHQ/Ask-out-your-Valentine | 互动式 Valentine 提问 | GIF、动态按钮、轻松互动 | “No 按钮逃跑”类设计只能当玩笑，真实关系中要保留拒绝权 |
| 103 | https://github.com/visibait/valentines | 记忆卡片游戏 + proposal | 用共同记忆解锁表达，适合纪念日 | 可改造成“我们相识很久”的记忆路线 |
| 95 | https://github.com/UjjwalSaini07/AlwaysBeMine | Valentine 告白网站 | 动画与氛围感 | 适合轻告白，不适合复杂关系说明 |
| 54 | https://github.com/junayed-hasan/valentines_blossoming_flower | 花朵动画表白网页 | 视觉效果温柔 | 适合做结尾礼物，不替代真实对话 |
| 19 | https://github.com/warengonzaga/love-cards | 可定制 love cards | 卡片式短句、模块化 | 适合生成多张回忆卡 |
| 18 | https://github.com/Rushi-45/National-Princess-Day | love letters + playlist + flip cards | 音乐、翻卡、情书结合 | 可参考多媒体纪念页 |
| 16 | https://github.com/ViktorHadzhiyanev/Valentines-Day-Surprise | Interactive digital love letter | 数字情书体验 | 适合“打开一封信”的交互隐喻 |
| 11 | https://github.com/yosgi/Typing_Love_Letter | 打字机情书模板 | 程序员式打字机效果 | 文案仍要用户化，否则模板感强 |
| 10 | https://github.com/ayushraistudio/Love-Letter-Service | 情书生成/发送网页 | 实时预览、移动端优先 | 生成器容易泛泛而谈，需要补真实细节 |
| 3 | https://github.com/leonardtng/write-some-love-letters | Strachey 风格情书生成器 | 历史/随机组合情书生成灵感 | 更偏复古玩具，不适合严肃表达 |
| 2 | https://github.com/Mayborg121/garden | 长距离关系互动故事 | 把“距离”转化为体验式叙事 | 适合异地、久识、长期陪伴主题 |
| 2 | https://github.com/shallowsingaa/love-page | 中文表白信网页模板 | 纯静态中文告白页 | 低星，仅作样式参考 |
| 2 | https://github.com/huazizhanyes/confession | 520 表白信封 | 中文信封隐喻 | 低星，仅作样式参考 |

---

## C. 蒸馏结论

### 1. 需要补的不是“更肉麻的辞藻”，而是“关系判断 + 表达结构”

告白信和久识情书的难点通常不是写不出漂亮句子，而是：

- 当前关系是否适合写长信；
- 写信会不会把对方逼到必须回应的位置；
- 如何表达“我喜欢你”，又不把多年关系变成情感债务；
- 如何把共同经历写具体，而不是复制网络情话；
- 对方积极、犹豫、不回应或拒绝后，下一步怎么做。

### 2. 真实关系中要优先保留对方的拒绝权

很多表白网页项目会使用“逃跑 No 按钮”“只能点 Yes”等趣味交互。狗头军师可以把它们当作轻松视觉梗，但不得把这种交互转译成现实压力。真实告白必须允许：

- 对方不立即答复；
- 对方拒绝；
- 对方只愿意保持朋友关系；
- 用户有尊严地收束，而不是继续追问或情绪绑架。

### 3. 最适合狗头军师的新能力

新增能力命名为：**告白信与久识情书**。

触发场景：

- “帮我写一封表白信”；
- “我们认识很多年了，我想写情书”；
- “我暗恋老朋友很久，想不尴尬地说出来”；
- “周年纪念日长文 / 生日情书 / 异地长信”；
- “帮我润色这段告白，别太油”；
- “如果她拒绝了，我怎么收场”。

核心输出：

1. **是否适合现在写**：短讯、短信、长信、暂缓四选一；
2. **素材提问**：只问会让信变具体的事实；
3. **信件结构**：事实回忆、感受变化、清晰邀请、低压出口；
4. **成品版本**：稳健版、温柔深情版、轻松不尴尬版；
5. **发送与后续**：何时发、发后多久不追问、积极/犹豫/拒绝/不回应怎么接。

---

## D. 已落地文件

本次调研已蒸馏为两个运行资产：

- 运行指南：`references/practical/告白信与久识情书：真诚表达指南.md`
- 独立 Skill：`skills/love-letter-confession/SKILL.md`

同时已把根 `SKILL.md` 的按需加载表接入该指南，并将 Gem 文库构建脚本纳入该资料。
