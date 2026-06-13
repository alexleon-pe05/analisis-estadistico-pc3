import matplotlib
matplotlib.use('Agg')
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from statsmodels.formula.api import ols
from statsmodels.stats.anova import anova_lm
from scipy.stats import f as f_dist, studentized_range
import os, warnings
warnings.filterwarnings('ignore')

# ============================================================
# PROBLEMA #3 - Cuadrado Latino 5x5 con Dato Perdido
# DefendNet Alliance — Tasa de Deteccion de Amenazas (%)
# ============================================================
TITULO      = "PROBLEMA #3 - Cuadrado Latino 5x5 con Dato Perdido - DefendNet Alliance"
NOMBRE_FIL  = "Vector"
NOMBRE_COL  = "Analista"
NOMBRE_TRAT = "Protocolo"
RESPUESTA   = "Tasa de Deteccion de Amenazas (%)"

p = 5

filas_idx = ["Phishing","Ransomware","DDoS","Zeroday","Supply_ch"]
cols_idx  = ["A1","A2","A3","A4","A5"]

# Cuadrado Latino 5x5 ciclico
# A=EDR+TI  B=SOAR  C=XDR  D=IA_triage  E=ZeroTrust
cuadrado = [
    ["A","B","C","D","E"],   # V1 Phishing
    ["B","C","D","E","A"],   # V2 Ransomware (D=PERDIDO en A3)
    ["C","D","E","A","B"],   # V3 DDoS
    ["D","E","A","B","C"],   # V4 Zero-day
    ["E","A","B","C","D"],   # V5 Supply-chain
]

y_mat = [
    [88.47, 85.09, 92.44, 82.82, 96.33],
    [86.32, 93.75, None,  96.65, 88.04],   # None = dato perdido (V2/A3/Protocolo D)
    [91.82, 82.35, 96.15, 86.84, 85.26],
    [83.87, 95.64, 88.62, 87.08, 93.18],
    [95.72, 87.84, 86.54, 92.37, 82.23],
]

# ----------------------------------------------------------
N_orig = p * p; alpha = 0.05

fila_col, col_col, trat_col, y_col = [], [], [], []
for i in range(p):
    for j in range(p):
        fila_col.append(filas_idx[i])
        col_col.append(cols_idx[j])
        trat_col.append(cuadrado[i][j])
        y_col.append(np.nan if y_mat[i][j] is None else float(y_mat[i][j]))

df_full = pd.DataFrame({
    NOMBRE_FIL:  pd.Categorical(fila_col,  categories=filas_idx),
    NOMBRE_COL:  pd.Categorical(col_col,   categories=cols_idx),
    NOMBRE_TRAT: pd.Categorical(trat_col,  categories=sorted(set(trat_col))),
    'Y': y_col
})

idx_na = df_full['Y'].isna()
row_na = df_full[idx_na].iloc[0]
fila_p = row_na[NOMBRE_FIL]; col_p = row_na[NOMBRE_COL]; trat_p = row_na[NOMBRE_TRAT]
print(f"Dato perdido: {NOMBRE_FIL}={fila_p} | {NOMBRE_COL}={col_p} | {NOMBRE_TRAT}={trat_p}")

# FORMULA DE YATES: Y' = (p*(R + C_col + T_t) - 2*G) / ((p-1)*(p-2))
df_sin = df_full.dropna(subset=['Y'])
G     = df_sin['Y'].sum()
R     = df_sin[df_sin[NOMBRE_FIL]  == fila_p]['Y'].sum()
C_col = df_sin[df_sin[NOMBRE_COL]  == col_p]['Y'].sum()
T_t   = df_sin[df_sin[NOMBRE_TRAT] == trat_p]['Y'].sum()
Y_prima = (p*(R + C_col + T_t) - 2*G) / ((p-1)*(p-2))
print(f"G={G:.4f}  R={R:.4f}  C_col={C_col:.4f}  T_t={T_t:.4f}")
print(f"Y' = ({p}*({R:.4f}+{C_col:.4f}+{T_t:.4f}) - 2*{G:.4f}) / ({p-1}*{p-2}) = {Y_prima:.6f}")

df_full.loc[idx_na, 'Y'] = Y_prima
df = df_full.copy()

