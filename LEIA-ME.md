# Aplicativo Aliança — protótipo inicial

Este pacote contém a primeira interface navegável do aplicativo da Comunidade Evangélica da Aliança.

## Identidade visual
A logo oficial enviada foi incluída no cabeçalho do aplicativo como `logo-alianca.jpg`.

## O que já está incluído
- Layout responsivo para celular e computador.
- Navegação entre Início, Agenda, Ministérios, Pedidos de oração, Cultos ao vivo, Devocional, Área de membros, Contribuições e Galeria.
- Manifesto PWA e service worker inicial para permitir instalação quando hospedado em HTTPS.
- Conteúdo demonstrativo claramente identificado.

## Importante: ainda não é uma versão pronta para os membros
Não há banco de dados, autenticação, envio real de pedidos, notificações push, pagamentos, upload de fotos ou painel administrativo. Essas partes precisam ser conectadas e testadas antes de divulgar o aplicativo. Em especial, cadastro e área de membros devem usar autenticação e regras de acesso seguras.

## Próximas informações necessárias
1. Logo oficial em PNG/SVG e cores institucionais (se houver).
2. Endereço da igreja e contatos oficiais.
3. Programação atual confirmada.
4. Link do YouTube/transmissão.
5. Chave Pix e instruções oficiais, somente se a liderança quiser exibir no app.
6. Lista de ministérios e responsáveis que podem ser divulgados.

## Como visualizar
Abra `index.html` no navegador para testar a interface. Para instalar como PWA, publique os arquivos em um domínio HTTPS; depois use “Adicionar à Tela de Início” no iPhone ou “Instalar app” no Android, conforme o navegador.


## Administração definida
A igreja escolheu uma **equipe de administradores**. Na próxima etapa, recomendamos permissões por função:
- **Administrador geral:** configura o aplicativo e gerencia acessos.
- **Comunicação:** publica avisos, agenda, fotos e vídeos.
- **Líderes de ministérios:** enviam propostas de atualização do próprio departamento, sem publicação direta.
- **Apóstolos:** avaliam e aprovam as alterações antes de qualquer publicação.
- **Equipe de oração:** acessa somente os pedidos de oração autorizados.

Essas permissões ainda precisam ser implementadas no backend com login individual, regras de acesso e proteção dos dados. Não compartilhe senhas entre os administradores.

## Fluxo obrigatório de aprovação
Toda alteração enviada por líderes de ministérios deve ficar como **pendente de avaliação**. Somente os Apóstolos podem aprovar a publicação. O sistema final deverá registrar quem enviou, quem avaliou, a decisão e a data, sem permitir publicação direta pelo líder.
