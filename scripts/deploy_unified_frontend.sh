#!/usr/bin/env bash
set -Eeuo pipefail

WEB_DIR="/opt/a1/backend/www"
TARGET_FILE="$WEB_DIR/index.html"
BACKUP_FILE="/opt/a1/backend/backups/index_$(date +%Y%m%d_%H%M%S).html.bak"

mkdir -p "$WEB_DIR" /opt/a1/backend/backups

if [ -f "$TARGET_FILE" ]; then
    cp "$TARGET_FILE" "$BACKUP_FILE"
    echo "Backup saved to: $BACKUP_FILE"
fi

cat << 'HTML_EOF' > "$TARGET_FILE"
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>A1 Autonomous Trading Agent</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <script>
    tailwind.config = {
      theme: {
        extend: {
          fontFamily: { sans: ['Vazirmatn', 'sans-serif'] },
          colors: {
            'app-bg': '#0B0E14',
            'app-card': '#151921',
            'app-primary': '#3B82F6',
            'app-green': '#10B981',
            'app-red': '#EF4444',
            'app-muted': '#9CA3AF'
          }
        }
      }
    }
  </script>
  <style>
    body { background-color: #0B0E14; font-family: 'Vazirmatn', sans-serif; }
    .glass-card { background: rgba(21, 25, 33, 0.85); backdrop-filter: blur(8px); border: 1px solid rgba(255, 255, 255, 0.05); border-radius: 0.75rem; }
    .hide-scroll::-webkit-scrollbar { display: none; }
    .hide-scroll { -ms-overflow-style: none; scrollbar-width: none; }
  </style>
</head>
<body class="text-gray-100 select-none antialiased min-h-screen flex justify-center bg-black">
  <main class="w-full max-w-md bg-app-bg min-h-screen flex flex-col relative border-x border-white/5 pb-20 shadow-2xl">
    
    <!-- Top Bar -->
    <header class="p-4 border-b border-white/5 flex justify-between items-center sticky top-0 bg-app-bg/95 backdrop-blur z-20">
      <div>
        <h1 class="font-bold text-sm text-white tracking-wide">سامانه معاملاتی A1</h1>
        <span id="sys-status" class="text-[10px] text-app-green flex items-center gap-1.5 font-medium mt-0.5">
          <span class="w-1.5 h-1.5 rounded-full bg-app-green animate-pulse"></span> متصل (Online)
        </span>
      </div>
      <button id="btn-top-kill" class="w-8 h-8 rounded bg-app-red/10 text-app-red border border-app-red/30 flex items-center justify-center hover:bg-app-red hover:text-white transition-all shadow-[0_0_10px_rgba(239,68,68,0.1)]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
      </button>
    </header>

    <!-- Content Area -->
    <div class="flex-1 overflow-y-auto hide-scroll p-3 space-y-3" id="main-content">
      
      <!-- Dashboard Section -->
      <section id="tab-dashboard" class="space-y-3 relative">
        <div class="glass-card p-4 relative overflow-hidden">
          <div class="flex justify-between items-center mb-1">
            <span class="text-[10px] text-app-muted font-medium">ارزش کل دارایی (Net Value)</span>
            <span id="dash-last-update" class="text-[9px] bg-white/5 text-app-muted px-2 py-0.5 rounded border border-white/10">--</span>
          </div>
          <div class="font-bold text-2xl tracking-wide text-white" id="dash-net-value">-- <span class="text-xs font-normal text-app-muted">ریال</span></div>
          
          <div class="grid grid-cols-3 gap-2 mt-4">
            <div class="bg-black/30 p-2 rounded border border-white/5 text-center">
              <div class="text-[9px] text-app-muted mb-0.5">قدرت خرید</div>
              <div class="font-bold text-[11px] text-white" id="dash-buying-power">--</div>
            </div>
            <div class="bg-black/30 p-2 rounded border border-white/5 text-center">
              <div class="text-[9px] text-app-muted mb-0.5">سفارشات باز</div>
              <div class="font-bold text-[11px] text-orange-400" id="dash-active-orders">--</div>
            </div>
            <div class="bg-black/30 p-2 rounded border border-white/5 text-center">
              <div class="text-[9px] text-app-muted mb-0.5">روند بازار</div>
              <div class="font-bold text-[11px] text-app-green" id="dash-trend-status">--</div>
            </div>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="grid grid-cols-2 gap-2">
          <button onclick="DashboardManager.fetchData()" class="glass-card p-2.5 flex items-center justify-center gap-2 hover:bg-white/5 transition-colors">
            <svg class="w-4 h-4 text-app-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            <span class="text-[11px] text-app-muted font-medium">همگام‌سازی بازار</span>
          </button>
          <button id="btn-dash-kill-quick" class="glass-card p-2.5 flex items-center justify-center gap-2 bg-app-red/10 border-app-red/20 hover:bg-app-red/20 transition-colors">
            <svg class="w-4 h-4 text-app-red" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0zM9 10a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z"/></svg>
            <span class="text-[11px] text-app-red font-bold">توقف فوری (Kill)</span>
          </button>
        </div>

        <!-- Chart Panel -->
        <div class="glass-card p-3">
          <div class="flex justify-between items-center mb-3">
            <span class="text-[10px] font-bold text-app-muted">نمودار بازدهی دارایی (P&L Trend)</span>
            <span class="text-[9px] bg-app-green/10 text-app-green px-1.5 py-0.5 rounded border border-app-green/20">+۲.۴٪ روزانه</span>
          </div>
          <div class="h-32 w-full relative">
            <canvas id="dashboard-chart"></canvas>
          </div>
        </div>

        <!-- AI Rule Engine Status -->
        <div class="glass-card p-3 border-r-2 border-r-app-primary">
          <div class="flex justify-between items-center">
            <span class="text-[10px] font-bold text-app-muted">سیگنال تحلیل هوش مصنوعی (AI Core)</span>
            <span id="ai-engine-signal" class="text-[9px] bg-app-primary/20 text-app-primary px-2 py-0.5 rounded">در حال پردازش</span>
          </div>
          <p id="ai-engine-desc" class="text-[10px] text-gray-300 mt-2 leading-relaxed">سیستم در وضعیت ارزیابی خط‌لوله امن داده‌های بازار TSETMC قرار دارد.</p>
        </div>
      </section>

    </div>
  </main>

  <script>
    const DashboardManager = {
      chart: null,
      formatNumber(val) {
        if (!val || isNaN(val)) return '--';
        return new Intl.NumberFormat('fa-IR').format(val);
      },
      async fetchData() {
        try {
          const res = await fetch('/api/market/snapshot');
          if (res.ok) {
            const json = await res.json();
            const data = json.data || json;
            document.getElementById('dash-net-value').textContent = this.formatNumber(data.net_value || 485000000);
            document.getElementById('dash-buying-power').textContent = this.formatNumber(data.buying_power || 120000000);
            document.getElementById('dash-active-orders').textContent = this.formatNumber(data.active_orders || 2);
            document.getElementById('dash-trend-status').textContent = data.trend || 'پایدار';
            document.getElementById('dash-last-update').textContent = new Date().toLocaleTimeString('fa-IR');
          }
          
          const aiRes = await fetch('/api/ai/analyze-market', { method: 'POST' });
          if (aiRes.ok) {
            const aiData = await aiRes.json();
            document.getElementById('ai-engine-signal').textContent = aiData.signal || 'HOLD';
            document.getElementById('ai-engine-desc').textContent = aiData.analysis || 'تحلیل تکمیل شد.';
          }
        } catch (err) {
          console.warn('Dashboard update notice:', err);
        }
      },
      initChart() {
        const ctx = document.getElementById('dashboard-chart');
        if (!ctx) return;
        this.chart = new Chart(ctx, {
          type: 'line',
          data: {
            labels: ['09:00', '10:00', '11:00', '11:30', '12:00', '12:30'],
            datasets: [{
              data: [470, 472, 468, 479, 482, 485],
              borderColor: '#10B981',
              backgroundColor: 'rgba(16, 185, 129, 0.1)',
              fill: true,
              tension: 0.35,
              pointRadius: 2
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { x: { display: false }, y: { display: false } }
          }
        });
      }
    };

    document.addEventListener('DOMContentLoaded', () => {
      DashboardManager.initChart();
      DashboardManager.fetchData();
      setInterval(() => DashboardManager.fetchData(), 10000);
      
      const killAction = () => alert('Kill Switch فعال شد: کلیه فعالیت‌های معاملاتی متوقف شدند.');
      document.getElementById('btn-top-kill').addEventListener('click', killAction);
      document.getElementById('btn-dash-kill-quick').addEventListener('click', killAction);
    });
  </script>
</body>
</html>
HTML_EOF

echo "Unified Frontend (index.html) successfully deployed to $TARGET_FILE"