# ANOVA  gl_Error = (p-1)*(p-2) - 1 = 11 (ajustado por dato estimado)
formula = f"Y ~ C({NOMBRE_FIL}) + C({NOMBRE_COL}) + C({NOMBRE_TRAT})"
modelo  = ols(formula, data=df).fit()
tabla_anova = anova_lm(modelo, typ=2)

key_F = f"C({NOMBRE_FIL})"; key_C = f"C({NOMBRE_COL})"; key_T = f"C({NOMBRE_TRAT})"
sc_F = tabla_anova.loc[key_F, 'sum_sq']
sc_C = tabla_anova.loc[key_C, 'sum_sq']
sc_T = tabla_anova.loc[key_T, 'sum_sq']
sc_E = tabla_anova.loc['Residual', 'sum_sq']
sc_Tot = sc_F + sc_C + sc_T + sc_E

gl_F = p-1; gl_C = p-1; gl_T = p-1
gl_E = (p-1)*(p-2) - 1    # = 11
cm_E = sc_E / gl_E

ft = f_dist.ppf(1-alpha, gl_F, gl_E)
Fc_F = (sc_F/gl_F) / cm_E
Fc_C = (sc_C/gl_C) / cm_E
Fc_T = (sc_T/gl_T) / cm_E

print("\n" + "="*70)
print(f"TABLA ANOVA AJUSTADA  gl_Error={gl_E}  Y'={Y_prima:.4f}")
print("="*70)
print(f"  {NOMBRE_FIL:<14} GL={gl_F} SC={sc_F:.4f} CM={sc_F/gl_F:.4f} Fc={Fc_F:.4f} Ft={ft:.4f}  {'SIGNIFICATIVO ***' if Fc_F>ft else 'no sig'}")
print(f"  {NOMBRE_COL:<14} GL={gl_C} SC={sc_C:.4f} CM={sc_C/gl_C:.4f} Fc={Fc_C:.4f} Ft={ft:.4f}  {'SIGNIFICATIVO ***' if Fc_C>ft else 'no sig'}")
print(f"  {NOMBRE_TRAT:<14} GL={gl_T} SC={sc_T:.4f} CM={sc_T/gl_T:.4f} Fc={Fc_T:.4f} Ft={ft:.4f}  {'SIGNIFICATIVO ***' if Fc_T>ft else 'no sig'}")
print(f"  {'Error':<14} GL={gl_E} SC={sc_E:.4f} CM={cm_E:.4f}")
print(f"  {'Total':<14} GL={N_orig-2} SC={sc_Tot:.4f}")

# --- Tukey manual (gl_E ajustado = 11) ---
q_val    = studentized_range.ppf(0.95, p, gl_E)
T_alpha  = q_val * np.sqrt(cm_E / p)

def _tukey_manual(df_in, factor, nombre):
    medias = df_in.groupby(factor, observed=True)['Y'].mean().sort_values(ascending=False)
    print(f"\n{'='*70}\nTUKEY MANUAL - {nombre}")
    print(f"  CM_E={cm_E:.4f}  gl_E={gl_E}  n_nivel=p={p}")
    print(f"  q(0.05,{p},{gl_E})={q_val:.4f}   T_alpha={T_alpha:.4f}")
    print("="*70)
    nivs = medias.index.tolist()
    for i in range(len(nivs)):
        for j in range(i+1, len(nivs)):
            ni, nj = nivs[i], nivs[j]
            dif = abs(medias[ni] - medias[nj])
            sig = "SIGNIFICATIVO *" if dif > T_alpha else "no significativo"
            print(f"  {ni} vs {nj}: |{medias[ni]:.4f}-{medias[nj]:.4f}| = {dif:.4f} {'>' if dif>T_alpha else '<'} {T_alpha:.4f} -> {sig}")
    return medias

if Fc_F > ft:
    medias_F = _tukey_manual(df, NOMBRE_FIL, NOMBRE_FIL)
else:
    medias_F = df.groupby(NOMBRE_FIL, observed=True)['Y'].mean()

medias_C = df.groupby(NOMBRE_COL, observed=True)['Y'].mean()

if Fc_T > ft:
    medias_T = _tukey_manual(df, NOMBRE_TRAT, NOMBRE_TRAT)
else:
    medias_T = df.groupby(NOMBRE_TRAT, observed=True)['Y'].mean()

