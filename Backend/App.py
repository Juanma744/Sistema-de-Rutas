from flask import Flask, request, jsonify
from flask_cors import CORS
from pyswip import Prolog

app = Flask(__name__)
CORS(app)

prolog = Prolog()
prolog.consult("Rutas.pl")

def checar_servicio(ciudad, tipo):
    """Verifica si una ciudad tiene un servicio específico en Prolog"""
    return bool(list(prolog.query(f"servicio({ciudad.lower()}, {tipo.lower()})")))

@app.route('/buscar-ruta', methods=['POST'])
def buscar_ruta():
    datos = request.json
    origen = datos['origen'].lower()
    destino = datos['destino'].lower()
    modo_p = datos['modo_presupuesto']
    pres_max = datos.get('presupuesto_max', 0)
    tipo_camino = datos['tipo_ruta']
    servicios = datos['servicios']

    query = f"ruta_completa({origen}, {destino}, Ruta, Costo, DistTotal, Tipos, Costos, Dists)"
    
    try:
        resultados = list(prolog.query(query))
        rutas_formateadas = []

        if not resultados:
            return jsonify({"rutas": []})

        for res in resultados:
            camino = [str(c) for c in res['Ruta']]
            tipos = [str(t) for t in res['Tipos']]
            costos_lista = res['Costos']
            distancias_lista = res['Dists']
            costo_total = res['Costo']

            # Filtros de tipo de camino
            if tipo_camino == 'libre' and 'cuota' in tipos: continue
            if tipo_camino == 'cuota' and 'libre' in tipos: continue
            if tipo_camino == 'mixta' and not ('libre' in tipos and 'cuota' in tipos): continue
            
            # Filtro de presupuesto
            if modo_p == 'limite' and costo_total > pres_max: continue

            # Filtro de servicios mínimos
            cumple_servicios = True
            if not servicios.get('cualquiera', True):
                for s_nombre, activado in servicios.items():
                    if activado and s_nombre != 'cualquiera':
                        if not any(checar_servicio(c, s_nombre) for c in camino):
                            cumple_servicios = False
                            break
            if not cumple_servicios: continue

            # Recolectar info de ciudades para la gráfica de servicios
            ciudades_detalladas = []
            for c in camino:
                servs_prolog = list(prolog.query(f"servicio({c.lower()}, S)"))
                ciudades_detalladas.append({
                    "nombre": c.capitalize(),
                    "servicios": [s['S'] for s in servs_prolog]
                })

            # Construir tramos exactos
            tramos_detallados = []
            for i in range(len(tipos)):
                tramos_detallados.append({
                    "o": camino[i].capitalize(),
                    "d": camino[i+1].capitalize(),
                    "tipo": tipos[i].capitalize(),
                    "costo": costos_lista[i],
                    "distancia": distancias_lista[i]
                })

            rutas_formateadas.append({
                "camino": " ➔ ".join([c.capitalize() for c in camino]),
                "costo": costo_total,
                "distanciaTotal": res['DistTotal'],
                "tramos": tramos_detallados,
                "ciudades": ciudades_detalladas
            })

        rutas_formateadas = sorted(rutas_formateadas, key=lambda x: x['costo'])
        if modo_p == 'barata' and rutas_formateadas:
            rutas_formateadas = [rutas_formateadas[0]]

        return jsonify({"rutas": rutas_formateadas})

    except Exception as e:
        print(f"Error detectado en App.py: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)