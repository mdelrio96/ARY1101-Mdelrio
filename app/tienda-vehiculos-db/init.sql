-- ============================
-- Base de datos
-- ============================
CREATE DATABASE IF NOT EXISTS tienda_vehiculos
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- ============================
-- Usuario de aplicación
-- ============================
CREATE USER IF NOT EXISTS 'alumno'@'%' IDENTIFIED BY 'alumno123';

GRANT ALL PRIVILEGES ON tienda_vehiculos.* TO 'alumno'@'%';

FLUSH PRIVILEGES;

-- ============================
-- Usar base de datos
-- ============================
USE tienda_vehiculos;

-- ============================
-- Tabla vehiculos
-- ============================
CREATE TABLE IF NOT EXISTS vehiculos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion VARCHAR(255),
  precio DECIMAL(12,2) NOT NULL,
  stock INT NOT NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ============================
-- Datos iniciales
-- ============================
INSERT INTO vehiculos (nombre, descripcion, precio, stock) VALUES
('Toyota Corolla', 'Sedán, motor 1.8, automático, año 2023', 18990000, 5),
('Mazda CX-5', 'SUV, motor 2.5, automático, año 2022', 24990000, 3),
('Chevrolet Onix', 'Hatchback, motor 1.0 Turbo, año 2023', 15990000, 6),
('Ford Ranger', 'Pickup, motor 2.0 Turbo Diesel, año 2022', 32990000, 2),
('Honda CR-V', 'SUV, motor 1.5 Turbo, automático, año 2023', 27990000, 4);