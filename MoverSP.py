import os
import csv
import shutil
import random
import argparse


def dividir_archivos(csv_original, carpeta_origen):
    # Configuración inicial (modifica según tus necesidades)
    csv_original = os.path.join(carpeta_origen, csv_original)           # Nombre del archivo CSV original
    # carpeta_origen = 'archivos_originales'  # Carpeta con los archivos originales
    # carpeta_salida = 'datasets_divididos'   # Carpeta base para los grupos
    grupo_70 = 'entrenamiento'                   # Nombre carpeta para el 70%
    grupo_30 = 'validacion'                   # Nombre carpeta para el 30%

    # print(f'Ruta Archivo {}')    
    # Crear carpetas principales si no existen
    os.makedirs(os.path.join(carpeta_origen, grupo_70), exist_ok=True)
    os.makedirs(os.path.join(carpeta_origen, grupo_30), exist_ok=True)
    
    # Leer CSV original y extraer nombres de archivos
    encabezado = []
    archivos = []
    filas_csv = []
    with open(csv_original, 'r', newline='', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        try:
            encabezado = next(reader)
        except StopIteration:
            print("! Error el archivo está vacío ¡")
            return

        for fila in reader:
            if len(fila) > 1:  # Asegurar que hay al menos 2 columnas
                archivos.append(fila[1])
                filas_csv.append(fila)
    
    # Mezclar y dividir los archivos (70% - 30%)
    random.shuffle(archivos)
    total = len(archivos)
    corte = int(total * 0.7)
    grupo1 = set(archivos[:corte])  # Conjunto para búsqueda eficiente
    grupo2 = set(archivos[corte:])
    
    # Función para procesar cada grupo
    def procesar_grupo(grupo, nombre_grupo):
        ruta_carpeta = os.path.join(carpeta_origen, nombre_grupo)
        csv_salida = os.path.join(ruta_carpeta, f'datos_{nombre_grupo}.csv')
        
        with open(csv_salida, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)

            # Escribir encabezados primero
            writer.writerow(encabezado)

            for fila in filas_csv:
                if len(fila) > 1 and fila[1] in grupo:
                    # Copiar archivo físico
                    origen = os.path.join(carpeta_origen, fila[1] + '.sp')
                    destino = os.path.join(ruta_carpeta, fila[1] + '.sp')
                    if os.path.exists(origen):
                        shutil.copy2(origen, destino)
                    # Escribir fila en CSV del grupo
                    writer.writerow(fila)
    
    # Procesar ambos grupos
    procesar_grupo(grupo1, grupo_70)
    procesar_grupo(grupo2, grupo_30)
    
    print("¡Proceso completado con éxito!")
    print(f"- Archivos en Entrenamiento: {len(grupo1)}")
    print(f"- Archivos en Validación: {len(grupo2)}")
    print(f"CSVs generados en: '{os.path.join(carpeta_origen, grupo_70)}' y '{os.path.join(carpeta_origen, grupo_30)}'")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Dividir archivos en grupos 70/30%')
    parser.add_argument('--csv', required=True, help='Ruta al archivo CSV original')
    parser.add_argument('--origen', required=True, help='Carpeta con archivos originales')
    # parser.add_argument('--salida', required=True, help='Carpeta base para los grupos')
    # parser.add_argument('--grupo70', default='grupo_70', help='Nombre carpeta para el 70% (default: grupo_70)')
    # parser.add_argument('--grupo30', default='grupo_30', help='Nombre carpeta para el 30% (default: grupo_30)')
    
    args = parser.parse_args()
    
    dividir_archivos(
        csv_original=args.csv,
        carpeta_origen=args.origen
        # ,
        # carpeta_salida=args.salida,
        # grupo_70=args.grupo70,
        # grupo_30=args.grupo30
    )