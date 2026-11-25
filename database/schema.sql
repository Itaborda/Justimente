-- Esquema inicial PostgreSQL para JustiMente.
-- Ejecutar en una base vacía. Ajustar políticas y retención antes de producción.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(30) UNIQUE NOT NULL CHECK (code IN ('citizen','lawyer','psychologist','admin')),
  name VARCHAR(80) NOT NULL
);
INSERT INTO roles(code,name) VALUES
 ('citizen','Ciudadano'),('lawyer','Abogado'),('psychologist','Psicólogo'),('admin','Administrador')
ON CONFLICT DO NOTHING;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role_id UUID NOT NULL REFERENCES roles(id),
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(180) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  email_verified_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE specialties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) UNIQUE NOT NULL,
  discipline VARCHAR(20) NOT NULL CHECK (discipline IN ('legal','psychological'))
);
CREATE TABLE professional_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  years_experience SMALLINT CHECK (years_experience >= 0),
  modality VARCHAR(20) NOT NULL CHECK (modality IN ('virtual','in_person','hybrid')),
  verification_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending','verified','rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE professional_specialties (
  professional_id UUID REFERENCES professional_profiles(id) ON DELETE CASCADE,
  specialty_id UUID REFERENCES specialties(id),
  PRIMARY KEY(professional_id,specialty_id)
);
CREATE TABLE professional_credentials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID NOT NULL REFERENCES professional_profiles(id) ON DELETE CASCADE,
  credential_type VARCHAR(80) NOT NULL,
  issuing_entity VARCHAR(150),
  verification_status VARCHAR(20) NOT NULL DEFAULT 'pending',
  secure_file_key TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  citizen_id UUID NOT NULL REFERENCES users(id),
  professional_id UUID REFERENCES professional_profiles(id),
  area VARCHAR(20) NOT NULL CHECK (area IN ('legal','psychological')),
  subject VARCHAR(500) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','review','assigned','active','completed','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX requests_citizen_status_idx ON requests(citizen_id,status);
CREATE TABLE professional_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id UUID NOT NULL REFERENCES professional_profiles(id) ON DELETE CASCADE,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  CHECK (ends_at > starts_at)
);
CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES requests(id),
  professional_id UUID NOT NULL REFERENCES professional_profiles(id),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'requested' CHECK (status IN ('requested','confirmed','cancelled','completed')),
  CHECK (ends_at > starts_at)
);
CREATE INDEX appointments_professional_time_idx ON appointments(professional_id,starts_at,ends_at);
CREATE TABLE legal_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(120) UNIQUE NOT NULL,
  description TEXT
);
CREATE TABLE legal_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES legal_categories(id),
  title VARCHAR(180) NOT NULL,
  body TEXT NOT NULL,
  official_url TEXT,
  reviewed_at DATE,
  published BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE TABLE psychological_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(180) NOT NULL,
  category VARCHAR(100) NOT NULL,
  body TEXT NOT NULL,
  reviewed_by_professional BOOLEAN NOT NULL DEFAULT FALSE,
  published BOOLEAN NOT NULL DEFAULT FALSE
);
-- Conversaciones y notas profesionales deben contar con controles reforzados,
-- consentimiento, cifrado de aplicación y políticas de acceso específicas.
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES users(id),
  scope VARCHAR(20) NOT NULL CHECK (scope IN ('legal','psychological','general')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id),
  encrypted_body BYTEA NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(150) NOT NULL,
  body TEXT NOT NULL,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  consent_type VARCHAR(80) NOT NULL,
  policy_version VARCHAR(30) NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  withdrawn_at TIMESTAMPTZ
);
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  resource_type VARCHAR(80) NOT NULL,
  resource_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
