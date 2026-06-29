import re

with open('morse_keyboard.ahk', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add BuildTriplesTab function
triples_func = """
BuildTriplesTab() {
    return "
(
SÍLABAS TRIPLAS (C + Mod + V)

+ r [Sufixo A]: b,c,d,f,g,p,t,v
br: bra=QAQQA bre=QAQAA bri=QAQRA
cr: cra=QRQQA cre=QRQAA cri=QRQRA
dr: dra=QQQQQA dre=QQQQAA dri=QQQQRA
fr: fra=QQRQQA fre=QQRQAA fri=QQRQRA
gr: gra=QAQQQA gre=QAQQAA gri=QAQQRA
pr: pra=AQQQQA pre=AQQQAA pri=AQQQRA
tr: tra=AAAQQA tre=AAAAAA tri=AAAQRA
vr: vra=ARQQQA vre=ARQQAA vri=ARQQRA

+ l [Sufixo AQ]: b,c,f,g,p,t
bl: bla=QAQQAQ ble=QAQAAQ bli=QAQRAQ
cl: cla=QRQQAQ cle=QRQAAQ cli=QRQRAQ
fl: fla=QQRQQAQ fle=QQRQAAQ fli=QQRQRAQ
gl: gla=QAQQQAQ gle=QAQQAAQ gli=QAQQRAQ
pl: pla=AQQQQAQ ple=AQQQAAQ pli=AQQQRAQ
tl: tla=AAAQQAQ tle=AAAAAAQ tli=AAAQRAQ

+ h [Sufixo AR]: c,l,n
ch: cha=QRQQAR che=QRQAAR chi=QRQRAR
lh: lha=QRRQQAR lhe=QRRQAAR lhi=QRRQRAR
nh: nha=AAQQAR nhe=AAQAAR nhi=AAQRAR

q/g+u [Sufixo AA]: q,g
qu: qua=AQAQQAA que=AQAQAAA qui=AQAQRAA
gu: gua=QAQQQAA gue=QAQQAAA gui=QAQQRAA
)"
}
"""

# Insert it right after BuildSyllablesTab
text = re.sub(
    r'(BuildSyllablesTab\(\) \{.*?\n\)\"\n\})',
    r'\1\n' + triples_func,
    text,
    flags=re.DOTALL
)

# 2. Modify t3c1 and add t3c2
gui_old = """global t3c1 := osd.AddText("x265 y105 w630 h440 c0xaaaacc", BuildSyllablesTab())
t3c1.SetFont("s8.5", MONO_FONT)"""

gui_new = """global t3c1 := osd.AddText("x265 y105 w320 h440 c0xaaaacc", BuildSyllablesTab())
t3c1.SetFont("s8.5", MONO_FONT)
global t3c2 := osd.AddText("x585 y105 w310 h440 c0xaaaacc", BuildTriplesTab())
t3c2.SetFont("s8.5", MONO_FONT)"""

text = text.replace(gui_old, gui_new)

with open('morse_keyboard.ahk', 'w', encoding='utf-8-sig') as f:
    f.write(text)

print("Updated GUI OSD!")
