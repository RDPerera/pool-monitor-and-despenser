import hashlib
from pathlib import Path
fav = Path('web/favicon.png')
logo = Path('lib/assets/images/logo.png')
print('favicon', fav.stat().st_size, 'logo', logo.stat().st_size)
print('favicon-hash', hashlib.sha256(fav.read_bytes()).hexdigest())
print('logo-hash', hashlib.sha256(logo.read_bytes()).hexdigest())
