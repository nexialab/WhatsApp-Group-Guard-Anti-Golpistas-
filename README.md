# Evolution Guard para n8n

Pacote com 3 workflows e um schema SQL para monitorar grupos de WhatsApp via Evolution API e moderar mensagens suspeitas.

## Arquivos
- `00_schema.sql`
- `01_realtime_moderation_workflow.json`
- `02_initial_group_sync_workflow.json`
- `03_score_recalculation_workflow.json`

## Variáveis de ambiente esperadas no n8n
Defina estas envs no container do n8n:
- `EVOLUTION_BASE_URL=https://seu-dominio-evolution`
- `EVOLUTION_INSTANCE=nome-da-instancia`
- `EVOLUTION_API_KEY=sua-api-key`

## Credenciais
Nos nodes Postgres, substitua `__SET_POSTGRES_CREDENTIAL__` pela credencial real no n8n após importar.

## Ordem de implantação
1. Rode o `00_schema.sql` no Postgres.
2. Importe os 3 workflows no n8n.
3. Aponte os nodes Postgres para sua credencial.
4. Configure o webhook da Evolution para chamar:
   `POST https://SEU_N8N/webhook/evolution-group-moderation`
5. Na Evolution, habilite ao menos estes eventos:
   - `MESSAGES_UPSERT`
   - `GROUP_PARTICIPANTS_UPDATE`
   - `GROUPS_UPSERT`
6. Faça a sincronização inicial executando manualmente o workflow `02_initial_group_sync_workflow.json`.
7. Ative os workflows 1 e 3.

## Observações importantes
- Para deletar mensagem de terceiros e remover membros, a instância conectada precisa ser admin do grupo.
- O workflow de moderação aplica score básico por texto + score histórico vindo da tabela `contact_scores`.
- Ajuste regexes e limiares no node `Evaluate Moderation`.
- O endpoint de remoção pode variar entre versões da Evolution. Se a sua versão usar outro path, ajuste o node `Remove Participant`.
- O endpoint de deleção foi configurado como `DELETE /chat/deleteMessageForEveryone/{instance}` com body `{ id, remoteJid, fromMe, participant }`.
- O sync inicial usa `getParticipants=true` no endpoint `fetchAllGroups`, conforme a documentação atual.

## Recomendação prática
Comece com:
- `auto_delete_enabled = true`
- `auto_remove_enabled = false`
- validar por 1 ou 2 dias
- depois habilitar remoção automática

## Melhorias sugeridas
- adicionar Redis para cache de admins por grupo
- integrar alertas no Chatwoot/Slack
- criar dashboard com Metabase/Supabase
- adicionar allowlist dinâmica via painel interno
