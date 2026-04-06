# 🛡️ WhatsApp Group Guard — Anti-Golpistas

> Moderação automática e inteligente para grupos de WhatsApp. Apaga mensagens de não-admins instantaneamente, puntua contatos suspeitos e protege sua comunidade 24h por dia.

---

## 🚀 Visão Geral

O **WhatsApp Group Guard** é um sistema de moderação automática para grupos de WhatsApp, construído sobre:

| Componente | Papel |
|---|---|
| **n8n** | Motor de automação — orquestra todos os fluxos |
| **Evolution API** | Integração com WhatsApp (envio, deleção, remoção) |
| **PostgreSQL / Supabase** | Persistência de políticas, whitelist, scores e logs |

### O que ele faz

- 🗑️ **Apaga automaticamente** qualquer mensagem enviada por não-admins
- 🚫 **Remove participantes** suspeitos (opcional, desativado por padrão)
- 🔔 **Alerta admins** via WhatsApp quando uma moderação ocorre
- 📊 **Calcula score de risco** de cada contato a cada 10 minutos
- 🏷️ **Whitelist** para liberar membros de confiança individualmente
- 📋 **Controle por grupo** — você decide quais grupos são moderados

---

## 🧠 Como Funciona — Os 3 Fluxos

### Fluxo 00 — Bootstrap (Sincronização Inicial)

Executado **uma única vez** manualmente para popular o banco com o estado atual de todos os grupos.

```
Manual Trigger
  → Busca todos os grupos da instância Evolution (com participantes)
  → Explode cada participante em uma linha separada
  → Salva na tabela participant_snapshots (is_admin, is_present)
```

Sem esse passo, o sistema não sabe quem é admin e pode moderar incorretamente.

---

### Fluxo 01 — Moderação em Tempo Real

Esse é o coração do sistema. Ativado a cada mensagem recebida via webhook.

```
Webhook POST /evolution-group-moderation
  → Normaliza o evento (extrai groupJid, senderJid, messageId, texto, etc.)
  → Filtra: só processa mensagens de grupo que não sejam do próprio bot
  → Carrega política do grupo + whitelist + score do remetente (banco)
  → Busca membros do grupo na Evolution (quem é admin agora)
  → Avalia moderação:
      • Remetente é admin?      → Permite. Fim.
      • Remetente está na whitelist? → Permite. Fim.
      • Caso contrário:         → shouldModerate = true, shouldDelete = true
  → Se deve moderar:
      ├── Registra incidente no banco (Log Incident)
      ├── Envia alerta para admin (se configurado na policy)
      ├── Apaga a mensagem para todos (Delete Message)
      └── Remove o participante do grupo (se shouldRemove = true)
  → Se for evento GROUP_PARTICIPANTS_UPDATE:
      → Atualiza participant_snapshots (entrada/saída de membros)
```

---

### Fluxo 02 — Inteligência / Score Engine

Roda em **background a cada 10 minutos** de forma totalmente automática.

```
Schedule Trigger (10 em 10 minutos)
  → Agrega sinais de cada contato:
      • Quantos grupos diferentes ele está presente
      • Quantas entradas nas últimas 24h
      • Incidentes de moderação nos últimos 7 dias
      • Remoções nos últimos 30 dias
      • Deleções nos últimos 7 dias
  → Calcula score de risco (0–100):
      score = (grupos × 10) + (entradas_24h × 8) + (incidentes × 15)
            + (remoções × 20) + (deleções × 8)
      + bônus: +15 se ≥ 3 grupos, +15 se ≥ 5 grupos, +10 se ≥ 3 entradas recentes
  → Classifica nível de risco:
      • 0–29   → low (baixo)
      • 30–49  → medium (médio)
      • 50–69  → high (alto)
      • 70–100 → critical (crítico)
  → Salva/atualiza na tabela contact_scores
```

O score é consultado no Fluxo 01 e pode ser usado para endurecimento automático de políticas.

---

## 🗄️ Banco de Dados — Tabelas

| Tabela | O que armazena |
|---|---|
| `group_policies` | Configuração de moderação por grupo (ativar/desativar, remover, alertar) |
| `trusted_senders` | Whitelist — contatos liberados (global ou por grupo) |
| `participant_snapshots` | Foto dos participantes de cada grupo (is_admin, is_present) |
| `moderation_incidents` | Log completo de cada ação de moderação (quem, quando, o quê) |
| `contact_scores` | Score de risco calculado por contato/telefone |

---

## ⚙️ Pré-requisitos

Antes de começar, você precisa ter:

### Infraestrutura
- **n8n** rodando (VPS, Docker ou cloud)
- **PostgreSQL** ou conta no **Supabase** (recomendado)
- **Evolution API** instalada e acessível

