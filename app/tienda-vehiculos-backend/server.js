const express = require("express");
const cors = require("cors");
const mysql = require("mysql2/promise");

const app = express();
const PORT = process.env.PORT || 3001;

const {
  DB_HOST = "db",
  DB_USER = "alumno",
  DB_PASSWORD = "alumno123",
  DB_NAME = "tienda_vehiculos",
  DB_PORT = 3306,
} = process.env;

app.use(cors());
app.use(express.json());

let pool;

// Inicializar pool de conexiones
async function initDb() {
  pool = mysql.createPool({
    host: DB_HOST,
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
    port: Number(DB_PORT),
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  });
  console.log("✅ Pool de conexiones MySQL inicializado.");
}

// Esperar a que MySQL esté listo (reintentos)
async function waitForDb(retries = 10, delayMs = 2000) {
  for (let i = 1; i <= retries; i++) {
    try {
      const conn = await pool.getConnection();
      await conn.ping();
      conn.release();
      console.log("✅ MySQL listo (ping OK).");
      return;
    } catch (e) {
      console.log(`⏳ Esperando MySQL... intento ${i}/${retries}`);
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  throw new Error("❌ No se pudo conectar a MySQL luego de varios intentos.");
}

// Helper para manejar errores
function handleError(res, error, message = "Error interno del servidor") {
  console.error(error);
  res.status(500).json({ message });
}

// Validación básica (precio/stock)
// Nota: evitamos caracteres acentuados en nombres de funciones para máxima compatibilidad.
function validateVehiculoInput({ nombre, precio, stock }) {
  if (!nombre || precio == null || stock == null) {
    return { ok: false, message: "Nombre, precio y stock son obligatorios." };
  }

  const precioNum = Number(precio);
  const stockNum = Number(stock);

  if (!Number.isFinite(precioNum) || precioNum < 0) {
    return { ok: false, message: "Precio inválido." };
  }
  if (!Number.isInteger(stockNum) || stockNum < 0) {
    return { ok: false, message: "Stock inválido (debe ser entero >= 0)." };
  }

  return { ok: true, precioNum, stockNum };
}

// Obtener todos los vehículos
app.get("/api/vehiculos", async (req, res) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, nombre, descripcion, precio, stock FROM vehiculos ORDER BY id DESC"
    );
    res.json(rows);
  } catch (err) {
    handleError(res, err, "No se pudieron obtener los vehículos.");
  }
});

// Obtener un vehículo por ID
app.get("/api/vehiculos/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await pool.query(
      "SELECT id, nombre, descripcion, precio, stock FROM vehiculos WHERE id = ?",
      [id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: "Vehículo no encontrado." });
    }
    res.json(rows[0]);
  } catch (err) {
    handleError(res, err, "No se pudo obtener el vehículo.");
  }
});

// Crear un nuevo vehículo
app.post("/api/vehiculos", async (req, res) => {
  const { nombre, descripcion, precio, stock } = req.body;

  const validation = validateVehiculoInput({ nombre, precio, stock });
  if (!validation.ok) {
    return res.status(400).json({ message: validation.message });
  }

  try {
    const [result] = await pool.query(
      "INSERT INTO vehiculos (nombre, descripcion, precio, stock) VALUES (?, ?, ?, ?)",
      [nombre, descripcion || null, validation.precioNum, validation.stockNum]
    );
    const nuevoId = result.insertId;
    const [rows] = await pool.query(
      "SELECT id, nombre, descripcion, precio, stock FROM vehiculos WHERE id = ?",
      [nuevoId]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    handleError(res, err, "No se pudo crear el vehículo.");
  }
});

// Actualizar un vehículo
app.put("/api/vehiculos/:id", async (req, res) => {
  const { id } = req.params;
  const { nombre, descripcion, precio, stock } = req.body;

  const validation = validateVehiculoInput({ nombre, precio, stock });
  if (!validation.ok) {
    return res.status(400).json({ message: validation.message });
  }

  try {
    const [result] = await pool.query(
      "UPDATE vehiculos SET nombre = ?, descripcion = ?, precio = ?, stock = ? WHERE id = ?",
      [nombre, descripcion || null, validation.precioNum, validation.stockNum, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Vehículo no encontrado." });
    }

    const [rows] = await pool.query(
      "SELECT id, nombre, descripcion, precio, stock FROM vehiculos WHERE id = ?",
      [id]
    );
    res.json(rows[0]);
  } catch (err) {
    handleError(res, err, "No se pudo actualizar el vehículo.");
  }
});

// Eliminar un vehículo
app.delete("/api/vehiculos/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const [result] = await pool.query("DELETE FROM vehiculos WHERE id = ?", [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: "Vehículo no encontrado." });
    }
    res.json({ message: "Vehículo eliminado correctamente." });
  } catch (err) {
    handleError(res, err, "No se pudo eliminar el vehículo.");
  }
});

// Endpoint de salud (valida DB)
app.get("/api/health", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT 1 AS ok");
    res.json({ status: "ok", db: rows[0].ok === 1 });
  } catch (e) {
    res.status(500).json({ status: "error", db: false });
  }
});

// Arranque controlado: init pool -> esperar DB -> levantar servidor
(async () => {
  try {
    await initDb();
    await waitForDb();

    app.listen(PORT, () => {
      console.log(`✅ Servidor backend escuchando en puerto ${PORT}`);
    });
  } catch (err) {
    console.error("❌ Error al iniciar backend:", err.message || err);
    process.exit(1);
  }
})();
