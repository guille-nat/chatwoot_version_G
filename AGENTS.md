# CLAUDE.md — CoopFlow Development Guide

> Proyecto: CoopFlow
> Tipo: SaaS multiempresa para cooperativas agropecuarias argentinas
> Base conversacional: Chatwoot Fork
> Dominio principal: Agro + IA + Operaciones + WhatsApp

archivos relevantes:
- doc/CoopFlow_PRD_v1.0.md
- doc/vision_&_product_context.md 
- doc/product_roadmap.md
---

# 1. Identidad del proyecto

CoopFlow NO es Chatwoot.

Chatwoot es únicamente la infraestructura conversacional sobre la cual se construye el producto.

CoopFlow es un sistema operativo para cooperativas agropecuarias argentinas.

El objetivo principal es digitalizar la relación entre la cooperativa y sus asociados utilizando WhatsApp como interfaz principal y un núcleo de negocio propio llamado Coop Core.

Toda decisión de arquitectura debe priorizar el dominio agropecuario antes que la mensajería.

---

# 2. Filosofía del producto

- WhatsApp First
- API First
- IA asiste, las personas deciden
- Integrar antes que reemplazar
- Modular
- Multiempresa
- Auditabilidad completa
- Información accionable
- Automatización operativa
- Español argentino como idioma nativo

---

# 3. Qué es CoopFlow

CoopFlow integra:

- Conversaciones
- Solicitudes
- Cupos de descarga
- Transporte
- Mercado de granos
- Clima
- Agronomía
- Documentos
- Alertas
- Automatizaciones
- Analítica
- IA

El productor nunca debería sentir que está usando un software.

Debe sentir que está hablando con su cooperativa.

---

# 4. Público objetivo

## Cliente

Cooperativas agropecuarias argentinas.

## Usuarios internos

- Operadores
- Logística
- Administración
- Agrónomos
- Comerciales
- Gerentes
- Dirección

## Usuario final

Productores asociados.

---

# 5. WhatsApp First

Toda funcionalidad debe poder ejecutarse mediante lenguaje natural.

Ejemplos válidos:

- ¿Cómo está la soja?
- Mandame el gráfico del último año.
- Avisame cuando pase los 400 dólares.
- Necesito un cupo para mañana.
- Quiero cerrar precio.
- Necesito un camión.
- Comprame 20 bolsas de maíz.
- Mandame mi liquidación.
- ¿Cómo viene el clima?
- ¿Va a haber viento mañana?
- Necesito una visita del agrónomo.
- Te mando una foto del lote.

Si una funcionalidad solo existe en el Dashboard, es una implementación incompleta.

---

# 6. IA

La IA nunca reemplaza decisiones humanas.

La IA puede:

- interpretar mensajes
- clasificar solicitudes
- extraer datos
- resumir conversaciones
- transcribir audios
- analizar imágenes
- generar tareas
- sugerir respuestas
- generar reportes
- detectar prioridades

La IA nunca debe:

- aprobar operaciones comerciales
- cerrar contratos automáticamente
- modificar datos críticos sin confirmación
- asumir información faltante
- tomar decisiones financieras
- comprometer precios
- autorizar créditos

---

# 7. Idioma y localización

TODO el producto está pensado para Argentina.

## Obligatorio

- Idioma principal: español
- Locale: es-AR
- Zona horaria: America/Argentina/Buenos_Aires
- Fechas: DD/MM/AAAA
- Decimales: coma
- Moneda: ARS / USD
- Unidades: sistema métrico

## Prohibido

- Respuestas automáticas en inglés
- Traducciones innecesarias
- Formatos estadounidenses
- Terminología técnica frente al productor

---

# 8. Transcripción de audios

Todas las transcripciones deben realizarse en español argentino.

## Configuración obligatoria

- language: es
- locale: es-AR

## Reglas

- Conservar nombres propios
- Conservar números
- Conservar toneladas
- Conservar hectáreas
- Conservar variedades
- Conservar siglas agrícolas
- No traducir marcas

Ejemplo:

Correcto:
"Necesito descargar 28 toneladas de maíz mañana en la planta de Armstrong."

