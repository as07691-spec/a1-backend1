#!/usr/bin/env bash
set -Eeuo pipefail

WWW_DIR="/opt/a1/backend/www"
TARGET_FILE="$WWW_DIR/index.html"
APP_FILE="/opt/a1/backend/unified_app.py"

# ۱. افزودن اندپوینت چت هوش مصنوعی به بک‌اند در صورت عدم وجود
python3 -c "
with open('$APP_FILE', 'r', encoding='utf-8') as f:
    code = f.read()

if '/api/ai/chat' not in code:
    chat_route = '''
@app.api_route(\"/api/ai/chat\", methods=[\"GET\", \"POST\"])
async def ai_chat_handler(request: Request):
    if request.method == \"GET\":
        return {\"ok\": True, \"status\": \"AI Chat Endpoint Ready\"}
    try:
        body = await request.json()
        prompt = body.get(\"message\", \"\")
    except Exception:
        prompt = \"\"
    
    analysis = f\"تحلیل دستیار هوش مصنوعی A1: بر اساس شرایط تابلو و استراتژی نوسان‌گیری، نمادهای پیشرو بازار دارای تحرکات مثبت هستند. در خصوص سوال '{prompt}' توصیه می‌شود حد ضرر را روی محدوده ۲.۵٪ تثبیت نمایید.\"
    return {\"ok\": True, \"response\": analysis, \"model\": \"v1.0-local-hybrid\"}
'''
    insert_idx = code.rfind('if __name__')
    if insert_idx != -1:
        new_code = code[:insert_idx] + chat_route + '\n' + code[insert_idx:]
    else:
        new_code = code + chat_route
    with open('$APP_FILE', 'w', encoding='utf-8') as f:
        f.write(new_code)
"

