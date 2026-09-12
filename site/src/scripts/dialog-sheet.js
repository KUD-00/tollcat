const DRAWER_MQ = '(max-width: 959px)';
const CLOSE_SEL = '[data-support-close], [data-trust-close], [data-platform-close]';
const OFFSCREEN = 'translate3d(0, 100svh, 0)';

function isDrawer() {
  return window.matchMedia(DRAWER_MQ).matches;
}

function prefersReduce() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

function bindDragToDismiss(dialog, sheet) {
  let startY = 0;
  let startT = 0;
  let dy = 0;
  let active = false;
  let pointerId = 0;

  const isHandle = (target) => {
    if (!(target instanceof Element)) return false;
    if (target.closest(`${CLOSE_SEL}, .support-back, .support-sheet-body, .trust-scroller, .trust-nav`)) {
      return false;
    }
    return target === sheet || Boolean(target.closest('.support-sheet-bar'));
  };

  const reset = () => {
    active = false;
    dy = 0;
    sheet.style.transition = '';
    sheet.style.transform = '';
  };

  sheet.addEventListener('pointerdown', (event) => {
    if (!dialog.open || !isDrawer() || event.button !== 0) return;
    if (!isHandle(event.target)) return;
    active = true;
    pointerId = event.pointerId;
    startY = event.clientY;
    startT = performance.now();
    dy = 0;
    sheet.setPointerCapture(event.pointerId);
    sheet.style.transition = 'none';
  });

  sheet.addEventListener('pointermove', (event) => {
    if (!active || event.pointerId !== pointerId) return;
    dy = Math.max(0, event.clientY - startY);
    sheet.style.transform = `translate3d(0, ${dy}px, 0)`;
  });

  const finish = (event) => {
    if (!active || (event && event.pointerId !== pointerId)) return;
    active = false;
    const elapsed = Math.max(1, performance.now() - startT);
    const velocity = dy / elapsed;
    const threshold = Math.max(88, sheet.offsetHeight * 0.2);
    if (dy > threshold || (dy > 36 && velocity > 0.7)) {
      sheet.style.transition = '';
      dismiss(dialog, sheet);
      return;
    }
    sheet.style.transition = 'transform 320ms var(--ease)';
    sheet.style.transform = 'translate3d(0, 0, 0)';
    const snap = () => {
      if (sheet.dataset.dismissing === '1') return;
      sheet.style.transition = '';
      sheet.style.transform = '';
    };
    sheet.addEventListener('transitionend', snap, { once: true });
    window.setTimeout(snap, 360);
  };

  sheet.addEventListener('pointerup', finish);
  sheet.addEventListener('pointercancel', () => {
    if (!active) return;
    reset();
  });
  dialog.addEventListener('close', reset);
}

function dismiss(dialog, sheet) {
  if (!dialog.open) return;
  if (!isDrawer() || prefersReduce()) {
    dialog.close();
    return;
  }
  if (sheet.dataset.dismissing === '1') return;
  sheet.dataset.dismissing = '1';
  const done = () => {
    if (sheet.dataset.dismissing !== '1') return;
    delete sheet.dataset.dismissing;
    sheet.style.transition = '';
    sheet.style.transform = '';
    if (dialog.open) dialog.close();
  };
  sheet.style.transition = 'transform 280ms var(--ease)';
  sheet.style.transform = OFFSCREEN;
  sheet.addEventListener('transitionend', done, { once: true });
  window.setTimeout(done, 320);
}

function bindOpenLock(dialog, sheet) {
  let generation = 0;

  const settle = () => {
    if (dialog.open) sheet.classList.add('is-settled');
  };

  const onOpen = () => {
    const token = ++generation;
    document.documentElement.classList.add('overlay-open');
    sheet.classList.remove('is-settled');
    dialog.scrollTop = 0;
    if (prefersReduce()) {
      settle();
      return;
    }
    window.setTimeout(() => {
      if (token === generation) settle();
    }, isDrawer() ? 420 : 240);
  };

  const onClose = () => {
    generation += 1;
    sheet.classList.remove('is-settled');
    const others = document.querySelectorAll('dialog.support-dialog[open]');
    if (![...others].some((el) => el !== dialog)) {
      document.documentElement.classList.remove('overlay-open');
    }
  };

  dialog.addEventListener('beforetoggle', (event) => {
    if (event.newState === 'open') onOpen();
    else onClose();
  });
  dialog.addEventListener('toggle', (event) => {
    if (event.newState === 'open') onOpen();
    else onClose();
  });

  sheet.addEventListener('animationend', (event) => {
    if (event.target !== sheet) return;
    if (event.animationName !== 'support-drawer-in' && event.animationName !== 'support-dialog-in') return;
    settle();
  });
}