Incorrecto:
"I need to unload 28 tons of corn tomorrow."

---

# 9. OCR y documentos

El OCR debe estar optimizado para documentos argentinos.

Tipos soportados:

- Facturas
- Cartas de porte
- Liquidaciones
- Contratos
- Recetas agronómicas
- Análisis de suelo
- Remitos
- PDFs
- Imágenes

Extraer:

- CUIT
- Fecha
- Número
- Producto
- Cantidad
- Importe
- Patente
- Destino
- Observaciones

---

# 10. Filosofía de Chatwoot

Modificar Chatwoot lo menos posible.

Chatwoot administra:

- conversaciones
- contactos
- agentes
- equipos
- mensajes
- archivos
- estados de atención

La lógica agrícola pertenece a Coop Core.

Siempre preferir:

- Webhooks
- APIs
- Servicios externos
- Extensiones
- Paneles laterales

Evitar modificar el core de Chatwoot salvo que sea estrictamente necesario.

---

# 11. Arquitectura

Productor
↓
WhatsApp
↓
Chatwoot Fork
↓
Eventos
↓
Coop Core
↓
Servicios
↓
Integraciones

Nunca invertir este flujo.

---

# 12. Base de datos

Nunca guardar información agrícola en tablas de Chatwoot.

Usar tablas propias.

## Entidades principales

- cooperatives
- branches
- producers
- fields
- plots
- campaigns
- crops
- requests
- deliveries
- unloading_slots
- transport_orders
- grain_contracts
- market_prices
- weather_alerts
- agronomy_visits
- documents
- notifications
- automation_rules

---

# 13. Solicitudes

Todo proceso operativo es una Solicitud.

## Tipos

- unloading_slot
- delivery
- transport
- purchase
- sale
- agronomy
- document
- claim
- consultation

## Estados

- new
- waiting_information
- under_review
- assigned
- in_progress
- completed
- cancelled

Una conversación puede generar múltiples solicitudes.

---

# 14. Mercado de granos

El mercado es un módulo principal.

Nunca hardcodear mercados.

Diseñar proveedores intercambiables.

## Mercados

- Rosario
- MATBA
- ROFEX
- Chicago
- Bahía Blanca
- Necochea

## Funciones

- Precio actual
- Variación
- Histórico
- Gráficos
- Alertas
- Objetivos
- Cierre de precio
- Contratos
- Posiciones

---

# 15. Clima

El clima es un módulo principal.

Nunca depender de una sola fuente.

## Variables

- temperatura
- lluvia
- viento
- humedad
- punto de rocío
- presión
- evapotranspiración
- temperatura de suelo
- humedad de suelo

## Alertas

- granizo
- helada
- viento fuerte
- lluvia intensa
- sequía

## Variables agrícolas

- ventana de pulverización
- ventana de cosecha
- riesgo de deriva
- riesgo de helada

---

# 16. Agronomía

Funciones:

- agenda
- visitas
- recorridas
- fotos
- observaciones
- recomendaciones
- tareas
- seguimiento

La IA puede generar un análisis preliminar pero nunca un diagnóstico definitivo.

---

# 17. Integraciones ERP

CoopFlow NO implementa un ERP.

Integrarse con:

- Finnegans
- Albor
- SAP
- Tango
- Sistemas propios

## Regla

Si una función ya existe correctamente en el ERP, integrar.

No duplicar.

---

# 18. API First

Toda funcionalidad debe existir como API.

Luego podrá consumirse desde:

- WhatsApp
- Dashboard
- Portal web
- App móvil
- Integraciones externas

Usar:

- REST
- JSON
- Versionado
- Idempotencia
- Webhooks

---

# 19. Seguridad

Obligatorio:

- JWT
- Refresh tokens
- RBAC
- Auditoría
- Logs
- Rate limiting
- Encriptación en tránsito
- Encriptación en reposo para datos sensibles

Nunca exponer información financiera sin autorización.

---

# 20. Multiempresa

Cada cooperativa es un tenant.

Aislamiento obligatorio.

Nunca compartir:

- productores
- documentos
- conversaciones
- precios privados
- contratos
- configuraciones

