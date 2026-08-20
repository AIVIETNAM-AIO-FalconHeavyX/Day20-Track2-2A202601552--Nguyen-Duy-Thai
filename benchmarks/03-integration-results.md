# 03 - Integrate: RAG pipeline run

Host `Windows-AMD64` · llama.cpp `b10488` ·
retrieval backend: **keyword overlap** · 3 queries

| Query | Contexts retrieved | embed (ms) | retrieve (ms) | llm (ms) | total (ms) |
|:--|--:|--:|--:|--:|--:|
| Why is goodput more useful than raw throughp... | goodput, paged, radix | 0.0 | 0.1 | 3892.9 | 3893.0 |
| What problem does PagedAttention actually so... | paged, radix, disagg | 0.0 | 0.0 | 2761.4 | 2761.5 |
| When does splitting prefill and decode help?... | disagg, radix, batching | 0.0 | 0.0 | 3536.1 | 3536.1 |

Mean per stage (ms): embed **0.0** · retrieve **0.0** ·
llm **3396.8** · total **3396.9**
Dominant stage: **llm** (100% of total)

## Answers returned

**Why is goodput more useful than raw throughput?**

> Based on the provided context, **Goodput** is more useful than raw throughput because it specifically accounts for the **SLOs (Service Level Objectives)** and **TPOT (Throughput at Saturation)**.

Here is the breakdown of why this makes it superior:

1.  **Accurate Measurement of Efficiency**: Raw throughput measures the total requests per second (in the context of the provided text, likely referr

**What problem does PagedAttention actually solve?**

> PagedAttention solves the problem of **internal fragmentation** in GPU memory.

While the context mentions that it stores KV cache in non-contiguous pages to remove fragmentation, the specific problem it addresses is that the internal fragmentation of contiguous memory (like the main GPU memory) is often too large for the total number of tokens or the specific workload, leading to wasted memory. B

**When does splitting prefill and decode help?**

> Splitting prefill and decode helps when the **compute-bound part of the pipeline is the bottleneck**, specifically when the prefilling phase requires significant processing power that would otherwise be wasted if the entire operation were executed in a single pass.

In this context, the context states that prefill is compute-bound. When a model is split into multiple separate pools (e.g., for diff


## Trạng thái các thành phần N16-N19

N16 Cloud/IaC: stub, chạy localhost; N17 Data pipeline: stub, dùng dữ liệu trong
bộ nhớ; N18 Lakehouse: stub, chưa nối kho dữ liệu thật; N19 Vector/features:
stub, dùng `TOY_DOCS` và keyword overlap; N20 serving là real qua llama-server.
LLM chiếm gần 100% tổng latency (3396.8/3396.9 ms), đúng với kỳ vọng vì model
phải decode tới 200 token trong mỗi query. Nếu cần giảm một nửa latency, tôi
sẽ giảm ngân sách output và tối ưu decode/queue trước; embed và retrieve hiện
chỉ mất khoảng 0.1 ms nên không phải nút thắt.
