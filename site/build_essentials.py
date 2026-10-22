"""Build essentials.html (the short deck) from index.html (the full deck).

Reuses the full deck's <head> (styles), icon sprite, controls, and script, and lifts a few
diagrams by slide id. Run after editing index.html: python3 build_essentials.py
"""
import re, sys, os

SITE = os.path.dirname(os.path.abspath(__file__))

full = open(os.path.join(SITE, 'index.html')).read()

def section(n):
    m = re.search(r'<section class="slide" id="s%d" tabindex="-1">.*?</section>' % n, full, flags=re.S)
    return m.group(0)


def figure(n, k=0):
    figs = re.findall(r'  <figure class="diagram">.*?</figure>\n', section(n), flags=re.S)
    return figs[k]


def full_link(n, text):
    return f'  <p class="see"><a href="index.html#s{n}">{text}</a></p>\n'


# ---- pieces lifted from the full deck ----------------------------------------------------
tiles_s1 = re.search(r'  <div class="tiles">.*?</div>\n  </div>\n', section(1), flags=re.S).group(0)
fig_button = figure(3)
fig_tests = figure(4)
fig_roles = figure(6).replace('<figcaption>The goal is to help these three roles understand each other.</figcaption>',
                              '<figcaption>No one grades their own work. The human verifies the result, not the test results.</figcaption>')
fig_bridge = figure(13)
fig_tool = figure(15)
howto = figure(16)
fig_ramp = (figure(30)
            .replace('purple button (28)', 'purple button')
            .replace('discount codes (29): each trigger fires in turn', 'discount codes: each trigger fires in turn')
            .replace(' The purple button of slide 28 sits at the light path; the discount codes of slide 29 span the KB to full discovery.',
                     ' The purple button sits at the light path; the discount codes span the KB to full discovery.'))
install = re.search(r'  <details class="more"><summary>Install on Fedora</summary>.*?</div></details>\n', section(16), flags=re.S).group(0)
report = re.search(r'<pre class="report" aria-label="A sample delivery">.*?</pre>', section(27), flags=re.S).group(0)

# The timeline, simplified: no machine lane, no labels on the Lean dots, one gap box.
timeline = '''  <figure class="diagram">
    <svg viewBox="0 0 760 210" role="img" aria-label="Lanes from January to October 2026. Process: Claude Code from January, the orbital plugins from April, the method by hand from June, the AIDLC from late August, Orbital Shifting from 21 October. Lean: in use from April on, never dropped. Hoggwood Health: client work kept shipping the whole time.">
      <text x="130" y="16" class="band">2026</text>
      <g class="sub" text-anchor="middle">
        <text x="160.5" y="36" class="sub">Jan</text><text x="221.5" y="36" class="sub">Feb</text><text x="282.5" y="36" class="sub">Mar</text><text x="343.5" y="36" class="sub">Apr</text><text x="404.5" y="36" class="sub">May</text>
        <text x="465.5" y="36" class="sub">Jun</text><text x="526.5" y="36" class="sub">Jul</text><text x="587.5" y="36" class="sub">Aug</text><text x="648.5" y="36" class="sub">Sep</text><text x="709.5" y="36" class="sub">Oct</text>
      </g>
      <path class="arr" style="stroke-width:1;opacity:.5" d="M191 42V50M252 42V50M313 42V50M374 42V50M435 42V50M496 42V50M557 42V50M618 42V50M679 42V50"/>
      <text x="10" y="76" class="b">Process</text><text x="10" y="91" class="sub">changed</text>
      <rect class="box" x="152" y="52" width="161" height="44" rx="8"/><text x="232" y="79" text-anchor="middle" class="lbl">Claude Code</text>
      <rect class="box hum" x="315" y="52" width="143" height="44" rx="8"/><text x="386" y="72" text-anchor="middle" class="b">Orbital</text><text x="386" y="88" text-anchor="middle" class="b">plugins</text>
      <rect class="box gap" x="460" y="52" width="149" height="44" rx="8"/><text x="534" y="72" text-anchor="middle" class="b">By hand</text><text x="534" y="88" text-anchor="middle" class="sub">long prompts</text>
      <rect class="box mid" x="611" y="52" width="106" height="44" rx="8"/><text x="664" y="79" text-anchor="middle" class="b">AIDLC</text>
      <rect class="box chk" x="719" y="52" width="24" height="44" rx="6"/>
      <path d="M731 96V108" stroke="var(--good)" stroke-width="2"/><text x="743" y="118" text-anchor="end" class="lbl b" style="fill:var(--good)">Orbital Shifting, live 21 Oct</text>
      <text x="10" y="146" class="b">Lean</text><text x="10" y="161" class="sub">never dropped</text>
      <path d="M315 146H743" stroke="var(--amber)" stroke-width="3" stroke-linecap="round"/>
      <g class="tam"><circle cx="315" cy="146" r="4"/><circle cx="339" cy="146" r="5"/><circle cx="465" cy="146" r="5"/><circle cx="514" cy="146" r="4"/><circle cx="610" cy="146" r="4"/><circle cx="634" cy="146" r="5"/><circle cx="714" cy="146" r="5"/></g>
      <text x="10" y="186" class="b">Delivery</text><text x="10" y="201" class="sub">constant</text>
      <rect x="152" y="174" width="591" height="22" rx="11" style="fill:var(--accent);opacity:.22"/>
      <text x="447" y="190" text-anchor="middle" class="b">Hoggwood Health: client work kept shipping</text>
    </svg>
    <figcaption>The philosophy held the whole way, so the quality of the client work held. What changed was how much of the method a tool ran.</figcaption>
  </figure>
'''