### Evolution API
- Instância criada
- WhatsApp conectado via QR Code
- API Key ativa
- Status: `connected`

---

## 🔌 Setup Passo a Passo

### 1. Banco de Dados

Execute o arquivo `00_schema.sql` no seu PostgreSQL/Supabase. Ele cria todas as tabelas necessárias.

No Supabase, vá em **SQL Editor** e cole o conteúdo do arquivo.

---

### 2. Variáveis de Ambiente no n8n

No painel do n8n, vá em **Settings → Environment Variables** e adicione:

```
EVOLUTION_BASE_URL=https://seu-dominio-evolution
EVOLUTION_INSTANCE=nome-da-instancia
EVOLUTION_API_KEY=sua-api-key
```

---

### 3. Importar o Workflow

1. Abra o n8n
2. Menu superior → **Import from file**
3. Selecione o arquivo `Whatsapp Guard.json`
4. Salve e configure as credenciais PostgreSQL nos nodes que pedem

---

### 4. Configurar Credenciais no n8n

Nos nodes **Postgres** (Load Group Policy, Log Incident, Upsert Snapshot, etc.), configure:

| Campo | Valor |
|---|---|
| Host | host do seu banco |
| Port | 5432 |
| Database | nome do banco |
| User | usuário |
| Password | senha |

Para **Supabase**: use o host `db.xxxx.supabase.co`, porta `5432`, banco `postgres`.

---

### 5. Configurar Webhook na Evolution

Aponte o webhook da sua instância Evolution para:

```
POST https://SEU_N8N/webhook/evolution-group-moderation
```

**Eventos obrigatórios a habilitar:**
- `MESSAGES_UPSERT`
- `GROUP_PARTICIPANTS_UPDATE`
- `GROUPS_UPSERT`

---

### 6. Colocar o Bot nos Grupos

O número conectado na Evolution precisa:

- ✅ Estar **dentro** dos grupos que serão moderados
- ✅ Ser **ADMIN** nesses grupos

> **Sem isso o sistema não consegue apagar mensagens nem remover usuários.**

Como fazer:
1. Pegue o número conectado na instância Evolution
2. Adicione esse número nos grupos desejados
3. Promova-o para **Administrador**

---

### 7. Bootstrap — Sincronização Inicial

Execute o **Fluxo 00** manualmente **uma única vez**:

1. No n8n, abra o workflow `Whatsapp Guard`
2. Localize o nó **Manual Trigger** (região "FLUXO 00 - Bootstrap")
3. Clique em **Execute node**

Isso sincroniza todos os grupos e participantes com o banco de dados.

---

### 8. Ativar os Fluxos

- Ative o **Webhook** (Fluxo 01 — moderação em tempo real)
- Ative o **Schedule Trigger** (Fluxo 02 — score a cada 10 min)

---

## 🎯 Controlar Quais Grupos São Moderados

A moderação é controlada pela tabela `group_policies`.

**O sistema só age em grupos cadastrados nessa tabela.**

### Ativar moderação em um grupo

```sql
INSERT INTO group_policies (group_jid, group_name)
VALUES ('120363XXXXXXXXX@g.us', 'Nome do Grupo');
```

> O `group_jid` é o ID do grupo no formato `120363XXXXXXXXX@g.us`. Você pode encontrá-lo nos logs do webhook ou na Evolution API.

### Desativar moderação

```sql
DELETE FROM group_policies
WHERE group_jid = '120363XXXXXXXXX@g.us';
```

### Campos disponíveis na policy

| Campo | Tipo | Padrão | Descrição |
|---|---|---|---|
| `group_jid` | text | — | ID do grupo (obrigatório) |
| `group_name` | text | — | Nome amigável |
| `only_admins_can_post` | boolean | true | Ativa regra de só-admins |
| `auto_delete_enabled` | boolean | true | Apagar mensagem automaticamente |
| `auto_remove_enabled` | boolean | false | Remover participante automaticamente |
| `admin_alert_number` | text | null | Número do admin para receber alertas |
| `min_score_to_delete` | int | — | Score mínimo para deletar |
| `min_score_to_remove` | int | — | Score mínimo para remover |

---

## 🔐 Whitelist — Liberar Contatos de Confiança

Para liberar um número específico (equipe interna, suporte, vendas, parceiros):

### Whitelist global (vale para todos os grupos)

```sql
INSERT INTO trusted_senders (phone)
VALUES ('5531999990000');
```

### Whitelist por grupo

```sql
INSERT INTO trusted_senders (phone, group_jid)
VALUES ('5531999990000', '120363XXXXXXXXX@g.us');
```

### Remover da whitelist

