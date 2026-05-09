% Todo lo que inicie con mayuscula son variables, lo que inicie con minuscula es un valor constante

lugar(zamora).
lugar(morelia).
lugar(queretaro).
lugar(jacona).
lugar(uruapan).
lugar(patzcuaro).
lugar(tangancicuaro).




%        origen, destino, distancia, costo, tipo de camino 
conexion(zamora, morelia, 150, 150, cuota).
conexion(zamora, morelia, 200, 99, libre).

conexion(uruapan, patzcuaro, 180, 30, libre).
conexion(uruapan, patzcuaro, 100, 70, cuota).

conexion(zamora, jacona, 5, 0, libre).
conexion(jacona, tangancicuaro, 20, 0, libre).

conexion(morelia, patzcuaro, 60, 30, libre).
conexion(morelia, jacona, 190, 170, cuota).


conexion(morelia, tangancicuaro, 130, 70, libre).

conexion(queretaro, morelia, 600, 100, libre).
conexion(queretaro, morelia, 400, 300, cuota).


servicio(morelia, gasolinera).
servicio(queretaro, turistico).
servicio(jacona, gasolinera).
servicio(jacona, paradero).
servicio(zamora, paradero).
servicio(morelia, paraderos).
servicio(morelia, turistico).
servicio(patzcuaro, turistico).



% Fase 2

% Condición 1: El camino va directo (de Origen a Destino)
tramo(Origen, Destino, Distancia, Costo, Tipo) :- 
    conexion(Origen, Destino, Distancia, Costo, Tipo).

% Condición 2: El camino va de regreso (de Destino a Origen)
tramo(Origen, Destino, Distancia, Costo, Tipo) :- 
    conexion(Destino, Origen, Distancia, Costo, Tipo).

% Regla principal que el usuario ejecuta
ruta(Origen, Destino, RutaFinal) :-
    buscar_ruta(Origen, Destino, [Origen], RutaInvertida),
    reverse(RutaInvertida, RutaFinal).

% Caso Base: Hay un tramo directo desde el punto Actual hasta el Destino
buscar_ruta(Actual, Destino, Visitados, [Destino | Visitados]) :-
    tramo(Actual, Destino, _, _, _).

% Caso Recursivo: Damos un salto a un punto intermedio
buscar_ruta(Actual, Destino, Visitados, RutaFinal) :-
    tramo(Actual, Intermedio, _, _, _),           % 1. Buscamos a dónde podemos ir desde aquí
    \+ member(Intermedio, Visitados),             % 2. CONTROL DE CICLOS: Verificamos no haber pisado esa ciudad antes
    buscar_ruta(Intermedio, Destino, [Intermedio | Visitados], RutaFinal). % 3. Repetimos el viaje desde la nueva ciudad


% ==========================================
% CÁLCULO DE MÉTRICAS 
% ==========================================

% 1. La Regla Principal: Prepara la lista de visitados y lanza la búsqueda
ruta_con_costo(Origen, Destino, RutaFinal, CostoTotal, DistanciaTotal) :-
    buscar_ruta_con_costo(Origen, Destino, [Origen], RutaInvertida, CostoTotal, DistanciaTotal),
    reverse(RutaInvertida, RutaFinal).

% 2. El Caso Base: Cuando llegas al destino en un solo salto
buscar_ruta_con_costo(Actual, Destino, Visitados, [Destino | Visitados], Costo, Distancia) :-
    tramo(Actual, Destino, Distancia, Costo, _).

% 3. El Caso Recursivo: Cuando saltas a una ciudad intermedia
buscar_ruta_con_costo(Actual, Destino, Visitados, RutaFinal, CostoTotal, DistanciaTotal) :-
    tramo(Actual, Intermedio, DistanciaTramo, CostoTramo, _),
    \+ member(Intermedio, Visitados),
    % Aquí ocurre la magia: seguimos buscando lo que falta...
    buscar_ruta_con_costo(Intermedio, Destino, [Intermedio | Visitados], RutaFinal, CostoRestante, DistanciaRestante),
    % ...y cuando Prolog regresa del viaje, suma los resultados
    CostoTotal is CostoTramo + CostoRestante,
    DistanciaTotal is DistanciaTramo + DistanciaRestante.

% ==========================================
% RESTRICCIONES POR PRESUPUESTO
% ==========================================

ruta_en_presupuesto(Origen, Destino, PresupuestoMaximo, RutaFinal) :-
    % 1. Buscamos cualquier ruta y sacamos cuánto cuesta
    ruta_con_costo(Origen, Destino, RutaFinal, CostoTotal, _),
    
    % 2. Filtramos: El costo total debe ser menor o igual al presupuesto
    CostoTotal =< PresupuestoMaximo.