# ---- the slides ---------------------------------------------------------------------------
N = 10
def head(n, icon, part):
    return f'  <div class="num"><svg class="ic"><use href="#{icon}"/></svg>{n} of {N} · {part}</div>\n'

slides = []
slides.append(head(1, 'i-target', 'The problem') + '''  <h1>The wrong-spec problem</h1>
  <p class="big">An agent can build <em>exactly</em> what it was told, and still build the wrong thing.</p>
  <p>An <strong>agent</strong> is an AI that does the work, such as <a href="https://claude.com/claude-code">Claude Code</a>. A <strong>spec</strong> is what it builds from: the request, the ticket, and the tests.</p>
''' + tiles_s1 + '''  <p>The human is the source of intent. <mark>The human is not always the source of clarity.</mark></p>
''' + full_link(1, 'Full deck: the wrong-spec problem'))

slides.append(head(2, 'i-eye', 'The problem') + '''  <h2>"Make the button purple"</h2>
''' + fig_button + '''  <p>The fix costs one line, if it comes early. The agent says its claim back with one example, and the human answers: <q>No, only that button.</q></p>
''' + full_link(3, 'Full deck: the example'))

slides.append(head(3, 'i-orbit', 'The idea') + '''  <h2>Alignment</h2>
  <p class="big">The human, the agent, and the formal records <em>agree</em> on what to build and on when it is done.</p>
''' + fig_roles + '''  <ul class="chips" aria-label="The four goals">
    <li class="chip"><svg class="ic"><use href="#i-lens"/></svg>Clear</li>
    <li class="chip"><svg class="ic"><use href="#i-target"/></svg>Accurate</li>
    <li class="chip"><svg class="ic"><use href="#i-speech"/></svg>Honest</li>
    <li class="chip"><svg class="ic"><use href="#i-bolt"/></svg>Fast</li>
  </ul>
''' + full_link(5, 'Full deck: the philosophy, the roles, and loud versus quiet'))

slides.append(head(4, 'i-forall', 'The idea') + '''  <h2>Tests and proofs</h2>
  <p>The real claim behind "add discount codes": <mark>no discount code takes a price below the floor</mark>, for every code and every cart.</p>
''' + fig_tests + '''  <p class="big">A test written from a wrong spec <em>passes</em>.</p>
  <p>So ask early whether the spec matches what the human means. When a claim must hold for every case, prove it in <a href="https://lean-lang.org">Lean</a>.</p>
''' + full_link(4, 'Full deck: tests and proofs'))

slides.append(head(5, 'i-cal', 'The story') + '''  <h2>The idea held; the machinery changed</h2>
  <p>Ty reached this process in 2026 through three eras. <mark>The process kept changing. The delivery did not.</mark></p>
''' + timeline + full_link(8, 'Full deck: the timeline, the five chapters, and the eras'))

slides.append(head(6, 'i-split', 'The story') + '''  <h2>Why signals, not tiers</h2>
  <p>The AIDLC, the era before, sorted work into tiers by difficulty. <mark>The middle tiers drifted to the ends</mark>, and what is hard for a model changes with every model. One thing does not change:</p>
''' + fig_bridge + '''  <blockquote><p>"I'm making the bet that even with ASI, humans will still need to explain what they want."</p></blockquote>
''' + full_link(12, 'Full deck: why the tiers had to go'))

