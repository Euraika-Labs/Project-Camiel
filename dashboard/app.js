'use strict';
const number = new Intl.NumberFormat('nl-BE', {maximumFractionDigits: 2});
const element = id => document.getElementById(id);
const duration = seconds => `${number.format(seconds)} seconden`;
const date = stamp => stamp ? `${stamp.slice(8, 10)}-${stamp.slice(5, 7)}-${stamp.slice(0, 4)} ${stamp.slice(11)}` : 'Nog geen';
async function request(path, options) {
  const response = await fetch(path, {cache: 'no-store', ...options});
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || 'De voortgang kon niet worden geladen.');
  return data;
}
async function refresh() {
  const [progress, summary] = await Promise.all([request('/api/progress'), request('/api/summary')]);
  element('lessons').textContent = number.format(summary.total_lessons_completed);
  element('stars').textContent = number.format(summary.total_stars);
  element('time').textContent = duration(summary.total_time_seconds);
  element('last').textContent = date(summary.last_session);
  element('breakdown').textContent = [1, 2, 3].map(n => `${n} ${n === 1 ? 'ster' : 'sterren'}: ${number.format(summary.star_rating_breakdown[`${n}_star`])}`).join(' · ');
  const rows = document.createDocumentFragment();
  for (const entry of progress.entries) {
    const row = document.createElement('tr');
    for (const value of [entry.lesson_id, `${entry.stars} / 3`, duration(entry.time_seconds), date(entry.completed_at)]) {
      const cell = document.createElement('td');
      cell.textContent = value;
      row.appendChild(cell);
    }
    rows.appendChild(row);
  }
  element('history').replaceChildren(rows);
  element('empty').hidden = progress.entries.length > 0;
}
element('upload').addEventListener('submit', async event => {
  event.preventDefault();
  const button = event.target.querySelector('button');
  const file = element('file').files[0];
  if (!file) return;
  if (file.size > 2 * 1024 * 1024) {
    element('status').textContent = 'Bestand is te groot (maximaal 2 MiB).';
    return;
  }
  button.disabled = true;
  element('status').textContent = 'Bestand controleren…';
  try {
    await request('/api/progress/import', {method: 'POST', body: new FormData(event.target)});
    await refresh();
    element('status').textContent = 'Voortgang geladen. Het spelbestand is niet gewijzigd.';
  } catch (error) {
    element('status').textContent = error.message;
  } finally {
    button.disabled = false;
  }
});
refresh().then(() => { element('status').textContent = 'Kies een voortgangsbestand om te beginnen.'; })
  .catch(() => { element('status').textContent = 'Dashboard niet bereikbaar. Controleer of de lokale server draait.'; });