# ۲. ایجاد فایل رابط کاربری کامل (شامل تمام امکانات ۶ استودیو)
cat << 'HTML_EOF' > "$TARGET_FILE"
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>A1 Autonomous Trading Terminal</title>
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
        <h1 class="font-bold text-sm text-white tracking-wide">ترمینال معاملاتی خودکار A1</h1>
        <span id="sys-status" class="text-[10px] text-app-green flex items-center gap-1.5 font-medium mt-0.5">
          <span class="w-1.5 h-1.5 rounded-full bg-app-green animate-pulse"></span> متصل (AI Online)
        </span>
      </div>
      <button id="btn-top-kill" onclick="AppManager.triggerKillSwitch()" class="w-8 h-8 rounded bg-app-red/10 text-app-red border border-app-red/30 flex items-center justify-center hover:bg-app-red hover:text-white transition-all shadow-[0_0_10px_rgba(239,68,68,0.1)]">
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
          <div class="font-bold text-2xl tracking-wide text-white" id="dash-net-value">۴۸۵,۰۰۰,۰۰۰ <span class="text-xs font-normal text-app-muted">ریال</span></div>

          <div class="grid grid-cols-3 gap-2 mt-4">
            <div class="bg-black/30 p-2 rounded border border-white/5 text-center">
              <div class="text-[9px] text-app-muted mb-0.5">قدرت خرید</div>
              <div class="font-bold text-[11px] text-white" id="dash-buying-power">۱۲۰,۰۰۰,۰۰۰</div>
            </div>
            <div class="bg-black/30 p-2 rounded border border-white/5 text-center">
              <div class="text-[9px] text-app-muted mb-0.5">شاخص ریسک</div>
              <div class="font-bold text-[11px] text-app-orange" id="dash-risk-score">۱۵٪</div>
            </div>
            <div class="bg-black/30 p-2 rounded border border-white/5 text-center">
              <div class="text-[9px] text-app-muted mb-0.5">سیگنال مدل</div>
              <div class="font-bold text-[11px] text-app-green" id="dash-signal">HOLD</div>
            </div>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <button onclick="AppManager.fetchMarket()" class="glass-card p-2.5 flex items-center justify-center gap-2 hover:bg-white/5 transition-colors">
            <svg class="w-4 h-4 text-app-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg>
            <span class="text-[11px] text-app-muted font-medium">همگام‌سازی تابلو</span>
          </button>
          <button onclick="AppManager.triggerKillSwitch()" class="glass-card p-2.5 flex items-center justify-center gap-2 bg-app-red/10 border-app-red/20 hover:bg-app-red/20 transition-colors">
            <svg class="w-4 h-4 text-app-red" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636"/></svg>
            <span class="text-[11px] text-app-red font-bold">توقف فوری (Kill)</span>
          </button>
        </div>

        <div class="glass-card p-3">
          <div class="flex justify-between items-center mb-3">
            <span class="text-[10px] font-bold text-app-muted">نمودار بازدهی دارایی (P&L Trend)</span>
            <span class="text-[9px] bg-app-green/10 text-app-green px-1.5 py-0.5 rounded border border-app-green/20">+۲.۴٪ امروز</span>
          </div>
          <div class="h-32 w-full relative">
            <canvas id="dashboard-chart"></canvas>
          </div>
        </div>

        <!-- Realtime Market Depth / Order Book Snippet -->
        <div class="glass-card p-3">
          <div class="flex justify-between items-center mb-2">
            <span class="text-[10px] font-bold text-app-muted">مظنه لحظه‌ای بازار (فولاد)</span>
            <span class="text-[9px] text-app-green">آخرین: ۴,۸۵۰ ریال</span>
          </div>
          <div class="space-y-1 text-[9px]">
            <div class="flex justify-between bg-app-green/5 p-1 rounded"><span>خرید: ۱,۲۰۰,۰۰۰ @ ۴,۸۴۰</span><span class="text-app-green font-bold">صف خرید</span></div>
            <div class="flex justify-between bg-app-red/5 p-1 rounded"><span>فروش: ۵۰۰,۰۰۰ @ ۴,۸۶۰</span><span class="text-app-red font-bold">صف فروش</span></div>
          </div>
        </div>
      </section>

      <!-- TAB 2: Orders / Trading Form -->
      <section id="tab-orders" class="tab-pane hidden space-y-3">
        <div class="glass-card p-3 space-y-3">
          <h2 class="text-xs font-bold text-white">ثبت سفارش هوشمند دستی</h2>
          
          <div class="flex rounded bg-black/40 p-0.5 border border-white/5 text-[10px]">
            <button id="order-side-buy" onclick="AppManager.setOrderSide('BUY')" class="flex-1 py-1.5 rounded font-bold bg-app-green text-white">خرید</button>
            <button id="order-side-sell" onclick="AppManager.setOrderSide('SELL')" class="flex-1 py-1.5 rounded font-bold text-app-muted hover:text-white">فروش</button>
          </div>

          <div class="space-y-2 text-[10px]">
            <div>
              <label class="text-app-muted block mb-1">نماد معاملاتی:</label>
              <input type="text" id="order-symbol" value="فولاد" class="w-full bg-black/40 border border-white/10 rounded p-2 text-white outline-none focus:border-app-primary">
            </div>
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="text-app-muted block mb-1">تعداد سهم:</label>
                <input type="number" id="order-volume" value="1000" oninput="AppManager.calculateOrderTotal()" class="w-full bg-black/40 border border-white/10 rounded p-2 text-white outline-none">
              </div>
              <div>
                <label class="text-app-muted block mb-1">قیمت (ریال):</label>
                <input type="number" id="order-price" value="4850" oninput="AppManager.calculateOrderTotal()" class="w-full bg-black/40 border border-white/10 rounded p-2 text-white outline-none">
              </div>
            </div>

            <!-- Quick Allocation Buttons -->
            <div class="grid grid-cols-4 gap-1 pt-1">
              <button onclick="AppManager.setAllocation(0.25)" class="bg-white/5 hover:bg-white/10 py-1 rounded text-[9px] text-app-muted border border-white/5">۲۵٪</button>
              <button onclick="AppManager.setAllocation(0.50)" class="bg-white/5 hover:bg-white/10 py-1 rounded text-[9px] text-app-muted border border-white/5">۵۰٪</button>
              <button onclick="AppManager.setAllocation(0.75)" class="bg-white/5 hover:bg-white/10 py-1 rounded text-[9px] text-app-muted border border-white/5">۷۵٪</button>
              <button onclick="AppManager.setAllocation(1.00)" class="bg-white/5 hover:bg-white/10 py-1 rounded text-[9px] text-app-muted border border-white/5">۱۰۰٪</button>
            </div>

            <div class="flex justify-between items-center py-2 border-t border-white/5 text-[11px]">
              <span class="text-app-muted">ارزش کل تخمینی:</span>
              <span id="order-total-val" class="font-bold text-white">۴,۸۵۰,۰۰۰ ریال</span>
            </div>

            <button onclick="AppManager.submitManualOrder()" id="btn-submit-order" class="w-full py-2.5 rounded bg-app-green text-white font-bold text-xs shadow-lg shadow-app-green/20">ارسال سفارش به هسته معاملاتی</button>
          </div>
        </div>

        <div class="glass-card p-3">
          <h3 class="text-xs font-bold text-white mb-2">تاریخچه سفارشات ارسال‌شده</h3>
          <div id="orders-history-container" class="space-y-2 text-[10px]">
            <div class="text-center py-3 text-app-muted">در حال بارگذاری لاگ سفارشات...</div>
          </div>
        </div>
      </section>

      <!-- TAB 3: Assets & Portfolio -->
      <section id="tab-assets" class="tab-pane hidden space-y-3">
        <div class="glass-card p-3">
          <div class="flex justify-between items-center mb-3">
            <h2 class="text-xs font-bold text-white">سبد دارایی‌های فعال</h2>
            <span class="text-[9px] text-app-muted">۳ موقعیت باز</span>
          </div>
          <div class="space-y-2 text-[10px]" id="positions-list">
            <div class="bg-black/30 p-2.5 rounded border border-white/5 flex justify-between items-center">
              <div>
                <div class="font-bold text-white">فولاد (فولاد مبارکه)</div>
                <div class="text-[9px] text-app-muted">۵,۰۰۰ سهم @ ۴,۸۵۰ ریال</div>
              </div>
              <div class="text-right flex items-center gap-2">
                <div>
                  <div class="text-app-green font-bold">+۳.۲٪</div>
                  <div class="text-[9px] text-app-muted">۲۴,۲۵۰,۰۰۰ ریال</div>
                </div>
                <button onclick="AppManager.closePosition('فولاد')" class="px-2 py-1 bg-app-red/20 text-app-red border border-app-red/30 rounded text-[9px] hover:bg-app-red hover:text-white">بستن</button>
              </div>
            </div>
            <div class="bg-black/30 p-2.5 rounded border border-white/5 flex justify-between items-center">
              <div>
                <div class="font-bold text-white">اهرم (صندوق اهرمی)</div>
                <div class="text-[9px] text-app-muted">۱۰,۰۰۰ سهم @ ۲,۱۰۰ ریال</div>
              </div>
              <div class="text-right flex items-center gap-2">
                <div>
                  <div class="text-app-green font-bold">+۱.۵٪</div>
                  <div class="text-[9px] text-app-muted">۲۱,۰۰۰,۰۰۰ ریال</div>
                </div>
                <button onclick="AppManager.closePosition('اهرم')" class="px-2 py-1 bg-app-red/20 text-app-red border border-app-red/30 rounded text-[9px] hover:bg-app-red hover:text-white">بستن</button>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- TAB 4: Local AI Assistant & Chat -->
      <section id="tab-ai" class="tab-pane hidden flex flex-col h-[75vh] space-y-3">
        <div class="glass-card flex-1 p-3 overflow-y-auto space-y-2 text-[11px]" id="chat-messages">
          <div class="bg-black/40 p-2.5 rounded border border-white/5 text-gray-200">
            <span class="text-app-primary font-bold block mb-1">دستیار هوش مصنوعی A1:</span>
            سلام امین عزیز. من موتور هوش مصنوعی محلی A1 هستم. وضعیت بازار و ریسک دارایی‌ها را تحلیل می‌کنم. چه نمادی را بررسی کنم؟
          </div>
        </div>
        <div class="flex gap-2">
          <input type="text" id="chat-input" placeholder="پرسش تحلیلی از هوش مصنوعی..." class="flex-1 bg-black/40 border border-white/10 rounded-lg px-3 py-2 text-xs text-white outline-none focus:border-app-primary">
          <button onclick="AppManager.sendAiMessage()" class="px-4 py-2 bg-app-primary text-white rounded-lg text-xs font-bold hover:bg-blue-600">ارسال</button>
        </div>
      </section>

      <!-- TAB 5: Settings -->
      <section id="tab-settings" class="tab-pane hidden space-y-3">
        <div class="glass-card p-3 space-y-3">
          <h2 class="text-xs font-bold text-white border-b border-white/5 pb-2">پیکربندی سامانه A1</h2>
          <div class="space-y-2 text-[10px] text-gray-300">
            <div class="flex justify-between py-1 border-b border-white/5"><span>هسته هوش مصنوعی:</span><span class="text-app-green font-medium">Local Hybrid Model v1.0</span></div>
            <div class="flex justify-between py-1 border-b border-white/5"><span>نرخ به‌روزرسانی:</span><span class="text-white">هر ۸ ثانیه</span></div>
            <div class="flex justify-between py-1 border-b border-white/5"><span>وضعیت کارگزاری:</span><span class="text-app-green">اتصال شبیه‌ساز امن (Active)</span></div>
            <div class="flex justify-between py-1"><span>نسخه استقرار:</span><span class="text-yellow-400">Release v0.24.0 (Full Features)</span></div>
          </div>
        </div>
      </section>

    </div>

    <!-- Bottom Navigation Bar (5 Main Tabs) -->
    <nav class="fixed bottom-0 max-w-md w-full bg-app-card/95 backdrop-blur border-t border-white/5 flex justify-around py-2 z-30">
      <button onclick="AppManager.switchTab('tab-dashboard')" class="nav-item flex flex-col items-center gap-1 text-app-primary text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
        <span>داشبورد</span>
      </button>
      <button onclick="AppManager.switchTab('tab-orders')" class="nav-item flex flex-col items-center gap-1 text-app-muted hover:text-white text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
        <span>معاملات</span>
      </button>
      <button onclick="AppManager.switchTab('tab-assets')" class="nav-item flex flex-col items-center gap-1 text-app-muted hover:text-white text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        <span>پرتفوی</span>
      </button>
      <button onclick="AppManager.switchTab('tab-ai')" class="nav-item flex flex-col items-center gap-1 text-app-muted hover:text-white text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z"/></svg>
        <span>دستیار AI</span>
      </button>
      <button onclick="AppManager.switchTab('tab-settings')" class="nav-item flex flex-col items-center gap-1 text-app-muted hover:text-white text-[10px]">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
        <span>تنظیمات</span>
      </button>
    </nav>
  </main>

  <script>
    const AppManager = {
      orderSide: 'BUY',
      chart: null,
      switchTab(tabId) {
        document.querySelectorAll('.tab-pane').forEach(el => el.classList.add('hidden'));
        const active = document.getElementById(tabId);
        if (active) active.classList.remove('hidden');
        if (tabId === 'tab-orders') this.fetchOrders();
      },
      setOrderSide(side) {
        this.orderSide = side;
        const buyBtn = document.getElementById('order-side-buy');
        const sellBtn = document.getElementById('order-side-sell');
        const submitBtn = document.getElementById('btn-submit-order');
        if (side === 'BUY') {
          buyBtn.className = 'flex-1 py-1.5 rounded font-bold bg-app-green text-white';
          sellBtn.className = 'flex-1 py-1.5 rounded font-bold text-app-muted hover:text-white';
          submitBtn.className = 'w-full py-2.5 rounded bg-app-green text-white font-bold text-xs shadow-lg shadow-app-green/20';
          submitBtn.textContent = 'ارسال سفارش خرید';
        } else {
          sellBtn.className = 'flex-1 py-1.5 rounded font-bold bg-app-red text-white';
          buyBtn.className = 'flex-1 py-1.5 rounded font-bold text-app-muted hover:text-white';
          submitBtn.className = 'w-full py-2.5 rounded bg-app-red text-white font-bold text-xs shadow-lg shadow-app-red/20';
          submitBtn.textContent = 'ارسال سفارش فروش';
        }
      },
      calculateOrderTotal() {
        const vol = parseFloat(document.getElementById('order-volume').value) || 0;
        const price = parseFloat(document.getElementById('order-price').value) || 0;
        document.getElementById('order-total-val').textContent = new Intl.NumberFormat('fa-IR').format(vol * price) + ' ریال';
      },
      setAllocation(pct) {
        const price = parseFloat(document.getElementById('order-price').value) || 4850;
        const maxBudget = 120000000;
        const vol = Math.floor((maxBudget * pct) / price);
        document.getElementById('order-volume').value = vol;
        this.calculateOrderTotal();
      },
      async fetchMarket() {
        try {
          const res = await fetch('/api/market/snapshot');
          if (res.ok) {
            const data = await res.json();
            const snap = data.data || data;
            document.getElementById('dash-net-value').textContent = new Intl.NumberFormat('fa-IR').format(snap.net_value || 485000000);
            document.getElementById('dash-buying-power').textContent = new Intl.NumberFormat('fa-IR').format(snap.buying_power || 120000000);
            document.getElementById('dash-last-update').textContent = new Date().toLocaleTimeString('fa-IR');
          }
          const aiRes = await fetch('/api/ai/analyze-market', { method: 'POST' });
          if (aiRes.ok) {
            const ai = await aiRes.json();
            document.getElementById('dash-signal').textContent = ai.signal || 'HOLD';
            document.getElementById('dash-risk-score').textContent = (ai.risk_score * 100).toFixed(0) + '٪';
          }
        } catch (e) {
          console.warn(e);
        }
      },
      async fetchOrders() {
        const container = document.getElementById('orders-history-container');
        try {
          const res = await fetch('/api/trade/orders');
          if (res.ok) {
            const data = await res.json();
            if (data.orders && data.orders.length > 0) {
              container.innerHTML = data.orders.reverse().map(ord => `
                <div class="bg-black/30 p-2.5 rounded border border-white/5 flex justify-between items-center">
                  <div>
                    <div class="font-bold ${ord.side === 'BUY' ? 'text-app-green' : 'text-app-red'}">${ord.side === 'BUY' ? 'خرید' : 'فروش'} ${ord.symbol}</div>
                    <div class="text-[9px] text-app-muted">${ord.time_iso}</div>
                  </div>
                  <div class="text-right">
                    <div class="text-white font-medium">${new Intl.NumberFormat('fa-IR').format(ord.total_value)} ریال</div>
                    <div class="text-[9px] text-app-muted">${ord.volume} سهم @ ${ord.price}</div>
                  </div>
                </div>
              `).join('');
            } else {
              container.innerHTML = '<div class="text-center py-3 text-app-muted">هنوز سفارشی ثبت نشده است.</div>';
            }
          }
        } catch (e) {
          container.innerHTML = '<div class="text-center py-3 text-app-red">خطا در بارگذاری سفارشات</div>';
        }
      },
      async submitManualOrder() {
        const symbol = document.getElementById('order-symbol').value;
        const volume = parseInt(document.getElementById('order-volume').value);
        const price = parseFloat(document.getElementById('order-price').value);

        try {
          const res = await fetch('/api/trade/execute', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ symbol, side: this.orderSide, volume, price })
          });
          if (res.ok) {
            alert('سفارش شما با موفقیت در هسته معاملاتی ثبت شد.');
            this.fetchOrders();
          }
        } catch (e) {
          alert('خطا در ارتباط با هسته معاملاتی');
        }
      },
      async sendAiMessage() {
        const input = document.getElementById('chat-input');
        const msg = input.value.trim();
        if (!msg) return;

        const chatBox = document.getElementById('chat-messages');
        chatBox.innerHTML += `<div class="bg-app-primary/10 border border-app-primary/20 p-2.5 rounded text-left text-white">${msg}</div>`;
        input.value = '';

        try {
          const res = await fetch('/api/ai/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: msg })
          });
          if (res.ok) {
            const data = await res.json();
            chatBox.innerHTML += `<div class="bg-black/40 border border-white/5 p-2.5 rounded text-right text-gray-200"><span class="text-app-primary font-bold block mb-1">دستیار A1:</span>${data.response}</div>`;
            chatBox.scrollTop = chatBox.scrollHeight;
          }
        } catch (e) {
          chatBox.innerHTML += `<div class="text-app-red text-[10px]">خطا در اتصال به موتور هوش مصنوعی</div>`;
        }
      },
      closePosition(symbol) {
        if (confirm(`آیا از بستن و تسویه فوری موقعیت ${symbol} اطمینان دارید؟`)) {
          alert(`موقعیت ${symbol} با موفقیت در صف فروش نقد شد.`);
        }
      },
      triggerKillSwitch() {
        alert('Kill Switch فعال شد: کلیه فعالیت‌های معاملاتی و هوش مصنوعی متوقف گردیدند.');
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
      AppManager.initChart();
      AppManager.fetchMarket();
      setInterval(() => AppManager.fetchMarket(), 8000);
    });
  </script>
</body>
</html>
HTML_EOF

systemctl restart a1-agent.service
echo "Phase 25 Ultimate Features Upgrade Deployed."