---

# 21. UX

Toda pantalla debe responder una pregunta.

- ¿Qué está pendiente?
- ¿Qué requiere atención?
- ¿Qué genera dinero?
- ¿Qué bloquea una operación?

Eliminar ruido visual.

Priorizar:

- rapidez
- legibilidad
- estados claros
- acciones directas

---

# 22. Mensajes al productor

Usar lenguaje simple.

Correcto:
"Tu cupo fue confirmado para mañana a las 9:00."

Incorrecto:
"El workflow de descarga fue completado."

Nunca usar jerga técnica de software.

---

# 23. Automatizaciones

Las automatizaciones deben ser configurables.

Ejemplos:

- Recordatorio de cupo
- Aviso de lluvia
- Precio objetivo alcanzado
- Documento disponible
- Solicitud sin respuesta
- Visita programada
- Vencimiento de factura

---

# 24. Feed inteligente

El sistema debe poder generar un resumen personalizado por productor.

Ejemplo:

- Precio soja
- Lluvia esperada
- Viento
- Alertas
- Cupos
- Documentos
- Visitas
- Promociones relevantes

El objetivo es entregar contexto, no solo datos.

---

# 25. Analítica

El Dashboard debe responder preguntas.

- ¿Qué sucursal tiene más demoras?
- ¿Qué productores consultan más?
- ¿Qué solicitudes están vencidas?
- ¿Qué agrónomo tiene mayor carga?
- ¿Qué cultivo genera más consultas?

---

# 26. AI Agents

Los agentes deben pensar como empleados de una cooperativa.

## Operador

Prioriza atención y derivación.

## Logística

Prioriza cupos, entregas y transporte.

## Administración

Prioriza documentos y estados.

## Agrónomo

Prioriza visitas y alertas.

## Comercial

Prioriza oportunidades y seguimiento.

## Gerente

Prioriza KPIs y decisiones.

Cada agente solo recibe el contexto necesario.

---

# 27. Build / Test / Run

## Setup

bundle install && pnpm install

## Run

pnpm dev
overmind start -f Procfile.dev

## Ruby

Usar rbenv y la versión de .ruby-version.

Siempre usar bundle exec.

---

# 28. Lint

## Ruby

bundle exec rubocop -a

## JS

pnpm eslint
pnpm eslint:fix

---

# 29. Tests

## Ruby

bundle exec rspec

## JS

pnpm test

No escribir tests salvo que:

- se modifique lógica crítica
- se agregue una API
- se cambie un workflow
- se corrija un bug importante

---

# 30. Estilo de código

- Código simple
- Happy path primero
- Sin sobreingeniería
- Sin duplicación
- Nombres descriptivos
- Métodos cortos
- Servicios por responsabilidad

---

# 31. Tailwind

- Solo Tailwind
- Sin CSS custom
- Sin inline styles
- Sin scoped CSS

---

# 32. Decisiones de producto

Antes de implementar preguntar:

1. ¿Lo necesita una cooperativa?
2. ¿Puede hacerse por WhatsApp?
3. ¿Existe integración?
4. ¿Duplica el ERP?
5. ¿Genera valor económico?
6. ¿Reduce trabajo?
7. ¿Reduce errores?
8. ¿Mejora una decisión?

Si la mayoría es NO, no construir.

---

# 33. Commits

Usar Conventional Commits.

Ejemplos:

- feat(market): add grain price alerts
- feat(weather): add spraying window
- feat(slots): add unloading slot workflow
- fix(ai): improve spanish transcription

No mencionar Claude.

---

# 34. PRs

Incluir:

- cambio funcional
- impacto al usuario
- cómo probar
- riesgos
- migraciones
- integraciones

---

# 35. Roadmap conceptual

F1 Plataforma
F2 Solicitudes
F3 Mercado
F4 Clima
F5 Agronomía
F6 Comercial
F7 Documentos
F8 Inteligencia
F9 Automatizaciones
F10 Portal

---

# 36. Regla de oro

CoopFlow no compite por tener más pantallas.

Compite por:

