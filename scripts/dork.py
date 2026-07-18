import sys
import ollama
import subprocess

def generate_dorks(target):
    """
    Injeta o alvo no prompt e força o LLM a cuspir apenas a sintaxe de pesquisa OSINT.
    """
    prompt = f"""SYSTEM INSTRUCTION: You are an elite OSINT investigator. 
    Generate 5 advanced, highly specific Google Dorks to investigate the following target: {target}
    Include operators like site:, inurl:, ext:, intitle:, filetype:. 
    RETURN STRICTLY AND ONLY THE 5 DORKS, one per line. Do not add conversational text, numbering, or formatting blocks."""
    
    try:
        client = ollama.Client(host='http://127.0.0.1:11434')
        response = client.chat(
            model='granite3.2:2b', # Ajuste para a tag do seu modelo local de texto
            messages=[{'role': 'user', 'content': prompt}],
            options={
                'temperature': 0.0, # Lógica fria e determinística
                'seed': 42
            }
        )
        
        raw_dorks = response['message']['content'].strip()
        # Filtro de segurança caso o LLM teime em colocar blocos de markdown ```
        clean_dorks = raw_dorks.replace("```", "").strip()
        
        return clean_dorks
        
    except Exception as e:
        return f"Erro de Inferência OSINT: {e}"

if __name__ == "__main__":
    # 1. Puxa o alvo capturado pelo AutoHotkey
    try:
        target_input = sys.argv[1]
    except IndexError:
        # Fallback de teste de bancada
        target_input = "sicredi.com.br"
        
    # 2. Forja as Dorks
    dorks_prontos = generate_dorks(target_input)
    
    # 3. Injeta o resultado letal direto no Clipboard
    try:
        subprocess.run(['clip'], input=dorks_prontos, text=True, check=True)
    except Exception as e:
        pass