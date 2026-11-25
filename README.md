# JustiMente

**Orientación para tus derechos. Acompañamiento para ti.**

Plataforma web de demostración que reúne orientación jurídica general, recursos de bienestar emocional, asistente informativo, directorio y registro de solicitudes.

## Requisitos
- Node.js 20 o superior
- npm 10 o superior
- PostgreSQL (opcional para el esquema y la siguiente etapa de persistencia)

## Inicio rápido

```bash
npm install
cp .env.example .env
npm run dev
```

Frontend: http://localhost:5173  
API: http://localhost:4000/api  
Salud de API: http://localhost:4000/api/health

El modo inicial de demostración mantiene usuarios y solicitudes en memoria: los datos se pierden al reiniciar el servidor. Para ejecutar el esquema PostgreSQL, crea una base de datos y ejecuta `database/schema.sql`. La conexión PostgreSQL está preparada en `.env.example`, pero la persistencia de las rutas todavía debe integrarse antes de producción.

## Funcionalidades incluidas
- Interfaz responsive con identidad visual JustiMente y logo suministrado.
- Navegación entre inicio, orientación jurídica, bienestar emocional, asistente, directorio y biblioteca.
- Registro e inicio de sesión con hash bcrypt y JWT.
- Roles iniciales ciudadano, abogado y psicólogo; los perfiles profesionales requieren verificación (los perfiles visibles son demostrativos).
- Registro y consulta de solicitudes por usuario.
- Asistente informativo basado en respuestas guiadas; no es un modelo de IA conectado.
- API REST con validación Zod, Helmet, CORS y limitación de intentos en autenticación.
- Esquema SQL inicial para usuarios, roles, profesionales, credenciales, solicitudes, citas, recursos, conversaciones, consentimientos y auditoría.

## Rutas API
- `GET /api/health`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me` (JWT)
- `GET /api/professionals`
- `POST /api/requests` (JWT)
- `GET /api/requests` (JWT)

## Variables de entorno
Revisa `.env.example`. En producción configura un `JWT_SECRET` aleatorio de al menos 32 caracteres, HTTPS, CORS con el dominio real y una base de datos administrada con copias de seguridad.

## Importante antes de producción
Este paquete es una base funcional/MVP, no una plataforma lista para tratar casos reales ni datos clínicos o jurídicos sensibles. Antes de publicar:
1. Conectar PostgreSQL en todas las operaciones y aplicar migraciones.
2. Implementar recuperación y verificación de correo, renovación/revocación de sesión y controles de acceso por rol completos.
3. Crear agenda real con transacciones y bloqueo contra reservas duplicadas.
4. Implementar verificación documental de profesionales y panel administrativo con auditoría.
5. Incorporar consentimiento informado, política de privacidad, retención/borrado, cifrado de campos sensibles y pruebas de seguridad.
6. Revisar contenidos jurídicos con profesionales y fuentes oficiales colombianas; validar rutas institucionales y emergencias.
7. Conectar un proveedor de IA solo después de establecer controles de privacidad, minimización y revisión humana.

La plataforma no reemplaza a abogados, psicólogos ni instituciones competentes. No usar información ficticia como credencial real. No cargar datos sensibles en la demo.
