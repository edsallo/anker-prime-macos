(()=>{
 const themes=[['anker','Anker · светлая'],['mint','Мята · тёмная'],['ocean','Океан'],['graphite','Графит'],['sand','Песок']];
 const selected=themes.some(([id])=>id===document.documentElement.dataset.theme)?document.documentElement.dataset.theme:'anker';
 document.documentElement.dataset.theme=selected;
 const header=document.querySelector('header');if(!header)return;
 const select=document.createElement('select');select.className='appearance-picker';select.setAttribute('aria-label','Цветовая тема');
 for(const [id,label] of themes)select.add(new Option(label,id));select.value=selected;
 select.onchange=()=>{document.documentElement.dataset.theme=select.value;window.webkit?.messageHandlers?.appearance?.postMessage(select.value);};header.append(select);
})();
