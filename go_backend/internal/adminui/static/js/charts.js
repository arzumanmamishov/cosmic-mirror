// Hand-rolled SVG charts for the dashboard (no chart library: the CSP
// only allows this origin's scripts). Specs: thin marks, 4px rounded data
// ends anchored to the baseline, a 2px surface gap between adjacent bars,
// 2px lines with a ringed end dot, hairline gridlines, a hover tooltip on
// every chart and a table view under each one. Colours come from CSS
// custom properties so light and dark mode each use their own steps.

import { h, s, fmtNum, fmtCompact, fmtDay, fmtPct } from './ui.js';

const HEIGHT = 200;
const MARGIN = { top: 14, right: 12, bottom: 26, left: 40 };
const BAR_MAX = 24;
const BAR_GAP = 2;

/** Clean ticks for a count axis: 0, step, 2·step … ≥ max (step ∈ 1·2·5·10ⁿ). */
export function niceTicks(max, target = 4) {
  if (!(max > 0)) return { top: 4, ticks: [0, 1, 2, 3, 4] };
  const raw = max / target;
  const mag = 10 ** Math.floor(Math.log10(raw));
  const norm = raw / mag;
  const step = Math.max(1, (norm <= 1 ? 1 : norm <= 2 ? 2 : norm <= 5 ? 5 : 10) * mag);
  const top = Math.ceil(max / step) * step;
  const ticks = [];
  for (let v = 0; v <= top + step / 2; v += step) ticks.push(Math.round(v));
  return { top, ticks };
}

function makeTooltip(wrap) {
  const tip = h('div', { class: 'chart-tip', role: 'presentation', hidden: true });
  wrap.append(tip);
  return {
    show(x, y, title, value) {
      tip.replaceChildren(h('div', { class: 'chart-tip-title' }, title), h('div', { class: 'chart-tip-value' }, value));
      tip.hidden = false;
      const w = tip.offsetWidth;
      const maxLeft = wrap.clientWidth - w / 2 - 4;
      tip.style.left = `${Math.max(w / 2 + 4, Math.min(x, maxLeft))}px`;
      tip.style.top = `${y}px`;
    },
    hide() { tip.hidden = true; },
  };
}

function frame(width) {
  const svg = s('svg', { class: 'chart-svg', width, height: HEIGHT, viewBox: `0 0 ${width} ${HEIGHT}` });
  const plotW = width - MARGIN.left - MARGIN.right;
  const plotH = HEIGHT - MARGIN.top - MARGIN.bottom;
  return { svg, plotW, plotH };
}

function yAxis(svg, ticks, top, plotW, plotH) {
  const y = (v) => MARGIN.top + plotH - (v / top) * plotH;
  for (const t of ticks) {
    const ty = Math.round(y(t)) + 0.5;
    svg.append(s('line', { class: t === 0 ? 'chart-baseline' : 'chart-grid', x1: MARGIN.left, x2: MARGIN.left + plotW, y1: ty, y2: ty }));
    svg.append(s('text', { class: 'chart-tick', x: MARGIN.left - 8, y: ty, 'text-anchor': 'end', 'dominant-baseline': 'middle' }, fmtCompact(t)));
  }
  return y;
}

/** Labels every 7th day counting back from the last, so "today" is always labelled. */
function xLabels(svg, data, xCenter) {
  const n = data.length;
  data.forEach((d, i) => {
    if ((n - 1 - i) % 7 !== 0) return;
    svg.append(s('text', { class: 'chart-tick', x: xCenter(i), y: HEIGHT - 8, 'text-anchor': 'middle' }, fmtDay(d.day)));
  });
}

function responsive(wrap, draw) {
  let lastWidth = 0;
  const redraw = () => {
    const width = Math.max(280, Math.floor(wrap.clientWidth || 600));
    if (width === lastWidth) return;
    lastWidth = width;
    draw(width);
  };
  if ('ResizeObserver' in window) {
    let frameReq = 0;
    new ResizeObserver(() => {
      cancelAnimationFrame(frameReq);
      frameReq = requestAnimationFrame(redraw);
    }).observe(wrap);
  }
  requestAnimationFrame(redraw);
}

function tableView(data, valueLabel) {
  return h('details', { class: 'table-view' },
    h('summary', null, 'Show as table'),
    h('div', { class: 'table-scroll' },
      h('table', { class: 'table table-compact' },
        h('thead', null, h('tr', null, h('th', null, 'Day (UTC)'), h('th', { class: 'num' }, valueLabel))),
        h('tbody', null, [...data].reverse().map((d) =>
          h('tr', null, h('td', null, fmtDay(d.day, { weekday: 'short', month: 'short', day: 'numeric' })), h('td', { class: 'num' }, fmtNum(d.count))))))));
}

