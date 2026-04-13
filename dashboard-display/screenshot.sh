#!/bin/bash
# Capture Looker Studio dashboard screenshots and push to GitHub
# Runs via launchd every 12h

set -e

REPO_DIR="/tmp/vs-studio-first-project"
DISPLAY_DIR="$REPO_DIR/dashboard-display"

cd "$REPO_DIR"

# Take screenshots with Selenium (headless Chrome, retina 2x)
python3 - <<'PYTHON'
import time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

PAGES = [
    ("https://lookerstudio.google.com/embed/reporting/0809760c-30c8-4961-85b4-ddf29531e4a8/page/p_cgr1rn38zd", "/tmp/vs-studio-first-project/dashboard-display/page1.png"),
    ("https://lookerstudio.google.com/embed/reporting/0809760c-30c8-4961-85b4-ddf29531e4a8/page/p_b8w3oo38zd", "/tmp/vs-studio-first-project/dashboard-display/page2.png"),
]

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--window-size=2560,1440")
opts.add_argument("--force-device-scale-factor=2")
opts.add_argument("--hide-scrollbars")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-gpu")

driver = webdriver.Chrome(options=opts)

for url, path in PAGES:
    print(f"Capturing {url}...")
    driver.get(url)
    time.sleep(12)
    height = driver.execute_script("return document.documentElement.scrollHeight")
    driver.set_window_size(2560, height)
    time.sleep(2)
    driver.save_screenshot(path)
    print(f"Saved to {path}")

driver.quit()
print("Screenshots done!")
PYTHON

# Commit and push
cd "$REPO_DIR"
git add dashboard-display/page1.png dashboard-display/page2.png
if git diff --cached --quiet; then
    echo "No changes to push"
else
    git commit -m "auto: refresh dashboard screenshots $(date '+%Y-%m-%d %H:%M')"
    git push origin main
    echo "Pushed to GitHub"
fi