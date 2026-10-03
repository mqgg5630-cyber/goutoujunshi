#!/usr/bin/env python3
"""Build the Gemini Gem knowledge library (deliverable/gem) from references/.

Consolidates the 43 reference documents into 10 knowledge volumes (Gemini Gems
accept at most 10 knowledge files), each with a distilled preface, a source
manifest, and the full original text. Re-run after editing references/ to
regenerate. Output:
  deliverable/gem/0N-*.md        (upload these to the Gem's Knowledge section)
  deliverable/gem/txt/0N-*.txt   (fallback copies if .md upload is refused)
  deliverable/gem/MANIFEST.json  (volume -> source mapping, sizes, sha256)
"""
import hashlib
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "references"
OUT = ROOT / "deliverable" / "gem"
OUT.mkdir(parents=True, exist_ok=True)

K = "knowledge"
P = "practical"

VOLUMES = [
    {
        "file": "00-文库导读与工作方式.md",
        "title": "文库导读与工作方式",
        "preface": (
            "本卷是整套文库的使用说明书：怎么给建议分级、怎么对待证据、怎么分析聊天记录、"
            "怎么维护关系档案。回答任何问题时，本卷的规则优先；其他各卷与本卷冲突时，"
            "以本卷的证据分级和使用边界为准。"
        ),
        "when": (
            "用户问「你的建议有什么依据」；需要判断一条话术属于 A/B/C 哪一级；拿到聊天记录要分析；"
            "需要建立或更新关系档案；不确定某类内容能不能协助。"
        ),
        "sources": [
            (P, "00-导读与使用分级.md"),
            (K, "01-证据分级与内容边界.md"),
            (P, "长期记忆与关系档案.md"),
            (P, "ChatLab聊天记录分析适配.md"),
        ],
        "notes": "「ChatLab」在本 Gem 场景中即用户粘贴或上传的聊天记录文本／截图。",
    },
    {
        "file": "01-心理学与哲学基础.md",
        "title": "心理学与哲学基础",
        "preface": (
            "关系科学的主干：把关系看成动态系统、感知到的伴侣回应性、交换与承诺、权力与压力；"
            "依恋风格与情绪调节（重点是焦虑—回避循环的改写）；MBTI 能做什么、科学上限制在哪、"
            "如何翻译成协商问题；恋爱哲学的追问与中国思想资源。人格标签只用于提出问题，"
            "不用于诊断个体或预测结局。"
        ),
        "when": (
            "用户或对象陷入焦虑追逐—回避撤退循环；用 MBTI 问「合不合适」；需要研究依据或理论框架；"
            "想做关系练习（卷末十二个练习与对话卡）；问「爱是什么」这类哲学问题；要延伸书单。"
        ),
        "sources": [
            (K, "02-亲密关系心理学总论.md"),
            (K, "03-依恋理论与情绪调节.md"),
            (K, "04-MBTI人格与匹配.md"),
            (K, "10-恋爱哲学.md"),
            (K, "18-实用练习与对话卡.md"),
            (K, "19-核心书单与论文索引.md"),
        ],
    },
    {
        "file": "02-吸引约会与关系启动.md",
        "title": "吸引、约会与关系启动",
        "preface": (
            "从认识到确定关系的科学与实践：吸引不是单一排名；关系启动四项基本能力（可接近、好奇、"
            "明确兴趣、承受不确定）；互惠判断看趋势不看单点；在线约会与数字关系（资料页、聊天转见面、"
            "文字局限、数字边界、诈骗识别）；主动表达喜欢、第一次见面安排、低强度可退出的自然接触；"
            "场景感与松弛感的八项可迁移能力。"
        ),
        "when": (
            "刚认识想推进；邀约见面；网上聊得好线下冷；要不要主动、怎么主动；第一次见面做什么；"
            "怀疑遇到「杀猪盘」或网络诈骗。"
        ),
        "sources": [
            (K, "06-吸引约会与关系启动.md"),
            (K, "09-在线约会与数字关系.md"),
            (P, "主动表达、第一次见面与自然接触.md"),
            (P, "场景感、松弛感与社交校准：从接话到关系推进.md"),
        ],
    },
    {
        "file": "03-日常沟通与情绪价值.md",
        "title": "日常沟通与情绪价值",
        "preface": (
            "让日常对话变好的六个工具箱：巧妙接话（核心是「连」不是「接」）；真诚具体的夸人；"
            "有效提供情绪价值（先确认对方要倾听、陪伴还是建议）；化解尴尬的救场方法；提升表达逻辑性；"
            "轻松娱乐式的「废话文学」回复。共同点：真实、具体、把对方当人而不是当目标。"
        ),
        "when": (
            "日常聊天接不住话；想让对方感觉被认可、被支持；场面尴尬需要救场；表达混乱需要理清；"
            "想要轻松幽默的回复风格。"
        ),
        "sources": [
            (P, "巧妙接话技巧：让沟通更流畅的实用指南.md"),
            (P, "万能夸人的话术技巧：真诚认可的实用指南.md"),
            (P, "为他人提供情绪价值：温暖且有效的回应指南.md"),
            (P, "化解尴尬：轻松救场的实用指南.md"),
            (P, "提升表达逻辑性：从混乱到清晰的实用指南.md"),
            (P, "废话文学回复指南：轻松应对各类场景.md"),
        ],
    },
    {
        "file": "04-冲突修复与关系进退.md",
        "title": "冲突、失衡与关系进退",
        "preface": (
            "冲突不是零和：冲突分类、可复用对话结构（约时间、软启动、高质量倾听、共同定义、试行方案）、"
            "情绪淹没与暂停协议、修复的构成；理性吵架的打法；投入失衡的四区域判断、一页事实账、"
            "行动阶梯与停止条件；分手的体面结构、失恋恢复、复合前评估、背叛后的三阶段；高情商拒绝与护边界。"
        ),
        "when": (
            "正在吵架或冷战后修复；感觉付出不对等；考虑降级投入或退出；分手后想复合；被背叛不知道怎么办；"
            "需要拒绝别人又不伤关系。"
        ),
        "sources": [
            (K, "07-沟通冲突与修复.md"),
            (K, "15-分手背叛与关系修复.md"),
            (P, "万能吵架技巧：理性冲突处理指南.md"),
            (P, "关系投入失衡：互惠判断、降级投入与退出决策.md"),
            (P, "高情商拒绝他人：体面护边界的实用指南.md"),
        ],
    },
    {
        "file": "05-实战话术编排器.md",
        "title": "实战话术编排器（即时回复核心）",
        "preface": (
            "整套文库最常用的一卷：一条可发送消息的生成流程——只定一个本轮目标、按需组合三层"
            "（承接／推进／收线）、做五项口吻校准（贴合用户日常用词、长度、标点、亲密程度、表情习惯）、"
            "为每句话留积极／含糊／不回应三种后续分支；附常用场景话术库（刚加联系方式、对方说累了、"
            "只回「哈哈」、问「你怎么突然找我」、泛聊转邀约、软拒绝「下次吧」）；以及把被动聊天"
            "转为主动引导的方法。"
        ),
        "when": (
            "用户问「这句话怎么回」；需要当场给出可复制成品；想从泛聊转邀约；对方冷淡或含糊时定下一步。"
        ),
        "sources": [
            (P, "实战话术编排器：从一句回复到后续分支.md"),
            (P, "聊天化被动为主动：引导互动的实用指南.md"),
        ],
    },
    {
        "file": "06-伦理边界与经典体系转译.md",
        "title": "伦理边界与经典体系转译",
        "preface": (
            "操控识别与伦理替代：PUA 的技术拆解、容易伪装成技巧的危险信念、识别自己是否正被操控；"
            "同意作为持续过程、边界与控制的区别、高风险信号；Blueprint／冷读／Mystery／自然流等经典"
            "社交体系的机制、证据等级与风险边界；公开表达案例的伦理转译。可保留的是真实、可观察、"
            "可纠正、可退出的能力；禁止贬低、服从测试、虚假时间限制、嫉妒操控、煤气灯等实施方案。"
        ),
        "when": (
            "怀疑自己或对方在被操控；用户想用「推拉」「冷读」「框架」类技巧；涉及性同意与亲密边界；"
            "要把网上学到的「社交技术」转成伦理、安全的用法。"
        ),
        "sources": [
            (K, "05-PUA操控与伦理替代.md"),
            (K, "08-同意边界性与亲密.md"),
            (K, "20-经典社交体系的机制、证据与风险边界.md"),
            (P, "自然流、内在状态与结构化互动：伦理能力转译.md"),
            (P, "公开表达案例的伦理转译.md"),
        ],
    },
    {
        "file": "07-婚姻家庭与社会变迁.md",
        "title": "婚姻、家庭与社会变迁",
        "preface": (
            "长期关系与现实议题：婚前需要谈清的主题、家庭生命周期各阶段任务（初婚、育儿、学龄、"
            "中年照护、空巢老年）；金钱／家务／育儿／双方家庭的协商工具与「公平」的三种含义；"
            "现代婚姻变迁史与中国婚姻制度时间线；人口与社会背景数据；多元关系与反刻板印象"
            "（性少数伴侣、知情同意的非单偶、年龄差、残障慢病、再婚继亲单亲、跨文化阶层）。"
        ),
        "when": (
            "谈婚论嫁、同居、财产与家务分工、育儿分工、与父母和亲家的边界；用户或对象处于再婚、单亲、"
            "跨文化等情境；需要把个人困境放进社会背景理解。"
        ),
        "sources": [
            (K, "11-婚姻家庭与生命周期.md"),
            (K, "12-金钱家务育儿与双方家庭.md"),
            (K, "13-现代婚姻变迁史.md"),
            (K, "14-社会发展与家庭变迁.md"),
            (K, "16-多元关系与反刻板印象.md"),
        ],
    },
    {
        "file": "08-法律安全与危机转介.md",
        "title": "法律、安全与危机转介",
        "preface": (
            "安全卷，优先级最高。先判断属于普通关系问题还是危险情形；中国反家暴法律基础（人身安全"
            "保护令等）；证据保存；即时安全计划；自伤或伤人威胁的应对；婚姻财产与离婚基础提醒；"
            "婚恋诈骗识别。出现家暴、跟踪、强迫、财务控制、人身威胁或自伤风险时：先确认当下安全，"
            "引导联系可信支持或当地紧急服务，再谈其他。"
        ),
        "when": "任何涉及人身安全、控制、威胁、跟踪、诈骗、法律程序的问题——立即先查本卷。",
        "sources": [
            (K, "17-中国法律安全与危机转介.md"),
        ],
    },
    {
        "file": "09-社交与职场通用技能.md",
        "title": "社交与职场通用技能",
        "preface": (
            "恋爱之外的通用社交工具，仅当恋爱问题确实涉及同事关系、请求协助或权力结构时使用，"
            "或用户明确要求：托人办事的高效话术；有效拓展与维护人脉；获得领导青睐（价值匹配到信任"
            "建立）；被孤立后的自我调适与破局；由内到外的气场塑造。原则与恋爱各卷一致：真实、互惠、"
            "可退出。"
        ),
        "when": (
            "恋爱问题牵扯职场或权力结构；用户想提升社交自信与气场；被群体孤立需要破局；需要求人办事。"
        ),
        "sources": [
            (P, "托人办事的高效话术指南.md"),
            (P, "有效拓展人脉：从建立到维护的实用指南.md"),
            (P, "获得领导青睐：从价值匹配到信任建立的实用指南.md"),
            (P, "被孤立如何破局：从自我调适到建立连接的实用指南.md"),
            (P, "提高气场：从内到外的力量感塑造指南.md"),
        ],
    },
]


