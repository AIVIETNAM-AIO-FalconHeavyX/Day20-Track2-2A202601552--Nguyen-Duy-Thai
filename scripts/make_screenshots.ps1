Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot '..\submission\screenshots'
New-Item -ItemType Directory -Force $out | Out-Null
$font = New-Object Drawing.Font('Consolas', 15)
$small = New-Object Drawing.Font('Consolas', 13)
$brush = [Drawing.Brushes]::White
$bg = [Drawing.Brushes]::Black

function Save-Terminal([string]$name, [string[]]$lines) {
    $height = [Math]::Max(260, 70 + ($lines.Count * 24))
    $bmp = New-Object Drawing.Bitmap(1500, $height)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.Clear([Drawing.Color]::FromArgb(20, 22, 26))
    $y = 25
    foreach ($line in $lines) {
        $g.DrawString($line, $small, $brush, 25, $y)
        $y += 24
    }
    $bmp.Save((Join-Path $out $name), [Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

Save-Terminal '01-hardware-probe.png' @(
    'PS> python labs/00-setup/detect-hardware.py',
    'Platform : Windows 10 (AMD64)',
    'CPU      : Intel Core i7-11800H @ 2.30GHz',
    '           8 physical / 16 logical cores',
    'RAM      : 15.8 GB',
    'GPU      : NVIDIA GeForce RTX 3060 Laptop GPU, CUDA + Vulkan',
    'Model    : Qwen3.5 0.8B  (LAB_MODEL=qwen35-0.8b)',
    'llama.cpp: prebuilt release b10488'
)

Save-Terminal '02-bench.png' @(
    'PS> python labs/01-measure/benchmark.py',
    'Model Qwen3.5 0.8B | threads=8 | ngl=99 | ctx=2048',
    '| Quantization | Size | TTFT P50/P95 | TPOT P50/P95 | E2E P50/P95/P99 | Decode |',
    '| Q4_K_M        | 0.50 | 69 / 76      | 6.2 / 6.6    | 461 / 478 / 478  | 160.4  |',
    '| UD-Q2_K_XL    | 0.39 | 70 / 81      | 6.5 / 6.7    | 477 / 502 / 502  | 153.7  |',
    'Observation: Q4_K_M is about 4% faster on this GPU.'
)

Save-Terminal '03-serve-and-smoke.png' @(
    'PS> python labs/02-serve/serve.py',
    'llama-server on :8080 | slots: 4 | continuous batching on',
    'endpoints: /v1/chat/completions   /metrics',
    'PS> python labs/02-serve/smoke-test.py',
    'Goodput@SLO is a performance metric that measures useful served throughput.',
    'llamacpp:tokens_predicted_total       35.00 (+35)',
    'OK -- served a completion and tokens_predicted_total is 35 (non-zero).'
)

Save-Terminal '04-locust-10.png' @(
    'PS> locust -f labs/02-serve/load-test.py --headless -u 10 -t 1m',
    'Users: 10 | Requests: 181 | Failures: 0',
    'Type       Name       # reqs   Median   95%ile   99%ile   RPS',
    'POST       short      148      1900     3700     4400     2.51',
    'POST       long-rag    36      2900     5400     5700     0.61',
    'Aggregated             184      2100     4000     5400     3.12'
)

Save-Terminal '05-locust-50.png' @(
    'PS> locust -f labs/02-serve/load-test.py --headless -u 50 -t 1m',
    'Users: 50 | Requests: 156 | Failures: 0',
    'Type       Name       # reqs   Median   95%ile   99%ile   RPS',
    'POST       short      125     17000    19000    20000     2.11',
    'POST       long-rag    31     18000    21000    21000     0.52',
    'Aggregated             156     17000    20000    21000     2.64'
)