function bindPagerSwipe(scroller) {
  const slides = [...scroller.querySelectorAll('[data-platform-slide], [data-trust-slide]')];
  if (slides.length < 2) return;

  const clamp = (value) => Math.max(0, Math.min(slides.length - 1, value));
  const readIndex = () => {
    const width = scroller.clientWidth;
    if (width <= 0) return 0;
    return clamp(Math.round(scroller.scrollLeft / width));
  };
  const go = (nextIndex, smooth = true) => {
    const target = slides[clamp(nextIndex)];
    if (!(target instanceof HTMLElement)) return;
    scroller.scrollTo({
      left: target.offsetLeft,
      behavior: smooth ? 'smooth' : 'instant',
    });
  };

  let startX = 0;
  let startY = 0;
  let startScroll = 0;
  let startIndex = 0;
  let startT = 0;
  let tracking = false;
  let axis = null;
  let pointerId = 0;

  scroller.addEventListener('pointerdown', (event) => {
    if (event.button !== 0) return;
    if (event.target instanceof Element && event.target.closest('a, button')) return;
    tracking = true;
    axis = null;
    pointerId = event.pointerId;
    startX = event.clientX;
    startY = event.clientY;
    startScroll = scroller.scrollLeft;
    startIndex = readIndex();
    startT = performance.now();
  });

  scroller.addEventListener('pointermove', (event) => {
    if (!tracking || event.pointerId !== pointerId) return;
    const dx = event.clientX - startX;
    const dy = event.clientY - startY;
    if (axis === null && (Math.abs(dx) > 10 || Math.abs(dy) > 10)) {
      axis = Math.abs(dx) > Math.abs(dy) * 1.1 ? 'x' : 'y';
    }
    if (axis !== 'x') return;
    if (event.pointerType === 'mouse' || event.pointerType === 'pen') {
      scroller.scrollLeft = startScroll - dx;
    }
  });

  const end = (event) => {
    if (!tracking || (event && event.pointerId !== pointerId)) return;
    tracking = false;
    if (axis !== 'x') {
      axis = null;
      return;
    }
    axis = null;
    const dx = (event?.clientX ?? startX) - startX;
    const elapsed = Math.max(1, performance.now() - startT);
    const width = Math.max(1, scroller.clientWidth);
    const threshold = Math.max(48, width * 0.15);
    const flicked = Math.abs(dx) > 28 && Math.abs(dx) / elapsed > 0.45;
    const nativeMoved = Math.abs(scroller.scrollLeft - startScroll);

    if ((event?.pointerType === 'touch' || event?.pointerType === 'pen') && nativeMoved > 12 && !flicked) {
      return;
    }

    if (dx <= -threshold || (flicked && dx < 0)) go(startIndex + 1);
    else if (dx >= threshold || (flicked && dx > 0)) go(startIndex - 1);
    else go(startIndex);
  };

  scroller.addEventListener('pointerup', end);
  scroller.addEventListener('pointercancel', end);
  scroller.addEventListener('dragstart', (event) => event.preventDefault());

  if (typeof ResizeObserver === 'function') {
    new ResizeObserver(() => go(readIndex(), false)).observe(scroller);
  }
}

function bindDialogSheet(dialog) {
  if (!(dialog instanceof HTMLDialogElement) || dialog.dataset.sheetBound === '1') return;
  dialog.dataset.sheetBound = '1';
  const sheet = dialog.querySelector('.support-sheet');
  if (!(sheet instanceof HTMLElement)) return;

  dialog.addEventListener('click', (event) => {
    if (event.target !== dialog) return;
    dismiss(dialog, sheet);
  });

  bindOpenLock(dialog, sheet);
  bindDragToDismiss(dialog, sheet);
  const scroller = dialog.querySelector('[data-platform-scroller], [data-trust-scroller]');
  if (scroller instanceof HTMLElement) bindPagerSwipe(scroller);
}

function bindDialogSheets(root = document) {
  for (const dialog of root.querySelectorAll('dialog.support-dialog')) {
    bindDialogSheet(dialog);
  }
}

bindDialogSheets();
