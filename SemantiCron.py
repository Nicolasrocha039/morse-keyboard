import sys
import time
import json
import ollama
import subprocess
import os
import uuid

AGENDA_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "agenda.json")

def carregar_agenda():
    if not os.path.exists(AGENDA_FILE):
        return []
    try:
        with open(AGENDA_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    except:
        return []

def salvar_agenda(agenda):
    try:
        with open(AGENDA_FILE, 'w', encoding='utf-8') as f:
            json.dump(agenda, f, ensure_ascii=False, indent=4)
    except Exception as e:
        print("Erro ao salvar agenda:", e)

def adicionar_tarefa(task_id, intent, action, delay):
    agenda = carregar_agenda()
    agora = time.time()
    agenda.append({
        "id": task_id,
        "intent": intent,
        "action": action,
        "timestamp_str": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(agora)),
        "trigger_time": agora + delay,
        "trigger_time_str": time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(agora + delay)),
        "delay": delay
    })
    salvar_agenda(agenda)

def remover_tarefa(task_id):
    agenda = carregar_agenda()
    agenda = [t for t in agenda if t.get("id") != task_id]
    salvar_agenda(agenda)

def parse_time_intent(natural_text):
    """
    O motor semântico. Força o LLM a calcular a intenção e o tempo em segundos.
    """
    prompt = f"""SYSTEM INSTRUCTION: You are an intelligent chronometer API. 
    Analyze the user's natural language command: "{natural_text}"
    Determine the core action and the exact time delay in seconds from now.
    Return STRICTLY AND ONLY a raw JSON format: {{"action": "string", "delay_seconds": integer}}.
    Example 1: "desliga a luz do quarto em 5 minutos" -> {{"action": "luz_quarto_off", "delay_seconds": 300}}
    Example 2: "me avisa do log daqui a meia hora" -> {{"action": "aviso_log", "delay_seconds": 1800}}
    Do not add conversational text or formatting blocks."""
    
    try:
        client = ollama.Client(host='http://127.0.0.1:11434')
        response = client.chat(
            model='granite3.2:2b', # Atualizado para a tag correta
            messages=[{'role': 'user', 'content': prompt}],
            options={'temperature': 0.0, 'seed': 42}
        )
        
        raw_output = response['message']['content']
        # Filtro de extração do JSON
        clean_json = raw_output[raw_output.find('{'):raw_output.rfind('}')+1]
        return json.loads(clean_json)
        
    except Exception as e:
        print(f"Error calling ollama: {e}")
        return {"action": "error", "delay_seconds": 0}

def execute_action(action_id):
    """
    O roteador de ações. Onde a magia do SO acontece.
    """
    if action_id == "error":
        return
        
    # ==========================================
    # SEU SWITCH DE AUTOMAÇÕES VAI AQUI
    # ==========================================
    if "luz" in action_id:
        # Exemplo: Disparo de API local para automação do ambiente
        # requests.post("URL_DA_SUA_API_DE_LUZ")
        print("Luzes alteradas.")
        
    elif "aviso" in action_id or "lembrete" in action_id:
        # Exemplo: Notificação nativa do Windows para te tirar do hiperfoco
        subprocess.run(['msg', '*', 'SemantiCron: O tempo da sua tarefa estourou!'])
        
    else:
        # Fallback genérico visual se não reconhecer a ação exata
        subprocess.run(['msg', '*', f'SemantiCron Executado: {action_id}'])

if __name__ == "__main__":
    try:
        user_intent = sys.argv[1]
    except IndexError:
        sys.exit(1)
        
    # 1. Extração Semântica
    parsed_data = parse_time_intent(user_intent)
    delay = parsed_data.get("delay_seconds", 0)
    action = parsed_data.get("action", "error")
    
    task_id = str(uuid.uuid4())
    
    # 2. Registrar e Motor de Espera
    if delay > 0 and action != "error":
        adicionar_tarefa(task_id, user_intent, action, delay)
        print(f"Tarefa '{action}' agendada para daqui a {delay} segundos.")
        time.sleep(delay)
        
    # 3. Execução
    if action != "error":
        execute_action(action)
        remover_tarefa(task_id)