function summaryLabel(title, data, unit) {
  const total = data.reduce((a, d) => a + d.count, 0);
  const peak = data.reduce((best, d) => (d.count > best.count ? d : best), data[0] || { count: 0, day: '' });
  return `${title}: ${fmtNum(total)} ${unit} over ${data.length} days` +
    (peak.count ? `, peak ${fmtNum(peak.count)} on ${fmtDay(peak.day)}` : '');
}

/** Column chart of a daily count series ([{day, count}]). Single series → no legend. */
export function columnChart(data, { title, unit, colorVar = '--series-1' }) {
  const wrap = h('div', { class: 'chart', style: { '--c': `var(${colorVar})` } });
  const root = h('div', null, wrap, tableView(data, unit[0].toUpperCase() + unit.slice(1)));
  const tip = makeTooltip(wrap);

  responsive(wrap, (width) => {
    tip.hide();
    const { svg, plotW, plotH } = frame(width);
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', summaryLabel(title, data, unit));
    const max = Math.max(0, ...data.map((d) => d.count));
    const { top, ticks } = niceTicks(max);
    const y = yAxis(svg, ticks, top, plotW, plotH);
    const band = plotW / data.length;
    const barW = Math.max(2, Math.min(BAR_MAX, band - BAR_GAP));
    const xCenter = (i) => MARGIN.left + band * i + band / 2;
    const baseY = y(0);

    const hover = s('rect', { class: 'chart-hover-band', y: MARGIN.top, height: plotH, width: band, visibility: 'hidden' });
    svg.append(hover);
    data.forEach((d, i) => {
      if (d.count <= 0) return; // a zero draws nothing
      const x = xCenter(i) - barW / 2;
      const yTop = y(d.count);
      const hgt = baseY - yTop;
      const r = Math.min(4, hgt, barW / 2);
      // Rounded at the data end, square on the baseline.
      svg.append(s('path', {
        class: 'chart-bar',
        d: `M${x},${baseY} V${yTop + r} A${r},${r} 0 0 1 ${x + r},${yTop} H${x + barW - r} A${r},${r} 0 0 1 ${x + barW},${yTop + r} V${baseY} Z`,
      }));
    });
    xLabels(svg, data, xCenter);

    // Hit targets: the whole band, taller and wider than the bar.
    data.forEach((d, i) => {
      const hit = s('rect', { class: 'chart-hit', x: MARGIN.left + band * i, y: MARGIN.top, width: band, height: plotH });
      hit.addEventListener('mouseenter', () => {
        hover.setAttribute('x', MARGIN.left + band * i);
        hover.setAttribute('visibility', 'visible');
        tip.show(xCenter(i), Math.min(y(d.count), baseY) - 8,
          fmtDay(d.day, { weekday: 'short', month: 'short', day: 'numeric' }), `${fmtNum(d.count)} ${unit}`);
      });
      hit.addEventListener('mouseleave', () => {
        hover.setAttribute('visibility', 'hidden');
        tip.hide();
      });
      svg.append(hit);
    });

    wrap.querySelector('svg')?.remove();
    wrap.prepend(svg);
  });
  return root;
}

