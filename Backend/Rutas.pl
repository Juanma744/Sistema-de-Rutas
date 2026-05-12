% ==========================================
% Base de Conocimientos: Ciudades
% ==========================================
lugar(zamora).
lugar(morelia).
lugar(queretaro).
lugar(jacona).
lugar(uruapan).
lugar(patzcuaro).
lugar(tangancicuaro).

% ==========================================
% Conexiones: origen, destino, distancia, costo, tipo
% ==========================================
conexion(zamora, morelia, 150, 150, cuota).
conexion(zamora, morelia, 200, 0, libre).
conexion(uruapan, patzcuaro, 180, 0, libre).
conexion(uruapan, patzcuaro, 100, 70, cuota).
conexion(zamora, jacona, 5, 0, libre).
conexion(jacona, tangancicuaro, 20, 0, libre).
conexion(morelia, patzcuaro, 60, 0, libre).
conexion(morelia, jacona, 190, 170, cuota).
conexion(morelia, tangancicuaro, 130, 0, libre).

% CONEXIÓN CORREGIDA: Morelia a Querétaro
conexion(morelia, queretaro, 400, 300, cuota).
conexion(morelia, queretaro, 600, 0, libre).

% ==========================================
% Servicios detallados
% ==========================================
servicio(morelia, gasolinera).
servicio(morelia, paradero).
servicio(morelia, turistico).
servicio(queretaro, turistico).
servicio(queretaro, gasolinera).
servicio(jacona, gasolinera).
servicio(jacona, paradero).
servicio(zamora, paradero).
servicio(zamora, gasolinera).
servicio(patzcuaro, turistico).
servicio(patzcuaro, gasolinera).
servicio(uruapan, gasolinera).
servicio(tangancicuaro, turistico).

% ==========================================
% Lógica de búsqueda bidireccional
% ==========================================

tramo(A, B, D, C, T) :- conexion(A, B, D, C, T).
tramo(A, B, D, C, T) :- conexion(B, A, D, C, T).

% Predicado principal corregido (Se eliminó reverse de Tipos, Costos y Distancias)
ruta_completa(Origen, Destino, RutaFinal, CostoTotal, DistTotal, Tipos, Costos, Distancias) :-
    viajar(Origen, Destino, [Origen], RutaInvertida, CostoTotal, DistTotal, Tipos, Costos, Distancias),
    reverse(RutaInvertida, RutaFinal).

% Caso base: Llegamos al destino
viajar(Actual, Destino, Visitados, [Destino|Visitados], Costo, Dist, [Tipo], [Costo], [Dist]) :-
    tramo(Actual, Destino, Dist, Costo, Tipo).

% Caso recursivo: Buscar ciudad intermedia
viajar(Actual, Destino, Visitados, RutaFinal, CostoTotal, DistTotal, [Tipo|RestoTipos], [CostoTramo|RestoCostos], [DistTramo|RestoDists]) :-
    tramo(Actual, Intermedio, DistTramo, CostoTramo, Tipo),
    Intermedio \= Destino,
    \+ member(Intermedio, Visitados),
    viajar(Intermedio, Destino, [Intermedio|Visitados], RutaFinal, CostoResto, DistResto, RestoTipos, RestoCostos, RestoDists),
    CostoTotal is CostoTramo + CostoResto,
    DistTotal is DistTramo + DistResto.