- menos llamadas
- menos mensajes perdidos
- menos planillas
- menos errores
- más ventas
- mejores decisiones
- más tiempo para el productor y la cooperativa

Toda línea de código debe acercar al sistema a ese objetivo.


---

# Modular Product Architecture

CoopFlow está diseñado como una plataforma modular.

Todas las funcionalidades deben desarrollarse como módulos independientes.

Los módulos pueden habilitarse, deshabilitarse, licenciarse y configurarse sin modificar el resto del sistema.

Nunca asumir que un módulo está disponible.

Toda funcionalidad debe consultar el sistema de Feature Flags antes de ejecutarse.

---

# Feature Flags

Toda funcionalidad del sistema debe estar protegida mediante Feature Flags.

Nunca utilizar validaciones basadas únicamente en el plan comercial.

Incorrecto

if plan == "enterprise"

Correcto

Feature.enabled?(:market)

Feature.enabled?(:weather)

Feature.enabled?(:documents)

Feature.enabled?(:ai)

Los Feature Flags deben poder activarse para:

- una cooperativa
- una sucursal
- un usuario
- un rol
- un ambiente
- un grupo beta

---

# Planes comerciales

Los planes comerciales son únicamente conjuntos de funcionalidades.

Ejemplo:

Starter

- Conversaciones
- Productores
- Solicitudes

Professional

Todo Starter +

- Mercado
- Clima
- Documentos
- IA

Enterprise

Todo Professional +

- ERP
- Automatizaciones
- Analytics
- API Premium
- Branding
- SSO

Los planes nunca deben contener lógica de negocio.

Los planes únicamente habilitan funcionalidades.

---

# Add-ons

Toda funcionalidad debe poder venderse individualmente.

Ejemplos:

- Mercado
- Clima
- OCR
- Speech to Text
- Vision AI
- Portal del Asociado
- Integraciones ERP
- Automatizaciones
- Analytics

El sistema debe permitir agregar módulos sin modificar código existente.

---

# Panel Super Administrador

Debe existir un panel exclusivo para la administración global del SaaS.

Desde este panel debe ser posible administrar:

- Cooperativas
- Suscripciones
- Planes
- Feature Flags
- Módulos
- Integraciones
- Branding
- Límites
- Facturación
- Auditoría

Toda configuración realizada desde este panel debe aplicarse inmediatamente sin necesidad de desplegar una nueva versión.

---

# Gestión de funcionalidades

Cada módulo debe permitir:

- habilitarse
- deshabilitarse
- configurarse
- versionarse
- licenciarse
- auditarse

Nunca eliminar código porque un cliente no tenga acceso.

Simplemente ocultar la funcionalidad mediante Feature Flags.

---

# Menú dinámico

El Dashboard nunca debe asumir un menú fijo.

El menú debe construirse dinámicamente según:

- módulos habilitados
- permisos del usuario
- rol
- sucursal
- cooperativa

Si un módulo no está habilitado, no debe mostrarse.

---

# Data Ownership

Toda la información pertenece a la cooperativa.

CoopFlow únicamente administra esa información.

El cliente nunca debe quedar cautivo del sistema.

Toda entidad importante debe poder:

- importarse
- exportarse
- respaldarse
- restaurarse
- sincronizarse mediante API

---

# Importación

Todo módulo nuevo debe implementar un sistema de importación.

Formatos mínimos soportados:

- CSV
- XLSX
- JSON

La importación debe incluir:

- validación previa
- vista previa
- detección de errores
- reporte de resultados
- rollback cuando sea posible

---

# Exportación

Toda información importante debe poder exportarse.

Como mínimo:

- Productores
- Campos
- Lotes
- Cultivos
- Solicitudes
- Conversaciones
- Documentos
- Contratos
- Cotizaciones
- Reportes
- Auditorías
- Configuraciones
- Usuarios
- Automatizaciones

Formatos soportados:

- CSV
- XLSX
- JSON
- PDF (reportes)

Toda exportación debe poder ejecutarse también mediante API.

---

# API First

Toda operación disponible desde la interfaz debe existir como API.

Si una funcionalidad no puede automatizarse mediante API, su diseño debe reconsiderarse.

---

