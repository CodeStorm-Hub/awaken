-- PostGIS is required for territory geometry (ST_Union, ST_Difference, etc.)
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
