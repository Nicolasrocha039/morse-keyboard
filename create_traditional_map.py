import os

morse_standard = {
    'a': 'AR',
    'b': 'RAAA',
    'c': 'RARA',
    'd': 'RAA',
    'e': 'A',
    'f': 'AARA',
    'g': 'RRA',
    'h': 'AAAA',
    'i': 'AA',
    'j': 'ARRR',
    'k': 'RAR',
    'l': 'ARAA',
    'm': 'RR',
    'n': 'RA',
    'o': 'RRR',
    'p': 'ARRA',
    'q': 'RRAR',
    'r': 'ARA',
    's': 'AAA',
    't': 'R',
    'u': 'AAR',
    'v': 'AAAR',
    'w': 'ARR',
    'x': 'RAAR',
    'y': 'RARR',
    'z': 'RRAA'
}

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    source_ini = os.path.join(base_dir, "morse_map.ini")
    target_ini = os.path.join(base_dir, "morse_map_traditional.ini")
    
    with open(source_ini, "r", encoding="utf-16le") as f:
        lines = f.readlines()
        
    out_lines = []
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith("["):
            out_lines.append(line)
            continue
            
        parts = line.split("=", 1)
        if len(parts) == 2:
            val = parts[1]
            if len(val) == 1 and val.isalpha():
                # É uma letra simples
                continue
                
        # Mantém tudo que não for letra isolada
        out_lines.append(line)
        
    # Adicionar as novas letras
    out_lines.append("; --- Letras Tradicionais ---")
    for letter, code in morse_standard.items():
        out_lines.append(f"{code}={letter}")
        
    out_lines.append("; --- Letras Tradicionais (Maiusculas) ---")
    # Prefixo RRRR para maiúsculas
    for letter, code in morse_standard.items():
        out_lines.append(f"RRRR{code}={letter.upper()}")

    # Adicionar o atalho QQQQ e AAAA
    out_lines.append("QQQQ={ToggleTraditionalMode}")
    out_lines.append("AAAA={ToggleTraditionalMode}")
    
    with open(target_ini, "w", encoding="utf-16le") as f:
        f.write("\n".join(out_lines) + "\n")
        
    print("morse_map_traditional.ini gerado com sucesso.")

if __name__ == "__main__":
    main()