slides.append(head(7, 'i-box', 'The tool') + '''  <h2>What it is</h2>
''' + fig_tool + '''  <dl class="gloss">
    <div><dt><svg class="ic"><use href="#i-feather"/></svg>The prompt</dt><dd>One plain-text file, appended to the agent's system prompt. It says how to work: start light, shift up on a signal.</dd></div>
    <div><dt><svg class="ic"><use href="#i-term"/></svg>orbit-kb</dt><dd>A command-line tool that keeps the knowledge base (KB): every fact declared, typed, and checked.</dd></div>
    <div><dt><svg class="ic"><use href="#i-db"/></svg>Prolog</dt><dd><a href="https://www.swi-prolog.org">SWI-Prolog</a> 9 or later with <a href="https://github.com/SWI-Prolog/sCASP">s(CASP)</a>: answers the KB's questions.</dd></div>
    <div><dt><svg class="ic"><use href="#i-lean"/></svg>Lean 4</dt><dd>Only for proofs. Install with <a href="https://github.com/leanprover/elan">elan</a>. Optional helpers: <a href="https://github.com/theTyster/sharlean">sharlean</a> (shared libraries such as <a href="https://github.com/leanprover-community/mathlib4">Mathlib</a>) and <a href="https://github.com/oOo0oOo/lean-lsp-mcp">lean-lsp-mcp</a>.</dd></div>
  </dl>
''' + full_link(15, 'Full deck: what it is, and why Lean and Prolog'))

slides.append(head(8, 'i-term', 'The tool') + '''  <h2>How to use it</h2>
''' + howto + '''  <p>You rarely type <code>orbit-kb</code> yourself. Most requests stay on the light path: <mark>one check, no KB</mark>.</p>
''' + install + full_link(16, 'Full deck: how to use it, with the commands the agent runs'))

slides.append(head(9, 'i-layers', 'In practice') + '''  <h2>The gradient</h2>
  <p class="big">No tier is picked up front. Each <em>signal</em> adds one rung, and each rung comes off when its cause is resolved.</p>
''' + fig_ramp + '''  <blockquote><p>"This pattern offers, when it really needs it, a level of rigor that can guarantee correctness."</p></blockquote>
  <p class="muted">A proof holds for every case of the Lean model. The checks tie the model to the code.</p>
  <p class="see"><a href="index.html#s28">The lightest path, step by step</a> · <a href="index.html#s29">The most rigorous path</a></p>
''')

slides.append(head(10, 'i-check', 'In practice') + '''  <h2>What you get back</h2>
  <p>Six fields, in short plain sentences. An empty field says "none", so you see that the agent looked.</p>
''' + report + '''
  <h3>Go deeper</h3>
  <ul class="chips" aria-label="Sections of the full deck">
    <li class="chip"><svg class="ic"><use href="#i-feather"/></svg><a href="index.html#s20">The light path</a></li>
    <li class="chip"><svg class="ic"><use href="#i-layers"/></svg><a href="index.html#s21">Shifting up</a></li>
    <li class="chip"><svg class="ic"><use href="#i-compass"/></svg><a href="index.html#s23">Discovery</a></li>
    <li class="chip"><svg class="ic"><use href="#i-scale"/></svg><a href="index.html#s24">The vote</a></li>
    <li class="chip"><svg class="ic"><use href="#i-flame"/></svg><a href="index.html#s25">Burns</a></li>
    <li class="chip"><svg class="ic"><use href="#i-shield"/></svg><a href="index.html#s26">Trust and honesty</a></li>
  </ul>
''')

labels = ["Problem", "Example", "Alignment", "Tests and proofs", "Timeline", "Why", "What it is", "How to use", "The gradient", "What you get"]
assert len(slides) == N == len(labels)

body = '\n\n'.join(f'<section class="slide" id="s{i}" tabindex="-1">\n{s}</section>' for i, s in enumerate(slides, 1))
nav = '\n'.join(f'      <li><a href="#s{i}"><span>{i}</span><span class="t"> {t}</span></a></li>' for i, t in enumerate(labels, 1))

# ---- assemble -----------------------------------------------------------------------------
pre = full[:full.index('<header class="top">')]
pre = pre.replace('<title>Orbital Shifting</title>', '<title>Orbital Shifting Essentials</title>', 1)
header = f'''<header class="top">
  <strong>Orbital Shifting: the essentials</strong>
  <a class="alt" href="index.html">Full deck</a>
  <nav aria-label="Slide index">
    <ol>
{nav}
    </ol>
  </nav>
</header>

<main>

{body}

<p class="hint nojs" style="padding-inline:1.1rem;text-align:center">Without JavaScript, scroll.</p>
</main>
'''
tail = full[full.index('<div class="controls" id="controls">'):]
tail = tail[:tail.index('<!--\nFact-check note.')] + '''<!--
Essentials: a ten-slide short version of index.html, built by a script from its diagrams.
Slides 2, 3, 4, 6, 7, and 9 reuse the full deck's diagrams (full slides 3, 6, 4, 13, 15, 30). The
timeline on slide 5 is the full slide 8 without the machine lane and the Lean dot labels. Slide 8's
diagram is shared with full slide 16. The fact-check note in index.html covers every claim here.
-->
</body>
</html>
'''
open(os.path.join(SITE, 'essentials.html'), 'w').write(pre + header + tail)
print('ok', len(pre + header + tail))