```sql
DELETE FROM trusted_senders
WHERE phone = '5531999990000';
```

> O telefone deve estar no formato só números, com DDD e DDI. Exemplo: `5511999990000`

---

## 🔥 Ativar Remoção Automática de Participantes

Por padrão, o sistema **apenas apaga mensagens**. Para também remover o participante:

```sql
UPDATE group_policies
SET auto_remove_enabled = true
WHERE group_jid = '120363XXXXXXXXX@g.us';
```

> **Recomendação:** comece só com deleção. Valide por 1-2 dias antes de ativar remoção.

---

## 🔔 Alertas para Admins

Para receber uma mensagem no WhatsApp toda vez que uma moderação ocorrer:

```sql
UPDATE group_policies
SET admin_alert_number = '5531999990000'
WHERE group_jid = '120363XXXXXXXXX@g.us';
```

---

## 🧪 Testes

### Teste básico (deve deletar)

1. Entre em um grupo monitorado com um número **não-admin**
2. Envie qualquer mensagem
3. Resultado esperado: mensagem apagada automaticamente

### Teste de admin (deve permitir)

1. Envie mensagem com um número **admin** do grupo
2. Resultado esperado: mensagem permanece

### Teste de whitelist (deve permitir)

1. Cadastre um número na tabela `trusted_senders`
2. Envie mensagem com esse número (mesmo não sendo admin)
3. Resultado esperado: mensagem permanece

---

## ⚠️ Quando Usar e Quando Não Usar

### ✅ Use em

- Grupos de lançamento de produtos
- Grupos de avisos / comunicados
- Comunidades controladas
- Grupos VIP com acesso restrito

### ❌ Não use em

- Grupos de conversa livre entre amigos
- Suporte aberto ao cliente
- Comunidades públicas onde todos devem poder falar

> Este sistema é **agressivo por design**: apaga toda mensagem de não-admin sem análise de conteúdo.

---

## 🧩 Troubleshooting

### ❌ Mensagem não foi apagada

Verifique:
- O bot é **admin** do grupo?
- O grupo está cadastrado em `group_policies`?
- O webhook está ativo no n8n?
- O evento `MESSAGES_UPSERT` está habilitado na Evolution?
- O `participant` no payload está vindo corretamente? (tente `participantAlt`)

### ❌ Bootstrap não encontra grupos

Verifique:
- A instância Evolution está com status `connected`?
- O parâmetro `getParticipants=true` está sendo enviado?
- A API Key está correta nas variáveis de ambiente?

### ❌ Score não está sendo calculado

Verifique:
- O Schedule Trigger (Fluxo 02) está **ativo**?
- A tabela `participant_snapshots` tem dados? (precisa do bootstrap)
- As credenciais do banco estão corretas no nó `Aggregate Signals`?

### ❌ Erro no node Evaluate Moderation

Causa provável:
- Falta do nó **Merge** antes do Evaluate Moderation
- A busca de membros na Evolution retornou vazio
- Formato do `participant` diferente do esperado — tente normalizar via `digitsOnly()`

### ❌ Admin está sendo moderado

Verifique:
- O bootstrap foi executado? A tabela `participant_snapshots` tem o registro do admin com `is_admin = true`?
- A busca ao vivo de membros (`Find Group Members`) está retornando a lista correta?
- O número do admin está no mesmo formato que o `senderJid` do webhook?

---

## 🏗️ Arquitetura Resumida

```
[WhatsApp]
    ↓ mensagem
[Evolution API]
    ↓ webhook POST
[n8n — Fluxo 01]
    ↓ normaliza evento
    ↓ verifica group_policies
    ↓ busca membros (Evolution)
    ↓ avalia: admin? whitelist? score?
    ├── Sim → passa
    └── Não → deleta mensagem + loga incidente + alerta admin
    
[n8n — Fluxo 02] (a cada 10 min)
    ↓ agrega sinais por telefone
    ↓ calcula score de risco (0–100)
    ↓ salva em contact_scores

[n8n — Fluxo 00] (execução única manual)
    ↓ busca todos os grupos
    ↓ explode participantes
    ↓ popula participant_snapshots
```

---

## 📋 Boas Práticas

- **Sempre configure a whitelist** antes de ativar em produção — evita moderar equipe interna
- **Teste em um grupo separado** antes de ativar nos grupos reais
- **Comece sem remoção** (`auto_remove_enabled = false`) e valide por alguns dias
- **Monitore a tabela `moderation_incidents`** nos primeiros dias para detectar falsos positivos
- **Mantenha o bot como admin** — se ele perder o status de admin, para de funcionar silenciosamente

---

## 👩‍💻 Desenvolvimento

Desenvolvido por **Ana Paula Perci**
