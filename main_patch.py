from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import os

# این کد باید در فایل اصلی main.py شما ادغام شود
# فرض بر این است که اپلیکیشن شما 'app' نام دارد

@app.get("/")
async def read_index():
    # مسیر فایل index.html را بر اساس خروجی مرحله قبل تنظیم کنید
    return FileResponse('/opt/a1/backend/static/index.html')

# برای سِرو کردن بقیه فایل‌ها (CSS/JS)
if os.path.exists('/opt/a1/backend/static'):
    app.mount("/static", StaticFiles(directory="/opt/a1/backend/static"), name="static")
