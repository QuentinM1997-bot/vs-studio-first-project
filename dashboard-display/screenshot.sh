#!/bin/bash
# Capture Looker Studio dashboard screenshots and push to GitHub
# Runs via cron daily at 07:00 Dubai

set -e

REPO_DIR="$HOME/vs-studio-first-project"

PYTHON="python3"
if [ -x "$HOME/dashboard-venv/bin/python3" ]; then
    PYTHON="$HOME/dashboard-venv/bin/python3"
fi

cd "$REPO_DIR"

"$PYTHON" - <<"PYTHON"
import time, os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

REPO = os.path.expanduser("~/vs-studio-first-project")
PAGES = [
    ("https://lookerstudio.google.com/embed/reporting/0809760c-30c8-4961-85b4-ddf29531e4a8/page/p_cgr1rn38zd", f"{REPO}/dashboard-display/page1.png"),
    ("https://lookerstudio.google.com/embed/reporting/0809760c-30c8-4961-85b4-ddf29531e4a8/page/p_b8w3oo38zd", f"{REPO}/dashboard-display/page2.png"),
]

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--window-size=2560,1440")
opts.add_argument("--hide-scrollbars")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-gpu")
opts.add_argument("--disable-dev-shm-usage")
opts.add_argument("--disable-blink-features=AutomationControlled")
opts.add_argument("--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36")

driver = webdriver.Chrome(options=opts)
for url, path in PAGES:
    print(f"Capturing {url}...")
    driver.get(url)
    time.sleep(30)
    driver.save_screenshot(path)
    print(f"  Saved {path} ({os.path.getsize(path)}B)")
driver.quit()
print("Screenshots done!")
PYTHON

cd "$REPO_DIR"
git add dashboard-display/page1.png dashboard-display/page2.png
if git diff --cached --quiet; then
    echo "No changes to push"
else
    DATE=$(date "+%Y-%m-%d %H:%M")
    git commit -m "auto: refresh dashboard screenshots $DATE"
    git push origin main
    echo "Pushed to GitHub"
fi
