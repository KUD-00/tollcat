// 类别来自 shared/api-contract.json（generate-shared.py 改写本行）。
const CATEGORIES = new Set(['bug', 'idea', 'provider', 'other']);

function bindContactForm(root = document) {
  const form = root.querySelector('[data-contact]');
  if (!(form instanceof HTMLFormElement) || form.dataset.bound === '1') return;
  form.dataset.bound = '1';

  const endpoint = form.dataset.endpoint;
  const status = form.querySelector('[data-contact-status]');
  const submit = form.querySelector('[type="submit"]');
  if (!endpoint || !(status instanceof HTMLElement) || !(submit instanceof HTMLButtonElement)) return;

  const labels = {
    sending: submit.dataset.sending ?? '',
    sent: status.dataset.sent ?? '',
    rateLimited: status.dataset.rateLimited ?? '',
    failed: status.dataset.failed ?? '',
  };
  const idleLabel = submit.textContent ?? '';
  let inflight = false;

  const setStatus = (text, kind) => {
    status.textContent = text;
    status.dataset.kind = kind;
  };

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (inflight) return;

    const data = new FormData(form);
    const note = String(data.get('message') ?? '').trim();
    const composed = [...form.querySelectorAll('[data-compose]')]
      .map((field) => {
        if (!(field instanceof HTMLInputElement || field instanceof HTMLTextAreaElement)) return '';
        const value = String(data.get(field.name) ?? '').trim();
        const label = field.dataset.compose?.trim();
        if (!value || !label) return '';
        return `${label}: ${value}`;
      })
      .filter(Boolean);
    const prefix = form.dataset.composePrefix?.trim();
    const message = [
      prefix ? `[${prefix}]` : '',
      ...composed,
      note,
    ]
      .filter(Boolean)
      .join('\n');
    if (!message) return;

    const rawCategory = String(data.get('category') ?? 'other');
    const category = CATEGORIES.has(rawCategory) ? rawCategory : 'other';
    const contact = String(data.get('contact') ?? '').trim();

    inflight = true;
    submit.disabled = true;
    submit.textContent = labels.sending;
    setStatus('', 'idle');

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          id: crypto.randomUUID(),
          category,
          message,
          ...(contact ? { contact } : {}),
          appVersion: 'site',
          osVersion: '',
          locale: document.documentElement.lang || '',
          deviceModel: 'web',
        }),
      });
      if (response.status === 429) {
        setStatus(labels.rateLimited, 'error');
        return;
      }
      if (!response.ok) {
        setStatus(labels.failed, 'error');
        return;
      }
      form.reset();
      setStatus(labels.sent, 'ok');
    } catch {
      setStatus(labels.failed, 'error');
    } finally {
      inflight = false;
      submit.disabled = false;
      submit.textContent = idleLabel;
    }
  });
}

bindContactForm();
