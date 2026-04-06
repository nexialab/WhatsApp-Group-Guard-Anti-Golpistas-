# WhatsApp-Group-Guard-Anti-Golpistas-

🚀 Visão Geral

O WhatsApp Group Guard é um sistema de moderação automática para grupos de WhatsApp, desenvolvido utilizando:

n8n (orquestração de fluxos)
Evolution API (integração com WhatsApp)
PostgreSQL / Supabase (persistência e inteligência)

O objetivo do sistema é:

🔥 Proteger grupos contra golpistas e mensagens maliciosas em tempo real

👩‍💻 Desenvolvimento

Este projeto foi desenvolvido por:

Ana Paula Perci

🎯 Problema que resolve

Em lançamentos e comunidades grandes, é comum:

Golpistas entrarem em grupos
Enviarem mensagens com:
PIX
links falsos
“chama no privado”
Admins não conseguirem acompanhar em tempo real
💡 Solução

O sistema atua como um moderador automático, capaz de:

Monitorar mensagens em grupos
Identificar remetentes
Verificar permissões (admin vs não-admin)
Aplicar regras de moderação
Apagar mensagens automaticamente
(Opcional) Remover participantes
🧠 Como funciona (Arquitetura)

O sistema é composto por 3 camadas:

1. 🔁 Monitoramento em tempo real

Workflow principal no n8n:

Recebe eventos via webhook da Evolution
Normaliza o payload
Identifica:
grupo
remetente
mensagem
2. 🧩 Enriquecimento de dados

O fluxo consulta:

👥 Participantes do grupo (Find Group Members)
⚙️ Configuração do grupo (Load Group Policy)
🧾 Whitelist
📊 Score histórico (opcional)
3. ⚔️ Motor de decisão (Evaluate Moderation)

Regra atual do sistema:

SE usuário NÃO é admin
→ mensagem é apagada automaticamente

Com suporte a:

whitelist
regras por grupo
thresholds (modo avançado)
4. 🧨 Ação

Se necessário:

🗑️ Deleta mensagem
🚫 (Opcional) remove usuário
📢 alerta admin
🏗️ Estrutura do Projeto
/workflows
  ├── realtime_moderation.json
  ├── bootstrap_sync.json
  ├── score_engine.json

/database
  ├── schema.sql

/README.md
⚙️ Setup do Projeto
🧱 1. Banco de Dados (Supabase ou PostgreSQL)
Criar banco

Você pode usar:

Supabase (recomendado)
PostgreSQL local
VPS
Rodar o schema

Execute o arquivo:

00_schema.sql

Isso cria:

group_policies
trusted_senders
participant_snapshots
moderation_incidents
contact_scores
🤖 2. Evolution API
Criar instância
Criar instância na Evolution
Conectar WhatsApp via QR Code
Confirmar status: connected
⚠️ IMPORTANTE

A conta conectada deve:

Estar nos grupos
Ser ADMIN dos grupos

Sem isso:

❌ não consegue deletar mensagens
❌ não consegue remover usuários
Configurar Webhook

Apontar para o n8n:

POST /webhook/evolution-group-moderation

Eventos necessários:

MESSAGES_UPSERT
GROUP_PARTICIPANTS_UPDATE
GROUPS_UPSERT
🔗 3. n8n
Importar workflows

Importe os arquivos JSON:

realtime moderation
bootstrap sync
score engine
Configurar credenciais
PostgreSQL / Supabase
Host
Port
Database
User
Password
Evolution API
Base URL
Instance Name
API Key
🔄 Fluxos do Sistema
🧪 Workflow 1 — Bootstrap (Inicial)

Função:

Buscar todos os grupos
Buscar participantes
Popular banco (participant_snapshots)

Execução:

Manual (1x ou quando necessário)
⚙️ Workflow 2 — Realtime Moderation

Função:

Receber mensagens
Avaliar remetente
Aplicar regra
Deletar mensagem
📊 Workflow 3 — Score Engine (Opcional)

Função:

Calcular score de risco
Identificar padrões entre grupos
🔥 Regra atual de moderação
Modo agressivo (ativo)
SE NÃO É ADMIN → APAGA
Com whitelist

Se estiver em:

trusted_senders

→ NÃO apaga

🧪 Como testar
Passo 1

Rodar bootstrap

Passo 2

Verificar tabela:

participant_snapshots
Passo 3

Criar policy

INSERT INTO group_policies (group_jid, group_name)
VALUES ('SEU_GRUPO@g.us', 'Grupo Teste');
Passo 4

Rodar realtime

mandar mensagem com usuário não-admin
verificar:
shouldDelete: true
Passo 5

Verificar se apagou no grupo

⚠️ Cuidados importantes
⚠️ 1. Use em grupos corretos

Esse sistema é agressivo.

Use apenas em:

grupos de aviso
grupos de lançamento
grupos onde só admins devem falar
⚠️ 2. Whitelist

Adicione:

INSERT INTO trusted_senders (phone)
VALUES ('553199999999');

Para evitar bloquear:

equipe
suporte
vendas
⚠️ 3. Delay do WhatsApp

O delete só funciona se:

mensagem ainda está dentro do tempo permitido
instância tem permissão
🧠 Melhorias futuras
Detecção automática de ataque
Score inteligente por comportamento
Dashboard de moderação
Logs e métricas
Modo híbrido (IA + regra)
🧩 Troubleshooting
❌ Mensagem não apaga

Verificar:

instância é admin?
participant está correto?
ID da mensagem correto?
webhook está funcionando?
❌ Node não executa

Provável causa:

falta de Merge entre nodes
❌ Evaluate Moderation quebra

Verificar:

nome dos nodes
fluxo executado completo
payload da Evolution
🧠 Conceito chave do sistema

Esse projeto NÃO é só automação.

Ele é:

🔥 Um firewall comportamental para grupos de WhatsApp

🚀 Resultado esperado
0 mensagens de golpistas visíveis
redução drástica de fraude
proteção em escala
operação automática
📞 Contato interno

Projeto mantido por:
Ana Paula Perci

🧠 Conclusão

Esse sistema transforma grupos de WhatsApp em ambientes controlados e seguros, mesmo em cenários de alto volume e ataque coordenado.
