import os
import re

files_to_fix = ['osd.html', 'mapa_visual.html', 'remote.html', 'terminal.html', 'agenda.html']

nav_html = """
    <nav class="global-nav">
        <h1>>_ SemantiCron</h1>
        <div class="nav-links">
            <a href="terminal.html" class="btn">Terminal</a>
            <a href="agenda.html" class="btn">Agenda</a>
            <a href="mapa_visual.html" class="btn">Mapa Visual</a>
            <a href="osd.html" class="btn">OSD</a>
            <a href="remote.html" class="btn">Controle Remoto</a>
        </div>
    </nav>
"""

for fname in files_to_fix:
    if not os.path.exists(fname):
        continue
        
    with open(fname, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # REMOVE any mistakenly pasted </style>...</nav> blocks that were put in the middle of CSS
    bad_nav_pattern = re.compile(r'</style>\s*</head>\s*<body>\s*<nav[^>]*>.*?</nav>', re.DOTALL)
    content = bad_nav_pattern.sub('', content)

    # REMOVE any <nav> that might be in the body already, so we can re-insert it cleanly
    existing_nav_pattern = re.compile(r'<nav[^>]*>.*?</nav>', re.DOTALL)
    content = existing_nav_pattern.sub('', content)
    
    # Also remove duplicate premium CSS I added in the previous step
    premium_css_pattern = re.compile(r'/\* --- PREMIUM GLOBAL NAV --- \*/.*?(?=</style>)', re.DOTALL)
    content = premium_css_pattern.sub('', content)

    # Now, find the REAL <body> tag and insert the nav
    # But wait, what if the real <body> is something like <body class="...">?
    content = re.sub(r'(<body[^>]*>)', r'\1' + nav_html, content, count=1)
    
    # Re-add the Premium CSS just before </style>
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
    content = content.replace('</style>', premium_nav_css + '\n</style>')

    # Final touch: if there are multiple </style> tags, fix it. But we only replaced existing ones.
    
    with open(fname, 'w', encoding='utf-8') as f:
        f.write(content)
        
print("HTML structurally fixed and styled!")
