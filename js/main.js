/* main.js - Dashboard Control Estadístico PC3 */

document.addEventListener('DOMContentLoaded', () => {
    setupLightbox();
    setupDownloadButtons();
});

function setupLightbox() {
    const overlay = document.createElement('div');
    overlay.id = 'lightbox-overlay';
    overlay.innerHTML = `
        <img id="lightbox-img" src="" alt="Vista ampliada">
        <a id="lightbox-download" download title="Descargar imagen"
           style="position:absolute;top:16px;right:16px;background:rgba(0,0,0,0.6);color:white;
                  border-radius:8px;padding:6px 10px;display:flex;align-items:center;gap:4px;
                  text-decoration:none;font-size:13px;font-family:Inter,sans-serif;
                  transition:background 0.2s;">
            <span class="material-symbols-outlined" style="font-size:18px">download</span>
            Descargar
        </a>`;
    document.body.appendChild(overlay);

    const lbImg = document.getElementById('lightbox-img');
    const lbDownload = document.getElementById('lightbox-download');

    document.querySelectorAll('main img[src*="imagenes/"]').forEach(img => {
        img.style.cursor = 'zoom-in';
        img.classList.add('img-lightbox');
        img.addEventListener('click', () => {
            lbImg.src = img.src;
            lbDownload.href = img.src;
            lbDownload.download = img.src.split('/').pop();
            overlay.classList.add('active');
        });
    });

    overlay.addEventListener('click', e => {
        if (e.target === overlay || e.target === lbImg) overlay.classList.remove('active');
    });

    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') overlay.classList.remove('active');
    });
}

function setupDownloadButtons() {
    document.querySelectorAll('main img[src*="imagenes/"]').forEach(img => {
        const wrapper = document.createElement('div');
        wrapper.className = 'img-wrapper';
        img.parentNode.insertBefore(wrapper, img);
        wrapper.appendChild(img);

        img.onerror = function() { this.parentElement.style.display = 'none'; };
        if (img.complete && img.naturalWidth === 0) { wrapper.style.display = 'none'; }

        const btn = document.createElement('a');
        btn.href = img.src;
        btn.download = img.src.split('/').pop();
        btn.className = 'img-download-btn';
        btn.title = 'Descargar';
        btn.innerHTML = '<span class="material-symbols-outlined">download</span>';
        btn.addEventListener('click', e => e.stopPropagation());
        wrapper.appendChild(btn);
    });
}
