---
name: setup-automation
description: Expert advisor that helps decide and create the right Claude Code automation
disable-model-invocation: true
---

# Claude Code Expert - Setup Automation

L'utente vuole automatizzare: $ARGUMENTS

---

## Step 0: Aggiornamento documentazione

Prima di procedere, aggiorna la tua conoscenza:

1. Fetch la documentazione ufficiale:
   - https://code.claude.com/docs/en/best-practices
   - https://code.claude.com/docs/en/skills
   - https://code.claude.com/docs/en/hooks-guide
   - https://code.claude.com/docs/en/sub-agents
   - https://code.claude.com/docs/en/settings

2. Aggiorna `docs/claude-code-reference.md` nel plugin con eventuali novità rilevanti per la scelta tra skill, hook, subagent, permissions, CLAUDE.md e custom commands.

---

## Step 1: Intervista approfondita

Usa AskUserQuestion per chiarire il caso d'uso. Fai domande specifiche:

### Timing e frequenza
- Quando deve succedere questa automazione?
  - Sempre, ad ogni azione specifica (es. ogni commit, ogni edit)
  - Solo in certi contesti (es. solo per progetti TUI)
  - Solo su richiesta esplicita dell'utente

### Natura dell'automazione
- Deve essere garantito/deterministico (DEVE succedere) o è una linea guida (DOVREBBE succedere)?
- Serve intelligenza/decisioni di Claude o basta eseguire uno script/comando?
- Può fallire silenziosamente o deve bloccare l'operazione?

### Scope
- Si applica a tutti i progetti o solo a questo?
- Si applica a tutto il progetto o solo a certi tipi di file/lavoro?
- Altri sviluppatori del team devono seguire la stessa regola?

### Input/Output
- Servono parametri/argomenti?
- Deve produrre file, output, o modificare configurazioni?

---

## Step 2: Analisi e decisione

Basandoti sulle risposte, usa questa matrice decisionale:

| Criterio | Hook | Skill | Skill (manual) | Subagent | Permissions | CLAUDE.md | Custom Cmd |
|----------|------|-------|----------------|----------|-------------|-----------|------------|
| Deve succedere SEMPRE senza eccezioni | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| È una regola su cosa Claude può/non può fare | ❌ | ❌ | ❌ | ❌ | ✅ | ⚠️ | ❌ |
| Conoscenza di dominio applicata automaticamente | ❌ | ✅ | ❌ | ❌ | ❌ | ⚠️ | ❌ |
| Workflow complesso da invocare manualmente | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Serve contesto separato/isolato | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Review/analisi indipendente | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Regola semplice globale | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Shortcut per prompt frequente | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

### Combinazioni comuni

- **Hook + Skill**: Quando deve succedere sempre (hook) ma richiede logica complessa (skill)
- **Skill + Subagent**: Quando la skill definisce il workflow ma serve un subagent per analisi approfondite
- **Permissions + CLAUDE.md**: Permissions per blocco tecnico, CLAUDE.md per spiegare il perché

---

## Step 3: Spiega la decisione

Prima di creare, spiega all'utente:
1. Cosa hai deciso di creare e perché
2. Alternative considerate e perché scartate
3. Come funzionerà in pratica
4. Eventuali limitazioni o considerazioni

Chiedi conferma prima di procedere.

---

## Step 4: Crea i file

Dopo conferma, crea i file necessari:

### Per Hook
```json
// .claude/settings.json
{
  "hooks": {
    "[eventType]": [
      {
        "command": "...",
        "description": "..."
      }
    ]
  }
}
```

Eventi disponibili: `preBash`, `postBash`, `preEdit`, `postEdit`, `preWrite`, `postWrite`, `beforeCommit`, `afterCommit`

### Per Skill
```markdown
// .claude/skills/[nome]/SKILL.md
---
name: [nome]
description: [descrizione]
disable-model-invocation: [true se workflow manuale, false se automatico]
---
[contenuto]
```

### Per Subagent
```markdown
// .claude/agents/[nome].md
---
name: [nome]
description: [descrizione]
tools: [lista tool: Read, Grep, Glob, Bash, Edit, Write]
model: [opus|sonnet|haiku]
---
[system prompt specializzato]
```

### Per Permissions
```json
// .claude/settings.json
{
  "permissions": {
    "allow": ["..."],
    "deny": ["..."]
  }
}
```

### Per Custom Command
```json
// .claude/settings.json
{
  "customCommands": {
    "[nome]": "[prompt]"
  }
}
```

### Per CLAUDE.md
Aggiungi la regola al file CLAUDE.md nella root del progetto.

---

## Step 5: Verifica e istruzioni

Dopo aver creato:
1. Mostra i file creati
2. Spiega come testare/usare l'automazione
3. Suggerisci eventuali miglioramenti futuri
4. Se è una skill/subagent, mostra il comando per invocarla

---

## Note importanti

- Se l'utente usa `--dangerously-skip-permissions`, i Permissions non funzionano. Suggerisci Hook come alternativa per blocchi.
- Le istruzioni in CLAUDE.md sono advisory, non garantite. Se serve certezza, usa Hook.
- Gli Hook sono script, non hanno accesso all'intelligenza di Claude. Per logica complessa, combina Hook + Skill.
- I Subagent consumano token extra ma preservano il contesto principale.
