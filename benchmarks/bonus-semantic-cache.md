# Bonus B5 - Semantic cache offline

Môi trường: Windows local, semantic-cache-demo chạy `--offline --sweep`.

| Threshold | Cache hits |
|---:|---:|
| 0.70 | 3/8 |
| 0.80 | 3/8 |
| 0.85 | 3/8 |
| 0.90 | 3/8 |
| 0.95 | 3/8 |

Ở threshold 0.80, có 3/8 hit (38%), tương đương 3 lần gọi LLM được bỏ qua và khoảng
750 ms decode tiết kiệm trong mô phỏng. Đường cong threshold phẳng vì embedder offline
là bag-of-words, similarity gần như chỉ có 0 hoặc 1; không nên dùng kết quả này để chọn
threshold production. Bài học thực tế là semantic cache nằm trước prefix/KV cache và
có thể bỏ qua toàn bộ prefill/decode cho paraphrase, nhưng phải kiểm soát false hit và
tách dữ liệu theo tenant.
