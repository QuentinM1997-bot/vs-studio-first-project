#!/bin/bash
# Capture Looker Studio dashboard screenshots and push to GitHub
# Runs via cron daily at 07:00 Dubai

set -e

REPO_DIR="$HOME/vs-studio-first-project"

# Use venv python if available, fallback to system python3
PYTHON="python3"
if [ -x "$HOME/dashboard-venv/bin/python3" ]; then
    PYTHON="$HOME/dashboard-venv/bin/python3"
fi

cd "$REPO_DIR"

# Take full-page screenshots via CDP (no cropping, retina 2x)
"$PYTHON" - <<"PYTHON"
import time, base64, os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

REPO = os.path.expanduser("~/vs-studio-first-project")
PAGES = [
    ("https://lookerstudio.google.com/embed/reporting/0809760c-30c8-4961-85b4-ddf29531e4a8/page/p_cgr1rn38zd", f"{REPO}/dashboard-display/page1.png"),
    ("https://lookerstudio.google.com/embed/reporting/0809760c-30c8-4961-85b4-ddf29531e4a8/page/p_b8w3oo38zd", f"{REPO}/dashboard-display/page2.png"),
]

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--window-size=2560,2000")
opts.add_argument("--hide-scrollbars")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-gpu")
opts.add_argument("--disable-dev-shm-usage")

driver = webdriver.Chrome(options=opts)

for url, path in PAGES:
    print(f"Capturing {url}...")
    driver.get(url)
    time.sleep(15)

    w = driver.execute_script("return document.documentElement.scrollWidth")
    h = driver.execute_script("return document.documentElement.scrollHeight")
    driver.set_window_size(w, h)
    time.sleep(3)

    w2 = driver.execute_script("return document.documentElement.scrollWidth")
    h2 = driver.execute_script("return document.documentElement.scrollHeight")

    result = driver.execute_cdp_cmd("Page.captureScreenshot", {
        "format": "png",
        "captureBeyondViewport": True,
        "clip": {"x": 0, "y": 0, "width": w2, "height": h2, "scale": 2}
    })

    with open(path, "wb") as f:
        f.write(base64.b64decode(result["data"]))
    print(f"  Saved {path} ({w2}x{h2} @2x)")

driver.quit()
print("Screenshots done!")
PYTHON

# Commit and push
cd "$REPO_DIR"
git add dashboard-display/page1.png dashboard-display/page2.png
if git diff --cached --quiet; then
    echo "No changes to push"
else
    DATE=$(date "+%Y-%m-%d %H:%M"); git commit -m "auto: refresh dashboard screenshots $DATE"
    git push origin main
    echo "Pushed to GitHub"
fi
