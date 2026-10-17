/* lab.js - what the menu (index.html) and the exercise page (page.html) share.
 *
 * There is no build step. exercises.json lists the tiers and their exercises,
 * each written exercise is a directory under exercises/, and a page fetches
 * the files it shows when it loads. The text on a page is the text in the
 * repository, and the solution behind the button is the solution.asm that
 * "./check --solutions" tests.
 *
 * fetch() does not work on a file:// page, so the pages have to be served:
 * lab/README.md says how.
 */
'use strict';

// highlight.js comes inside the decks' vendored reveal.js plugin, which
// hands it out without needing reveal itself. The decks' corrections to its
// x86 grammar apply here too.
const hljs = RevealHighlight().hljs;
fixX86Grammar(hljs);

// A failed fetch is marked as one, because it usually means the page was
// opened as a file instead of served, and the error page can then say so.
async function fetchText(path) {
    let response;
    try {
        response = await fetch(path);
    } catch {
        response = { ok: false, status: 'no', statusText: 'response' };
    }
    if (!response.ok) {
        const error = new Error(`Could not load ${path}: ${response.status} ${response.statusText}.`);
        error.notServed = true;
        throw error;
    }
    return response.text();
}

async function loadLab() {
    return JSON.parse(await fetchText('exercises.json'));
}

// The exercises ticked done, kept in this browser only. Storage can be
// switched off or cleared, so every access is allowed to fail: the tick is
// then simply not remembered.
const progress = {
    key: id => `x86-lab:done:${id}`,

    isDone(id) {
        try {
            return localStorage.getItem(this.key(id)) === 'yes';
        } catch {
            return false;
        }
    },

    setDone(id, done) {
        try {
            if (done) {
                localStorage.setItem(this.key(id), 'yes');
            } else {
                localStorage.removeItem(this.key(id));
            }
        } catch {
            // not remembered; nothing else is lost
        }
    },
};

// Make an element. Children are elements or strings, and a string is always
// text, never markup.
function el(tag, attrs = {}, ...children) {
    const node = document.createElement(tag);
    for (const [name, value] of Object.entries(attrs)) {
        node.setAttribute(name, value);
    }
    node.append(...children);
    return node;
}

// Difficulty as three dots, the first n of them lit.
function dots(n) {
    const span = el('span', { class: 'dots', title: `Difficulty ${n} of 3` });
    for (let i = 1; i <= 3; i++) {
        span.append(el('span', i <= n ? {} : { class: 'off' }, '●'));
    }
    return span;
}

// An exercise is written once it has a directory. Until then the menu shows
// it greyed out, as a plan.
const isWritten = exercise => Boolean(exercise.dir);

// The list of a tier's exercises, used by the menu and by a tier's notes.
function exerciseList(tier) {
    const list = el('ol');
    for (const exercise of tier.exercises) {
        const tick = progress.isDone(exercise.id) ? '✓' : '';
        const name = isWritten(exercise)
            ? el('a', { href: `page.html?ex=${exercise.id}`, class: 'name' }, exercise.title)
            : el('span', { class: 'name', title: 'Not written yet' }, exercise.title);
        list.append(el('li', isWritten(exercise) ? {} : { class: 'planned' },
            el('span', { class: 'tick' }, tick),
            el('span', { class: 'id' }, exercise.id.toUpperCase()),
            name,
            dots(exercise.difficulty)));
    }
    return list;
}