LINK_RE = re.compile(r"\[([^\]]*)\]\(([^)]+)\)")


def volume_refs() -> dict:
    """basename of every source doc -> the volume that contains it."""
    m = {}
    for idx, vol in enumerate(VOLUMES):
        for _kind, name in vol["sources"]:
            m[name] = f"卷{idx:02d}"
    return m


VOL_REF = volume_refs()


def rewrite_links(text: str, source_name: str) -> str:
    """The source docs cross-link each other with relative paths, which are
    broken inside deliverable/gem (and useless inside a Gem). Rewrite every
    local markdown link to a plain-volume pointer; keep http(s)/mailto and
    in-file anchors; strip other local links down to their label text."""

    def repl(m: "re.Match") -> str:
        label, target = m.group(1), m.group(2).strip()
        if re.match(r"^(https?://|mailto:)", target):
            return m.group(0)
        if target.startswith("#"):
            return m.group(0)
        base = target.split("#", 1)[0].rsplit("/", 1)[-1]
        if base in VOL_REF and base != source_name:
            return f"{label}（见{VOL_REF[base]}）"
        return label

    return LINK_RE.sub(repl, text)


def read(path: Path) -> str:
    text = path.read_text(encoding="utf-8").strip()
    return rewrite_links(text, path.name)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    try:
        commit = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True
        ).strip()
    except Exception:
        commit = "unknown"
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    manifest = {
        "name": "goutoujunshi Gemini Gem knowledge library",
        "generated": stamp,
        "source_commit": commit,
        "instructions_file": "Gem系统指令.md",
        "volumes": [],
    }

    for idx, vol in enumerate(VOLUMES):
        parts = [
            f"# 狗头军师知识文库 · 卷{idx:02d} {vol['title']}",
            "",
            f"> 蒸馏自 goutoujunshi 仓库 references/（生成于 {stamp}，源提交 {commit}）。"
            "本文件上传到 Gemini Gem 的「知识」区。",
            "",
            f"**本卷定位**：{vol['preface']}",
            "",
            f"**何时查本卷**：{vol['when']}",
        ]
        if vol.get("notes"):
            parts += ["", f"**场景说明**：{vol['notes']}"]
        parts += ["", "**收录原文**："]
        for n, (kind, name) in enumerate(vol["sources"], 1):
            parts.append(f"{n}. `references/{kind}/{name}`")
        parts += ["", "---", ""]
        for n, (kind, name) in enumerate(vol["sources"], 1):
            src = REF / kind / name
            parts.append(f"<!-- 收录{n}：references/{kind}/{name} -->")
            parts.append(f"# 【收录{n}】{name}")
            parts.append("")
            parts.append(read(src))
            parts += ["", "---", ""]
        body = "\n".join(parts).rstrip() + "\n"

        out_md = OUT / vol["file"]
        out_md.write_text(body, encoding="utf-8")

        out_txt = OUT / "txt" / vol["file"].replace(".md", ".txt")
        out_txt.parent.mkdir(parents=True, exist_ok=True)
        out_txt.write_text(body, encoding="utf-8")

        manifest["volumes"].append(
            {
                "file": vol["file"],
                "title": vol["title"],
                "sources": [f"references/{k}/{n}" for k, n in vol["sources"]],
                "bytes": out_md.stat().st_size,
                "sha256": sha256(out_md),
            }
        )
        print(f"built {vol['file']}  ({out_md.stat().st_size} B, {len(vol['sources'])} sources)")

    (OUT / "MANIFEST.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("wrote MANIFEST.json")

    # checksums over every generated file (MANIFEST first, then all others)
    sums = []
    for p in sorted(OUT.rglob("*")):
        if p.is_file() and p.name != "SHA256SUMS.txt":
            sums.append(f"{sha256(p)}  {p.relative_to(OUT).as_posix()}")
    (OUT / "SHA256SUMS.txt").write_text("\n".join(sums) + "\n", encoding="utf-8")
    print(f"wrote SHA256SUMS.txt ({len(sums)} files)")


if __name__ == "__main__":
    main()
