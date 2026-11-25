import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import rateLimit from 'express-rate-limit'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { randomUUID } from 'node:crypto'
import { z } from 'zod'
import pg from 'pg'
import type { Request, Response } from 'express'

const app = express()
const PORT = Number(process.env.PORT || 4000)
const JWT_SECRET = process.env.JWT_SECRET || 'development_only_change_this_secret_please_32_chars'

if (process.env.NODE_ENV === 'production' && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET es obligatorio en producción')
}

app.use(helmet())

app.use(cors({
  origin: process.env.CLIENT_ORIGIN || 'http://localhost:5173'
}))

app.use(express.json({ limit: '20kb' }))

app.use('/api/auth', rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 30,
  standardHeaders: true,
  legacyHeaders: false
}))

type User = {
  id: string
  name: string
  email: string
  passwordHash: string
  role: string
}

type RequestItem = {
  id: string
  userId: string
  area: string
  subject: string
  status: string
  createdAt: string
  professional?: string
}

const users: User[] = []
const requests: RequestItem[] = []

const professionals = [
  {
    id: 'demo-a',
    name: 'Profesional demostrativo A',
    profession: 'Abogado/a',
    specialty: 'Derecho de familia',
    description: 'Perfil ficticio para demostración; no está habilitado para atención.',
    modality: 'Virtual',
    verified: false,
    demo: true
  },
  {
    id: 'demo-p',
    name: 'Profesional demostrativo B',
    profession: 'Psicólogo/a',
    specialty: 'Bienestar emocional',
    description: 'Perfil ficticio para demostración; no está habilitado para atención.',
    modality: 'Virtual',
    verified: false,
    demo: true
  }
]

const pool = process.env.DATABASE_URL
  ? new pg.Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: process.env.NODE_ENV === 'production'
        ? { rejectUnauthorized: true }
        : undefined
    })
  : null

const asyncHandler = (fn: any) =>
  (req: Request, res: Response, next: express.NextFunction) =>
    Promise.resolve(fn(req, res, next)).catch(next)

const tokenFor = (u: User) =>
  jwt.sign(
    { sub: u.id, role: u.role },
    JWT_SECRET,
    { expiresIn: '2h', issuer: 'justimente' }
  )

const auth = (req: any, res: Response, next: express.NextFunction) => {
  const raw = req.headers.authorization?.replace(/^Bearer\s+/i, '')

  if (!raw) {
    return res.status(401).json({
      message: 'Debes iniciar sesión.'
    })
  }

  try {
    req.claims = jwt.verify(raw, JWT_SECRET, {
      issuer: 'justimente'
    })
    next()
  } catch {
    return res.status(401).json({
      message: 'Sesión inválida o vencida.'
    })
  }
}

const publicUser = (u: User) => ({
  id: u.id,
  name: u.name,
  email: u.email,
  role: u.role
})

// Comprobar funcionamiento de la API
app.get('/api/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    mode: pool ? 'postgres-configured' : 'demo-memory'
  })
})

// REGISTRO
app.post('/api/auth/register', asyncHandler(async (req: Request, res: Response) => {
  const schema = z.object({
    name: z.string()
      .trim()
      .min(2, 'El nombre debe tener al menos 2 caracteres')
      .max(100),

    email: z.string()
      .trim()
      .email('Escribe un correo electrónico válido')
      .max(180)
      .transform(value => value.toLowerCase()),

    password: z.string()
      .min(8, 'La contraseña debe tener mínimo 8 caracteres')
      .max(72),

    role: z.enum([
      'citizen',
      'lawyer',
      'psychologist'
    ]).default('citizen')
  })

  const data = schema.parse(req.body)

  const email = data.email

  if (users.some(u => u.email === email)) {
    return res.status(409).json({
      message: 'Ya existe una cuenta con ese correo.'
    })
  }

  const user: User = {
    id: randomUUID(),
    name: data.name,
    email,
    passwordHash: await bcrypt.hash(data.password, 12),
    role: data.role
  }

  users.push(user)

  return res.status(201).json({
    message: 'Cuenta creada correctamente.',
    token: tokenFor(user),
    user: publicUser(user)
  })
}))

// INICIO DE SESIÓN
app.post('/api/auth/login', asyncHandler(async (req: Request, res: Response) => {
  const data = z.object({
    email: z.string().trim().email().transform(value => value.toLowerCase()),
    password: z.string().min(1).max(72)
  }).parse(req.body)

  const user = users.find(u => u.email === data.email)

  if (!user || !await bcrypt.compare(data.password, user.passwordHash)) {
    return res.status(401).json({
      message: 'Correo o contraseña incorrectos.'
    })
  }

  return res.json({
    token: tokenFor(user),
    user: publicUser(user)
  })
}))

// USUARIO AUTENTICADO
app.get('/api/auth/me', auth, (req: any, res: Response) => {
  const user = users.find(u => u.id === req.claims.sub)

  if (!user) {
    return res.status(404).json({
      message: 'Usuario no encontrado.'
    })
  }

  return res.json({
    user: publicUser(user)
  })
})

// DIRECTORIO DE PROFESIONALES
app.get('/api/professionals', (_req: Request, res: Response) => {
  res.json({ professionals })
})

// CREAR SOLICITUD
app.post('/api/requests', auth, asyncHandler(async (req: any, res: Response) => {
  const data = z.object({
    area: z.enum(['Jurídica', 'Psicológica']),
    subject: z.string().trim().min(3).max(500),
    professionalId: z.string().optional()
  }).parse(req.body)

  const professional = data.professionalId
    ? professionals.find(p => p.id === data.professionalId)
    : undefined

  if (data.professionalId && !professional) {
    return res.status(404).json({
      message: 'Profesional no encontrado.'
    })
  }

  const item: RequestItem = {
    id: randomUUID(),
    userId: req.claims.sub,
    area: data.area,
    subject: data.subject,
    status: 'pending',
    createdAt: new Date().toISOString(),
    professional: professional?.name
  }

  requests.unshift(item)

  return res.status(201).json({
    request: {
      id: item.id,
      area: item.area,
      subject: item.subject,
      status: item.status,
      createdAt: item.createdAt,
      professional: item.professional
    }
  })
}))

// CONSULTAR SOLICITUDES
app.get('/api/requests', auth, (req: any, res: Response) => {
  return res.json({
    requests: requests
      .filter(r => r.userId === req.claims.sub)
      .map(({ userId, ...r }) => r)
  })
})

// MANEJO DE ERRORES
app.use((
  err: any,
  _req: Request,
  res: Response,
  _next: express.NextFunction
) => {
  if (err instanceof z.ZodError) {
    return res.status(400).json({
      message: 'Revisa los datos ingresados.',
      errors: err.issues.map(issue => ({
        field: issue.path.join('.'),
        message: issue.message
      }))
    })
  }

  console.error('Error en JustiMente:', err)

  return res.status(500).json({
    message: 'Ocurrió un error interno.'
  })
})

app.listen(PORT, () => {
  console.log(
    `JustiMente API en puerto ${PORT} (${pool ? 'PostgreSQL configurado' : 'modo demostración en memoria'})`
  )
})
