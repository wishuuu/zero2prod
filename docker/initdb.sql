-- Create an application user to align with local tooling (.env)
DO $$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app'
   ) THEN
      CREATE ROLE app LOGIN PASSWORD 'secret';
   END IF;
END
$$;

-- Ensure the app user can work with the default DB
GRANT ALL PRIVILEGES ON DATABASE newsletter TO app;

-- Grant privileges on the public schema and future objects
\connect newsletter
GRANT USAGE, CREATE ON SCHEMA public TO app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO app;
