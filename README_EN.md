# Qwen3.6-35B-A3B on GTX 1070 8GB: 22 tok/s on an old card

> **English** | [中文](README.md)

Most people assume Qwen3.6-35B-A3B needs at least 12 GB VRAM. Can an older 8 GB card like the GTX 1070 handle it?

**Yes — and it runs well.**

Tested on a GTX 1070 8 GB, Qwen3.6-35B-A3B reaches about **22 tok/s** with q8_0 KV cache and 32K context. Smooth enough for daily chat and agent use.

> 📖 For the full 12 GB benchmark, see [rtx3060-qwen3.6-35b-guide](https://github.com/castlen3/rtx3060-qwen3.6-35b-guide)

---

## TL;DR

| Metric | Value |
|--------|-------|
| GPU | GTX 1070 8 GB (Pascal, CC 6.1) |
| Decode speed | **22.3 tok/s** (q8_0) / **22.8 tok/s** (q4_0) |
| VRAM peak | ~7.5 GB (q8_0, n_cpu_moe=30) |
| Context | **32K stable** (q8_0) / **64K stable** (q4_0) |
| vs RTX 3060 12 GB | ~15% slower (26.3 vs 22.3 tok/s) |

> 📊 Full benchmark data: [results/simple_benchmark_EN.md](results/simple_benchmark_EN.md)

## Recommended config

```bash
llama-server.exe ^
  -m "Qwen3.6-35B-A3B-Q4_K_M.gguf" ^
  -t 4 ^
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

| Metric | Value |
|--------|-------|
| Decode | **~22.3 tok/s** |
| VRAM | ~7.5 GB |
| Context | 32768 (32K) |

> ⚠️ **`-fa on` is required.** Without flash attention, VRAM grows linearly with context length — 8 GB will OOM.

## Test environment

| Component | Spec |
|-----------|------|
| GPU | NVIDIA GeForce GTX 1070 (8191 MiB, Pascal) |
| CPU | Intel Core i7-7700K (4c/8t @ 4.20 GHz) |
| RAM | 32 GB DDR4 |
| OS | Windows 10 |
| llama.cpp | b9500 |
| CUDA | 12.4 (**required** — 13.3 drops CC 6.1 support) |
| Model | Qwen3.6-35B-A3B-Q4_K_M.gguf (19.7 GB) |

## Key findings

### n_cpu_moe is the decisive parameter

On 8 GB, one more or one less n_cpu_moe can make or break performance:

```
q8_0, ctx=32768, ngl=40:

n_cpu_moe   Decode       VRAM      Status
───────────────────────────────────────────
  28        8.5 tok/s    7.9 GB    ⚠️  thrashing
  29       22.0 tok/s    7.7 GB    ✅  borderline
  30       22.3 tok/s    7.5 GB    ✅  recommended
```

A single n_cpu_moe step (~200 MB VRAM) causes a 2.6x speed drop. **Never max out 8 GB VRAM.**

### q8_0 vs q4_0

| KV cache | n_cpu_moe | Max ctx | Decode | Use case |
|----------|-----------|---------|--------|----------|
| q8_0 | 30 | 32K | 22.3 | Quality-first, daily use |
| q4_0 | 28 | 64K | 22.8 | Long context, VRAM savings |

q4_0 handles 64K context with zero VRAM growth (flash attention).

## vs RTX 3060 12 GB

| | RTX 3060 12 GB | GTX 1070 8 GB |
|---|---|---|
| ngl | 40 | 40 |
| n_cpu_moe | 28 | 30 |
| KV cache | q8_0 | q8_0 |
| Context | 32K | 32K |
| Decode | 26.3 tok/s | 22.3 tok/s |
| VRAM peak | ~9.1 GB | ~7.5 GB |

The only parameter difference is n_cpu_moe (28 vs 30). Everything else is identical.

## Pitfalls

1. **CUDA version** — GTX 1070 (CC 6.1) needs CUDA 12.x binaries. Official CUDA 13.3 builds don't include Pascal kernels — `--list-devices` will be empty.
2. **Verify real GPU** — Always run `llama-server.exe --list-devices` first. Empty output = CPU-only.
3. **Don't squeeze VRAM** — n_cpu_moe=28 + q8_0 loads but decodes at 8 tok/s instead of 22. Keep 300-500 MB free.
4. **Flash attention** — `-fa on` is what makes 32K context possible on 8 GB. Without it, guaranteed OOM.

## Quick start

1. Download [llama.cpp b9500 CUDA 12.4](https://github.com/ggml-org/llama.cpp/releases/tag/b9500) — grab both `cudart-llama-bin-win-cuda-12.4-x64.zip` and `llama-b9500-bin-win-cuda-12.4-x64.zip`, extract, and put the cudart DLLs next to the .exe files.
2. Download `Qwen3.6-35B-A3B-Q4_K_M.gguf` (~19.7 GB).
3. Run the recommended command above.
4. Verify: `curl http://localhost:8080/health` → `{"status":"ok"}`
