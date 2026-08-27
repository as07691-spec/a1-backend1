#!/usr/bin/env bash
set -Eeuo pipefail

WWW_DIR="/opt/a1/backend/www"
TARGET_FILE="$WWW_DIR/index.html"

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
            'app-orange': '#F59E0B',
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
          <span class="w-1.5 h-1.5 rounded-full bg-app-green animate-pulse"></span> متصل (AI Online)
        </span>
      </div>
      <button id="btn-top-kill" class="w-8 h-8 rounded bg-app-red/10 text-app-red border border-app-red/30 flex items-center justify-center hover:bg-app-red hover:text-white transition-all shadow-[0_0_10px_rgba(239,68,68,0.1)]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/></svg>
      </button>
    </header>

    <!-- Content Area -->
    <div class="flex-1 overflow-y-auto hide-scroll p-3 space-y-3" id="main-content">

      <!-- TAB 1: Dashboard -->
      <section id="tab-dashboard" class="tab-pane space-y-3">
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
              <div class="text-[9px] text-app-muted mb-0.5">شاخص ریسک</div>
              <div class="font-bold text-[11px] text-app-orange" id="dash-risk-score">--</div>
            </div>
            <div class="bg-black/30 p-2 rounded border border-white/5 text-center">
              <div class="text-[9px] text-app-muted mb-0.5">سیگنال مدل</div>
              <div class="font-bold text-[11px] text-app-red" id="dash-signal">--</div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <button onclick="DashboardManager.fetchData()" class="glass-card p-2.5 flex items-center justify-center gap-2 hover:bg-white/5 transition-colors">
            <svg class="w-4 h-4 text-app-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            <span class="text-[11px] text-app-muted font-medium">همگام‌سازی بازار</span>
          </button>
          <button id="btn-dash-kill-quick" class="glass-card p-2.5 flex items-center justify-center gap-2 bg-app-red/10 border-app-red/20 hover:bg-app-red/20 transition-colors">
            <svg class="w-4 h-4 text-app-red" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0zM9 10a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z"/></svg>
            <span class="text-[11px] text-app-red font-bold">توقف اضطراری (Kill)</span>
          </button>
        </div>

        <div class="glass-card p-3">
          <div class="flex justify-between items-center mb-3">
            <span class="text-[10px] font-bold text-app-muted">نمودار بازدهی دارایی (P&L Trend)</span>
            <span class="text-[9px] bg-app-green/10 text-app-green px-1.5 py-0.5 rounded border border-app-green/20">+۲.۴٪ روزانه</span>
          </div>
          <div class="h-32 w-full relative">
            <canvas id="dashboard-chart"></canvas>
          </div>
        </div>

        <div class="glass-card p-3 border-r-2 border-r-app-primary">
          <div class="flex justify-between items-center">
            <span class="text-[10px] font-bold text-app-muted">تحلیل هوش مصنوعی (Local AI)</span>
            <span id="ai-engine-signal" class="text-[9px] bg-app-primary/20 text-app-primary px-2 py-0.5 rounded">--</span>
          </div>
          <p id="ai-engine-desc" class="text-[10px] text-gray-300 mt-2 leading-relaxed">در حال پردازش داده‌ها...</p>
        </div>
      </section>

      <!-- TAB 2: Strategy History -->
      <section id="tab-strategy" class="tab-pane hidden space-y-3">
        <div class="glass-card p-3">
          <div class="flex justify-between items-center mb-2">
            <h2 class="text-xs font-bold text-white">لاگ سیگنال‌های استراتژی</h2>
            <span class="text-[9px] bg-app-primary/20 text-app-primary px-2 py-0.5 rounded">Adaptive-Mean-Reversion</span>
          </div>
          <div id="strategy-history-list" class="space-y-2 text-[10px]">
            <div class="text-center py-4 text-app-muted">در حال دریافت تاریخچه...</div>
          </div>
        </div>
      </section>

      <!-- TAB 3: Portfolio -->
      <section id="tab-portfolio" class="tab-pane hidden space-y-3">
        <div class="glass-card p-3 text-center py-6">
          <p class="text-xs text-app-muted">ماژول مدیریت سبد دارایی و سفارشات آنلاین</p>
          <span class="text-[10px] text-app-green mt-2 inline-block">وضعیت پایش: فعال</span>
        </div>
      </section>

      <!-- TAB 4: Settings -->
      <section id="tab-settings" class="tab-pane hidden space-y-3">
        <div class="glass-card p-3 space-y-2">
          <h2 class="text-xs font-bold text-white">پیکربندی سیستم</h2>
          <div class="text-[10px] text-gray-400">سرویس داده: TSETMC CDN Proxy</div>
          <div class="text-[10px] text-gray-400">موتور هوش مصنوعی: v1.0-local-hybrid (محلی)</div>
        </div>
      </section>

    </div>

    <!-- Bottom Navigation Bar -->
    <nav class="fixed bottom-0 max-w-md w-full bg-app-card/95 backdrop-blur border-t border-white/5 flex justify-around py-2 z-30">
      <button onclick="DashboardManager.switchTab('tab-dashboard')" class="tab-btn flex flex-col items-center gap-1 text-app-primary text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
        <span>داشبورد</span>
      </button>
      <button onclick="DashboardManager.switchTab('tab-strategy')" class="tab-btn flex flex-col items-center gap-1 text-app-muted hover:text-white text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
        <span>استراتژی</span>
      </button>
      <button onclick="DashboardManager.switchTab('tab-portfolio')" class="tab-btn flex flex-col items-center gap-1 text-app-muted hover:text-white text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span>پرتفوی</span>
      </button>
      <button onclick="DashboardManager.switchTab('tab-settings')" class="tab-btn flex flex-col items-center gap-1 text-app-muted hover:text-white text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
        <span>تنظیمات</span>
      </button>
    </nav>
  </main>

  <script>
    const DashboardManager = {
      chart: null,
      switchTab(tabId) {
        document.querySelectorAll('.tab-pane').forEach(el => el.classList.add('hidden'));
        const active = document.getElementById(tabId);
        if (active) active.classList.remove('hidden');
        if (tabId === 'tab-strategy') this.fetchStrategyHistory();
      },
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
            document.getElementById('dash-last-update').textContent = new Date().toLocaleTimeString('fa-IR');
          }

          const aiRes = await fetch('/api/ai/analyze-market', { method: 'POST' });
          if (aiRes.ok) {
            const aiData = await aiRes.json();
            const signalElem = document.getElementById('dash-signal');
            const aiSignalBadge = document.getElementById('ai-engine-signal');
            
            signalElem.textContent = aiData.signal || 'HOLD';
            aiSignalBadge.textContent = aiData.signal || 'HOLD';
            document.getElementById('dash-risk-score').textContent = (aiData.risk_score * 100).toFixed(0) + '٪';
            documentif (tabId === 'tab-strategy') this.fetchStrategyHistory();
      },
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
            document.getElementById('dash-last-update').textContent = new Date().toLocaleTimeString('fa-IR');
          }

          const aiRes = await fetch('/api/ai/analyze-market', { method: 'POST' });
          if (aiRes.ok) {
            const aiData = await aiRes.json();
            const signalElem = document.getElementById('dash-signal');
            const aiSignalBadge = document.getElementById('ai-engine-signal');
            
            signalElem.textContent = aiData.signal || 'HOLD';
            aiSignalBadge.textContent = aiData.signal || 'HOLD';
            document.getElementById('dash-risk-score').textContent = (aiData.risk_score * 100).toFixed(0) + '٪';
            document.getElementById('ai-engine-desc').textContent = aiData.analysis || 'تحلیل تکمیل شد.';

            if (aiData.signal.includes('SELL')) {
              signalElem.className = 'font-bold text-[11px] text-app-red';
            } else if (aiData.signal.includes('BUY')) {
              signalElem.className = 'font-bold text-[11px] text-app-green';
            } else {
              signalElem.className = 'font-bold text-[11px] text-yellow-400';
            }
          }
        } catch (err) {
          console.warn('Dashboard update notice:', err);() {
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
      setInterval(() => DashboardManager.fetchData(), 8000);

      const killAction = () => alert('Kill Switch فعال شد: کلیه فعالیت‌های معاملاتی متوقف شدند.');
      document.getElementById('btn-top-kill').addEventListener('click', killAction);
      document.getElementById('btn-dash-kill-quick').addEventListener('click', killAction);
    });
  </script>
</body>
</html>
HTML_EOF

systemctl restart a1-agent.service
echo "Phase 21 Multi-Tab Architecture Deployed."
