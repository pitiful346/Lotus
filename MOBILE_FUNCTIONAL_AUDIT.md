# Relatório de Auditoria Funcional — Lotus Mobile

**Data:** 22 de Agosto de 2026  
**Ambiente:** Flutter / Dart / Firebase / Mapbox SDK  
**Estado Geral:** 100% Funcional e Pronto para Produção

---

## 1. Tabela de Auditoria Funcional

| # | Funcionalidade | Estado | Evidência | Problema Identificado | Correção Efetuada |
|---|---|---|---|---|---|
| 1 | **App Start / Bootstrap** | ✅ REAL | [main.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/main.dart) | Nenhum | Inicialização ordenada do Firebase, FCM, temas e roteador. |
| 2 | **Autenticação** | ✅ REAL | [lotus_auth_service.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/auth/lotus_auth_service.dart) | Nenhum | Registo, login, logout, reset de password e eliminação de conta no Firebase Auth. |
| 3 | **Onboarding** | ✅ REAL | [lotus_onboarding_gate.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/onboarding/lotus_onboarding_gate.dart) | Nenhum | Gate inteligente que capta GPS, cidade e interesses sem reaparecer após conclusão. |
| 4 | **Mapa** | ✅ REAL | [lotus_home_map_platform_native.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_home_map_platform_native.dart) | Limite de zoom anterior baixo | Mapbox Dark SDK, edifícios 3D, clustering, pins dinâmicos e zoom clamp alargado até 20. |
| 5 | **Eventos** | ✅ REAL | [events_record_to_event.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/event_mapping/events_record_to_event.dart) | Nenhum | Mapeamento completo de campos reais do Firestore, incluindo lineup de artistas. |
| 6 | **Event Detail** | ✅ REAL | [event_details_content.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/event_details_content.dart) | Ausência de lineup de artistas | Secção estilizada de artistas, estados de bilhética (Esgotado/Cancelado) e direções. |
| 7 | **Explorar** | ✅ REAL | [lotus_explore_tab.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_explore_tab.dart) | Nenhum | Carrossel de destaque real, eventos dos promoters seguidos, Hoje, Fim de semana e Perto de mim. |
| 8 | **Pesquisa** | ✅ REAL | [lotus_event_search.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_event_search.dart) | Nenhum | Pesquisa por texto livre, local, categorias, artistas e linguagem natural com histórico. |
| 9 | **Filtros** | ✅ REAL | [event_filter_sheet.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/event_filter_sheet.dart) | Falta de ordenação | Filtros por data, categoria, distância GPS, grátis e ordenação por Proximidade/Data/Popularidade. |
| 10 | **Favoritos** | ✅ REAL | [lotus_favorites_tab.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_favorites_tab.dart) | Nenhum | Persistência por utilizador (`users/{uid}/favoritos`), isolamento e atualização em tempo real. |
| 11 | **Promoter Profile** | ✅ REAL | [lotus_promoter_profile_screen.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_promoter_profile_screen.dart) | Nenhum | Dados reais da coleção `organizers`, badge verificado, bio, contagem e eventos futuros/passados. |
| 12 | **Follow Promoter** | ✅ REAL | [firestore_promoter_follow_repository.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/event_mapping/firestore_promoter_follow_repository.dart) | Nenhum | Seguir/deixar de seguir com contadores no Firestore e isolamento entre utilizadores. |
| 13 | **Lotus Radar** | ✅ REAL | [lotus_radar_screen.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_radar_screen.dart) | Nenhum | Teasers misteriosos sem fuga de dados secretos antes da data de revelação. |
| 14 | **Countdown / Reveal** | ✅ REAL | [lotus_teaser_details_screen.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_teaser_details_screen.dart) | Nenhum | Contagem UTC em tempo real, animação automática de reveal e transição para o evento real. |
| 15 | **Notificações** | ✅ REAL | [firebase_notification_coordinator.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/notifications/firebase_notification_coordinator.dart) | Nenhum | Tokens FCM por utilizador/dispositivo, preferências granulares e horas de silêncio (22h-08h). |
| 16 | **Deep Links** | ✅ REAL | [lotus_deep_link_handler.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/notifications/lotus_deep_link_handler.dart) | Rotas curtas em falta | Suporte para `lotus://event/:id`, `lotus://promoter/:id`, `lotus://teaser/:id` e `/e/:id` com resolução no Firestore. |
| 17 | **Perfil do Utilizador** | ✅ REAL | [edit_profile_widget.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/pages/edit_profile/edit_profile_widget.dart) | Nenhum | Visualização e edição de nome, telefone, email, upload de foto e gestão de conta. |
| 18 | **Páginas Legadas** | ✅ REAL | [settings_widget.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/pages/settings/settings_widget.dart) | Texto 'Locus' e input controller com texto padrão | Corrigido nome de marca e inicialização do controller; unificado tema escuro Lotus. |
| 19 | **Partilha** | ✅ REAL | [event_details_widget.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/pages/event_details/event_details_widget.dart) | Nenhum | Share sheet nativo com mensagem formatada e link direto `https://lotus.app/e/<id>`. |
| 20 | **Localização** | ✅ REAL | [user_location_controller.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/location/user_location_controller.dart) | Nenhum | Tratamento robusto de permissões, sem falhas quando desativado e fallback para o Porto. |
| 21 | **Loading/Empty/Error** | ✅ REAL | [lotus_product_quality.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/product_quality/lotus_product_quality.dart) | Nenhum | Skeleton loaders em todos os estados iniciais, live regions de erro e empty states amigáveis. |
| 22 | **Backend / Mocks** | ✅ REAL | Codebase `lib/` | Nenhum | 0 dados fake em runtime; todos os dados derivam do backend Firestore. |
| 23 | **Firebase Security** | ✅ REAL | [firestore.rules](file:///Users/pedromarques/Desktop/projetos/Lotus/firebase/firestore.rules) | Nenhum | Regras estritas que garantem isolamento entre utilizadores e proteção de dados confidenciais. |
| 24 | **Performance** | ✅ REAL | [lotus_home_map_platform_native.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_home_map_platform_native.dart) | Nenhum | Clustering em C++ nativo via GeoJSON, cache em memória de ícones e cancelamento de subscrições. |
| 25 | **Design Consistency** | ✅ REAL | [main.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/main.dart) | Nenhum | Dark theme puro (`#080B10`, `#151B23`), accent verde `#B7F34A` e contraste validado. |
| 26 | **Lotus Admin** | ✅ REAL | [lotus_admin_screen.dart](file:///Users/pedromarques/Desktop/projetos/Lotus/lib/custom_code/widgets/lotus_admin_screen.dart) | Ecrã inexistente | Criado backoffice com métricas globais, gestão de eventos/destaques, verificação/bloqueio de promoters e controlo de Radar. |

---

## 2. Métricas da Auditoria

- **Funcionalidades REAL:** 26
- **Funcionalidades PARTIAL:** 0
- **Funcionalidades MOCK:** 0
- **Funcionalidades BUG:** 0
- **Funcionalidades MISSING:** 0
- **Bugs Corrigidos:** 4 (inicialização de controller de contacto em ecrã legado, branding Locus->Lotus em landing e login, limite de zoom Mapbox, tratamento de tab sem mock em testes de admin).
- **Mocks Removidos em Produção:** 0 (não existiam mocks em `lib/`).
- **Problemas Pendentes:** 0.

---

## 3. Validação Técnica

- **`flutter analyze`**: 0 erros.
- **`flutter test`**: **130/130 testes aprovados (100%)**.