# Arquitectura basada en capacidades

El producto no se organiza por pantallas.

Se organiza por capacidades.

Ejemplos:

- Conversaciones
- Solicitudes
- Mercado
- Clima
- Agronomía
- Documentos
- Transporte
- Analytics
- Automatizaciones
- IA

Cada capacidad debe contener:

- modelos
- servicios
- APIs
- eventos
- permisos
- configuraciones
- componentes UI
- documentación

Las capacidades deben evolucionar independientemente.

---

# Principio de extensibilidad

Todo desarrollo nuevo debe responder las siguientes preguntas antes de implementarse:

1. ¿Puede venderse como un módulo independiente?

2. ¿Puede activarse o desactivarse desde el panel de administración?

3. ¿Puede utilizarse mediante API?

4. ¿Puede importarse información relacionada?

5. ¿Puede exportarse completamente?

6. ¿Respeta la arquitectura modular?

Si alguna respuesta es NO, revisar el diseño antes de comenzar el desarrollo.

---

# Regla de oro

Nunca desarrollar funcionalidades pensando en una única cooperativa.

Todo debe diseñarse como una plataforma SaaS multiempresa, configurable, modular y escalable.

Cada cliente debe poder contratar únicamente las funcionalidades que necesita, sin afectar la arquitectura ni requerir ramas específicas del código.


# Integration First

CoopFlow debe diseñarse como una plataforma abierta.

Siempre evaluar primero si existe un servicio confiable antes de desarrollar una solución propia.

El objetivo de CoopFlow es orquestar procesos, no reinventar servicios existentes.

Toda integración debe implementarse mediante adaptadores desacoplados.

Nunca depender directamente de un proveedor.

Siempre abstraer la implementación.

Ejemplo:

WeatherProvider

├── OpenWeather
├── SMN
├── Tomorrow.io
└── FutureProvider

El resto del sistema nunca debe conocer el proveedor utilizado.
```

---

## API First + API Friendly

```md
Toda funcionalidad debe poder ser consumida mediante API.

Toda integración externa debe poder conectarse sin modificar el núcleo del sistema.

El sistema debe exponer:

- REST API
- Webhooks
- Eventos
- SDK (futuro)

Y consumir:

- REST
- GraphQL
- Webhooks
- OAuth2
- JWT
- API Keys
```

---

## Catálogo de Integraciones

Desde el día uno pensaría en un Marketplace.

```text
Integraciones

✔ WhatsApp

✔ Telegram

✔ Email

✔ Twilio

✔ Mercado Pago

✔ Stripe

✔ Google Calendar

✔ Outlook

✔ Google Drive

✔ Dropbox

✔ OneDrive

✔ OpenAI

✔ Anthropic

✔ Gemini

✔ Ollama

✔ OpenWeather

✔ Tomorrow.io

✔ SMN

✔ SAP

✔ Tango

✔ Finnegans

✔ Albor

✔ Power BI

✔ Looker Studio

✔ Zapier

✔ n8n

✔ Make

✔ Node-RED

✔ MQTT

✔ Kafka
```

---

## Arquitectura de Adaptadores

No escribiría código así:

```ruby
OpenAI.chat(...)
```

Escribiría:

```ruby
AiProvider.chat(...)
```

Y por debajo:

```text
AiProvider

↓

OpenAIAdapter

AnthropicAdapter

GeminiAdapter

OllamaAdapter
```

Mañana cambiás de proveedor y el resto del sistema no se entera.

Lo mismo para:

* clima
* pagos
* correo
* mapas
* almacenamiento
* OCR
* Speech to Text
* Text to Speech
* autenticación

---

## Marketplace

Otra idea que me gusta mucho.

Que cada cooperativa pueda ir a un módulo de **Integraciones** y simplemente activar conectores.

Ejemplo:

```text
Marketplace

□ OpenAI

□ Anthropic

□ Gemini

□ Ollama

□ Google Calendar

□ Outlook

□ Mercado Pago

□ Stripe

□ Power BI

□ Zapier

□ n8n

□ ERP

□ SMTP

□ WhatsApp

□ Telegram
```

Todo configurable desde el panel.

---
