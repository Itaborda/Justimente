# Arquitectura inicial

```text
Navegador
  └── React + TypeScript + Vite
       └── API REST (Axios)
            └── Express + TypeScript
                 ├── Autenticación JWT / bcrypt
                 ├── Validación Zod
                 ├── Módulos: usuarios, profesionales, solicitudes
                 └── PostgreSQL (esquema inicial; integración pendiente)
```

## Separación de dominios
- Identidad: usuarios, roles y sesiones.
- Jurídico: categorías y recursos generales.
- Psicológico: recursos psicoeducativos y acceso restringido.
- Profesionales: perfiles, especialidades y credenciales verificables.
- Atención: solicitudes, disponibilidad y citas.
- Plataforma: notificaciones, consentimientos y auditoría.

## Seguridad
Aplicar mínimo privilegio, segregación de información jurídica/psicológica, minimización de datos, cifrado en tránsito y reposo, registros de auditoría sin contenido sensible y controles de acceso por objeto. El esquema SQL es una base, no una certificación de cumplimiento.
