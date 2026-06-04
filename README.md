# GTX 1070 8GB 跑 Qwen3.6-35B-A3B：老卡也能跑到 22 tok/s

> **中文** | [English](README_EN.md)

`Qwen3.6-35B-A3B` 一般認為至少要 12GB VRAM。那只有 8GB VRAM、卡也更老的 GTX 1070 有沒有機會？

**有，而且跑得不錯。**

實測在 GTX 1070 8GB 上，`Qwen3.6-35B-A3B` 可以跑到大約 **22 tok/s**，搭配 q8_0 KV cache + 32K context，日常對話完全順暢。

> 📖 12GB VRAM 的完整 benchmark 請見 [rtx3060-qwen3.6-35b-guide](https://github.com/castlen3/rtx3060-qwen3.6-35b-guide)

---

## TL;DR

| 項目 | 數值 |
|------|------|
| GPU | GTX 1070 8GB (Pascal, CC 6.1) |
| decode 速度 | **22.3 tok/s** (q8_0) / **22.8 tok/s** (q4_0) |
| VRAM peak | ~7.5 GB (q8_0, n_cpu_moe=30) |
| context | **32K 穩跑** (q8_0) / **64K 穩跑** (q4_0) |
| 與 RTX 3060 12GB 差距 | ~15%

> 📊 完整測試數據見 [results/simple_benchmark.md](results/simple_benchmark.md)（26.3 vs 22.3 tok/s） |

## 推薦配置

```bash
llama-server.exe ^
  -m "Qwen3.6-35B-A3B-Q4_K_M.gguf" ^
  -t 4 ^
  --host 0.0.0.0 ^
  --port 8080 ^
  -ngl 40 ^
  --n-cpu-moe 30 ^
  --no-mmap ^
  --cache-type-k q8_0 ^
  --cache-type-v q8_0 ^
  -c 32768 ^
  -np 1 ^
  --reasoning off ^
  -fa on ^
  -fit off
```

| 指標 | 數值 |
|------|------|
| decode | **~22.3 tok/s** |
| VRAM | ~7.5 GB |
| context | 32768 (32K) |

> ⚠️ **`-fa on` 必須開。** 沒開的話 VRAM 會隨 context 線性膨脹，8GB 一定爆。

## 測試環境

| 項目 | 數值 |
|------|------|
| GPU | NVIDIA GeForce GTX 1070 (8191 MiB, Pascal) |
| CPU | Intel Core i7-7700K (4c/8t @ 4.20GHz) |
| RAM | 32 GB DDR4 |
| OS | Windows 10 |
| llama.cpp | b9500 |
| CUDA | 12.4（**必須**，13.3 不支援 CC 6.1） |
| 模型 | Qwen3.6-35B-A3B-Q4_K_M.gguf (19.7 GB) |

## 關鍵參數分析

### n_cpu_moe 是決定性參數

在 8GB 上，n_cpu_moe 多 1 或少 1 會直接影響速度：

```
q8_0, ctx=32768, ngl=40:

n_cpu_moe   Decode       VRAM      狀態
──────────────────────────────────────────
  28         8.5 tok/s   7.9 GB    ⚠️  thrashing
  29        22.0 tok/s   7.7 GB    ✅  甜蜜邊界
  30        22.3 tok/s   7.5 GB    ✅  推薦
```

差一個 n_cpu_moe（約 200MB VRAM），速度差 2.6 倍。**8GB 絕對不能壓到底。**

### q8_0 vs q4_0

| KV cache | n_cpu_moe | ctx max | Decode | 何時用 |
|----------|-----------|---------|--------|--------|
| q8_0 | 30 | 32K | 22.3 | 品質優先，日常最佳 |
| q4_0 | 28 | 64K | 22.8 | 省 VRAM，超長 context |

q4_0 可以跑 64K context 且 VRAM 完全不受 context 影響（感謝 flash attention）。

## 與 RTX 3060 12GB 對比

| | RTX 3060 12GB | GTX 1070 8GB |
|---|---|---|
| ngl | 40 | 40 |
| n_cpu_moe | 28 | 30 |
| KV cache | q8_0 | q8_0 |
| context | 32K | 32K |
| decode | 26.3 tok/s | 22.3 tok/s |
| VRAM peak | ~9.1 GB | ~7.5 GB |

核心差異只有 n_cpu_moe（28 vs 30），其他參數完全一致。

## 踩坑記錄

1. **CUDA 版本** — GTX 1070 (CC 6.1) 需要 CUDA 12.x binary。官方 CUDA 13.3 不支援 Pascal，`--list-devices` 會是空的。
2. **先確認真 GPU** — `llama-server.exe --list-devices` 必須看到 GTX 1070，否則實際是 CPU-only。
3. **VRAM 不能壓到底** — n_cpu_moe=28 + q8_0 雖然能載入，但 decode 會從 22 → 8 tok/s。
4. **Flash attention** — `-fa on` 是 8GB 能跑 32K context 的關鍵，不開一定 OOM。

## 快速開始

1. 下載 [llama.cpp b9500 CUDA 12.4](https://github.com/ggml-org/llama.cpp/releases/tag/b9500)（選 `cudart-llama-bin-win-cuda-12.4-x64.zip` + `llama-b9500-bin-win-cuda-12.4-x64.zip`），解壓並把 cudart DLL 放到同目錄
2. 下載 `Qwen3.6-35B-A3B-Q4_K_M.gguf`（~19.7 GB）
3. 執行上面的推薦指令
4. 驗證：`curl http://localhost:8080/health` → `{"status":"ok"}`
