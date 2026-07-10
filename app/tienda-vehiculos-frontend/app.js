/**
 * Frontend simple para CRUD de vehículos.
 */

// URL base de la API
const API_BASE_URL = (() => {
  const host = window.location.hostname;
  // Local
  if (host === "localhost" || host === "127.0.0.1") {
    return "http://localhost:3001/api";
  }
  // EC2 u otro host: mismo hostname con puerto 3001
  return `http://${host}:3001/api`;
})();

const VEHICULOS_URL = `${API_BASE_URL}/vehiculos`;

let editandoId = null;

const tbody = document.getElementById("tbodyVehículos");
const btnCargar = document.getElementById("btnCargar");
const btnGuardar = document.getElementById("btnGuardar");
const btnCancelar = document.getElementById("btnCancelar");
const formTitle = document.getElementById("formTitle");
const statusDiv = document.getElementById("status");

const inputNombre = document.getElementById("nombre");
const inputDescripcion = document.getElementById("descripcion");
const inputPrecio = document.getElementById("precio");
const inputStock = document.getElementById("stock");

function setStatus(mensaje, tipo = "ok") {
  statusDiv.textContent = mensaje;
  statusDiv.className = "status " + tipo;
}

async function cargarVehículos() {
  try {
    const res = await fetch(VEHICULOS_URL);
    if (!res.ok) throw new Error("Error al cargar vehículos");
    const data = await res.json();
    renderVehículos(data);
    setStatus("Vehículos cargados correctamente.", "ok");
  } catch (err) {
    console.error(err);
    setStatus("No se pudieron cargar los vehículos. ¿Está el backend levantado?", "error");
  }
}

function renderVehículos(vehiculos) {
  tbody.innerHTML = "";

  vehiculos.forEach((p) => {
    const tr = document.createElement("tr");

    const precioNum = Number(p.precio);
    const precioTxt = Number.isFinite(precioNum) ? `$${precioNum.toFixed(2)}` : "";

    tr.innerHTML = `
      <td>${p.id}</td>
      <td>${p.nombre}</td>
      <td>${p.descripcion || ""}</td>
      <td>${precioTxt}</td>
      <td>${p.stock}</td>
      <td>
        <button data-id="${p.id}" class="btn-editar">Editar</button>
        <button data-id="${p.id}" class="btn-eliminar danger">Eliminar</button>
      </td>
    `;

    tbody.appendChild(tr);
  });

  // Asignar eventos a los botones
  document.querySelectorAll(".btn-editar").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      editarVehículo(id);
    });
  });

  document.querySelectorAll(".btn-eliminar").forEach((btn) => {
    btn.addEventListener("click", () => {
      const id = btn.getAttribute("data-id");
      if (confirm("¿Seguro que deseas eliminar este vehículo?")) {
        eliminarVehículo(id);
      }
    });
  });
}

function limpiarFormulario() {
  editandoId = null;
  formTitle.textContent = "Nuevo vehículo";
  inputNombre.value = "";
  inputDescripcion.value = "";
  inputPrecio.value = "";
  inputStock.value = "";
}

function obtenerDatosFormulario() {
  return {
    nombre: inputNombre.value.trim(),
    descripcion: inputDescripcion.value.trim(),
    precio: parseFloat(inputPrecio.value),
    stock: parseInt(inputStock.value, 10),
  };
}

function validarVehículo(prod) {
  if (!prod.nombre) return "El nombre es obligatorio.";
  if (!Number.isFinite(prod.precio) || prod.precio < 0) return "El precio debe ser un número mayor o igual a 0.";
  if (!Number.isInteger(prod.stock) || prod.stock < 0) return "El stock debe ser un número entero mayor o igual a 0.";
  return null;
}

async function guardarVehículo() {
  const vehiculo = obtenerDatosFormulario();
  const error = validarVehículo(vehiculo);
  if (error) {
    setStatus(error, "error");
    return;
  }

  // ✅ Guardamos el estado antes de limpiar el formulario (fix del mensaje)
  const estabaEditando = Boolean(editandoId);
  const idAEditar = editandoId;

  try {
    let res;

    if (estabaEditando) {
      // Actualizar
      res = await fetch(`${VEHICULOS_URL}/${idAEditar}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(vehiculo),
      });
    } else {
      // Crear
      res = await fetch(VEHICULOS_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(vehiculo),
      });
    }

    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.message || "Error al guardar el vehículo");
    }

    limpiarFormulario();
    await cargarVehículos();
    setStatus(estabaEditando ? "Vehículo actualizado correctamente." : "Vehículo creado correctamente.", "ok");
  } catch (err) {
    console.error(err);
    setStatus("Ocurrió un error al guardar el vehículo.", "error");
  }
}

async function editarVehículo(id) {
  try {
    const res = await fetch(`${VEHICULOS_URL}/${id}`);
    if (!res.ok) throw new Error("No se pudo obtener el vehículo");
    const p = await res.json();
    editandoId = p.id;
    formTitle.textContent = `Editar vehículo #${p.id}`;
    inputNombre.value = p.nombre;
    inputDescripcion.value = p.descripcion || "";
    inputPrecio.value = p.precio;
    inputStock.value = p.stock;
    setStatus("Editando vehículo.", "ok");
  } catch (err) {
    console.error(err);
    setStatus("No se pudo cargar el vehículo para editarlo.", "error");
  }
}

async function eliminarVehículo(id) {
  try {
    const res = await fetch(`${VEHICULOS_URL}/${id}`, { method: "DELETE" });
    if (!res.ok) throw new Error("Error al eliminar vehículo");
    await cargarVehículos();
    setStatus("Vehículo eliminado correctamente.", "ok");
  } catch (err) {
    console.error(err);
    setStatus("No se pudo eliminar el vehículo.", "error");
  }
}

// Eventos
btnCargar.addEventListener("click", cargarVehículos);
btnGuardar.addEventListener("click", guardarVehículo);
btnCancelar.addEventListener("click", () => {
  limpiarFormulario();
  setStatus("Edición cancelada.", "ok");
});

// Cargar vehículos al iniciar
cargarVehículos();
