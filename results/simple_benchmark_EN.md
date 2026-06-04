# Benchmark Data — GTX 1070 8GB

> Test date: 2026-06-04
> llama.cpp: b9500 + CUDA 12.4 (CC 6.1)
> Model: Qwen3.6-35B-A3B-Q4_K_M.gguf (19.7 GB)

## Fixed parameters

```
-ngl 40   --no-mmap   -fa on   -fit off   --reasoning off   -np 1   -t 4
```

## Core results

### q8_0 KV cache — n_cpu_moe sweep (ctx=32768)

| n_cpu_moe | Decode (tok/s) | VRAM | Status |
|-----------|---------------|------|--------|
| 28 | 8.5 | 7.9 GB | ⚠️ VRAM thrashing |
| 29 | 22.0 | 7.7 GB | ✅ Sweet spot |
| **30** | **22.3** | **7.5 GB** | ✅ **Recommended** |

> **n_cpu_moe=28 loads but VRAM is too tight — decode drops to 8.5 tok/s.**
> Moving 2 more experts to CPU (n_cpu_moe=30) costs ~0.5 tok/s but frees 500 MB VRAM headroom.

### q4_0 KV cache — context stress test (n_cpu_moe=28)

| ctx | Decode (tok/s) | VRAM |
|-----|---------------|------|
| 4096 | 22.8 | 7.9 GB |
| 8192 | 22.9 | 7.9 GB |
| 16384 | 22.8 | 7.9 GB |
| 32768 | 22.8 | 7.9 GB |
| **65536** | **22.9** | **7.9 GB** |

> Flash attention keeps VRAM flat regardless of context length. 64K uses the same VRAM as 4K.

### q8_0 vs q4_0 (best config comparison)

| KV cache | n_cpu_moe | ctx | Decode | Use case |
|----------|-----------|-----|--------|----------|
| q8_0 | 30 | 32K | 22.3 tok/s | Quality-first, daily use |
| q4_0 | 28 | 64K | 22.8 tok/s | Long context, VRAM savings |

## Full ngl/n_cpu_moe sweep (q4_0, ctx=4096)

| ngl | n_cpu_moe | Decode (tok/s) | VRAM |
|-----|-----------|---------------|------|
| 20 | 64 | 9.5 | 1.9 GB |
| 28 | 48 | 15.6 | 2.1 GB |
| 36 | 32 | 19.5 | 6.1 GB |
| 40 | 36 | 20.0 | 4.5 GB |
| 40 | 32 | 21.8 | 6.4 GB |
| **40** | **28** | **22.8** | **7.9 GB** |

## vs RTX 3060 12GB

| | RTX 3060 12GB | GTX 1070 8GB |
|---|---|---|
| ngl | 40 | 40 |
| n_cpu_moe | 28 | 30 |
| KV cache | q8_0 | q8_0 |
| context | 32K | 32K |
| decode | 26.3 tok/s | 22.3 tok/s |
| VRAM | ~9.1 GB | ~7.5 GB |
