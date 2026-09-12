const LINK_SEL = 'a[data-dialog="credentials"]';

function fillTemplate(template, current, total) {
  return template.replaceAll('{current}', String(current)).replaceAll('{total}', String(total));
}

function bindCarousel(dialog) {
  const scroller = dialog.querySelector('[data-trust-scroller]');
  const slides = [...dialog.querySelectorAll('[data-trust-slide]')];
  const dots = [...dialog.querySelectorAll('[data-trust-dot]')];
  const status = dialog.querySelector('[data-trust-page]');
  const prev = dialog.querySelector('[data-trust-prev]');
  const next = dialog.querySelector('[data-trust-next]');
  if (!(scroller instanceof HTMLElement) || slides.length === 0) return;

  const pageTemplate = dialog.dataset.pageTemplate ?? '{current} / {total}';
  const pageA11y = dialog.dataset.pageA11y ?? pageTemplate;
  let index = 0;
  let ticking = false;

  const clampIndex = (value) => Math.max(0, Math.min(slides.length - 1, value));

  const readIndex = () => {
    const width = scroller.clientWidth;
    if (width <= 0) return index;
    return clampIndex(Math.round(scroller.scrollLeft / width));
  };

  const paint = () => {
    index = readIndex();
    dots.forEach((dot, i) => {
      if (i === index) dot.setAttribute('aria-current', 'true');
      else dot.removeAttribute('aria-current');
    });
    if (status instanceof HTMLElement) {
      status.textContent = fillTemplate(pageTemplate, index + 1, slides.length);
      status.setAttribute('aria-label', fillTemplate(pageA11y, index + 1, slides.length));
    }
    if (prev instanceof HTMLButtonElement) prev.disabled = index === 0;
    if (next instanceof HTMLButtonElement) next.disabled = index === slides.length - 1;
  };

  const go = (nextIndex, smooth = true) => {
    const target = slides[clampIndex(nextIndex)];
    if (!(target instanceof HTMLElement)) return;
    scroller.scrollTo({
      left: target.offsetLeft,
      behavior: smooth ? 'smooth' : 'instant',
    });
    paint();
  };

  scroller.addEventListener(
    'scroll',
    () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        ticking = false;
        paint();
      });
    },
    { passive: true },
  );

  prev?.addEventListener('click', () => go(index - 1));
  next?.addEventListener('click', () => go(index + 1));
  dots.forEach((dot, i) => {
    dot.addEventListener('click', () => go(i));
  });

  scroller.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowRight') {
      event.preventDefault();
      go(index + 1);
    } else if (event.key === 'ArrowLeft') {
      event.preventDefault();
      go(index - 1);
    }
  });

  dialog.addEventListener('close', () => go(0, false));
  paint();
}

function bindDialog(dialog) {
  if (!(dialog instanceof HTMLDialogElement) || dialog.dataset.bound === '1') return;
  dialog.dataset.bound = '1';

  document.addEventListener('click', (event) => {
    if (event.defaultPrevented || event.button !== 0) return;
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const target = event.target;
    if (!(target instanceof Element)) return;
    const link = target.closest(LINK_SEL);
    if (!(link instanceof HTMLAnchorElement)) return;
    if (link.target && link.target !== '_self') return;
    event.preventDefault();
    if (!dialog.open) dialog.showModal();
  });

  dialog.querySelector('[data-trust-close]')?.addEventListener('click', () => dialog.close());
  bindCarousel(dialog);
}

function bindCredentialsDialog(root = document) {
  const dialog = root.querySelector('[data-trust-dialog]');
  if (dialog) bindDialog(dialog);
}

bindCredentialsDialog();
