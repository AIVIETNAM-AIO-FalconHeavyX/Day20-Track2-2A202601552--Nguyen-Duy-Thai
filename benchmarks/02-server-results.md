# 02 - Serve: load test + saturation reading

Host `Windows-AMD64` · llama.cpp `b10488` ·
`--parallel 4` · `ctx=2048` · `threads=8` ·
`ngl=99`

| Users | Reqs | RPS | P50 (ms) | P95 (ms) | P99 (ms) | Eff. concurrency | Failures |
|:--|--:|--:|--:|--:|--:|--:|--:|
| 10 | 181 | 3.11 | 2100 | 3900 | 5400 | 7.1 | 0.0% |
| 50 | 156 | 2.64 | 17000 | 20000 | 21000 | 41.1 | 0.0% |

*Effective concurrency = RPS x average latency (Little's Law) -- how many requests were
really in flight, regardless of how many users locust simulated. It counts queued requests
too, so the occupancy/slot ratio can legitimately exceed 1.0; it is occupancy, not
utilisation. For true slot utilisation use the server's own gauges (`make metrics`).*

## What these two runs say

| Going from 10 to 50 users | |
|:--|--:|
| Offered load | 5x |
| Throughput actually delivered | **0.85x** (17% of linear) |
| P95 latency | **5.13x** |
| Effective concurrency at 50 users | 41.1 vs `--parallel 4` slots (occupancy/slot ratio 10.26) |

**Saturated.** Throughput delivered only 0.85x for 5x the offered load, and effective concurrency (41.1) is at or above all 4 decode slots. Saturation sets in somewhere at or below 50 users; the load you added beyond that point became queue time rather than throughput.

Throughput moved 0.85x while P95 moved 5.13x. That gap is the goodput argument: past saturation you buy throughput by spending latency, and if your SLO is a P95 target then the requests you added are no longer being served within it. (This lab does not fix an SLO number for you -- pick one in your write-up and state how much goodput you keep at it.)

## Nhận định của tôi

Server bắt đầu bão hòa khi tải tiến gần hoặc vượt 4 slot, rõ nhất ở 50 users.
Bằng chứng thuyết phục nhất là tải tăng 5x nhưng throughput chỉ còn 0.85x,
P95 tăng 5.13x lên 20 giây, effective concurrency lên 41.1 so với 4 slot,
và metrics ghi nhận 44--46 request deferred. Phần latency tăng thêm chủ yếu là
thời gian xếp hàng. Để tăng goodput trong một SLO P95 thực tế, tôi sẽ thử giảm
độ dài output hoặc dùng quantization nhanh hơn trước; tăng `--parallel` chỉ
giúp nhận thêm request nhưng có thể làm queue và P95 xấu hơn trên GPU hiện tại.
