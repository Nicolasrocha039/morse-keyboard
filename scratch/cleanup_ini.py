import sys

def main():
    file_path = "morse_map.ini"
    out_path = "morse_map_clean.ini"
    
    with open(file_path, "r", encoding="utf-16le") as f:
        lines = f.readlines()
        
    cleaned_lines = []
    
    for line in lines:
        stripped = line.strip()
        
        # Keep empty lines and comments
        if not stripped or stripped.startswith(";"):
            # But let's skip the massive headers for syllables
            if "LÓGICA" in stripped.upper() or "--- MAIÚSCULAS ---" in stripped:
                continue
            cleaned_lines.append(line)
            continue
            
        # Parse key=value
        if "=" in stripped:
            key, val = stripped.split("=", 1)
            # Normal key if it's 1 char OR contains '{'
            if len(val) == 1 or "{" in val:
                cleaned_lines.append(line)
            else:
                # It's a syllable, skip it
                pass
        else:
            cleaned_lines.append(line)
            
    # Clean up multiple empty lines
    final_lines = []
    for line in cleaned_lines:
        if line.strip() == "" and final_lines and final_lines[-1].strip() == "":
            continue
        final_lines.append(line)
            
    with open(out_path, "w", encoding="utf-16le") as f:
        f.writelines(final_lines)

if __name__ == "__main__":
    main()
