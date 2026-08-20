# Reflection - Day 20 Lab

**Họ tên:** Nguyễn Duy Thái  
**Cohort:** AICB Track 2  
**Ngày submit:** 2026-08-20

## 1. Hardware & runtime

- **OS:** Windows 10
- **CPU:** Intel Core i7-11800H @ 2.30GHz
- **Cores:** 8 physical / 16 logical
- **CPU extensions:** thông tin probe không dùng để bật đường chạy chính
- **RAM:** 15.8 GB
- **Accelerator:** NVIDIA GeForce RTX 3060 Laptop GPU 6 GB, CUDA và Vulkan
- **llama.cpp asset:** `llama-b10488-bin-win-cuda-12.4-x64.zip`
- **Model:** Qwen3.5 0.8B (`LAB_MODEL=qwen35-0.8b`)
- **Quantization:** `Q4_K_M` + `UD-Q2_K_XL`

Tôi chạy local trên laptop. Tôi chủ động chọn Qwen thay vì Gemma để giảm thời gian tải và có
thêm mẫu trong load test; lựa chọn này vẫn đáp ứng đầy đủ rubric. Setup tải runtime CUDA và hai
GGUF thành công, không cần compiler hay Docker.

## 2. Đo lường

| Quantization | Size (GB) | Load (ms) | TTFT P50/P95 (ms) | TPOT P50/P95 (ms) | E2E P50/P95/P99 (ms) | Decode (tok/s) |
|---|--:|--:|--:|--:|--:|--:|
| Q4_K_M | 0.50 | 2749 | 69 / 76 | 6.2 / 6.6 | 461 / 478 / 478 | 160.4 |
| UD-Q2_K_XL | 0.39 | 2562 | 70 / 81 | 6.5 / 6.7 | 477 / 502 / 502 | 153.7 |

Bản 2-bit nhỏ hơn 0.11 GB nhưng decode chậm hơn khoảng 4%, còn TTFT gần như không đổi.
Trên GPU này, chi phí giải lượng tử 2-bit lớn hơn lợi ích giảm số byte phải đọc. Khi hỏi cùng
một câu, Q4_K_M cho câu trả lời ổn định và mạch lạc hơn, nên tôi chọn Q4_K_M cho serving.

## 3. Serving under load

| Users | RPS | P50 (ms) | P95 (ms) | P99 (ms) | Eff. concurrency | Failures |
|--:|--:|--:|--:|--:|--:|--:|
| 10 | 3.11 | 2100 | 3900 | 5400 | 7.1 | 0.0% |
| 50 | 2.64 | 17000 | 20000 | 21000 | 41.1 | 0.0% |

- **Offered load tăng 5x, throughput thực tế:** 0.85x
- **P95 tăng:** 5.13x
- **Effective concurrency ở 50 users:** 41.1 so với `--parallel=4` slots
- **Peak `n_busy_slots_per_decode`:** 3.96 / 4 slots

Server bão hòa ở tải 50 users. Throughput không tăng theo tải, P95 tăng mạnh và có 44--46
request deferred. Gauge 3.96/4 xác nhận continuous batching đang dùng gần đủ slot; effective
concurrency 41.1 bao gồm cả request nằm trong queue, nên lớn hơn số slot là hợp lý. Nếu cần
nâng goodput trong một SLO P95, tôi sẽ giảm output token hoặc dùng quantization nhanh hơn trước;
tăng số slot có thể làm queue dài hơn và không giải quyết nút thắt GPU.

## 4. Integration

| Day | Piece | Real hay stub? |
|---|---|---|
| N16 | Cloud/IaC | Stub, chạy localhost |
| N17 | Data pipeline | Stub, dữ liệu trong bộ nhớ |
| N18 | Lakehouse | Stub, chưa nối kho dữ liệu thật |
| N19 | Vector + features | Stub, `TOY_DOCS` và keyword overlap |
| N20 | Serving | Real, `llama-server` |

Latency trung bình của ba query:

- embed: **0.0 ms**
- retrieve: **0.0 ms** (khoảng 0.1 ms ở query đầu)
- llm: **3396.8 ms**
- tổng: **3396.9 ms**
- stage chiếm nhiều nhất: **LLM, gần 100%**

Kết quả phù hợp với dự đoán: pipeline toy gần như không tốn thời gian retrieve, còn model phải
decode tới 200 token. Nếu cần giảm một nửa latency, tôi sẽ giảm ngân sách output và tối ưu
decode/queue; thay embedding hoặc keyword search hiện chưa tạo khác biệt đáng kể.

## 5. Thay đổi quan trọng nhất

**Thay đổi:** giảm số thread từ baseline 8 xuống 4 theo kết quả tuning.

```text
before: 159.2 tok/s (8 threads, physical-core default)
after:  162.9 tok/s (4 threads)
speedup: 1.02x
```

Đây là cải thiện nhỏ nhưng đo được. Sweep cho thấy 1 thread đạt 162.3 tok/s, 4 thread đạt
162.9 tok/s, sau đó throughput giảm nhẹ ở 8 và 16 thread. Vì `ngl=99`, phần lớn công việc
đã chạy trên GPU; thêm CPU thread không tăng lượng công việc GPU mà thêm chi phí lập lịch,
đồng bộ và tranh chấp tài nguyên. Kết quả này cũng giải thích vì sao 32 thread không thắng.
Tôi không cố diễn giải đây là speedup lớn: trên workload và GPU này, thread count chỉ là knob
phụ, còn quantization và queue mới ảnh hưởng rõ hơn đến trải nghiệm serving.

## 6. Bonus

Tôi chạy semantic cache offline với embedding túi từ mô phỏng. Ở threshold 0.80,
cache hit 3/8 query (38%), giúp bỏ qua 3 lần gọi LLM và tiết kiệm khoảng 750 ms
decode trong mô phỏng. Sweep từ 0.70 đến 0.95 đều cho 3/8 vì embedder offline chỉ
cho similarity gần 0 hoặc 1; đây là giới hạn của stub, không phải bằng chứng rằng
mọi threshold đều tương đương. Khi triển khai thật, cần embedding model chuyên dụng,
đánh giá false hit/miss và tách cache theo tenant để tránh rò rỉ dữ liệu.

## 7. Điều làm tôi ngạc nhiên

Bản 2-bit nhỏ hơn nhưng chậm hơn trên GPU. Điều này nhắc tôi rằng quantization không tự động
đồng nghĩa với nhanh hơn: lợi ích phụ thuộc bottleneck thực tế và chi phí dequantization.

## 8. Self-check

- [x] `hardware.json` và `models/active.json` đã tạo
- [x] Benchmark hai quantization, tuning, serving và smoke test đã chạy
- [x] Load test 10/50 users và metrics đồng thời với 50 users đã chạy
- [x] RAG pipeline đủ 3 query đã chạy
- [x] Các report đã thay phần yêu cầu nhận xét
- [ ] Screenshots terminal cần được chụp và commit trước khi submit
- [ ] Chạy `verify` lần cuối sau khi thêm screenshots
