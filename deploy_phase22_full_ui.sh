#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: deploy_phase22_full_ui.sh
# PURPOSE: Connect Portfolio, Risk Engine, and Order Management into Mobile-First UI (Phase 22)
# TARGET DIRECTORY: /opt/a1/backend
# ARCHITECTURE ROLE: GapGPT (Architecture, QA & Contracts)
# ==============================================================================

set -euo pipefail

BACKEND_DIR="/opt/a1/backend"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKEND_DIR}/backups/backup_phase22_${TIMESTAMP}"

echo ">>> [STAGE 1] Creating Stage 22 Backup..."
mkdir -p "${BACKUP_DIR}"
if [ -f "${BACKEND_DIR}/static/index.html" ]; then
    cp "${BACKEND_DIR}/static/index.html" "${BACKUP_DIR}/index.html.bak"
fi
echo "Backup saved to: ${BACKUP_DIR}"

echo ">>> [STAGE 2] Deploying Comprehensive Multi-Tab UI..."
cat << 'HTML_EOF' > "${BACKEND_DIR}/static/index.html"
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>A1 Studio Pro - Trading & Risk Terminal</title>
    <style>
        :root {
            --bg-color: #0b0f19;
            --card-bg: #151d30;
            --card-sub: #0f1624;
            --accent-color: #2563eb;
            --accent-hover: #1d4ed8;
            --buy-color: #10b981;
            --sell-color: #ef4444;
            --warning-color: #f59e0b;
            --text-color: #f3f4f6;
            --text-muted: #9ca3af;
            --border-color: #2e384d;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background-color: var(--bg-color); color: var(--text-color); padding: 12px; display: flex; justify-content: center; min-height: 100vh; }
        .container { width: 100%; max-width: 520px; display: flex; flex-direction: column; gap: 14px; }
        
        .header { display: flex; justify-content: space-between; align-items: center; padding: 14px 16px; background: var(--card-bg); border-radius: 12px; border: 1px solid var(--border-color); }
        .status-badge { display: flex; align-items: center; gap: 6px; font-size: 12px; font-weight: bold; color: var(--buy-color); }
        .status-dot { width: 8px; height: 8px; border-radius: 50%; background-color: var(--buy-color); box-shadow: 0 0 8px var(--buy-color); }

        .nav-tabs { display: flex; background: var(--card-bg); border-radius: 10px; padding: 4px; border: 1px solid var(--border-color); gap: 4px; }
        .tab-btn { flex: 1; padding: 10px 4px; border: none; background: transparent; color: var(--text-muted); font-size: 13px; font-weight: bold; cursor: pointer; border-radius: 8px; transition: 0.2s; text-align: center; }
        .tab-btn.active { background: var(--accent-color); color: #fff; }

        .tab-content { display: none; flex-direction: column; gap: 14px; }
        .tab-content.active { display: flex; }

        .card { background: var(--card-bg); border-radius: 12px; padding: 16px; border: 1px solid var(--border-color); display: flex; flex-direction: column; gap: 12px; }
        .card-title { font-size: 15px; font-weight: bold; display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 8px; }

        .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .stat-box { background: var(--card-sub); padding: 10px 12px; border-radius: 8px; border: 1px solid var(--border-color); }
        .stat-label { font-size: 11px; color: var(--text-muted); }
        .stat-value { font-size: 14px; font-weight: bold; margin-top: 4px; }
        .stat-green { color: var(--buy-color); }
        .stat-red { color: var(--sell-color); }

        .form-group { display: flex; flex-direction: column; gap: 6px; }
        label { font-size: 12px; color: var(--text-muted); }
        input, select { background: var(--card-sub); border: 1px solid var(--border-color); border-radius: 8px; padding: 10px; color: #fff; font-size: 14px; outline: none; }
        input:focus { border-color: var(--accent-color); }
        
        .btn-group { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 6px; }
        .btn { padding: 12px; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 14px; transition: 0.2s; color: #fff; }
        .btn-buy { background: var(--buy-color); }
        .btn-buy:hover { opacity: 0.9; }
        .btn-sell { background: var(--sell-color); }
        .btn-sell:hover { opacity: 0.9; }

        .item-list { list-style: none; display: flex; flex-direction: column; gap: 8px; max-height: 280px; overflow-y: auto; }
        .item-card { background: var(--card-sub); padding: 10px 12px; border-radius: 8px; border: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; font-size: 13px; }
        .badge { padding: 3px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        .badge-buy { background: rgba(16, 185, 129, 0.2); color: var(--buy-color); }
        .badge-sell { background: rgba(239, 68, 68, 0.2); color: var(--sell-color); }
        .badge-risk-ok { background: rgba(16, 185, 129, 0.2); color: var(--buy-color); }
        .badge-risk-err { background: rgba(239, 68, 68, 0.2); color: var(--sell-color); }

        #response-msg { font-size: 12px; text-align: center; min-height: 18px; line-height: 1.4; }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <div>
                <strong>A1 Studio Pro</strong>
                <span style="font-size: 11px; color: var(--text-muted); margin-right: 4px;">فاز ۲۲</span>
            </div>
            <div class="status-badge">
                <span class="status-dot"></span>
                <span>سرویس فعال</span>
            </div>
        </div>

        <!-- Navigation Tabs -->
        <div class="nav-tabs">
            <button class="tab-btn active" onclick="switchTab('tab-trade')">معاملات</button>
            <button class="tab-btn" onclick="switchTab('tab-portfolio')">پورتفوی و سود/زیان</button>
            <button class="tab-btn" onclick="switchTab('tab-risk')">ارزیابی ریسک</button>
        </div>

        <!-- TAB 1: TRADING ENGINE -->
        <div id="tab-trade" class="tab-content active">
            <div class="card">
                <div class="card-title">ثبت سفارش پیشرفته</div>
                <div class="form-group">
                    <label for="symbol">نماد معاملاتی</label>
                    <input type="text" id="symbol" placeholder="مثال: فولاد" value="فولاد">
                </div>
                <div class="grid-2">
                    <div class="form-group">
                        <label for="quantity">حجم / تعداد</label>
                        <input type="number" id="quantity" placeholder="تعداد" value="1000">
                    </div>
                    <div class="form-group">
                        <label for="price">قیمت واحد (ریال)</label>
                        <input type="number" id="price" placeholder="قیمت" value="5000">
                    </div>
                </div>
                <div class="btn-group">
                    <button class="btn btn-buy" onclick="submitOrder('BUY')">ثبت سفارش خرید</button>
                    <button class="btn btn-sell" onclick="submitOrder('SELL')">ثبت سفارش فروش</button>
                </div>
                <div id="response-msg"></div>
            </div>

            <div class="card">
                <div class="card-title">
                    <span>تاریخچه زنده معاملات</span>
                    <span style="font-size: 11px; color: var(--text-muted);">به‌روزرسانی خودکار</span>
                </div>
                <ul class="item-list" id="order-list">
                    <li style="text-align: center; color: var(--text-muted); padding: 10px;">در حال بارگذاری...</li>
                </ul>
            </div>
        </div>

        <!-- TAB 2: PORTFOLIO ENGINE -->
        <div id="tab-portfolio" class="tab-content">
            <div class="card">
                <div class="card-title">خلاصه وضعیت دارایی</div>
                <div class="grid-2">
                    <div class="stat-box">
                        <div class="stat-label">ارزش کل پورتفوی</div>
                        <div class="stat-value" id="port-total-val">---</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">مانده نقدینگی</div>
                        <div class="stat-value" id="port-cash">---</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">سود/زیان کل</div>
                        <div class="stat-value" id="port-pnl">---</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-label">درصد بازدهی</div>
                        <div class="stat-value" id="port-return">---</div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-title">موقعیت‌های باز (Positions)</div>
                <ul class="item-list" id="positions-list">
                    <li style="text-align: center; color: var(--text-muted); padding: 10px;">در حال بارگذاری موقعیت‌ها...</li>
                </ul>
            </div>
        </div>

        <!-- TAB 3: RISK ENGINE -->
        <div id="tab-risk" class="tab-content">
            <div class="card">
                <div class="card-title">تست پیش از معامله ریسک (Pre-Trade Check)</div>
                <div class="form-group">
                    <label for="risk-symbol">نماد</label>
                    <input type="text" id="risk-symbol" value="فولاد">
                </div>
                <div class="grid-2">
                    <div class="form-group">
                        <label for="risk-quantity">تعداد سهم</label>
                        <input type="number" id="risk-quantity" value="20000">
                    </div>
                    <div class="form-group">
                        <label for="risk-price">قیمت پیشنهادی (ریال)</label>
                        <input type="number" id="risk-price" value="5500">
                    </div>
                </div>
                <button class="btn" style="background: var(--accent-color); margin-top: 6px;" onclick="checkRisk()">ارزیابی ریسک سفارش</button>
                <div id="risk-result" style="margin-top: 8px;"></div>
            </div>
        </div>
    </div>

    <script>
        function toPersianDigits(n) {
            if (n === null || n === undefined) return '';
            const f = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
            return n.toString().replace(/[0-9]/g, w => f[+w]);
        }

        function formatCurrency(val) {
            if (val === null || val === undefined || isNaN(val)) return '۰';
            return toPersianDigits(Number(val).toLocaleString('fa-IR'));
        }

        function switchTab(tabId) {
            document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
            
            document.getElementById(tabId).classList.add('active');
            event.currentTarget.classList.add('active');

            if (tabId === 'tab-portfolio') {
                fetchPortfolio();
            }
        }

        // ================= TRADING TAB =================
        async function fetchOrders() {
            try {
                const res = await fetch('/api/v1/trade/orders');
                const data = await res.json();
                const list = document.getElementById('order-list');
                const orders = data.orders || [];

                if (orders.length === 0) {
                    list.innerHTML = '<li style="text-align: center; color: var(--text-muted); padding: 10px;">هیچ سفارشی ثبت نشده است.</li>';
                    return;
                }

                list.innerHTML = orders.map(o => {
                    const isBuy = o.side === 'BUY';
                    return `
                        <li class="item-card">
                            <div>
                                <strong>${o.symbol}</strong>
                                <div style="font-size: 11px; color: var(--text-muted);">${toPersianDigits(o.timestamp || '')}</div>
                            </div>
                            <div style="text-align: left;">
                                <span class="badge ${isBuy ? 'badge-buy' : 'badge-sell'}">${isBuy ? 'خرید' : 'فروش'}</span>
                                <div style="margin-top: 4px; font-weight: bold;">${formatCurrency(o.quantity)} @ ${formatCurrency(o.price)}</div>
                            </div>
                        </li>
                    `;
                }).join('');
            } catch (err) {
                console.error("Order fetch error:", err);
            }
        }

        async function submitOrder(side) {
            const symbol = document.getElementById('symbol').value.trim();
            const quantity = parseInt(document.getElementById('quantity').value, 10);
            const price = parseFloat(document.getElementById('price').value);
            const msgEl = document.getElementById('response-msg');

            if (!symbol || isNaN(quantity) || isNaN(price)) {
                msgEl.style.color = 'var(--sell-color)';
                msgEl.innerText = 'لطفاً فیلدها را با مقادیر معتبر پر کنید.';
                return;
            }

            msgEl.style.color = 'var(--text-muted)';
            msgEl.innerText = 'در حال ارسال و ارزیابی سفارش...';

            try {
                const res = await fetch('/api/v1/trade/order', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ symbol, side, quantity, price })
                });

                const data = await res.json();
                if (res.ok) {
                    msgEl.style.color = 'var(--buy-color)';
                    msgEl.innerText = `سفارش ${side === 'BUY' ? 'خرید' : 'فروش'} با شناسه ${data.order_id || 'موفق'} ثبت شد.`;
                    fetchOrders();
                } else {
                    msgEl.style.color = 'var(--sell-color)';
                    msgEl.innerText = data.detail || 'خطا در ثبت سفارش.';
                }
            } catch (err) {
                msgEl.style.color = 'var(--sell-color)';
                msgEl.innerText = 'خطای اتصال به سرور backend.';
            }
        }

        // ================= PORTFOLIO TAB =================
        async function fetchPortfolio() {
            try {
                const [sumRes, posRes] = await Promise.all([
                    fetch('/api/v1/portfolio/summary'),
                    fetch('/api/v1/portfolio/positions')
                ]);

                if (sumRes.ok) {
                    const sum = await sumRes.json();
                    document.getElementById('port-total-val').innerText = formatCurrency(sum.total_value) + ' ریال';
                    document.getElementById('port-cash').innerText = formatCurrency(sum.cash_balance) + ' ریال';
                    
                    const pnlEl = document.getElementById('port-pnl');
                    pnlEl.innerText = formatCurrency(sum.total_unrealized_pnl) + ' ریال';
                    pnlEl.className = 'stat-value ' + (sum.total_unrealized_pnl >= 0 ? 'stat-green' : 'stat-red');

                    const retEl = document.getElementById('port-return');
                    retEl.innerText = toPersianDigits(sum.total_return_pct) + ' ٪';
                    retEl.className = 'stat-value ' + (sum.total_return_pct >= 0 ? 'stat-green' : 'stat-red');
                }

                if (posRes.ok) {
                    const posData = await posRes.json();
                    const list = document.getElementById('positions-list');
                    const positions = posData.positions || [];

                    if (positions.length === 0) {
                        list.innerHTML = '<li style="text-align: center; color: var(--text-muted); padding: 10px;">هیچ موقعیت بازی وجود ندارد.</li>';
                        return;
                    }

                    list.innerHTML = positions.map(p => {
                        const isProfit = p.unrealized_pnl >= 0;
                        return `
                            <li class="item-card">
                                <div>
                                    <strong>${p.symbol}</strong>
                                    <div style="font-size: 11px; color: var(--text-muted);">
                                        تعداد: ${formatCurrency(p.quantity)} | خرید: ${formatCurrency(p.average_buy_price)}
                                    </div>
                                </div>
                                <div style="text-align: left;">
                                    <div style="font-weight: bold; color: ${isProfit ? 'var(--buy-color)' : 'var(--sell-color)'};">
                                        ${formatCurrency(p.unrealized_pnl)} (${toPersianDigits(p.pnl_percentage)}٪)
                                    </div>
                                    <div style="font-size: 11px; color: var(--text-muted);">قیمت روز: ${formatCurrency(p.current_price)}</div>
                                </div>
                            </li>
                        `;
                    }).join('');
                }
            } catch (err) {
                console.error("Portfolio fetch error:", err);
            }
        }

        // ================= RISK TAB =================
        async function checkRisk() {
            const symbol = document.getElementById('risk-symbol').value.trim();
            const quantity = parseInt(document.getElementById('risk-quantity').value, 10);
            const price = parseFloat(document.getElementById('risk-price').value);
            const resultEl = document.getElementById('risk-result');

            resultEl.innerHTML = '<div style="font-size: 12px; color: var(--text-muted); text-align: center;">در حال اعتبارسنجی ریسک...</div>';

            try {
                const res = await fetch('/api/v1/risk/check-order', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ symbol, side: "BUY", quantity, price })
                });

                const data = await res.json();
                const badgeClass = data.passed ? 'badge-risk-ok' : 'badge-risk-err';
                const statusText = data.passed ? 'تأیید شده (مجاز)' : 'رد شده (غیرمجاز)';

                resultEl.innerHTML = `
                    <div style="background: var(--card-sub); padding: 10px; border-radius: 8px; border: 1px solid var(--border-color); font-size: 12px;">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                            <span>وضعیت سفارش:</span>
                            <span class="badge ${badgeClass}">${statusText}</span>
                        </div>
                        <div>امتیاز ریسک (Score): <strong>${toPersianDigits(data.risk_score)} / ۱۰۰</strong></div>
                        <div>ارزش سفارش: <strong>${formatCurrency(data.order_value)} ریال</strong></div>
                        ${data.reasons && data.reasons.length > 0 ? `<div style="color: var(--sell-color); margin-top: 6px;">دلایل: ${data.reasons.join(', ')}</div>` : ''}
                    </div>
                `;
            } catch (err) {
                resultEl.innerHTML = '<div style="font-size: 12px; color: var(--sell-color); text-align: center;">خطا در دریافت نتیجه ریسک.</div>';
            }
        }

        // Init
        fetchOrders();
        fetchPortfolio();
        setInterval(fetchOrders, 4000);
    </script>
</body>
</html>
HTML_EOF

echo ">>> [STAGE 3] Restarting a1-agent Service..."
systemctl restart a1-agent.service
sleep 2

echo ">>> [STAGE 4] Verifying HTTP Endpoints..."
systemctl is-active --quiet a1-agent.service && echo "Service status: active (running)" || { echo "Service failed!"; exit 1; }

UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)
if [ "$UI_STATUS" -eq 200 ]; then
    echo "SUCCESS: A1 Dashboard UI (Phase 22) online at http://127.0.0.1:8000/ (HTTP 200)"
else
    echo "ERROR: UI check returned HTTP $UI_STATUS"
    exit 1
fi

echo "=============================================================================="
echo " PHASE 22 DEPLOYMENT COMPLETE: Multi-tab UI with Portfolio & Risk connected."
echo "=============================================================================="
