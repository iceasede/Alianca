IGREJA COMUNIDADE EVANGÉLICA DA ALIANÇA — VERSÃO 31

Esta atualização corrige a exibição do formulário de cadastro público em três etapas. Agora somente a etapa ativa fica visível; as etapas seguintes permanecem ocultas até a pessoa avançar pelo botão Continuar. Também reforça a navegação acessível entre as etapas.

Etapas: 1) Dados pessoais; 2) Sua caminhada com a igreja; 3) Participação. A própria pessoa poderá atualizar seus dados pessoais quando o perfil individual estiver ativo. A classificação de vínculo (visitante, novo convertido, membro ou interessado) ficará reservada à equipe administrativa autorizada.

IMPORTANTE: o formulário ainda é demonstrativo. Não envia nem armazena cadastros. Banco de dados, login individual, permissões reais e histórico de alterações precisam ser implantados com autenticação e segurança antes de receber dados pessoais reais.

Para atualizar: extraia o ZIP e substitua os arquivos na raiz do repositório GitHub: index.html, sw.js, manifest.webmanifest, logo-alianca.png e logo-alianca.jpg. Faça Commit changes e aguarde a publicação do GitHub Pages.


## Versão 32 — autenticação inicial com Supabase
- O formulário público cria uma conta com e-mail e senha no Supabase Auth.
- Os dados cadastrais básicos são enviados como metadados da conta autenticada.
- A Área de Membros permite entrar com e-mail e senha, solicitar redefinição de senha e direciona “Quero me cadastrar” ao formulário público.
- A confirmação de e-mail depende da configuração do projeto Supabase.
- A criação da conta NÃO concede função administrativa.
- A sincronização dos dados para a tabela `profiles`, permissões por congregação, aprovação administrativa e auditoria ainda precisam ser configuradas e testadas no banco antes de usar com dados reais.
- A chave Publishable fica no código do navegador; nunca inserir Secret key ou service_role no site.


## Versão 33 – ajuste da Área de Membros
- O botão “Quero me cadastrar” direciona diretamente para a primeira etapa do cadastro.
- A versão mantém a integração de autenticação Supabase já configurada na versão anterior.
- O cache do aplicativo foi atualizado para forçar a recarga dos arquivos após a publicação.


## Versão 34 — redirecionamento após autenticação
- Após entrar com e-mail e senha, o usuário é levado automaticamente à página inicial.
- A página inicial exibe uma saudação de acesso realizado.
- O mesmo redirecionamento é aplicado quando o Supabase informa uma sessão autenticada, inclusive após confirmação de e-mail.
- A sessão continua sendo mantida pelo Supabase Auth no navegador.
- O cache do service worker foi atualizado para a versão 34.