# --- Helper Tukey plot ---
def _tukey_plot(ax, medias, T_alpha, titulo):
    niv = medias.sort_values().index.tolist()
    pares = []
    for i in range(len(niv)):
        for j in range(i+1, len(niv)):
            ni, nj = niv[i], niv[j]
            diff = float(medias[nj] - medias[ni])
            pares.append((f"{nj}-{ni}", diff, diff - T_alpha, diff + T_alpha))
    for idx, (lbl, diff, lo, hi) in enumerate(pares):
        sig = (lo > 0) or (hi < 0)
        col = 'red' if sig else 'steelblue'
        ax.plot([lo, hi], [idx, idx], color=col, linewidth=2)
        ax.plot(diff, idx, 'o', color=col, markersize=5)
    ax.set_yticks(range(len(pares)))
    ax.set_yticklabels([p[0] for p in pares], fontsize=8)
    ax.axvline(0, color='black', linewidth=0.8, linestyle='--')
    ax.set_title(titulo, fontweight='bold', fontsize=10)
    ax.set_xlabel('Diferencia de medias (IC 95%)')
    ax.grid(alpha=0.3, axis='x')

# ============================================================
# FIGURA 1: Barras + Tukey
# ============================================================
mg = df['Y'].mean()
fig = plt.figure(figsize=(18, 14))
fig.suptitle(TITULO + f"\n(Y' estimado = {Y_prima:.4f})", fontsize=14, fontweight='bold')
gs = gridspec.GridSpec(2, 3, figure=fig, hspace=0.50, wspace=0.35,
                       top=0.85, bottom=0.07, left=0.06, right=0.97)

ax1 = fig.add_subplot(gs[0, 0])
med_F = df.groupby(NOMBRE_FIL, observed=True)['Y'].mean()
ax1.bar(med_F.index, med_F.values, color='#7fb3d3', edgecolor='black')
ax1.axhline(mg, color='red', linestyle='--', linewidth=1.5, label='Media global')
ax1.set_title(f'Medias por {NOMBRE_FIL}', fontweight='bold')
ax1.set_xlabel(NOMBRE_FIL); ax1.set_ylabel(RESPUESTA)
ax1.tick_params(axis='x', rotation=25)
ax1.legend(fontsize=8); ax1.grid(axis='y', alpha=0.3)

ax2 = fig.add_subplot(gs[0, 1])
med_C_bar = df.groupby(NOMBRE_COL, observed=True)['Y'].mean()
ax2.bar(med_C_bar.index, med_C_bar.values, color='#f0a070', edgecolor='black')
ax2.axhline(mg, color='red', linestyle='--', linewidth=1.5, label='Media global')
ax2.set_title(f'Medias por {NOMBRE_COL}', fontweight='bold')
ax2.set_xlabel(NOMBRE_COL); ax2.set_ylabel(RESPUESTA)
ax2.legend(fontsize=8); ax2.grid(axis='y', alpha=0.3)

ax3 = fig.add_subplot(gs[0, 2])
med_T_bar = df.groupby(NOMBRE_TRAT, observed=True)['Y'].mean()
ax3.bar(med_T_bar.index, med_T_bar.values, color='#82c982', edgecolor='black')
ax3.axhline(mg, color='red', linestyle='--', linewidth=1.5, label='Media global')
ax3.set_title(f"Medias por {NOMBRE_TRAT}\n(con Y'={Y_prima:.3f})", fontweight='bold')
ax3.set_xlabel(NOMBRE_TRAT); ax3.set_ylabel(RESPUESTA)
ax3.legend(fontsize=8); ax3.grid(axis='y', alpha=0.3)

ax4 = fig.add_subplot(gs[1, 0:2])
_tukey_plot(ax4, medias_F, T_alpha,
            f'Prueba de Tukey - {NOMBRE_FIL} (IC 95% manual, gl_E={gl_E})')

ax5 = fig.add_subplot(gs[1, 2])
_tukey_plot(ax5, medias_T, T_alpha,
            f'Prueba de Tukey - {NOMBRE_TRAT} (IC 95% manual, gl_E={gl_E})')

BASE = os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else r'C:\Users\ASUS\Desktop\CONTROL PC3'
SELLO_PY = "Generado en Python  |  matplotlib  |  statsmodels (ANOVA) + scipy (Tukey)"
fig.text(0.5, 0.012, SELLO_PY, ha='center', va='bottom', fontsize=13,
         style='italic', fontweight='bold', color='#1a5276',
         bbox=dict(boxstyle='round,pad=0.4', facecolor='#eaf2f8', edgecolor='#1a5276', linewidth=1.2))
