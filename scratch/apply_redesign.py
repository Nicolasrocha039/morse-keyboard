import os
import re

files_to_fix = ['osd.html', 'mapa_visual.html', 'remote.html', 'terminal.html', 'agenda.html']

nav_html = """
    <!-- Premium Global Nav -->
    <nav class="global-nav">
        <h1>>_ Menu</h1>
        <div class="nav-links">
            <a href="terminal.html" class="btn">Terminal</a>
            <a href="agenda.html" class="btn">Agenda</a>
            <a href="mapa_visual.html" class="btn">Mapa Visual</a>
            <a href="osd.html" class="btn">OSD</a>
            <a href="remote.html" class="btn">Controle Remoto</a>
        </div>
    </nav>
"""

premium_nav_css = """
    /* --- PREMIUM GLOBAL NAV --- */
    :root {
        --nav-bg: rgba(15, 23, 42, 0.7);
        --nav-border: rgba(56, 189, 248, 0.3);
        --nav-text: #e2e8f0;
        --nav-accent: #38bdf8;
        --nav-hover: rgba(56, 189, 248, 0.2);
    }
    .global-nav {
        background: var(--nav-bg) !important;
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        padding: 12px 24px !important;
        display: flex;
        justify-content: space-between;
        align-items: center;
        border-bottom: 1px solid var(--nav-border) !important;
        font-family: 'Inter', 'Segoe UI', sans-serif !important;
        z-index: 9999;
        position: relative;
        box-shadow: 0 4px 30px rgba(0, 0, 0, 0.5);
        margin: 0;
    }
    .global-nav h1 {
        margin: 0;
        font-size: 1.25rem !important;
        font-weight: 700;
        color: var(--nav-accent) !important;
        letter-spacing: 0.5px;
        text-shadow: 0 0 10px rgba(56,189,248,0.4);
    }
    .global-nav .nav-links {
        display: flex;
        gap: 12px;
        flex-wrap: wrap;
    }
    .global-nav a.btn {
        background: transparent !important;
        color: var(--nav-text) !important;
        text-decoration: none;
        padding: 8px 16px !important;
        border-radius: 6px !important;
        font-weight: 500 !important;
        transition: all 0.3s ease !important;
        font-size: 0.9rem !important;
        border: 1px solid transparent;
    }
    .global-nav a.btn:hover {
        background: var(--nav-hover) !important;
        color: var(--nav-accent) !important;
        border: 1px solid var(--nav-border);
        box-shadow: 0 0 15px rgba(56, 189, 248, 0.2);
        transform: translateY(-1px);
    }
    /* --------------------------- */
"""

for fname in files_to_fix:
    if not os.path.exists(fname):
        continue
        
    with open(fname, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # 1. Fix encodings
    content = content.replace('Morse OSD ?" Monitor', 'Morse OSD — Monitor')
    content = content.replace('Pr?ximas', 'Próximas')
    content = content.replace('PrÃ³ximas', 'Próximas')
    
    # In files where someone manually added <nav> badly, remove old <nav> if any
    old_nav_pattern = re.compile(r'<nav[^>]*>.*?</nav>', re.DOTALL)
    content = old_nav_pattern.sub('', content)

    # In files where someone added old CSS badly, remove it
    old_css_pattern = re.compile(r'/\* Global Nav Bar Styles \*/.*?(?=</style>|<!--)', re.DOTALL)
    content = old_css_pattern.sub('', content)
    old_css_pattern2 = re.compile(r'/\* Nav Bar Styles \*/.*?(?=/\*|</style>|<!--)', re.DOTALL)
    content = old_css_pattern2.sub('', content)

    # Clean up double <body> tags if they exist (just in case)
    if content.count('<body>') > 1:
        # Complex to fix automatically without breaking, but git checkout handled the main files.
        pass

    # 2. Inject Nav into <body>
    # Replace first occurrence of <body> with <body> + nav_html
    # We use regex to handle <body class="..."> just in case
    content = re.sub(r'(<body[^>]*>)', r'\1' + nav_html, content, count=1)

    # 3. Inject CSS before </style>
    if '</style>' in content:
        content = content.replace('</style>', premium_nav_css + '\n</style>', 1)
    else:
        # If no style block, add one inside head
        content = content.replace('</head>', f'<style>\n{premium_nav_css}\n</style>\n</head>', 1)
        
    # Extra fix for agenda.html: remove the -20px margin hack that was on nav
    content = content.replace('margin: -20px -20px 20px -20px; /* pull up to edge */', '')

    with open(fname, 'w', encoding='utf-8') as f:
        f.write(content)

print("Redesign applied to all HTML pages!")