// Markdown to an <article>. A relative link in the Markdown is relative to
// the file it was written in, so it is resolved against that file's
// directory rather than against the page.
function renderMarkdown(text, base) {
    const article = el('article');
    article.innerHTML = marked.parse(text);
    for (const link of article.querySelectorAll('a[href]')) {
        const href = link.getAttribute('href');
        if (!/^([a-z]+:|#|\/)/i.test(href)) {
            link.setAttribute('href', base + href);
        }
    }
    decorateCode(article);
    return article;
}

// Colour every code block, and give each shell command a copy button.
function decorateCode(scope) {
    for (const code of scope.querySelectorAll('pre code')) {
        const language = (code.className.match(/language-(\S+)/) || [])[1];
        if (language === 'sh') {
            addCopyButton(code);
        }
        if (language && hljs.getLanguage(language)) {
            hljs.highlightElement(code);
        }
    }
}

function addCopyButton(code) {
    const pre = code.parentElement;
    const button = el('button', { class: 'copy', type: 'button' }, 'Copy');
    button.addEventListener('click', async () => {
        await copyText(code.textContent.trim());
        button.textContent = 'Copied';
        setTimeout(() => { button.textContent = 'Copy'; }, 1500);
    });
    pre.classList.add('command');
    pre.append(button);
}

// The clipboard API needs https or localhost, which Codespaces and a local
// server both are. Anywhere else, fall back to the older way.
async function copyText(text) {
    try {
        await navigator.clipboard.writeText(text);
    } catch {
        const area = el('textarea');
        area.value = text;
        document.body.append(area);
        area.select();
        document.execCommand('copy');
        area.remove();
    }
}

function showError(root, error) {
    const box = el('div', { class: 'error' }, el('p', {}, error.message));
    if (error.notServed) {
        box.append(el('p', {}, 'If this page was opened as a file, serve it instead: see lab/README.md.'));
    }
    root.replaceChildren(box, el('p', {}, el('a', { href: 'index.html' }, '← All tiers')));
}


/* The menu ---------------------------------------------------------------- */

async function showMenu(root) {
    try {
        const lab = await loadLab();
        const tiers = el('div', { class: 'tiers' });
        for (const tier of lab.tiers) {
            const card = el('section', { class: 'tier' },
                el('h2', {}, el('span', { class: 'letter' }, tier.id), tier.title),
                el('p', { class: 'blurb' }, tier.blurb));
            if (tier.intro) {
                card.append(el('p', { class: 'read-first' },
                    el('a', { href: `page.html?tier=${tier.id}` }, 'Read this first →')));
            }
            card.append(exerciseList(tier));
            tiers.append(card);
        }
        root.replaceChildren(tiers);
    } catch (error) {
        showError(root, error);
    }
}


/* One exercise, or one tier's notes --------------------------------------- */

async function showPage(root) {
    try {
        const lab = await loadLab();
        const params = new URLSearchParams(location.search);
        if (params.has('tier')) {
            await showTierNotes(root, lab, params.get('tier'));
        } else {
            await showExercise(root, lab, params.get('ex'));
        }
    } catch (error) {
        showError(root, error);
    }
}

// The line above the title: the way back, and where this page sits.
function crumbs(tier, ...more) {
    return el('nav', { class: 'crumbs' },
        el('a', { href: 'index.html' }, '← All tiers'),
        el('span', {}, `Tier ${tier.id} · ${tier.title}`),
        ...more);
}

async function showExercise(root, lab, id) {
    let tier, exercise;
    for (const t of lab.tiers) {
        const found = t.exercises.find(e => e.id === id);
        if (found) {
            tier = t;
            exercise = found;
        }
    }
    if (!exercise) {
        throw new Error(`There is no exercise "${id}".`);
    }
    if (!isWritten(exercise)) {
        throw new Error(`${exercise.id.toUpperCase()} ${exercise.title} is not written yet.`);
    }

    const base = `exercises/${exercise.dir}/`;
    const readme = await fetchText(base + 'README.md');
    document.title = `${exercise.id.toUpperCase()} · ${exercise.title} · x86-64 lab`;

    const notes = tier.intro
        ? [el('a', { href: `page.html?tier=${tier.id}` }, 'Tier notes')]
        : [];
    root.replaceChildren(
        crumbs(tier, ...notes, dots(exercise.difficulty)),
        renderMarkdown(readme, base),
        solution(base),
        finish(tier, exercise));
}

// The solution, behind a button. It is fetched the first time the button is
// pressed, so it is not even on the page until somebody asks for it.
function solution(base) {
    const code = el('code', { class: 'language-x86asm' });
    const pre = el('pre', {}, code);
    pre.hidden = true;
    const button = el('button', { class: 'reveal', type: 'button' }, 'Show solution');

    button.addEventListener('click', async () => {
        if (!code.dataset.loaded) {
            code.textContent = await fetchText(base + 'solution.asm');
            hljs.highlightElement(code);
            code.dataset.loaded = 'yes';
        }
        pre.hidden = !pre.hidden;
        button.textContent = pre.hidden ? 'Show solution' : 'Hide solution';
    });

    return el('section', { class: 'solution' },
        el('h2', {}, 'Solution'),
        el('p', {}, 'Stuck after the hints? Here is one way to write it, with a comment on every step.'),
        button,
        pre);
}

// The done tick, and the next written exercise in the same tier.
function finish(tier, exercise) {
    const box = el('input', { type: 'checkbox' });
    box.checked = progress.isDone(exercise.id);
    box.addEventListener('change', () => progress.setDone(exercise.id, box.checked));

    const written = tier.exercises.filter(isWritten);
    const next = written[written.indexOf(exercise) + 1];
    const onward = next
        ? el('a', { href: `page.html?ex=${next.id}` }, `Next: ${next.id.toUpperCase()} ${next.title} →`)
        : el('a', { href: 'index.html' }, 'Pick another tier →');

    return el('div', { class: 'finish' }, el('label', {}, box, 'Done with this one'), onward);
}

async function showTierNotes(root, lab, id) {
    const tier = lab.tiers.find(t => t.id === id);
    if (!tier || !tier.intro) {
        throw new Error(`Tier "${id}" has no notes.`);
    }
    const base = tier.intro.replace(/[^/]*$/, '');
    document.title = `Tier ${tier.id} · ${tier.title} · x86-64 lab`;
    root.replaceChildren(
        crumbs(tier),
        renderMarkdown(await fetchText(tier.intro), base),
        el('h2', {}, 'The exercises'),
        el('div', { class: 'tier' }, exerciseList(tier)));
}
