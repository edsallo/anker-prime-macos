from pathlib import Path
import shutil,subprocess,tempfile
root=Path(__file__).resolve().parent
app=root/'dist/Anker Prime.app'
if not app.exists():raise SystemExit('Build the app first: python3 build.py')
output=root/'Anker-Prime-macOS-Apple-Silicon.dmg'
with tempfile.TemporaryDirectory(prefix='anker-dmg-') as tmp:
 stage=Path(tmp);shutil.copytree(app,stage/app.name,symlinks=True)
 (stage/'Applications').symlink_to('/Applications')
 (stage/'Установка — Installation.txt').write_text('Перетащите Anker Prime в Applications. Затем извлеките диск и откройте приложение из Программ.\n\nDrag Anker Prime to Applications. Eject this disk, then open the app from Applications.\n\nApple Silicon · macOS 14+\nНеофициальное приложение. Сборка не заверена Apple.\nUnofficial app. This build is not notarized by Apple.\n')
 subprocess.run(['hdiutil','create','-ov','-volname','Anker Prime','-srcfolder',str(stage),'-format','UDZO',str(output)],check=True)
print(output)
