# CoopFlow — Product Master PRD v1.0

## 1. Visión

CoopFlow es una plataforma SaaS para cooperativas agropecuarias cuyo objetivo es convertirse en el sistema operativo de la relación entre la cooperativa y sus asociados.

No reemplaza al ERP. Se integra con él.

El productor utiliza WhatsApp como interfaz principal. La cooperativa utiliza una plataforma basada en Chatwoot + Coop Core.

## 2. Objetivos

- Digitalizar la comunicación.
- Convertir conversaciones en procesos.
- Centralizar información operativa.
- Incorporar IA como asistente.
- Integrar clima, mercado y documentación.

## 3. Principios

- WhatsApp First.
- API First.
- IA asiste, las personas deciden.
- Modular.
- Multiempresa.
- Auditabilidad completa.
- Integración antes que reemplazo.

## 4. Arquitectura

- Chatwoot Fork: conversaciones, agentes, canales.
- Coop Core: reglas de negocio.
- Motor IA.
- Motor Mercado.
- Motor Clima.
- Dashboard.
- Integraciones ERP.

## 5. Módulos

### Plataforma
Usuarios, roles, permisos, auditoría, configuración, API, webhooks.

### Productores
Asociados, establecimientos, lotes, campañas, cultivos.

### Conversaciones
WhatsApp, archivos, audios, fotos, OCR, transcripción.

### Solicitudes
Tipos:
- Cupos de descarga
- Transporte
- Compra de insumos
- Venta
- Agronomía
- Documentación
- Reclamos
- Consultas

Estados:
Nueva → Pendiente → Asignada → En proceso → Finalizada → Cancelada.

### Mercado
- Cotizaciones en tiempo real.
- Rosario, MATBA-ROFEX, Chicago.
- Gráficos.
- Histórico.
- Alertas.
- Cierre de precio.
- Contratos.

### Clima
- Pronóstico.
- Lluvias.
- Vientos.
- Humedad.
- Temperatura.
- Ventanas de pulverización.
- Heladas.
- Granizo.
- Alertas segmentadas.

### Agronomía
Visitas, agenda, imágenes, IA, recomendaciones.

### Comercial
Catálogo, stock, cotizaciones, pedidos.

### Documentos
Liquidaciones, cartas de porte, recetas, contratos, facturas.

### Dashboard
KPIs, tiempos, solicitudes, productividad, IA analítica.

## 6. WhatsApp como interfaz universal

Todo debe poder solicitarse mediante lenguaje natural.

Ejemplos:

- ¿Cómo está la soja?
- Mostrame el gráfico del último año.
- Avisame cuando llegue a USD 400.
- Necesito un cupo para mañana.
- Quiero cerrar precio.
- Necesito un camión.
- Comprame 20 bolsas de maíz.
- Mandame mi liquidación.
- ¿Cómo viene el clima?
- ¿Va a haber viento mañana?
- Necesito una visita del agrónomo.
- Te envío una foto del lote.

La IA interpreta la intención, ejecuta acciones mediante APIs y responde por WhatsApp.

## 7. Roadmap

F1 Plataforma base
F2 Solicitudes y workflows
F3 Mercado
F4 Clima (Gaucho Weather)
F5 Agronomía
F6 Comercial
F7 Documentación
F8 Inteligencia
F9 Automatizaciones
F10 Portal del asociado

## 8. Diferenciadores

- Chatwoot + IA + Agro.
- WhatsApp como interfaz.
- Integración con ERP.
- Información personalizada.
- Feed inteligente.
- Alertas proactivas.
- Automatización operativa.

## 9. Futuro

Integración con imágenes satelitales, NDVI, IoT, estaciones meteorológicas, drones, firma digital, financiamiento, campañas comerciales inteligentes y asistentes especializados por área.
