
"""
Conversor de archivos de texto separados por tabulación a CSV
Maneja archivos con información adicional antes de los datos
"""

import argparse
import csv
import os
import re
import sys
from typing import List, Tuple, Optional

class TextToCSVConverter:
    def __init__(self):
        self.data_start_patterns = [
            r'Standards:\s+Validation.*Property_\d+',
            r'^\s*\d+\s+\w+\s+[\d.]+',  # Línea que empieza con número
            r'^\s*Standards:',
        ]
        
    def find_data_start(self, lines: List[str]) -> int:
        """
        Encuentra la línea donde empiezan los datos reales
        
        Args:
            lines: Lista de líneas del archivo
            
        Returns:
            Índice de la línea donde empiezan los datos
        """
        for i, line in enumerate(lines):
            # Buscar la línea de encabezado "Standards: Validation..."
            if re.search(r'Standards:\s+Validation.*Property_\d+', line.strip()):
                return i
        
        # Si no encuentra el patrón de encabezado, buscar la primera línea de datos
        for i, line in enumerate(lines):
            line = line.strip()
            if line and re.match(r'^\s*\d+\s+\w+\s+[\d.]+', line):
                return i
        
        return 0  # Por defecto, empezar desde el principio
    
    def clean_line(self, line: str) -> str:
        """
        Limpia una línea eliminando espacios extra y caracteres no necesarios
        """
        return re.sub(r'\s+', '\t', line.strip())
    
    def parse_data_line(self, line: str) -> Optional[Tuple[str, str, str]]:
        """
        Parsea una línea de datos y extrae ID, resultado y valor
        
        Args:
            line: Línea de datos
            
        Returns:
            Tupla con (id_espectro, result_value, status) o None si no es válida
        """
        line = line.strip()
        if not line:
            return None
        
        # Dividir por tabulaciones o espacios múltiples
        parts = re.split(r'\s+', line)
        
        if len(parts) < 3:
            return None
        
        # Extraer componentes
        id_espectro = parts[0].strip()
        status = parts[1].strip()
        value_part = parts[2].strip()
        
        # Verificar que el ID sea numérico
        if not id_espectro.isdigit():
            return None
        
        # Extraer valor numérico de la columna de valor
        # Buscar patrón numérico (puede tener unidades como "mgKOH")
        value_match = re.search(r'([\d.]+)', value_part)
        if not value_match:
            return None
        
        result_value = value_match.group(1)
        
        # Convertir status a número
        # "Reject" = 0, números = su valor, otros = 1
        if status.lower() == 'reject':
            status_num = '0'
        elif status.isdigit():
            status_num = status
        else:
            status_num = '1'
        
        return id_espectro, result_value, status_num
    
    def process_file(self, input_file: str, output_file: str) -> bool:
        """
        Procesa un archivo de texto y lo convierte a CSV
        
        Args:
            input_file: Ruta del archivo de entrada
            output_file: Ruta del archivo de salida CSV
            
        Returns:
            True si el procesamiento fue exitoso
        """
        try:
            # Leer archivo
            with open(input_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            print(f"Procesando: {input_file}")
            print(f"Total líneas: {len(lines)}")
            
            # Encontrar donde empiezan los datos
            data_start_line = self.find_data_start(lines)
            print(f"Datos empiezan en línea: {data_start_line + 1}")
            
            # Procesar datos
            csv_data = []
            processed_lines = 0
            
            # Saltar línea de encabezado si existe
            start_idx = data_start_line
            if start_idx < len(lines) and 'Standards:' in lines[start_idx]:
                start_idx += 1
            
            for i in range(start_idx, len(lines)):
                line = lines[i]
                parsed_data = self.parse_data_line(line)
                
                if parsed_data:
                    id_espectro, result_value, status = parsed_data
                    csv_data.append([
                        len(csv_data) + 1,  # INDEX
                        id_espectro,        # IdEspectro
                        result_value,       # RESULT_VALUE
                        status              # Status
                    ])
                    processed_lines += 1
            
            # Escribir CSV
            with open(output_file, 'w', newline='', encoding='utf-8') as f:
                writer = csv.writer(f)
                # Escribir encabezado
                writer.writerow(['INDEX', 'IdEspectro', 'RESULT_VALUE', '#'])
                # Escribir datos
                writer.writerows(csv_data)
            
            print(f"✓ Procesadas {processed_lines} líneas de datos")
            print(f"✓ Archivo CSV creado: {output_file}")
            return True
            
        except Exception as e:
            print(f"✗ Error procesando {input_file}: {str(e)}")
            return False
    
    def process_directory(self, input_dir: str, output_dir: str, file_extension: str = '.txt') -> None:
        """
        Procesa todos los archivos de texto en un directorio
        
        Args:
            input_dir: Directorio de entrada
            output_dir: Directorio de salida
            file_extension: Extensión de archivos a procesar
        """
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        txt_files = [f for f in os.listdir(input_dir) if f.endswith(file_extension)]
        
        if not txt_files:
            print(f"No se encontraron archivos {file_extension} en {input_dir}")
            return
        
        print(f"Encontrados {len(txt_files)} archivos para procesar")
        
        successful = 0
        failed = 0
        
        for txt_file in txt_files:
            input_path = os.path.join(input_dir, txt_file)
            output_file = os.path.splitext(txt_file)[0] + '.csv'
            output_path = os.path.join(output_dir, output_file)
            
            if self.process_file(input_path, output_path):
                successful += 1
            else:
                failed += 1
            
            print("-" * 50)
        
        print(f"\nResumen:")
        print(f"✓ Archivos procesados exitosamente: {successful}")
        print(f"✗ Archivos con errores: {failed}")

def main():
    parser = argparse.ArgumentParser(
        description='Convierte archivos de texto separados por tabulación a CSV',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Ejemplos de uso:
  # Procesar un archivo individual
  python text_to_csv.py -f archivo.txt -o resultado.csv
  
  # Procesar todos los archivos .txt de un directorio
  python text_to_csv.py -d /ruta/archivos/entrada -o /ruta/archivos/salida
  
  # Procesar archivos con extensión específica
  python text_to_csv.py -d /ruta/entrada -o /ruta/salida -e .dat
        '''
    )
    
    parser.add_argument('-f', '--file', type=str, help='Archivo individual a procesar')
    parser.add_argument('-d', '--directory', type=str, help='Directorio con archivos a procesar')
    parser.add_argument('-o', '--output', type=str, required=True, help='Archivo o directorio de salida')
    parser.add_argument('-e', '--extension', type=str, default='.txt', help='Extensión de archivos a procesar (default: .txt)')
    
    args = parser.parse_args()
    
    if not args.file and not args.directory:
        print("Error: Debes especificar un archivo (-f) o un directorio (-d)")
        sys.exit(1)
    
    converter = TextToCSVConverter()
    
    if args.file:
        # Procesar archivo individual
        if not os.path.exists(args.file):
            print(f"Error: El archivo {args.file} no existe")
            sys.exit(1)
        
        success = converter.process_file(args.file, args.output)
        sys.exit(0 if success else 1)
    
    elif args.directory:
        # Procesar directorio
        if not os.path.exists(args.directory):
            print(f"Error: El directorio {args.directory} no existe")
            sys.exit(1)
        
        converter.process_directory(args.directory, args.output, args.extension)

if __name__ == "__main__":
    main()