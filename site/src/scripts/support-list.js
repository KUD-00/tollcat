const DIALOG_SEL = 'dialog.support-dialog';
const LINK_SEL = 'a[data-dialog="support-list"]';

function bindFilter(root) {
  const input = root.querySelector('[data-support-filter]');
  const empty = root.querySelector('[data-support-empty]');
  const items = [...root.querySelectorAll('[data-support-name]')];
  const sections = [...root.querySelectorAll('[data-support-section]')];
  if (!(input instanceof HTMLInputElement) || items.length === 0) return;

  const apply = () => {
    const needle = input.value.trim().toLocaleLowerCase();
    let visible = 0;
    for (const item of items) {
      const hay = `${item.dataset.supportHay ?? item.dataset.supportName ?? ''} ${item.textContent ?? ''}`.toLocaleLowerCase();
      const show = needle.length === 0 || hay.includes(needle);
      item.classList.toggle('is-filtered-out', !show);
      if (show) visible += 1;
    }
    for (const section of sections) {
      const any = section.querySelector('[data-support-name]:not(.is-filtered-out)');
      section.hidden = !any;
    }
    if (empty instanceof HTMLElement) empty.hidden = visible > 0;
  };

  input.addEventListener('input', apply);
}

function bindStack(stack) {
  if (!(stack instanceof HTMLElement) || stack.dataset.stackBound === '1') return;
  stack.dataset.stackBound = '1';

  const host = stack.dataset.host;
  const dialog = stack.closest('dialog');
  const detailPane = stack.querySelector('[data-pane="detail"]');
  const listPane = stack.querySelector('[data-pane="list"]');
  const titleEl = stack.querySelector('[data-detail-title]');
  const articles = new Map(
    [...stack.querySelectorAll('[data-detail]')].map((el) => [el.dataset.detail, el]),
  );
  if (!(detailPane instanceof HTMLElement) || !(listPane instanceof HTMLElement)) return;

  const setOpen = (key) => {
    const article = key ? articles.get(key) : undefined;
    const open = Boolean(article);
    stack.classList.toggle('is-detail', open);
    document.documentElement.classList.toggle('support-detail-open', open && host === 'page');
    for (const [id, el] of articles) {
      if (el instanceof HTMLElement) el.hidden = id !== key;
    }
    if (titleEl instanceof HTMLElement) titleEl.textContent = article?.dataset.name ?? '';
    if (open) {
      detailPane.hidden = false;
      listPane.setAttribute('aria-hidden', 'true');
      listPane.inert = true;
      const back = detailPane.querySelector('[data-support-back]');
      if (back instanceof HTMLElement) back.focus({ preventScroll: true });
    } else {
      listPane.removeAttribute('aria-hidden');
      listPane.inert = false;
      const current = stack.dataset.open;
      const opener = current ? stack.querySelector(`[data-support-open="${current}"]`) : null;
      if (opener instanceof HTMLElement) opener.focus({ preventScroll: true });
    }
    if (open) stack.dataset.open = key;
    else delete stack.dataset.open;
  };

  const syncHash = (key) => {
    if (host !== 'page') return;
    const next = key ? `#${key}` : `${location.pathname}${location.search}`;
    if (key) {
      if (location.hash !== `#${key}`) history.pushState({ support: key }, '', next);
    } else if (location.hash) {
      history.pushState({ support: '' }, '', next);
    }
  };

  const openKey = (key, { hash = true } = {}) => {
    if (!articles.has(key)) return false;
    setOpen(key);
    if (hash) syncHash(key);
    return true;
  };

  const closeDetail = ({ hash = true } = {}) => {
    setOpen('');
    if (hash) syncHash('');
  };

  stack.addEventListener('click', (event) => {
    if (event.defaultPrevented || event.button !== 0) return;
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
    const target = event.target;
    if (!(target instanceof Element)) return;
    const opener = target.closest('[data-support-open]');
    if (opener instanceof HTMLElement && stack.contains(opener)) {
      const key = opener.dataset.supportOpen;
      if (!key) return;
      event.preventDefault();
      if (dialog instanceof HTMLDialogElement && !dialog.open) dialog.showModal();
      openKey(key);
      return;
    }
    const back = target.closest('[data-support-back]');
    if (back && stack.contains(back)) {
      event.preventDefault();
      closeDetail();
    }
  });

  if (dialog instanceof HTMLDialogElement) {
    dialog.addEventListener('cancel', (event) => {
      if (!stack.classList.contains('is-detail')) return;
      event.preventDefault();
      closeDetail({ hash: false });
    });
    dialog.addEventListener('close', () => closeDetail({ hash: false }));
  }

  if (host === 'page') {
    const fromHash = () => {
      const key = location.hash.replace(/^#/, '');
      if (key && articles.has(key)) setOpen(key);
      else if (stack.classList.contains('is-detail')) setOpen('');
    };
    window.addEventListener('popstate', fromHash);
    fromHash();
  }

  stack.supportOpen = openKey;
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

  for (const close of dialog.querySelectorAll('[data-support-close]')) {
    close.addEventListener('click', () => dialog.close());
  }
}

function bindSupportList(root = document) {
  for (const list of root.querySelectorAll('[data-support-list]')) {
    if (list.dataset.bound === '1') continue;
    list.dataset.bound = '1';
    bindFilter(list);
  }
  for (const stack of root.querySelectorAll('[data-support-stack]')) {
    bindStack(stack);
  }
  const dialog = root.querySelector(DIALOG_SEL);
  if (dialog) bindDialog(dialog);
}

bindSupportList();
