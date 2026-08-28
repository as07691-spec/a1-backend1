#!/usr/bin/env bash
# ==============================================================================
# SCRIPT: deploy_phase20_ui.sh
# PURPOSE: Integrate Trading Engine (Phase 19) Endpoints into A1 Mobile-First UI (Phase 20)
# TARGET DIRECTORY: /opt/a1/backend
# AUTHOR: GapGPT (Architecture & QA)
# ==============================================================================

set -euo pipefail

BACKEND_DIR="/opt/a1/backend"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="${BACKEND_DIR}/backups/backup_phase20_${TIMESTAMP}"

echo ">>> [STAGE 1] Creating System Backup..."
mkdir -p "${BACKUP_DIR}"
if [ -f "${BACKEND_DIR}/app/main.py" ]; then
    cp "${BACKEND_DIR}/app/main.py" "${BACKUP_DIR}/main.py.bak"
fi
if [ -d "${BACKEND_DIR}/static" ]; then
    cp -r "${BACKEND_DIR}/static" "${BACKUP_DIR}/static.bak"
fi
echo "Backup created at: ${BACKUP_DIR}"

echo ">>> [STAGE 2] Building Mobile-First Trading UI Module..."
mkdir -p "${BACKEND_DIR}/static"

cat << 'HTML_EOF' > "${BACKEND_DIR}/static/index.html"
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>A1 Studio Pro - Trading Terminal</title>
    <style>
        :root {
            --bg-color: #0b0f19;
            --card-bg: #151d30;
            --accent-color: #2563eb;
            --accent-hover: #1d4ed8;
            --buy-color: #10b981;
            --sell-color: #ef4444;
            --text-color: #f3f4f6;
            --text-muted: #9ca3af;
            --border-color: #2e384d;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        body { background-color: var(--bg-color); color: var(--text-color); padding: 12px; display: flex; justify-content: center; }
        .container { width: 100%; max-width: 480px; display: flex; flex-direction: column; gap: 16px; }
        .header { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; background: var(--card-bg); border-radius: 12px; border: 1px solid var(--border-color); }
        .status-dot { width: 10px; height: 10px; border-radius: 50%; background-color: var(--buy-color); display: inline-block; }
        .nav-tabs { display: flex; background: var(--card-bg); border-radius: 10px; padding: 4px; border: 1px solid var(--border-color); }
        .tab-btn { flex: 1; padding: 10px; border: none; background: transparent; color: var(--text-muted); font-size: 14px; font-weight: bold; cursor: pointer; border-radius: 8px; transition: 0.2s; }
        .tab-btn.active { background: var(--accent-color); color: #fff; }
        .card { background: var(--card-bg); border-radius: 12px; padding: 16px; border: 1px solid var(--border-color); display: flex; flex-direction: column; gap: 12px; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        label { font-size: 13px; color: var(--text-muted); }
        input, select { background: #0f1624; border: 1px solid var(--border-color); border-radius: 8px; padding: 10px; color: #fff; font-size: 14px; outline: none; }
        input:focus, select:focus { border-color: var(--accent-color); }
        .btn-group { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 8px; }
        .btn { padding: 12px; border: none; border-radius: 8px; font-weight: bold; cursor: pointer; font-size: 14px; transition: 0.2s; color: #fff; }
        .btn-buy { background: var(--buy-color); }
        .btn-buy:hover { opacity: 0.9; }
        .btn-sell { background: var(--sell-color); }
        .btn-sell:hover { opacity: 0.9; }
        .order-history { list-style: none; display: flex; flex-direction: column; gap: 8px; max-height: 250px; overflow-y: auto; }
        .order-item { background: #0f1624; padding: 10px 12px; border-radius: 8px; border: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center; font-size: 13px; }
        .badge { padding: 3px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        .badge-buy { background: rgba(16, 185, 129, 0.2); color: var(--buy-color); }
        .badge-sell { background: rgba(239, 68, 68, 0.2); color: var(--sell-color); }
        #response-msg { font-size: 12px; text-align: center; min-height: 16px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div><strong>A1 Studio Pro</strong> <span style="font-size: 12px; color: var(--text-muted);">V20.0</span></div>
            <div><span class="status-dot"></span> <span style="font-size: 12px;">سیستم آماده</span></div>
        </div>

        <div class="nav-tabs">
            <button class="tab-btn active">معاملات</button>
            <button class="tab-btn" onclick="alert('ماژول تحلیل در دسترس است')">تحلیل هوش مصنوعی</button>
            <button class="tab-btn" onclick="alert('ماژول سبد سهام در فاز ۲۱ پیاده‌سازی می‌شود')">پورتفوی</button>
        </div>

        <div class="card">
            <h3>ثبت سفارش جدید</h3>
            <div class="form-group">
                <label for="symbol">نماد معاملاتی</label>
                <input type="text" id="symbol" placeholder="مثال: فولاد" value="فولاد">
            </div>
            <div class="form-group">
                <label for="quantity">تعداد / حجم</label>
                <input type="number" id="quantity" placeholder="تعداد سهم" value="۱۰۰۰">
            </div>
            <div class="form-group">
                <label for="price">قیمت واحد (ریال)</label>
                <input type="number" id="price" placeholder="قیمت" value="۵۰۰۰">
            </div>
            <div class="btn-group">
                <button class="btn btn-buy" onclick="submitOrder('BUY')">ارسال سفارش خرید</button>
                <button class="btn btn-sell" onclick="submitOrder('SELL')">ارسال سفارش فروش</button>
            </div>
            <div id="response-msg"></div>
        </div>

        <div class="card">
            <h3>تاریخچه زنده معاملات</h3>
            <ul class="order-history" id="order-list">
                <li style="text-align: center; color: var(--text-muted); padding: 10px;">در حال بارگذاری...</li>
            </ul>
        </div>
    </div>

    <script>
        const API_BASE = '/api/v1/trade';

        function toPersianDigits(n) {
            const f = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
            return n.toString().replace(/[0-9]/g, function(w) { return f[+w]; });
        }

        async function fetchOrders() {
            try {
                const res = await fetch(`${API_BASE}/orders`);
                const data = await res.json();
                const list = document.getElementById('order-list');
                list.innerHTML = '';
                
                const orders = data.orders || [];
                if (orders.length === 0) {
                    list.innerHTML = '<li style="text-align: center; color: var(--text-muted); padding: 10px;">هیچ سفارشی ثبت نشده است.</li>';
                    return;
                }

                orders.forEach(o => {
                    const isBuy = o.side === 'BUY';
                    const li = document.createElement('li');
                    li.className = 'order-item';
                    li.innerHTML = `
                        <div>
                            <strong>${o.symbol}</strong>
                            <div style="font-size: 11px; color: var(--text-muted);">${toPersianDigits(o.timestamp || '')}</div>
                        </div>
                        <div style="text-align: left;">
                            <span class="badge ${isBuy ? 'badge-buy' : 'badge-sell'}">${isBuy ? 'خرید' : 'فروش'}</span>
                            <div style="margin-top: 4px; font-weight: bold;">${toPersianDigits(o.quantity)} @ ${toPersianDigits(o.price)}</div>
                        </div>
                    `;
                    list.appendChild(li);
                });
            } catch (err) {
                console.error("Order fetch error:", err);
            }
        }

        async function submitOrder(side) {
            const symbol = document.getElementById('symbol').value;
            const quantity = parseInt(document.getElementById('quantity').value, 10);
            const price = parseFloat(document.getElementById('price').value);
            const msgEl = document.getElementById('response-msg');

            if (!symbol || isNaN(quantity) || isNaN(price)) {
                msgEl.style.color = 'var(--sell-color)';
                msgEl.innerText = 'لطفاً تمام فیلدها را به درستی تکمیل نمایید.';
                return;
            }

            msgEl.style.color = 'var(--text-muted)';
            msgEl.innerText = 'در حال ارسال به هسته معاملاتی...';

            try {
                const res = await fetch(`${API_BASE}/order`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ symbol, side, quantity, price })
                });
                
                const result = await res.json();
                if (res.ok) {
                    msgEl.style.color = 'var(--buy-color)';
                    msgEl.innerText = `سفارش با شناسه ${result.order_id || result.id || 'ثبت شده'} با موفقیت انجام شد.`;
                    fetchOrders();
                } else {
                    msgEl.style.color = 'var(--sell-color)';
                    msgEl.innerText = result.detail || 'خطا در ثبت سفارش.';
                }
            } catch (err) {
                msgEl.style.color = 'var(--sell-color)';
                msgEl.innerText = 'خطای شبکه در ارتباط با سرور.';
            }
        }

        fetchOrders();
        setInterval(fetchOrders, 4000);
    </script>
</body>
</html>
HTML_EOF

echo ">>> [STAGE 3] Mounting Static Files in main.py..."
python3 - << 'PY_EOF'
import re

main_path = "/opt/a1/backend/app/main.py"
with open(main_path, "r", encoding="utf-8") as f:
    content = f.read()

# Ensure StaticFiles and FileResponse imports
if "from fastapi.staticfiles import StaticFiles" not in content:
    content = "from fastapi.staticfiles import StaticFiles\nfrom fastapi.responses import FileResponse\n" + content

# Ensure mounting static directory and root index route
static_mount_code = """
# Phase 20: Mobile UI Dashboard Mount
import os
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

@app.get("/", include_in_schema=False)
async def serve_dashboard():
    return FileResponse(os.path.join(static_dir, "index.html"))
"""

if "serve_dashboard" not in content:
    content += "\n" + static_mount_code

with open(main_path, "w", encoding="utf-8") as f:
    f.write(content)

print("[INFO] Static mounts and root route added to main.py")
PY_EOF

echo ">>> [STAGE 4] Validating Python Syntax..."
python3 -m py_compile /opt/a1/backend/app/main.py

echo ">>> [STAGE 5] Restarting a1-agent Service..."
systemctl restart a1-agent.service
sleep 2

echo ">>> [STAGE 6] Verifying Endpoint & Service Status..."
systemctl is-active --quiet a1-agent.service && echo "Service is active and running." || { echo "Service failed!"; exit 1; }

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/)
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "SUCCESS: Dashboard UI is responding at http://127.0.0.1:8000/ (HTTP 200)"
else
    echo "ERROR: Root endpoint returned status code ${HTTP_CODE}"
    exit 1
fi

echo "=============================================================================="
echo " PHASE 20 DEPLOYMENT COMPLETE: Trading Engine successfully integrated with UI."
echo "=============================================================================="
