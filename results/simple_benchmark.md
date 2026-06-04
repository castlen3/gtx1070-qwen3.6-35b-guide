# Benchmark Data — GTX 1070 8GB

> 測試日期: 2026-06-04
> llama.cpp: b9500 + CUDA 12.4 (CC 6.1)
> 模型: Qwen3.6-35B-A3B-Q4_K_M.gguf (19.7 GB)

## 固定參數

```
-ngl 40   --no-mmap   -fa on   -fit off   --reasoning off   -np 1   -t 4
```

## 核心數據

### q8_0 KV cache — n_cpu_moe sweep (ctx=32768)

| n_cpu_moe | Decode (tok/s) | VRAM | 狀態 |
|-----------|---------------|------|------|
| 28 | 8.5 | 7.9 GB | ⚠️ VRAM thrashing |
| 29 | 22.0 | 7.7 GB | ✅ 甜蜜邊界 |
| **30** | **22.3** | **7.5 GB** | ✅ **推薦** |

> **n_cpu_moe=28 雖然能載入，但 VRAM 太緊導致 decode 掉到 8.5 tok/s。**
> 多放 2 個 expert 到 CPU（n_cpu_moe=30）只犧牲 ~0.5 tok/s，換來 500MB VRAM 安全空間。

### q4_0 KV cache — context 壓力測試 (n_cpu_moe=28)

| ctx | Decode (tok/s) | VRAM |
|-----|---------------|------|
| 4096 | 22.8 | 7.9 GB |
| 8192 | 22.9 | 7.9 GB |
| 16384 | 22.8 | 7.9 GB |
| 32768 | 22.8 | 7.9 GB |
| **65536** | **22.9** | **7.9 GB** |

> Flash attention 讓 VRAM 完全不隨 context 成長。64K 跟 4K 的 VRAM 用量相同。

### q8_0 vs q4_0 (最佳配置對比)

| KV cache | n_cpu_moe | ctx | Decode | 用途 |
|----------|-----------|-----|--------|------|
| q8_0 | 30 | 32K | 22.3 tok/s | 品質優先，日常推薦 |
| q4_0 | 28 | 64K | 22.8 tok/s | 超長 context，省 VRAM |

## 完整 ngl/n_cpu_moe sweep (q4_0, ctx=4096)

| ngl | n_cpu_moe | Decode (tok/s) | VRAM |
|-----|-----------|---------------|------|
| 20 | 64 | 9.5 | 1.9 GB |
| 28 | 48 | 15.6 | 2.1 GB |
| 36 | 32 | 19.5 | 6.1 GB |
| 40 | 36 | 20.0 | 4.5 GB |
| 40 | 32 | 21.8 | 6.4 GB |
| **40** | **28** | **22.8** | **7.9 GB** |

## 與 RTX 3060 12GB 對比

| | RTX 3060 12GB | GTX 1070 8GB |
|---|---|---|
| ngl | 40 | 40 |
| n_cpu_moe | 28 | 30 |
| KV cache | q8_0 | q8_0 |
| context | 32K | 32K |
| decode | 26.3 tok/s | 22.3 tok/s |
| VRAM | ~9.1 GB | ~7.5 GB |
