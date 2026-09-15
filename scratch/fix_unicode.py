from pathlib import Path
p = Path(r"c:\Users\benja\OneDrive\Desktop\Module\2SEM\Statik\Programm\Querschnitt.lua")
text = p.read_bytes()
clean = bytes(b for b in text if b < 128)
count = len(text) - len(clean)
p.write_bytes(clean)
print(f"Removed {count} non-ASCII bytes from {p}")
