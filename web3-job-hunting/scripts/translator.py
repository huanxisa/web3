"""英文 JD → 中文翻译

策略：
1. 标题通常很短，整段翻译。
2. 正文长，按段落切分（每段 ~3000 字符）后逐段翻译，再拼回。
3. 已是中文的内容不重复翻译。
4. 翻译失败时保留原文，不阻塞流程。

引擎选择：deep_translator.GoogleTranslator
- 完全免费、不需要 API Key
- 国内网络可能不稳定，失败时 fallback 到原文
"""

from __future__ import annotations

import re
import socket
import sys
import time
from pathlib import Path

# 强制 socket 级超时，避免 deep_translator 内部 requests 挂死（无 timeout 配置）
# 单段最长 3500 字符，正常 1-3 秒返回；20 秒还没回大概率是网络异常，应放弃重试
socket.setdefaulttimeout(20)

from deep_translator import GoogleTranslator

sys.path.insert(0, str(Path(__file__).resolve().parent))
from storage import list_jobs_needing_translation, update_translation  # noqa: E402

CHINESE_RE = re.compile(r"[\u4e00-\u9fff]")
MAX_CHUNK = 3500  # GoogleTranslator 单次安全长度


def is_chinese(text: str) -> bool:
    """如果中文字符占比 > 30%，认为已是中文。"""
    if not text:
        return False
    chinese = len(CHINESE_RE.findall(text))
    return chinese / max(len(text), 1) > 0.3


def chunk_text(text: str, size: int = MAX_CHUNK) -> list[str]:
    """按段落切，单段超长再按句切。"""
    chunks = []
    cur = ""
    for para in text.split("\n"):
        if len(cur) + len(para) + 1 < size:
            cur = cur + "\n" + para if cur else para
        else:
            if cur:
                chunks.append(cur)
            cur = para
            # 段落本身超长 → 强切
            while len(cur) > size:
                chunks.append(cur[:size])
                cur = cur[size:]
    if cur:
        chunks.append(cur)
    return chunks


def translate_text(text: str, retries: int = 1) -> str:
    """翻译单条文本。每段独立 retry，失败就放弃这段保留原文，不阻塞整体。"""
    if not text or not text.strip():
        return ""
    if is_chinese(text):
        return text
    out = []
    for chunk in chunk_text(text):
        translated_chunk = None
        for attempt in range(retries + 1):
            try:
                translated = GoogleTranslator(source="auto", target="zh-CN").translate(chunk)
                translated_chunk = translated or chunk
                break
            except Exception as e:
                if attempt == retries:
                    print(f"    [warn] 段翻译失败（保留英文）: {type(e).__name__}: {str(e)[:60]}", flush=True)
                    translated_chunk = chunk
                else:
                    time.sleep(0.5)
        out.append(translated_chunk or chunk)
    return "\n".join(out)


def run(limit: int | None = None) -> int:
    """跑翻译。返回成功翻译的岗位数。

    :param limit: 最多翻多少个（None=全部）。分批跑时传 50/100 等小数避免长时间挂死。
    """
    pending = list_jobs_needing_translation()
    if limit:
        pending = pending[:limit]
    total = len(pending)
    print(f"待翻译: {total} 个岗位", flush=True)
    if total == 0:
        return 0

    done = 0
    failed = 0
    start = time.time()
    for i, row in enumerate(pending, 1):
        title = row["title"] or ""
        desc = row["description_text"] or ""
        # 截短预览 + 显示 ETA
        elapsed = time.time() - start
        avg = elapsed / max(i - 1, 1) if i > 1 else 0
        remaining = (total - i + 1) * avg
        eta_min = int(remaining / 60)
        print(f"  [{i}/{total}] (elapsed {int(elapsed)}s, ETA {eta_min}m) {title[:55]}", flush=True)
        t0 = time.time()
        try:
            title_zh = translate_text(title)
            desc_zh = translate_text(desc)
            update_translation(row["id"], title_zh, desc_zh)
            done += 1
        except Exception as e:
            failed += 1
            print(f"    [error] 岗位整体翻译异常（跳过）: {type(e).__name__}: {str(e)[:80]}", flush=True)
        # 单条超过 30 秒发个警告（多半是网络/Google 限流）
        cost = time.time() - t0
        if cost > 30:
            print(f"    [slow] 这条耗时 {int(cost)}s（>30s 触发警告，可能 Google 限流）", flush=True)
        time.sleep(0.2)

    print(f"\n=== 翻译结束：完成 {done}/{total}，失败 {failed}，总耗时 {int((time.time()-start)/60)} 分钟 ===", flush=True)
    return done


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None,
                    help="最多翻多少个（默认全部）。分批跑用：--limit 50")
    ap.add_argument("--no-report", action="store_true",
                    help="翻完不自动重生成 jd_summary.md（默认会重生成）")
    args = ap.parse_args()
    n = run(limit=args.limit)
    # 翻译完成后自动重生成中文报告（用户硬要求："后续的更新都需要这一点"）
    if n > 0 and not args.no_report:
        print(f"\n✅ 本批翻译 {n} 个岗位，自动重生成 jd_summary.md...", flush=True)
        import reporter  # noqa
        reporter.run()
    elif n == 0:
        print("\n所有岗位都已翻译，无需重新生成。", flush=True)