% ==========================================
% FILTRO DE SERVICIOS: GASOLINERAS
% ==========================================

% Encuentra rutas que incluyan al menos una gasolinera
ruta_con_gasolinera(Origen, Destino, Ruta) :-
    % 1. Generamos una ruta posible
    ruta(Origen, Destino, Ruta),
    
    % 2. Verificamos que algún Lugar dentro de esa Ruta tenga gasolinera
    member(Lugar, Ruta),
    servicio(Lugar, gasolinera).

% ==========================================
% FILTROS DE LUGARES Y SERVICIOS
% ==========================================

% 1. Rutas que incluyan lugares turísticos
ruta_turistica(Origen, Destino, Ruta) :-
    ruta(Origen, Destino, Ruta),
    member(Lugar, Ruta),
    servicio(Lugar, turistico).

% 2. Rutas que pasen por un lugar específico (parada obligatoria)
ruta_pasa_por(Origen, Destino, Parada, Ruta) :-
    ruta(Origen, Destino, Ruta),
    member(Parada, Ruta).

% ==========================================
% FILTROS POR TIPO DE CAMINO
% ==========================================

% --- Reglas ayudantes para revisar los caminos entre ciudades ---
% Caso base: Una sola ciudad en la lista no tiene caminos que revisar
todos_libres([_]). 
% Caso recursivo: Revisa que de A hacia B sea libre, y luego revisa el resto
todos_libres([A, B | Resto]) :-
    tramo(A, B, _, _, libre),
    todos_libres([B | Resto]).

todos_cuota([_]).
todos_cuota([A, B | Resto]) :-
    tramo(A, B, _, _, cuota),
    todos_cuota([B | Resto]).

% --- Las reglas finales que usará el usuario ---

% 3. Rutas que sean SOLO por carretera libre
ruta_libre(Origen, Destino, Ruta) :-
    ruta(Origen, Destino, Ruta),
    todos_libres(Ruta).

% 4. Rutas que sean SOLO por carretera de cuota
ruta_cuota(Origen, Destino, Ruta) :-
    ruta(Origen, Destino, Ruta),
    todos_cuota(Ruta).

% 5. Rutas Mixtas (tienen de las dos)
ruta_mixta(Origen, Destino, Ruta) :-
    ruta(Origen, Destino, Ruta),
    \+ todos_libres(Ruta),   % NO es puramente libre
    \+ todos_cuota(Ruta).    % NO es puramente de cuota


% ==========================================
% CONSULTAS AVANZADAS 
% ==========================================

% 1. Todas las rutas posibles (Agrupa todos los resultados en una lista)
todas_las_rutas(Origen, Destino, ListaDeRutas) :-
    findall(R, ruta(Origen, Destino, R), ListaDeRutas).

% 2. Ruta más barata
% setof organiza de menor a mayor, por lo que el primer elemento es el mínimo
ruta_mas_barata(Origen, Destino, Ruta, Costo) :-
    setof((C, R), Dist^ruta_con_costo(Origen, Destino, R, C, Dist), [(Costo, Ruta) | _]).

% 3. Ruta más cara 
% Buscamos la última de la lista ordenada por setof
ruta_mas_cara(Origen, Destino, Ruta, Costo) :-
    setof((C, R), Dist^ruta_con_costo(Origen, Destino, R, C, Dist), Lista),
    last(Lista, (Costo, Ruta)).

% 4. Ruta más corta (Por distancia en KM)
ruta_mas_corta(Origen, Destino, Ruta, Distancia) :-
    setof((D, R), Costo^ruta_con_costo(Origen, Destino, R, Costo, D), [(Distancia, Ruta) | _]).

% 5. Ruta con al menos N puntos turísticos
% Regla ayudante para contar cuántos lugares de la lista son turísticos
contar_turisticos([], 0).
contar_turisticos([H|T], Cantidad) :-
    servicio(H, turistico), !,
    contar_turisticos(T, C1),
    Cantidad is C1 + 1.
contar_turisticos([_|T], Cantidad) :-
    contar_turisticos(T, Cantidad).

ruta_n_turisticos(Origen, Destino, N_Minimo, Ruta) :-
    ruta(Origen, Destino, Ruta),
    contar_turisticos(Ruta, Total),
    Total >= N_Minimo.

% 6. Ruta dentro de un rango de costo
ruta_rango_costo(Origen, Destino, Min, Max, Ruta, Costo) :-
    ruta_con_costo(Origen, Destino, Ruta, Costo, _),
    Costo >= Min,
    Costo =< Max.