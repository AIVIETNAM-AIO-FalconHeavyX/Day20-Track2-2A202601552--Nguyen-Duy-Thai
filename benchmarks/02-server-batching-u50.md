# 02 - Continuous batching under load (u50)

Host `Windows-AMD64` · `--parallel 4` · 15 samples over
60s at 2.0s intervals · raw CSV: `02-server-metrics-u50.csv`

| Gauge | Peak observed |
|:--|--:|
| `n_busy_slots_per_decode` (avg/decode) | 3.96 of 4 slots (99%) |
| `requests_processing` | 4 |
| `requests_deferred` | 46 |
| `kv_cache_usage_ratio` | n/a — not exported by llama.cpp `b10488` |
| `tokens_predicted_total` (final) | 22565 |

Highest sampled value was **3.96 of 4** slots. Note this gauge is llama.cpp's *average* busy slots per decode step, so the number below is the highest average we sampled, not an instantaneous maximum batch width. A peak near 1 means
requests were served one at a time -- either the load was too light to overlap, or
they arrived too far apart. A peak approaching `--parallel` means the scheduler was
genuinely packing concurrent requests into shared decode steps.
`requests_deferred` went above zero: more requests arrived than there were slots, so some waited. That wait is the queue time in your P95.

## Nhận xét batching

Peak `n_busy_slots_per_decode` là 3.96/4, khớp với việc server đang dùng gần
đủ 4 slot và xác nhận continuous batching hoạt động. Con số này không thể so
trực tiếp với effective concurrency 41.1 trong load report: 3.96 là độ rộng
batch trung bình ở một bước decode, còn 41.1 bao gồm cả request đang chờ trong
queue theo Little's Law. Tôi dùng gauge 3.96 để kết luận về batching và dùng
effective concurrency để kết luận saturation.
