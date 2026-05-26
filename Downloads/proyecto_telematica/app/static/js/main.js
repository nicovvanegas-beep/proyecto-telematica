// ============================================================
// main.js — Lógica del frontend
// Proyecto Final Telemática
// ============================================================

/**
 * Consulta el endpoint /api/status y muestra el resultado
 * en el div #status-box de la página de inicio.
 */
async function cargarEstado() {
    const box = document.getElementById('status-box');
    if (!box) return;   // solo corre en la página de inicio

    try {
        const resp = await fetch('/api/status');
        const data = await resp.json();

        // Formatear JSON de forma legible
        box.innerHTML = `
            <pre>${JSON.stringify(data, null, 2)}</pre>
            <p style="margin-top:0.75rem;color:#94a3b8;font-family:sans-serif;font-size:0.8rem;">
                ✅ Servicio activo y respondiendo
            </p>
        `;
    } catch (err) {
        box.innerHTML = `<p style="color:#ef4444;">⚠️ No se pudo conectar con la API</p>`;
    }
}

// Ejecutar al cargar la página
document.addEventListener('DOMContentLoaded', () => {
    cargarEstado();
});
