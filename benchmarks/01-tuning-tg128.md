# 01 - Tune: thread-count sweep

Model `Qwen3.5-0.8B-Q4_K_M.gguf` · host `Windows-AMD64` · llama.cpp `b10488`
CPU: **8 physical · 16 logical** cores · `ngl=99` · metric `tg128`

| threads (-t) | tg128 (tok/s) | vs best |
|:--|--:|--:|
| 1 | 162.3 | 100% |
| 4 | 162.9 | 100% |
| 8 | 159.2 | 98% |
| 16 | 158.8 | 97% |
| 32 | 161.7 | 99% |

**Best**: `-t 4` at 162.9 tok/s
**Slowest tested**: `-t 16` at 158.8 tok/s (1.03x spread)
**Against the physical-core default** (`-t 8`, 159.2 tok/s): 1.02x

Use this in your run:

```bash
LAB_N_THREADS=4 make bench
```

## Giải thích của tôi

Đường cong gần như phẳng, không có speedup lớn theo số thread: 1 thread đạt
162.3 tok/s, best là 4 thread với 162.9 tok/s, còn 8 thread mặc định chỉ còn
159.2 tok/s. Knee thực tế nằm rất sớm ở khoảng 4 thread; tăng lên 16 thread
giảm còn 158.8 tok/s. GPU offload (ngl=99) đã trở thành đường chạy chính nên
thêm CPU thread không làm tăng throughput đáng kể, trong khi vẫn có overhead
lập lịch và đồng bộ. Vì vậy tôi chọn 4 thread, nhanh hơn baseline 8 thread
khoảng 1.02x, nhưng coi đây là cải thiện nhỏ chứ không phải thay đổi căn bản.