/** Line chart of a daily count series, with an area wash and crosshair hover. */
export function lineChart(data, { title, unit, colorVar = '--series-1' }) {
  const wrap = h('div', { class: 'chart', style: { '--c': `var(${colorVar})` } });
  const root = h('div', null, wrap, tableView(data, unit[0].toUpperCase() + unit.slice(1)));
  const tip = makeTooltip(wrap);

  responsive(wrap, (width) => {
    tip.hide();
    const { svg, plotW, plotH } = frame(width);
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', summaryLabel(title, data, unit));
    const max = Math.max(0, ...data.map((d) => d.count));
    const { top, ticks } = niceTicks(max);
    const y = yAxis(svg, ticks, top, plotW, plotH);
    const n = data.length;
    const x = (i) => MARGIN.left + (n <= 1 ? plotW / 2 : (plotW * i) / (n - 1));
    const baseY = y(0);

    const points = data.map((d, i) => [x(i), y(d.count)]);
    const line = points.map(([px, py], i) => `${i ? 'L' : 'M'}${px.toFixed(1)},${py.toFixed(1)}`).join(' ');
    if (n > 1) {
      svg.append(s('path', { class: 'chart-area', d: `${line} L${x(n - 1)},${baseY} L${x(0)},${baseY} Z` }));
      svg.append(s('path', { class: 'chart-line', d: line }));
    }
    xLabels(svg, data, x);

    // End dot (ringed in the surface colour) + the latest value as a label.
    const last = points[n - 1];
    if (last) {
      svg.append(s('circle', { class: 'chart-dot', cx: last[0], cy: last[1], r: 4 }));
      svg.append(s('text', {
        class: 'chart-end-label', x: last[0] - 8, y: Math.max(MARGIN.top + 10, last[1] - 10), 'text-anchor': 'end',
      }, fmtNum(data[n - 1].count)));
    }

    const cross = s('line', { class: 'chart-crosshair', y1: MARGIN.top, y2: baseY, visibility: 'hidden' });
    const hoverDot = s('circle', { class: 'chart-dot', r: 4, visibility: 'hidden' });
    svg.append(cross, hoverDot);
    const overlay = s('rect', { class: 'chart-hit', x: MARGIN.left, y: MARGIN.top, width: plotW, height: plotH });
    const move = (evt) => {
      const rect = svg.getBoundingClientRect();
      const px = ((evt.clientX - rect.left) / rect.width) * width;
      const i = Math.max(0, Math.min(n - 1, Math.round(((px - MARGIN.left) / plotW) * (n - 1))));
      const [cx, cy] = points[i];
      cross.setAttribute('x1', cx);
      cross.setAttribute('x2', cx);
      cross.setAttribute('visibility', 'visible');
      hoverDot.setAttribute('cx', cx);
      hoverDot.setAttribute('cy', cy);
      hoverDot.setAttribute('visibility', 'visible');
      tip.show(cx, cy - 10, fmtDay(data[i].day, { weekday: 'short', month: 'short', day: 'numeric' }), `${fmtNum(data[i].count)} ${unit}`);
    };
    overlay.addEventListener('mousemove', move);
    overlay.addEventListener('mouseenter', move);
    overlay.addEventListener('mouseleave', () => {
      cross.setAttribute('visibility', 'hidden');
      hoverDot.setAttribute('visibility', 'hidden');
      tip.hide();
    });
    svg.append(overlay);

    wrap.querySelector('svg')?.remove();
    wrap.prepend(svg);
  });
  return root;
}

/**
 * Tall segmented bar: one whole split into parts ([{key, label, value, slot}]),
 * each part a block with its share printed inside when it fits, plus a
 * legend (names in block order, with counts) and a table view.
 */
export function segmentedBar(parts, { unit, emptyText }) {
  const total = parts.reduce((a, p) => a + p.value, 0);
  if (!total) return h('p', { class: 'muted' }, emptyText);
  const shown = parts.filter((p) => p.value > 0);
  const wrap = h('div', { class: 'chart chart-seg' });
  const bar = h('div', { class: 'segbar', role: 'img', 'aria-label': shown.map((p) => `${p.label}: ${fmtNum(p.value)} ${unit} (${fmtPct(p.value, total)})`).join(', ') });
  const tip = makeTooltip(wrap);
  for (const p of shown) {
    const label = h('span', { class: 'seg-label' }, fmtPct(p.value, total));
    const block = h('div', { class: `seg seg-${p.slot}`, style: { flexGrow: String(p.value) } }, label);
    block.addEventListener('mouseenter', () => {
      const left = block.offsetLeft + block.offsetWidth / 2;
      tip.show(left, -6, p.label, `${fmtNum(p.value)} ${unit} · ${fmtPct(p.value, total)}`);
    });
    block.addEventListener('mouseleave', () => tip.hide());
    bar.append(block);
  }
  wrap.prepend(bar);

  // Hide a share label that doesn't fit its block (never clip it).
  const fit = () => {
    for (const block of bar.children) {
      const label = block.firstElementChild;
      label.hidden = false;
      // The label carries 8px padding each side.
      if (label.offsetWidth > block.clientWidth) label.hidden = true;
    }
  };
  requestAnimationFrame(fit);
  if ('ResizeObserver' in window) new ResizeObserver(() => requestAnimationFrame(fit)).observe(bar);

  const legend = h('ul', { class: 'legend' }, shown.map((p) =>
    h('li', null, h('span', { class: `swatch seg-${p.slot}`, 'aria-hidden': 'true' }),
      h('span', { class: 'legend-name' }, p.label),
      h('span', { class: 'legend-value' }, `${fmtNum(p.value)} · ${fmtPct(p.value, total)}`))));

  const table = h('details', { class: 'table-view' },
    h('summary', null, 'Show as table'),
    h('table', { class: 'table table-compact' },
      h('thead', null, h('tr', null, h('th', null, 'Channel'), h('th', { class: 'num' }, 'Subscribers'), h('th', { class: 'num' }, 'Share'))),
      h('tbody', null, parts.map((p) => h('tr', null, h('td', null, p.label), h('td', { class: 'num' }, fmtNum(p.value)), h('td', { class: 'num' }, fmtPct(p.value, total)))))));

  return h('div', null, wrap, legend, table);
}
