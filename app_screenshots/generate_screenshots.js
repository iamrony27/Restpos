const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const SCRIPT_DIR = __dirname;
const RAW_DIR = path.join(SCRIPT_DIR, 'raw');
const OUT_DIR = path.join(SCRIPT_DIR, 'playstore_showcase');

if (!fs.existsSync(OUT_DIR)) {
  fs.mkdirSync(OUT_DIR, { recursive: true });
}

function toBase64(filePath) {
  const data = fs.readFileSync(filePath);
  return `data:image/png;base64,${data.toString('base64')}`;
}

const logoBase64 = toBase64(path.join('/media/NVME/aplication/restaurant POS/flutter_restaurant_pos/assets/icon/app_icon_round.png'));

const slides = [
  {
    id: '01_live_dashboard',
    rawImg: path.join(RAW_DIR, '01_dashboard_cropped.png'),
    badge: '📊 REAL-TIME POS ANALYTICS',
    badgeColor: '#FF6B00',
    title: 'Live Sales & <span class="highlight-orange">Turnover Insights</span>',
    subtitle: 'Monitor real-time revenue, order counts, average ticket size & dining turnover at a glance.',
    bgGradient: 'radial-gradient(circle at 50% 18%, rgba(255, 107, 0, 0.22) 0%, rgba(15, 23, 42, 0) 65%), linear-gradient(180deg, #0C1220 0%, #060913 100%)',
    highlightClass: 'highlight-orange',
    accentColor: '#FF6B00'
  },
  {
    id: '02_menu_catalog',
    rawImg: path.join(RAW_DIR, '02_menu_list_cropped.png'),
    badge: '🍽️ SMART DISH CATALOG',
    badgeColor: '#10B981',
    title: 'Visual Menu & <span class="highlight-green">Stock Control</span>',
    subtitle: 'Manage dish stock availability, bestseller tags, pricing & categories with instant one-tap switches.',
    bgGradient: 'radial-gradient(circle at 50% 18%, rgba(16, 185, 129, 0.20) 0%, rgba(15, 23, 42, 0) 65%), linear-gradient(180deg, #0A171B 0%, #050D10 100%)',
    highlightClass: 'highlight-green',
    accentColor: '#10B981'
  },
  {
    id: '03_touchscreen_grid',
    rawImg: path.join(RAW_DIR, '03_menu_grid_cropped.png'),
    badge: '⚡ HIGH-SPEED ORDERING',
    badgeColor: '#F59E0B',
    title: 'High-Speed <span class="highlight-amber">2-Column Grid POS</span>',
    subtitle: 'Streamlined visual ordering grid built for rush hours, counter express billing & kitchen dispatches.',
    bgGradient: 'radial-gradient(circle at 50% 18%, rgba(245, 158, 11, 0.20) 0%, rgba(15, 23, 42, 0) 65%), linear-gradient(180deg, #15110A 0%, #090704 100%)',
    highlightClass: 'highlight-amber',
    accentColor: '#F59E0B'
  },
  {
    id: '04_statutory_gst',
    rawImg: path.join(RAW_DIR, '04_reports_cropped.png'),
    badge: '🧾 STATUTORY TAX AUDIT',
    badgeColor: '#06B6D4',
    title: 'Audit-Ready <span class="highlight-cyan">GST & Tax Reports</span>',
    subtitle: 'Reconciled CGST, SGST, round-off audit, FSSAI verification & instant PDF tax report generation.',
    bgGradient: 'radial-gradient(circle at 50% 18%, rgba(6, 182, 212, 0.20) 0%, rgba(15, 23, 42, 0) 65%), linear-gradient(180deg, #0A1624 0%, #050B12 100%)',
    highlightClass: 'highlight-cyan',
    accentColor: '#06B6D4'
  },
  {
    id: '05_hardware_settings',
    rawImg: path.join(RAW_DIR, '05_settings_cropped.png'),
    badge: '🖨️ HARDWARE & CONFIGURATION',
    badgeColor: '#A855F7',
    title: 'Flexible Invoicing & <span class="highlight-purple">Thermal Printing</span>',
    subtitle: 'Instant Bluetooth 58mm/80mm ESC/POS pairing, 5% restaurant GST slabs & cash invoice round-off.',
    bgGradient: 'radial-gradient(circle at 50% 18%, rgba(168, 85, 247, 0.20) 0%, rgba(15, 23, 42, 0) 65%), linear-gradient(180deg, #130D24 0%, #070410 100%)',
    highlightClass: 'highlight-purple',
    accentColor: '#A855F7'
  }
];

