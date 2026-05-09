import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
import subprocess

def buscar_rutas():
    # 1. Obtener los datos de la interfaz
    origen = combo_origen.get()
    destino = combo_destino.get()
    presupuesto = entry_presupuesto.get()
    tipo_ruta = var_tipo_ruta.get()
    
    # Validar que no estén vacíos
    if not origen or not destino or not presupuesto:
        messagebox.showwarning("Advertencia", "Llena origen, destino y presupuesto.")
        return

    # 2. Aquí preparas la consulta (Solo texto simulado por ahora)
    texto_resultados.delete(1.0, tk.END) # Limpiar resultados anteriores
    texto_resultados.insert(tk.END, f"Buscando rutas de {origen} a {destino}...\n")
    texto_resultados.insert(tk.END, f"Filtros: Presupuesto ${presupuesto}, Tipo: {tipo_ruta}\n")
    texto_resultados.insert(tk.END, "-"*40 + "\n")
    
    # ---------------------------------------------------------
    # 3. CONEXIÓN CON PROLOG (Descomenta esto cuando tu Prolog funcione)
    # query = f"consultar({origen.lower()}, {destino.lower()}, {presupuesto})."
    # try:
    #     proceso = subprocess.Popen(
    #         ['swipl', '-q', '-f', 'Rutas.pl', '-g', query, '-t', 'halt'],
    #         stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    #     )
    #     salida, errores = proceso.communicate()
    #     if salida:
    #         texto_resultados.insert(tk.END, salida)
    #     if errores:
    #         texto_resultados.insert(tk.END, "\nErrores de Prolog:\n" + errores)
    # except Exception as e:
    #     texto_resultados.insert(tk.END, f"\nError al conectar con Prolog: {e}")
    # ---------------------------------------------------------
    
    # Simulación de resultado exitoso para que veas que funciona
    texto_resultados.insert(tk.END, f"> Ruta encontrada: {origen} -> Ciudad Intermedia -> {destino}\n")
    texto_resultados.insert(tk.END, f"> Costo estimado: ${int(presupuesto) - 50}\n")
    texto_resultados.insert(tk.END, f"> Cumple con todos los servicios requeridos.\n")

# Crear la ventana principal
root = tk.Tk()
root.title("Sistema de Rutas")
root.geometry("450x550")
root.config(padx=20, pady=20)

# --- SECCIÓN: Origen y Destino ---
ttk.Label(root, text="Origen:").grid(row=0, column=0, sticky="w", pady=5)
combo_origen = ttk.Combobox(root, values=["Zamora", "Morelia", "Guadalajara", "CDMX"])
combo_origen.grid(row=0, column=1, pady=5, sticky="ew")

ttk.Label(root, text="Destino:").grid(row=1, column=0, sticky="w", pady=5)
combo_destino = ttk.Combobox(root, values=["Zamora", "Morelia", "Guadalajara", "CDMX"])
combo_destino.grid(row=1, column=1, pady=5, sticky="ew")

# --- SECCIÓN: Filtros ---
ttk.Label(root, text="Presupuesto ($):").grid(row=2, column=0, sticky="w", pady=5)
entry_presupuesto = ttk.Entry(root)
entry_presupuesto.grid(row=2, column=1, pady=5, sticky="ew")

# Tipo de Ruta (RadioButtons)
ttk.Label(root, text="Tipo de Ruta:").grid(row=3, column=0, sticky="w", pady=5)
var_tipo_ruta = tk.StringVar(value="Rápida")
frame_ruta = ttk.Frame(root)
frame_ruta.grid(row=3, column=1, sticky="w")
root.mainloop()
