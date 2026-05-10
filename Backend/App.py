from flask import Flask, request, jsonify
from flask_cors import CORS
from pyswip import Prolog

# Configuramos el servidor
app = Flask(__name__)
CORS(app) 

# Inicializamos Prolog y leemos tu archivo (suponiendo que ya están en la misma carpeta)
prolog = Prolog()
prolog.consult("Rutas.pl")

@app.route('/buscar-ruta', methods=['POST'])
def buscar_ruta():
    datos = request.json
    origen = datos['origen']
    destino = datos['destino']
    modo_presupuesto = datos['modo_presupuesto']
    presupuesto_max = datos['presupuesto_max']
    tipo_ruta = datos['tipo_ruta']
    servicios = datos['servicios']

    # 1. SIEMPRE usamos la regla normal primero para que soporte todos los filtros
    consulta = f"ruta_con_costo({origen}, {destino}, Ruta, Costo, _)"

    # 2. Si eligió un límite, lo agregamos a la consulta
    if modo_presupuesto == 'limite':
        consulta += f", Costo =< {presupuesto_max}"

    # 3. Filtros de tipo de camino
    if tipo_ruta == 'libre':
        consulta += ", todos_libres(Ruta)"
    elif tipo_ruta == 'cuota':
        consulta += ", todos_cuota(Ruta)"
    elif tipo_ruta == 'mixta':
        consulta += ", \\+ todos_libres(Ruta), \\+ todos_cuota(Ruta)"

    # 4. Filtros de servicios
    if not servicios['cualquiera']:
        if servicios['gasolinera']:
            consulta += ", member(L1, Ruta), servicio(L1, gasolinera)"
        if servicios['paradero']:
            consulta += ", member(L2, Ruta), servicio(L2, paradero)"
        if servicios['turistico']:
            consulta += ", member(L3, Ruta), servicio(L3, turistico)"

    print(f"Preguntando a Prolog: ?- {consulta}.")

    try:
        # 5. Sacamos todas las rutas filtradas
        resultados = list(prolog.query(consulta))
        rutas_formateadas = []
        
        if resultados:
            for res in resultados:
                nombres = " ➔ ".join([str(ciudad).capitalize() for ciudad in res['Ruta']])
                rutas_formateadas.append({
                    "camino": nombres,
                    "costo": res['Costo']
                })
            
            # MAGIA 3: Si pidió la más barata, Python ordena la lista de menor a mayor precio
            if modo_presupuesto == 'barata':
                # Ordenamos usando el costo y nos quedamos solo con la posición [0] (la ganadora)
                rutas_formateadas = sorted(rutas_formateadas, key=lambda x: x['costo'])
                rutas_formateadas = [rutas_formateadas[0]]
                
            return jsonify({"rutas": rutas_formateadas})
        else:
            return jsonify({"rutas": []})
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

if __name__ == '__main__':
    app.run(debug=True, port=5000)