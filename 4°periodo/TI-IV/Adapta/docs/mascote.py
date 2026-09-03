import subprocess, pathlib

BASE = pathlib.Path('/Users/pedrinho/Adapta/assets')

DEFS = '''
<defs>
  <linearGradient id="corpo" gradientUnits="userSpaceOnUse" x1="260" y1="820" x2="780" y2="300">
    <stop offset="0" stop-color="#0D9488"/>
    <stop offset="0.55" stop-color="#14B8A6"/>
    <stop offset="1" stop-color="#A3E635"/>
  </linearGradient>
  <linearGradient id="crista" gradientUnits="userSpaceOnUse" x1="530" y1="330" x2="700" y2="240">
    <stop offset="0" stop-color="#22C55E"/>
    <stop offset="1" stop-color="#BEF264"/>
  </linearGradient>
  <linearGradient id="fundo" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#4F46E5"/>
    <stop offset="1" stop-color="#7C3AED"/>
  </linearGradient>
  <clipPath id="clipCorpo">
    <circle cx="620" cy="470" r="170"/>
    <ellipse cx="520" cy="620" rx="260" ry="190"/>
  </clipPath>
</defs>
'''

OLHO = {
 'normal': '''
  <circle cx="680" cy="450" r="72" fill="#0F766E"/>
  <circle cx="680" cy="450" r="54" fill="#FFFFFF"/>
  <circle cx="692" cy="452" r="27" fill="#1E293B"/>
  <circle cx="702" cy="440" r="10" fill="#FFFFFF"/>
  <path d="M 690 545 Q 745 592 805 548" fill="none" stroke="#0F766E" stroke-width="16" stroke-linecap="round"/>
 ''',
 'feliz': '''
  <circle cx="680" cy="450" r="72" fill="#0F766E"/>
  <circle cx="680" cy="450" r="54" fill="#FFFFFF"/>
  <path d="M 648 458 Q 680 420 712 458" fill="none" stroke="#1E293B" stroke-width="16" stroke-linecap="round"/>
  <path d="M 680 540 Q 745 610 810 540 Q 745 580 680 540 Z" fill="#0F766E"/>
 ''',
 'pensativo': '''
  <circle cx="680" cy="450" r="72" fill="#0F766E"/>
  <circle cx="680" cy="450" r="54" fill="#FFFFFF"/>
  <circle cx="672" cy="430" r="27" fill="#1E293B"/>
  <circle cx="682" cy="420" r="10" fill="#FFFFFF"/>
  <path d="M 700 552 L 790 548" fill="none" stroke="#0F766E" stroke-width="16" stroke-linecap="round"/>
  <text x="820" y="330" font-family="Arial, Helvetica, sans-serif" font-weight="700" font-size="150" fill="#FBBF24">?</text>
 ''',
}

def mascote(pose='normal', com_galho=True):
    galho = '<rect x="180" y="826" width="700" height="46" rx="23" fill="#B45309"/><rect x="180" y="826" width="700" height="18" rx="9" fill="#D97706" opacity="0.6"/>' if com_galho else ''
    return f'''
  <g id="mascote" transform="translate(52 -8)">
    <!-- cauda -->
    <path d="M 330 700 C 240 770, 130 720, 145 620 C 158 535, 275 528, 296 610 C 312 668, 240 700, 222 652"
          fill="none" stroke="#0D9488" stroke-width="66" stroke-linecap="round"/>
    <path d="M 330 700 C 240 770, 130 720, 145 620 C 158 535, 275 528, 296 610 C 312 668, 240 700, 222 652"
          fill="none" stroke="#2DD4BF" stroke-width="22" stroke-linecap="round" opacity="0.45" stroke-dasharray="520 900"/>
    {galho}
    <!-- patas -->
    <rect x="420" y="770" width="96" height="66" rx="33" fill="#0D9488"/>
    <rect x="590" y="770" width="96" height="66" rx="33" fill="#0D9488"/>
    <!-- crista -->
    <path d="M 522 340 Q 600 190 705 330 Z" fill="url(#crista)"/>
    <!-- corpo + cabeça -->
    <ellipse cx="520" cy="620" rx="260" ry="190" fill="url(#corpo)"/>
    <circle cx="620" cy="470" r="170" fill="url(#corpo)"/>
    <!-- barriga e pintas -->
    <g clip-path="url(#clipCorpo)">
      <ellipse cx="500" cy="690" rx="190" ry="120" fill="#ECFCCB" opacity="0.85"/>
      <circle cx="400" cy="560" r="30" fill="#D9F99D" opacity="0.55"/>
      <circle cx="560" cy="360" r="20" fill="#D9F99D" opacity="0.55"/>
      <circle cx="330" cy="640" r="18" fill="#D9F99D" opacity="0.55"/>
    </g>
    <!-- bochecha -->
    <circle cx="748" cy="520" r="24" fill="#FDA4AF" opacity="0.75"/>
    <!-- olho e boca -->
    {OLHO[pose]}
  </g>'''

def svg(conteudo, fundo=None, escala=1.0):
    fundo_svg = f'<rect width="1024" height="1024" rx="{fundo}" fill="url(#fundo)"/>' if fundo is not None else ''
    t = (1 - escala) * 512
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
{DEFS}
{fundo_svg}
<g transform="translate({t:.1f} {t:.1f}) scale({escala})">
{conteudo}
</g>
</svg>'''

def salvar(nome, conteudo, largura=1024):
    p = BASE / nome
    p.with_suffix('.svg').write_text(conteudo)
    subprocess.run(['rsvg-convert', '-w', str(largura), '-h', str(largura), '-o', str(p), str(p.with_suffix('.svg'))], check=True)
    p.with_suffix('.svg').unlink()

# in-app (transparente)
for pose in ('normal', 'feliz', 'pensativo'):
    salvar(f'mascote/camu_{pose}.png', svg(mascote(pose), escala=0.98), 768)

# ícone legado / iOS: fundo cheio + mascote
salvar('icone/icone.png', svg(mascote('normal', com_galho=False), fundo=0, escala=0.86))
# adaptive icon: foreground transparente, mascote em 62% (safe zone)
salvar('icone/icone_foreground.png', svg(mascote('normal', com_galho=False), escala=0.62))
print('ok')
