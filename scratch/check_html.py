with open('osd.html', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()
    print("Length:", len(content))
    print("Nav pos:", content.find('<nav'))
    print("Style pos:", content.find('</style>'))
    print("Body pos:", content.find('<body>'))
    print("Ambient glow pos:", content.find('Ambient glow'))
