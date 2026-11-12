from pathlib import Path

from PIL import Image, ImageOps

# Pfade relativ zum Ordner dieses Skripts (assets/icon/)
ICON_DIR = Path(__file__).resolve().parent

# 1️⃣ Lade das Bild
image_path = ICON_DIR / "icon.png"  # Ersetze dies durch den Pfad zu deinem Bild
image = Image.open(image_path)

# 2️⃣ Entferne den transparenten Rand (getbbox erkennt den sichtbaren Bereich)
cropped_image = image.crop(image.getbbox())

# 3️⃣ Erstelle eine neue transparente Leinwand mit 1024x1024 Pixeln
new_image = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))  # Vollständig transparent

# 4️⃣ Berechne die neue Größe des Logos (dynamische Skalierung)
width, height = cropped_image.size
aspect_ratio = min(1024 / width, 1024 / height)  # Passe den Maßstab an, damit er 1024x1024 nicht überschreitet
new_width = int(width * aspect_ratio)
new_height = int(height * aspect_ratio)

# 5️⃣ Skaliere das Logo (ohne Verzerrung)
resized_image = cropped_image.resize((new_width, new_height), Image.Resampling.LANCZOS)

# 6️⃣ Füge das Logo zentriert in die neue Leinwand ein
x_offset = (1024 - new_width) // 2  # Zentrieren horizontal
y_offset = (1024 - new_height) // 2  # Zentrieren vertikal
new_image.paste(resized_image, (x_offset, y_offset), mask=resized_image)  # Verwende die Maske, um die Transparenz zu erhalten

# 7️⃣ Speichere das Bild mit Transparenz
output_path = ICON_DIR / "logo_optimized.png"
new_image.save(output_path, format="PNG")

print(f"Das optimierte runde Logo wurde unter {output_path} gespeichert.")
