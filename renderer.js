const STORAGE_KEY = 'quick-notetaker.entries';

const listEl = document.getElementById('list');
const addBtn = document.getElementById('add-btn');
const template = document.getElementById('entry-template');

/** @type {{id: string, page: string, text: string}[]} */
let entries = loadEntries();

let dragSrcId = null;

function loadEntries() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveEntries() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
}

function makeId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

function autosize(textarea) {
  textarea.style.height = 'auto';
  textarea.style.height = textarea.scrollHeight + 'px';
}

function render() {
  listEl.innerHTML = '';
  for (const entry of entries) {
    listEl.appendChild(buildEntryEl(entry));
  }
}

function buildEntryEl(entry) {
  const node = template.content.firstElementChild.cloneNode(true);
  node.dataset.id = entry.id;

  const pageInput = node.querySelector('.page-input');
  const removeBtn = node.querySelector('.remove-btn');
  const textInput = node.querySelector('.text-input');

  pageInput.value = entry.page || '';
  textInput.value = entry.text || '';

  pageInput.addEventListener('input', () => {
    entry.page = pageInput.value;
    saveEntries();
  });

  textInput.addEventListener('input', () => {
    entry.text = textInput.value;
    autosize(textInput);
    saveEntries();
  });

  textInput.addEventListener('keydown', (e) => {
    if (e.key !== 'Enter') return;
    const value = textInput.value;
    const pos = textInput.selectionStart;
    const lineStart = value.lastIndexOf('\n', pos - 1) + 1;
    const currentLine = value.slice(lineStart, pos);
    const bulletMatch = currentLine.match(/^(\s*)-\s?/);
    if (bulletMatch) {
      e.preventDefault();
      const prefix = bulletMatch[1] + '- ';
      // Empty bullet line + Enter again removes the bullet instead of repeating it.
      if (currentLine.trim() === '-') {
        const before = value.slice(0, lineStart);
        const after = value.slice(pos);
        textInput.value = before + after;
        textInput.selectionStart = textInput.selectionEnd = lineStart;
      } else {
        const insert = '\n' + prefix;
        textInput.value = value.slice(0, pos) + insert + value.slice(pos);
        const caret = pos + insert.length;
        textInput.selectionStart = textInput.selectionEnd = caret;
      }
      entry.text = textInput.value;
      autosize(textInput);
      saveEntries();
    }
  });

  removeBtn.addEventListener('click', () => {
    entries = entries.filter((e) => e.id !== entry.id);
    saveEntries();
    render();
  });

  node.addEventListener('dragstart', () => {
    dragSrcId = entry.id;
    node.classList.add('dragging');
  });

  node.addEventListener('dragend', () => {
    node.classList.remove('dragging');
    document.querySelectorAll('.entry').forEach((el) => el.classList.remove('drag-over'));
  });

  node.addEventListener('dragover', (e) => {
    e.preventDefault();
    if (entry.id !== dragSrcId) node.classList.add('drag-over');
  });

  node.addEventListener('dragleave', () => {
    node.classList.remove('drag-over');
  });

  node.addEventListener('drop', (e) => {
    e.preventDefault();
    node.classList.remove('drag-over');
    if (!dragSrcId || dragSrcId === entry.id) return;
    reorder(dragSrcId, entry.id);
  });

  queueMicrotask(() => autosize(textInput));

  return node;
}

function reorder(sourceId, targetId) {
  const fromIndex = entries.findIndex((e) => e.id === sourceId);
  const toIndex = entries.findIndex((e) => e.id === targetId);
  if (fromIndex === -1 || toIndex === -1) return;
  const [moved] = entries.splice(fromIndex, 1);
  entries.splice(toIndex, 0, moved);
  saveEntries();
  render();
}

addBtn.addEventListener('click', () => {
  const entry = { id: makeId(), page: '', text: '' };
  entries.push(entry);
  saveEntries();
  render();
  const el = listEl.querySelector(`[data-id="${entry.id}"] .page-input`);
  el?.focus();
  listEl.scrollTop = listEl.scrollHeight;
});

render();
