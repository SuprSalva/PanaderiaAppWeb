"""
Descarga todos los íconos de animatedicons.co usados en los templates
y los guarda en static/icons/, luego actualiza cada archivo para usar rutas locales.

Uso: python download_icons.py
Escanea automáticamente todos los archivos .html dentro de templates/
"""
import re
import os
import glob
import urllib.request
import urllib.parse

TEMPLATES_DIR = 'templates'
ICONS_DIR = 'static/icons'

pattern = r'https://animatedicons\.co/get-icon\?name=([^&"\']+)&style=minimalistic&token=([a-f0-9\-]+)'

# Lee todos los templates HTML
html_files = glob.glob(os.path.join(TEMPLATES_DIR, '**', '*.html'), recursive=True)
print(f"Escaneando {len(html_files)} archivos HTML...\n")

# Mapeo url -> local_path  (se construye una sola vez para todos los archivos)
url_to_local = {}
file_contents = {}

for filepath in html_files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    file_contents[filepath] = content
    for name_enc, token in re.findall(pattern, content):
        name_clean = urllib.parse.unquote(name_enc).lower().replace(' ', '-')
        filename = f"{name_clean}-{token[:8]}.json"
        local_path = os.path.join(ICONS_DIR, filename)
        full_url = f"https://animatedicons.co/get-icon?name={name_enc}&style=minimalistic&token={token}"
        url_to_local[full_url] = local_path

print(f"Encontrados {len(url_to_local)} íconos únicos.\n")

os.makedirs(ICONS_DIR, exist_ok=True)

# Descarga solo los que no existen todavía
errors = []
new_downloads = 0
for url, local_path in url_to_local.items():
    if os.path.exists(local_path):
        continue
    try:
        print(f"  Descargando  {os.path.basename(local_path)} ...", end=' ')
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = resp.read()
        with open(local_path, 'wb') as f:
            f.write(data)
        print("OK")
        new_downloads += 1
    except Exception as e:
        print(f"ERROR: {e}")
        errors.append((url, str(e)))

if new_downloads == 0:
    print("  Ningún ícono nuevo (todos ya estaban descargados).")

print()

# Reemplaza URLs en cada archivo que las contenga
updated = 0
for filepath, content in file_contents.items():
    new_content = content
    for url, local_path in url_to_local.items():
        static_path = '/static/icons/' + os.path.basename(local_path)
        new_content = new_content.replace(url, static_path)
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"  Actualizado: {filepath}")
        updated += 1

print(f"\n{updated} archivo(s) actualizados con rutas locales.")

if errors:
    print(f"\nAdvertencia: {len(errors)} íconos no se pudieron descargar:")
    for url, err in errors:
        print(f"  {url}\n    -> {err}")
else:
    print("Todos los íconos descargados correctamente.")
