# Registro de Versões e Rollback (Changelog)

Este arquivo registra o histórico de alterações dos arquivos do projeto `morse_keyboard` para permitir desfazer (rollback) alterações facilmente a qualquer momento.

## 📋 Tabela de Versões

| Versão | Data / Hora | Descrição | Arquivos de Backup |
| :--- | :--- | :--- | :--- |
| **v2.1** | 08/07/2026 | **Versão Estável 2.1**<br>Refatoração completa do motor AHK (core, OSD, config), resolução de conflitos de modificadores e acentos, e integração robusta com Python/Ollama. | [v2.1_stable.zip](file:///c:/Users/Nicolas/.gemini/antigravity-ide/scratch/morse_keyboard/backups/v2.1_stable.zip) |

---

## 🔄 Como Fazer Rollback

Para restaurar o projeto para a versão v2.1 (versão estável local), basta extrair o conteúdo do arquivo `v2.1_stable.zip` localizado na pasta `backups/`, sobrescrevendo os arquivos atuais na raiz do projeto.

Você pode fazer isso manualmente ou rodando o seguinte comando no PowerShell na pasta do projeto:

```powershell
Expand-Archive -Path "backups\v2.1_stable.zip" -DestinationPath "." -Force
```

Após extrair os arquivos, clique com o botão direito no ícone verde do AutoHotkey na bandeja do sistema e selecione **"Reload This Script"** para aplicar as configurações da versão restaurada.