ruta1 = os.path.join(BASE, 'python_1.png')
plt.savefig(ruta1, dpi=150, bbox_inches='tight'); plt.close()
print(f"\nGrafica guardada: {ruta1}")

# ============================================================
# FIGURA 2: Tabla ANOVA
# ============================================================
dec_F = 'Significativo ***' if Fc_F > ft else 'No significativo'
dec_C = 'Significativo ***' if Fc_C > ft else 'No significativo'
dec_T = 'Significativo ***' if Fc_T > ft else 'No significativo'

encab = ['Fuente de Variacion', 'GL', 'SC', 'CM', 'Fc', 'Ft (a=5%)', 'Conclusion']
filas_t = [
    [NOMBRE_FIL,             str(gl_F), f'{sc_F:.4f}', f'{sc_F/gl_F:.4f}', f'{Fc_F:.4f}', f'{ft:.4f}', dec_F],
    [NOMBRE_COL,             str(gl_C), f'{sc_C:.4f}', f'{sc_C/gl_C:.4f}', f'{Fc_C:.4f}', f'{ft:.4f}', dec_C],
    [NOMBRE_TRAT,            str(gl_T), f'{sc_T:.4f}', f'{sc_T/gl_T:.4f}', f'{Fc_T:.4f}', f'{ft:.4f}', dec_T],
    [f'Error (gl={gl_E})*', str(gl_E), f'{sc_E:.4f}', f'{cm_E:.4f}',       '-',           '-',          '-' ],
    ['Total',                str(N_orig-2), f'{sc_Tot:.4f}', '-',           '-',           '-',          '-' ],
]
todas = [encab] + filas_t
nota  = f"* gl_Error ajustado = (p-1)(p-2)-1 = {gl_E}  (p=5 con dato perdido estimado Y'={Y_prima:.4f})"

fig2, ax_t = plt.subplots(figsize=(14, 4.5))
ax_t.set_xlim(0,1); ax_t.set_ylim(0,1); ax_t.axis('off')
fig2.suptitle(f'Tabla ANOVA - Cuadrado Latino 5x5 con Dato Perdido\n{TITULO}',
              fontsize=13, fontweight='bold', y=0.99)

col_x = [0.00, 0.26, 0.34, 0.46, 0.56, 0.66, 0.78, 1.00]
n_fil = len(todas); row_h = 0.75/n_fil; y_start = 0.88
sig_map = [Fc_F > ft, Fc_C > ft, Fc_T > ft]

for i, fila in enumerate(todas):
    y_top = y_start - i*row_h; y_bot = y_top - row_h; y_mid = (y_top+y_bot)/2
    if   i == 0:      bg, fg, fw = '#2c3e50','white','bold'
    elif 1 <= i <= 3: bg, fg, fw = ('#d5f5e3' if sig_map[i-1] else '#ebebeb'),'black','normal'
    elif i == 4:      bg, fg, fw = '#fdf2da','black','normal'
    else:             bg, fg, fw = '#eaecee','black','normal'
    for j, texto in enumerate(fila):
        x0, x1 = col_x[j], col_x[j+1]
        rect = plt.Rectangle((x0,y_bot), x1-x0, row_h, facecolor=bg,
                              edgecolor='#555555', linewidth=0.8,
                              transform=ax_t.transAxes, clip_on=True)
        ax_t.add_patch(rect)
        ax_t.text((x0+x1)/2, y_mid, texto, ha='center', va='center', fontsize=10,
                  color=fg, fontweight=fw, transform=ax_t.transAxes, clip_on=True)

ax_t.text(0.01, 0.04, nota, ha='left', va='bottom', fontsize=9,
          color='#c0392b', style='italic', transform=ax_t.transAxes)

fig2.text(0.5, 0.005, SELLO_PY, ha='center', va='bottom', fontsize=12,
          style='italic', fontweight='bold', color='#1a5276',
          bbox=dict(boxstyle='round,pad=0.4', facecolor='#eaf2f8', edgecolor='#1a5276', linewidth=1.2))
ruta2 = os.path.join(BASE, 'python_2.png')
plt.savefig(ruta2, dpi=150, bbox_inches='tight'); plt.close()
print(f"Tabla ANOVA guardada: {ruta2}")
