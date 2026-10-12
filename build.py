from pathlib import Path
import shutil,subprocess,plistlib,os
root=Path(__file__).resolve().parent;source=root/'backend';app=root/'dist/Anker Prime.app';contents=app/'Contents';resources=contents/'Resources';binary=contents/'MacOS'
resources.mkdir(parents=True,exist_ok=True);binary.mkdir(parents=True,exist_ok=True)
backend=resources/'backend';backend.mkdir(exist_ok=True)
for name in ['server.js','service.js','history.js','lib','public','node_modules']:
 p=source/name;q=backend/name
 if p.is_dir():shutil.copytree(p,q,dirs_exist_ok=True)
 else:shutil.copyfile(p,q)
shutil.copyfile(root/'src/desktop-server.js',backend/'desktop-server.js')
p=backend/'public/setup.html';p.write_text(p.read_text().replace('на сервере в зашифрованном виде','на этом Mac в зашифрованном виде'))
p=backend/'public/index.html';p.write_text(p.read_text().replace('<div><p class="eyebrow">ВАША ЗАРЯДНАЯ СТАНЦИЯ</p><h1>Всё под контролем<span>.</span></h1></div>','').replace('<span>Anker Prime · A2345 · 250 Вт</span>',''))
p=backend/'public/style.css';p.write_text(p.read_text()+'\n.heading:has(#charger[hidden]){display:none}\n')
# Keep desktop-only layout changes separate from the deployed websites.
p=backend/'public/index.html';p.write_text(p.read_text().replace('<p class="muted">Для ручных лимитов выберите пользовательский режим.</p>',''))
p=backend/'public/app.js';p.write_text(p.read_text().replace('<button id="profile-new" class="primary"','<div class="profile-create"><button id="profile-new" class="secondary"').replace('Сохранить лимиты в профиль</button>`','Сохранить лимиты в новый профиль</button></div>`'))
# Desktop appearance overlays share the existing server's allowed asset routes.
theme_js=(root/'src/appearance/theme.js').read_text()
for name in ['app.js','setup.js','history.js']:
 p=backend/'public'/name;p.write_text(theme_js+'\n'+p.read_text())
# Compact desktop layout; preserve charging controls and move help out of the grid.
p=backend/'public/index.html';html=p.read_text().replace('<h2>Распределение мощности</h2>','<h2>Распределение мощности</h2>')
html=html.replace('<span class="muted">Напряжение · ток · энергия</span>','<button id="power-help" class="link" aria-label="О распределении мощности">ⓘ О мощности</button>')
p.write_text(html)
p=backend/'public/app.js';js=p.read_text()
import re
js=re.sub(r"\+'<aside class=\"info-card\">.*?</aside>'",'',js)
js=js.replace('Отдано после сброса</span>','Энергия</span>')
js=js.replace('const custom=state.settings.mode===5;','const custom=state.settings.mode===5;document.body.classList.toggle(\"custom-mode\",custom);')
js+="\n$('#power-help').onclick=()=>openPanel('Распределение мощности','<p class=\"notice\">Общий бюджет станции — 250 Вт. В автоматических режимах мощность распределяет зарядка. В пользовательском режиме лимиты USB-C меняются с шагом 5 Вт; при нехватке бюджета лимиты других портов уменьшаются автоматически.</p><p class=\"muted\">У A1 и A2 общий выключатель, лимит и счётчик энергии. Напряжение и ток показаны отдельно. Энергия на карточках считается с момента последнего сброса.</p>');\n"
p.write_text(js)
# Separate energy and battery-equivalent help targets.
p=backend/'public/app.js';js=p.read_text()
js=js.replace(' title="Эквивалент при 3,7 В, без учёта потерь зарядки"','')
old="c.querySelector('.energy-value').textContent=state.energy[p]?n(state.energy[p].wh)+' Вт·ч · ≈ '+n(state.energy[p].wh/3.7*1000,0)+' мА·ч':'Нет счётчика';"
new="c.querySelector('.energy-value').innerHTML=state.energy[p]?'<span title=\"Энергия, отданная портом после сброса счётчика\">'+n(state.energy[p].wh)+' Вт·ч</span> · <span title=\"Приблизительный эквивалент ёмкости при 3,7 В, без учёта потерь зарядки\">≈ '+n(state.energy[p].wh/3.7*1000,0)+' мА·ч</span>':'Нет счётчика';"
assert old in js
p.write_text(js.replace(old,new))
p=backend/'public/style.css';css=p.read_text()
for color,var in {'#111a1f':'--panel','#11191d':'--panel','#263137':'--control','#2a363d':'--secondary','#44535b':'--border-control','#53636b':'--border-control','#152519':'--button-text','#142019':'--button-text','#12221a':'--button-text','#472e2a':'--error-bg','#895b50':'--error-border','#ffd8cb':'--error-text','#0007':'--shadow'}.items():css=css.replace(color,'var('+var+')')
p.write_text(css+'\n'+(root/'src/appearance/theme.css').read_text())
p=backend/'public/history.html';p.write_text(p.read_text().replace('История хранится на Ubuntu','История хранится на этом Mac'))
# Language setup runs after each page has registered its handlers.
for name in ['app.js','setup.js','history.js']:
 p=backend/'public'/name;js=p.read_text().replace("'ru-RU'","(window.ankerLocale||'ru-RU')")
 p.write_text(js+'\n'+(root/'src/appearance/i18n.js').read_text())

