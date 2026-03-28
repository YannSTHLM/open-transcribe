# -*- mode: python ; coding: utf-8 -*-

import os
from PyInstaller.utils.hooks import collect_submodules, collect_data_files, copy_metadata

block_cipher = None

# We need to collect implicit imports from faster_whisper, ctranslate2, tokenizers, etc.
hiddenimports = [
    'uvicorn.logging',
    'uvicorn.loops',
    'uvicorn.loops.auto',
    'uvicorn.protocols',
    'uvicorn.protocols.http',
    'uvicorn.protocols.http.auto',
    'uvicorn.protocols.websockets',
    'uvicorn.protocols.websockets.auto',
    'uvicorn.lifespan',
    'uvicorn.lifespan.on',
    'fastapi',
    'pydantic',
    'sqlalchemy',
    'faster_whisper',
    'ctranslate2',
    'tokenizers',
    'huggingface_hub',
    'av',
]

hypercorn_imports = collect_submodules('uvicorn')
hiddenimports.extend(hypercorn_imports)

# Collect data files for our libraries
datas = []
datas += collect_data_files('faster_whisper')
datas += collect_data_files('ctranslate2')
datas += collect_data_files('tokenizers')

# We also copy metadata so some huggingface/transformers logic works properly inside the bundle
# Only capturing core huggingface / tokenizers metadata to be safe
datas += copy_metadata('tokenizers')
datas += copy_metadata('huggingface-hub')

# Add the compiled frontend dist folder
# In build-app.sh we will build it first so it's available.
frontend_path = os.path.join('..', 'frontend', 'dist')
if os.path.exists(frontend_path):
    datas.append((frontend_path, 'frontend_dist'))
else:
    print(f"WARNING: Frontend dist not found at {frontend_path}. Build it first!")

a = Analysis(
    ['app/main.py'],
    pathex=['.'],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='OpenTranscribe',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='OpenTranscribe',
)
