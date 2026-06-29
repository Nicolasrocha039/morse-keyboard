import re

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

def extract_string(func_name, file_name):
    # Match the content between return " \n( \n ... \n)"
    pattern = rf'{func_name}\(\) {{\s*return "\s*\(\n(.*?)\n\)"\s*}}'
    match = re.search(pattern, text, flags=re.DOTALL)
    if match:
        content = match.group(1)
        with open(file_name, 'w', encoding='utf-8-sig') as f:
            f.write(content)
        print(f"Extracted {func_name} to {file_name}")
    else:
        print(f"Could not find {func_name}")

extract_string('BuildGeralCol1', 'osd_geral_col1.txt')
extract_string('BuildGeralCol2', 'osd_geral_col2.txt')
extract_string('BuildSyllablesTab', 'osd_syllables.txt')
extract_string('BuildTriplesTab', 'osd_triples.txt')