node_path=os.environ.get('NODE_BINARY') or shutil.which('node')
if not node_path:raise SystemExit('Node.js 22+ is required; install Node or set NODE_BINARY.')
shutil.copyfile(node_path,resources/'node');(resources/'node').chmod(0o755)
subprocess.run(['xcrun','swiftc','-O','-target','arm64-apple-macosx14.0','-framework','Cocoa','-framework','WebKit',str(root/'src/AnkerPrime.swift'),'-o',str(binary/'AnkerPrime')],check=True)
info={'CFBundleName':'Anker Prime','CFBundleDisplayName':'Anker Prime','CFBundleIdentifier':'com.edsallo.anker-prime.mac','CFBundleExecutable':'AnkerPrime','CFBundlePackageType':'APPL','CFBundleShortVersionString':'1.2.0','CFBundleVersion':'4','LSMinimumSystemVersion':'14.0','NSHighResolutionCapable':True,'NSAppTransportSecurity':{'NSAllowsLocalNetworking':True,'NSAllowsArbitraryLoadsInWebContent':True}}
(contents/'Info.plist').write_bytes(plistlib.dumps(info));subprocess.run(['codesign','--force','--deep','--sign','-',str(app)],check=True)
iconset=root/'Anker.iconset';iconset.mkdir(exist_ok=True)
for size in [16,32,64,128,256,512,1024]:
 dest=iconset/(f'icon_{size}x{size}.png' if size<1024 else 'icon_512x512@2x.png')
 subprocess.run(['sips','-z',str(size),str(size),str(root/'assets/icon.png'),'--out',str(dest)],check=True,stdout=subprocess.DEVNULL)
 if size in [32,64,256,512]:shutil.copyfile(dest,iconset/f'icon_{size//2}x{size//2}@2x.png')
subprocess.run(['iconutil','-c','icns',str(root/'Anker.iconset'),'-o',str(resources/'Anker.icns')],check=True)
info['CFBundleIconFile']='Anker.icns';(contents/'Info.plist').write_bytes(plistlib.dumps(info))
shutil.copyfile(root/'NODE-LICENSE.txt',resources/'NODE-LICENSE.txt')
shutil.copyfile(source/'LICENSE',resources/'BACKEND-LICENSE.txt')
subprocess.run(['codesign','--force','--deep','--sign','-',str(app)],check=True)
print(app)
