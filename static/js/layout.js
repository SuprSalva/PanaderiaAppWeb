  const sidebar    = document.getElementById('sidebar');
  const toggleIcon = document.getElementById('toggleIcon');
  let collapsed = false;

  function toggleSidebar() {
    collapsed = !collapsed;
    sidebar.classList.toggle('collapsed', collapsed);
    toggleIcon.textContent = collapsed ? '▶' : '◀';
    localStorage.setItem('dmSidebarCollapsed', collapsed);
  }

  if (localStorage.getItem('dmSidebarCollapsed') === 'true') {
    collapsed = true;
    sidebar.classList.add('collapsed');
    if (toggleIcon) toggleIcon.textContent = '▶';
  }

  const overlay = document.getElementById('sidebarOverlay');

  function openMobileSidebar() {
    sidebar.classList.add('mobile-open');
    overlay.classList.add('visible');
    document.body.style.overflow = 'hidden';
  }

  function closeMobileSidebar() {
    sidebar.classList.remove('mobile-open');
    overlay.classList.remove('visible');
    document.body.style.overflow = '';
  }

  const userMenu = document.getElementById('userMenu');

  function toggleUserMenu() { userMenu.classList.toggle('open'); }

  document.addEventListener('click', function (e) {
    if (userMenu && !userMenu.contains(e.target)) {
      userMenu.classList.remove('open');
    }
  });

  const iconFullscreen = document.getElementById('iconFullscreen');

  const ICON_EXPAND   = '⛶';   
  const ICON_COMPRESS = '⊡'; 

  function toggleFullscreen() {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen?.().catch(() => {});
    } else {
      document.exitFullscreen?.();
    }
  }

  document.addEventListener('fullscreenchange', function () {
    if (iconFullscreen) {
      iconFullscreen.textContent = document.fullscreenElement ? ICON_COMPRESS : ICON_EXPAND;
    }
  });

  const menuSearchInput = document.getElementById('menuSearch');
  const searchClearBtn  = document.getElementById('searchClear');
  const noResults       = document.getElementById('nav-no-results');

  function filterNav(query) {
    const q = query.trim().toLowerCase();

    searchClearBtn.classList.toggle('visible', q.length > 0);

    if (q.length > 0 && collapsed) {
      sidebar.classList.remove('collapsed');
    } else if (q.length === 0 && collapsed) {
      sidebar.classList.add('collapsed');
    }

    const sections  = document.querySelectorAll('#sidebarNav .nav-section');
    const allItems  = document.querySelectorAll('#sidebarNav .nav-item');
    let   anyVisible = false;

    sections.forEach(function (section) {
      const items        = section.querySelectorAll('.nav-item');
      let   sectionHasMatch = false;

      items.forEach(function (item) {
        const label = (item.getAttribute('data-label') || item.querySelector('.nav-label')?.textContent || '').toLowerCase();
        const match = q === '' || label.includes(q);

        item.classList.toggle('hidden-by-search', !match);
        if (match) { sectionHasMatch = true; }
      });

      section.classList.toggle('hidden-by-search', !sectionHasMatch && q !== '');
      if (sectionHasMatch) { anyVisible = true; }
    });

    if (noResults) {
      noResults.style.display = (q !== '' && !anyVisible) ? 'block' : 'none';
    }
  }

  function clearSearch() {
    menuSearchInput.value = '';
    filterNav('');
    menuSearchInput.focus();
  }

  menuSearchInput && menuSearchInput.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') { clearSearch(); }
  });

  document.querySelectorAll('.nav-item').forEach(function (link) {
    if (link.href === window.location.href) {
      link.classList.add('active');
    }
  });
