"""Estilo do PDF (mesmo visual da Lista 2, gerada com ReportLab)."""
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.lib.fonts import addMapping
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# Fontes TrueType com cobertura Unicode (≤, ≥, ≠, −, Δ); as Type1 padrão usam WinAnsi e não têm esses glifos
_FONTES = '/System/Library/Fonts/Supplemental/'
for nome, arq in [('Arial', 'Arial.ttf'), ('Arial-Bold', 'Arial Bold.ttf'), ('Arial-Italic', 'Arial Italic.ttf'),
                  ('Arial-BoldItalic', 'Arial Bold Italic.ttf'), ('CourierNew', 'Courier New.ttf')]:
    pdfmetrics.registerFont(TTFont(nome, _FONTES + arq))
addMapping('Arial', 0, 0, 'Arial')
addMapping('Arial', 1, 0, 'Arial-Bold')
addMapping('Arial', 0, 1, 'Arial-Italic')
addMapping('Arial', 1, 1, 'Arial-BoldItalic')
addMapping('Arial-Bold', 1, 0, 'Arial-Bold')
from reportlab.platypus import (Image, KeepTogether, Paragraph, Preformatted, SimpleDocTemplate, Spacer, Table,
                                TableStyle)

AZUL = colors.HexColor('#1F3A68')
AZUL_MEDIO = colors.HexColor('#2E5597')
AZUL_CLARO = colors.HexColor('#EEF3FA')
BORDA = colors.HexColor('#A9BCD9')
VERMELHO = colors.HexColor('#9B1C1C')
FUNDO_VERMELHO = colors.HexColor('#FCEFEF')
CINZA = colors.HexColor('#666666')

RODAPE = 'Lista 3 — Inteligência Artificial — Pedro Henrique Lopes de Melo'
LARGURA = A4[0] - 4 * cm

S = {
    'titulo': ParagraphStyle('titulo', fontName='Arial-Bold', fontSize=22, leading=28, alignment=TA_CENTER, spaceAfter=10),
    'subtitulo': ParagraphStyle('subtitulo', fontName='Arial', fontSize=12, leading=17, alignment=TA_CENTER),
    'h1': ParagraphStyle('h1', fontName='Arial-Bold', fontSize=16, leading=21, textColor=AZUL, spaceBefore=12, spaceAfter=6),
    'h2': ParagraphStyle('h2', fontName='Arial-Bold', fontSize=12.5, leading=17, textColor=AZUL_MEDIO, spaceBefore=10, spaceAfter=4),
    'corpo': ParagraphStyle('corpo', fontName='Arial', fontSize=9.8, leading=14.2, alignment=TA_JUSTIFY, spaceAfter=6),
    'bullet': ParagraphStyle('bullet', fontName='Arial', fontSize=9.8, leading=14.2, alignment=TA_JUSTIFY,
                             leftIndent=14, bulletIndent=4, spaceAfter=3),
    'legenda': ParagraphStyle('legenda', fontName='Arial', fontSize=8, leading=11, textColor=CINZA, alignment=TA_CENTER, spaceAfter=8),
    'celula': ParagraphStyle('celula', fontName='Arial', fontSize=7.6, leading=9.4),
    'celula_cab': ParagraphStyle('celula_cab', fontName='Arial-Bold', fontSize=7.6, leading=9.4, textColor=colors.white),
    'alerta': ParagraphStyle('alerta', fontName='Arial', fontSize=9.8, leading=14.2, textColor=VERMELHO, alignment=TA_JUSTIFY),
    'codigo': ParagraphStyle('codigo', fontName='CourierNew', fontSize=7.4, leading=9.2, leftIndent=18),
}


def p(texto, estilo='corpo'):
    return Paragraph(texto, S[estilo])


def bullets(itens):
    return [Paragraph(t, S['bullet'], bulletText='•') for t in itens]


def tabela(cabecalho, linhas, larguras=None, fonte=None):
    est_c = S['celula'] if fonte is None else ParagraphStyle('c', parent=S['celula'], fontSize=fonte, leading=fonte * 1.24)
    est_h = S['celula_cab'] if fonte is None else ParagraphStyle('h', parent=S['celula_cab'], fontSize=fonte, leading=fonte * 1.24)
    dados = [[Paragraph(str(c), est_h) for c in cabecalho]]
    dados += [[Paragraph(str(c), est_c) for c in linha] for linha in linhas]
    if larguras is not None:
        total = sum(larguras)
        larguras = [LARGURA * w / total for w in larguras]
    t = Table(dados, colWidths=larguras, repeatRows=1)
    estilo = [('BACKGROUND', (0, 0), (-1, 0), AZUL_MEDIO),
              ('GRID', (0, 0), (-1, -1), 0.4, BORDA),
              ('VALIGN', (0, 0), (-1, -1), 'TOP'),
              ('TOPPADDING', (0, 0), (-1, -1), 2.5), ('BOTTOMPADDING', (0, 0), (-1, -1), 2.5),
              ('LEFTPADDING', (0, 0), (-1, -1), 3.5), ('RIGHTPADDING', (0, 0), (-1, -1), 3.5)]
    for i in range(2, len(dados), 2):
        estilo.append(('BACKGROUND', (0, i), (-1, i), AZUL_CLARO))
    t.setStyle(TableStyle(estilo))
    return t


def caixa(texto):
    t = Table([[Paragraph(texto, S['alerta'])]], colWidths=[LARGURA])
    t.setStyle(TableStyle([('BOX', (0, 0), (-1, -1), 0.8, VERMELHO), ('BACKGROUND', (0, 0), (-1, -1), FUNDO_VERMELHO),
                           ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                           ('LEFTPADDING', (0, 0), (-1, -1), 8), ('RIGHTPADDING', (0, 0), (-1, -1), 8)]))
    return t


def figura(caminho, legenda, largura=LARGURA):
    from reportlab.lib.utils import ImageReader
    w, h = ImageReader(caminho).getSize()
    img = Image(caminho, width=largura, height=largura * h / w)
    return KeepTogether([img, Spacer(1, 3), p(legenda, 'legenda')])


def codigo(texto):
    return Preformatted(texto, S['codigo'])


def _cabecalho_rodape(canvas, doc):
    canvas.saveState()
    canvas.setFont('Arial', 8)
    canvas.setFillColor(CINZA)
    canvas.drawString(2 * cm, A4[1] - 1.2 * cm, RODAPE)
    canvas.drawRightString(A4[0] - 2 * cm, A4[1] - 1.2 * cm, str(doc.page))
    canvas.drawString(2 * cm, 1.2 * cm, RODAPE)
    canvas.drawRightString(A4[0] - 2 * cm, 1.2 * cm, str(doc.page))
    canvas.restoreState()


def gerar(caminho, historia):
    doc = SimpleDocTemplate(caminho, pagesize=A4, leftMargin=2 * cm, rightMargin=2 * cm, topMargin=2 * cm,
                            bottomMargin=2 * cm, title='Lista 3 — Inteligência Artificial',
                            author='Pedro Henrique Lopes de Melo')
    doc.build(historia, onFirstPage=_cabecalho_rodape, onLaterPages=_cabecalho_rodape)