function generateHtml(slide) {
  const screenshotBase64 = toBase64(slide.rawImg);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${slide.badge}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800;900&display=swap');

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      width: 1080px;
      height: 2280px;
      overflow: hidden;
      background: ${slide.bgGradient};
      font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: #FFFFFF;
      position: relative;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
    }

    /* Ambient Background Elements */
    .bg-grid {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      height: 700px;
      background-image: 
        radial-gradient(circle, rgba(255,255,255,0.06) 1px, transparent 1px);
      background-size: 32px 32px;
      opacity: 0.6;
      pointer-events: none;
    }

    /* Top Brand Bar */
    .top-brand-bar {
      position: relative;
      z-index: 10;
      padding: 70px 70px 0 70px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    .brand-logo-lockup {
      display: flex;
      align-items: center;
      gap: 16px;
    }

    .brand-logo-img {
      width: 52px;
      height: 52px;
      border-radius: 14px;
      box-shadow: 0 4px 16px rgba(0,0,0,0.4);
    }

    .brand-title {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: #FFFFFF;
    }

    .brand-edition-pill {
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.15);
      border-radius: 100px;
      padding: 6px 16px;
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 1px;
      color: #CBD5E1;
      text-transform: uppercase;
    }

    /* Typography & Promo Section */
    .promo-header {
      position: relative;
      z-index: 10;
      padding: 40px 70px 0 70px;
    }

    .badge-pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: ${slide.badgeColor}22;
      border: 1.5px solid ${slide.badgeColor}55;
      color: ${slide.badgeColor};
      border-radius: 100px;
      padding: 10px 22px;
      font-size: 16px;
      font-weight: 800;
      letter-spacing: 1.2px;
      text-transform: uppercase;
      box-shadow: 0 4px 20px ${slide.badgeColor}22;
    }

    .headline {
      margin-top: 24px;
      font-size: 56px;
      font-weight: 900;
      line-height: 1.15;
      letter-spacing: -1.2px;
      color: #F8FAFC;
      text-shadow: 0 4px 24px rgba(0, 0, 0, 0.5);
    }

    .highlight-orange {
      background: linear-gradient(135deg, #FF6B00 0%, #FFA726 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .highlight-green {
      background: linear-gradient(135deg, #10B981 0%, #34D399 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .highlight-amber {
      background: linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .highlight-cyan {
      background: linear-gradient(135deg, #06B6D4 0%, #38BDF8 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .highlight-purple {
      background: linear-gradient(135deg, #A855F7 0%, #C084FC 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .subtitle {
      margin-top: 18px;
      font-size: 26px;
      font-weight: 500;
      line-height: 1.45;
      color: #94A3B8;
      max-width: 920px;
    }

    /* Device Container */
    .device-wrapper {
      position: relative;
      z-index: 10;
      width: 100%;
      display: flex;
      justify-content: center;
      margin-top: 36px;
    }

    .phone-chassis {
      width: 860px;
      height: 1600px;
      background: #141A28;
      border-radius: 56px 56px 0 0;
      padding: 14px 14px 0 14px;
      box-shadow: 
        0 40px 120px rgba(0, 0, 0, 0.85),
        0 15px 40px rgba(0, 0, 0, 0.6),
        inset 0 1px 3px rgba(255, 255, 255, 0.25),
        inset 0 -1px 2px rgba(0, 0, 0, 0.5);
      border: 4px solid #2A344A;
      border-bottom: none;
      position: relative;
      overflow: hidden;
    }

    /* Screen display area */
    .phone-screen {
      width: 100%;
      height: 100%;
      background: #FFFFFF;
      border-radius: 44px 44px 0 0;
      overflow: hidden;
      position: relative;
      display: flex;
      flex-direction: column;
    }

    /* Clean Mock Status Bar */
    .mock-status-bar {
      height: 48px;
      width: 100%;
      background: #FAF8F5;
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 32px;
      font-size: 14px;
      font-weight: 700;
      color: #1E293B;
      flex-shrink: 0;
      border-bottom: 1px solid rgba(0,0,0,0.03);
    }

    .camera-punch {
      width: 13px;
      height: 13px;
      background: #000000;
      border-radius: 50%;
      box-shadow: inset 0 0 2px #334155;
    }

    .status-icons {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      font-weight: 800;
    }

    .battery-pill {
      width: 22px;
      height: 11px;
      border: 1.5px solid #1E293B;
      border-radius: 3px;
      padding: 1px;
      display: flex;
      align-items: center;
    }

    .battery-level {
      width: 80%;
      height: 100%;
      background: #1E293B;
      border-radius: 1px;
    }

    /* App screenshot image */
    .screenshot-img {
      width: 100%;
      height: auto;
      display: block;
      object-fit: cover;
    }

    /* Glossy Glass Reflection Overlay */
    .screen-gloss {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: linear-gradient(135deg, rgba(255,255,255,0.08) 0%, rgba(255,255,255,0) 45%);
      pointer-events: none;
    }
  </style>
</head>
<body>
  <div class="bg-grid"></div>

  <!-- Top Brand Navigation -->
  <div class="top-brand-bar">
    <div class="brand-logo-lockup">
      <img src="${logoBase64}" class="brand-logo-img" alt="Rest POS" />
      <div class="brand-title">Rest POS</div>
    </div>
    <div class="brand-edition-pill">Android POS Edition</div>
  </div>

  <!-- Main Copy Section -->
  <div class="promo-header">
    <div class="badge-pill">${slide.badge}</div>
    <h1 class="headline">${slide.title}</h1>
    <p class="subtitle">${slide.subtitle}</p>
  </div>

  <!-- Phone Mockup Container -->
  <div class="device-wrapper">
    <div class="phone-chassis">
      <div class="phone-screen">
        <div class="mock-status-bar">
          <div>9:41</div>
          <div class="camera-punch"></div>
          <div class="status-icons">
            <span>5G</span>
            <div class="battery-pill">
              <div class="battery-level"></div>
            </div>
          </div>
        </div>
        <img src="${screenshotBase64}" class="screenshot-img" alt="${slide.badge}" />
        <div class="screen-gloss"></div>
      </div>
    </div>
  </div>
</body>
</html>`;
}

// Generate all slides
for (const slide of slides) {
  const html = generateHtml(slide);
  const htmlPath = path.join(SCRIPT_DIR, `temp_${slide.id}.html`);
  const outPng = path.join(OUT_DIR, `${slide.id}.png`);

  fs.writeFileSync(htmlPath, html, 'utf8');
  console.log(`Rendering ${slide.id}...`);

  execSync(`google-chrome --headless=new --disable-gpu --no-sandbox --hide-scrollbars --window-size=1080,2280 --screenshot="${outPng}" "${htmlPath}"`, {
    stdio: 'inherit'
  });

  fs.unlinkSync(htmlPath);
  console.log(`Generated: ${outPng}`);
}

console.log('All slides rendered successfully!');
