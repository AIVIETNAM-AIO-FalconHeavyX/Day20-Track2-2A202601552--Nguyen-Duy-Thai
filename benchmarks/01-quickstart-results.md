# 01 - Measure: latency baseline

Model `Qwen3.5 0.8B` · host `Windows-AMD64` · llama.cpp `b10488`
Settings: `threads=8` `ngl=99` `ctx=2048`
`max_tokens=64` · warm-up discarded
Completed requests: `Q4_K_M` 10/10 · `UD-Q2_K_XL` 10/10

| Quantization | Size (GB) | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode (tok/s) |
|:--|--:|--:|--:|--:|--:|--:|
| Q4_K_M | 0.50 | 2749 | 69 / 76 | 6.2 / 6.6 | 461 / 478 / 478 | 160.4 |
| UD-Q2_K_XL | 0.39 | 2562 | 70 / 81 | 6.5 / 6.7 | 477 / 502 / 502 | 153.7 |

- **TTFT** = prefill. Short prompts keep it small; long-context RAG is where it explodes.
- **TPOT** = per-output-token decode cost, bounded by memory bandwidth. `decode tok/s = 1000 / TPOT_p50`.
- `UD-Q2_K_XL` decodes **1.04x SLOWER** than `Q4_K_M` here, despite being 0.11 GB smaller. That is a real result, not a mistake: fewer bits only buys speed when decode is limited by memory bandwidth. On a machine that is compute-limited instead — few cores, no GPU offload — the extra dequantization work of a heavily-quantized format can cost more than the bytes it saves. Say which case yours is.

## Nhận xét của tôi

Trên máy của tôi, bản UD-Q2_K_XL nhỏ hơn 0.11 GB nhưng không đáng đổi lấy tốc độ:
TTFT P50 gần như ngang nhau (70 so với 69 ms), còn TPOT P50 tăng từ 6.2 lên
6.5 ms, nên decode giảm từ 160.4 xuống 153.7 tok/s (chậm hơn khoảng 4%).
Q4_K_M cũng cho câu trả lời mạch lạc hơn khi hỏi cùng một câu. Vì GPU đã xử lý
phần lớn phép tính, lợi ích giảm dung lượng không bù được chi phí giải lượng tử
2-bit; tôi chọn Q4_K_M để serving.
