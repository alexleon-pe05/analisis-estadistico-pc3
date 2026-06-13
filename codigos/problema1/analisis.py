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
# PROBLEMA #1 - Factorial 4x3 - QuantEdge Capital
# ============================================================

TITULO      = "PROBLEMA #1 - Factorial: Estrategia x Regimen Volatilidad"
NOMBRE_A    = "Estrategia"
NOMBRE_B    = "Regimen"
RESPUESTA   = "Sharpe Ratio mensual"
PREFIJO_OUT = "P1"

NIVELES_A = ["Mkt.Making", "Arb.Triang", "Momentum", "Mean Rev."]
NIVELES_B = ["Baja", "Media", "Alta"]
n = 3

# Datos: para cada nivel de A, ingresar valores en orden B1*n, B2*n, B3*n
datos = [
    # A = Market Making: Baja(3), Media(3), Alta(3)
    0.77, 0.80, 0.83,   1.17, 1.20, 1.23,   1.72, 1.75, 1.78,
    # A = Arbitraje Triangular
    1.32, 1.35, 1.38,   1.82, 1.85, 1.88,   2.52, 2.55, 2.58,
    # A = Momentum
    1.07, 1.10, 1.13,   1.52, 1.55, 1.58,   2.12, 2.15, 2.18,
    # A = Mean Reversion
    1.62, 1.65, 1.68,   2.17, 2.20, 2.23,   2.97, 3.00, 3.03,
]

a = len(NIVELES_A); b = len(NIVELES_B); N = a * b * n
alpha = 0.05

col_A = [niv for niv in NIVELES_A for _ in range(b * n)]
col_B = [niv for _ in range(a) for niv in NIVELES_B for _ in range(n)]
df = pd.DataFrame({NOMBRE_A: col_A, NOMBRE_B: col_B, 'Y': datos})
df[NOMBRE_A] = pd.Categorical(df[NOMBRE_A], categories=NIVELES_A)
df[NOMBRE_B] = pd.Categorical(df[NOMBRE_B], categories=NIVELES_B)

# ============================================================
# ANOVA FACTORIAL (Tipo II)
# ============================================================
formula = f"Y ~ C({NOMBRE_A}) + C({NOMBRE_B}) + C({NOMBRE_A}):C({NOMBRE_B})"
modelo  = ols(formula, data=df).fit()
tabla_anova = anova_lm(modelo, typ=2)

print("=" * 65)
print(f"TABLA ANOVA - {TITULO}")
print("=" * 65)
print(tabla_anova.round(4))

gl_A  = a - 1; gl_B = b - 1; gl_AB = gl_A * gl_B; gl_E = a * b * (n - 1)
ft_A  = f_dist.ppf(1-alpha, gl_A,  gl_E)
ft_B  = f_dist.ppf(1-alpha, gl_B,  gl_E)
ft_AB = f_dist.ppf(1-alpha, gl_AB, gl_E)

key_A  = f"C({NOMBRE_A})"
key_B  = f"C({NOMBRE_B})"
key_AB = f"C({NOMBRE_A}):C({NOMBRE_B})"
Fc_A   = tabla_anova.loc[key_A,  'F']
Fc_B   = tabla_anova.loc[key_B,  'F']
Fc_AB  = tabla_anova.loc[key_AB, 'F']

print(f"\nFt {NOMBRE_A}  ({gl_A},{gl_E})  = {ft_A:.4f} | Fc={Fc_A:.4f} -> {'SIGNIFICATIVO' if Fc_A>ft_A else 'no sig.'}")
print(f"Ft {NOMBRE_B}  ({gl_B},{gl_E})  = {ft_B:.4f} | Fc={Fc_B:.4f} -> {'SIGNIFICATIVO' if Fc_B>ft_B else 'no sig.'}")
print(f"Ft AxB ({gl_AB},{gl_E}) = {ft_AB:.4f} | Fc={Fc_AB:.4f} -> {'SIGNIFICATIVO' if Fc_AB>ft_AB else 'no sig.'}")

# ============================================================
# TUKEY MANUAL
# ============================================================
sc_E_v  = tabla_anova.loc['Residual', 'sum_sq']
cm_E_v  = sc_E_v / gl_E
n_A     = b * n
n_B     = a * n

q_A       = studentized_range.ppf(0.95, a, gl_E)
q_B       = studentized_range.ppf(0.95, b, gl_E)
T_alpha_A = q_A * np.sqrt(cm_E_v / n_A)
T_alpha_B = q_B * np.sqrt(cm_E_v / n_B)

medias_A = df.groupby(NOMBRE_A, observed=True)['Y'].mean()
medias_B = df.groupby(NOMBRE_B, observed=True)['Y'].mean()

if Fc_A > ft_A:
    print("\n" + "=" * 65)
    print(f"TUKEY MANUAL - {NOMBRE_A}")
    print(f"  CM_E={cm_E_v:.4f}  gl_E={gl_E}  n_A={n_A}")
    print(f"  q(0.05,{a},{gl_E})={q_A:.4f}   T_alpha={T_alpha_A:.4f}")
    print("=" * 65)
    nivs_A = medias_A.sort_values(ascending=False).index.tolist()
    for i in range(len(nivs_A)):
        for j in range(i+1, len(nivs_A)):
            ni, nj = nivs_A[i], nivs_A[j]
            dif = abs(medias_A[ni] - medias_A[nj])
            sig = "SIGNIFICATIVO *" if dif > T_alpha_A else "no significativo"
            print(f"  {ni} vs {nj}: |{medias_A[ni]:.4f}-{medias_A[nj]:.4f}| = {dif:.4f} {'>' if dif>T_alpha_A else '<'} {T_alpha_A:.4f} -> {sig}")

if Fc_B > ft_B:
    print("\n" + "=" * 65)
    print(f"TUKEY MANUAL - {NOMBRE_B}")
    print(f"  CM_E={cm_E_v:.4f}  gl_E={gl_E}  n_B={n_B}")
    print(f"  q(0.05,{b},{gl_E})={q_B:.4f}   T_alpha={T_alpha_B:.4f}")
    print("=" * 65)
    nivs_B = medias_B.sort_values(ascending=False).index.tolist()
    for i in range(len(nivs_B)):
        for j in range(i+1, len(nivs_B)):
            ni, nj = nivs_B[i], nivs_B[j]
            dif = abs(medias_B[ni] - medias_B[nj])
            sig = "SIGNIFICATIVO *" if dif > T_alpha_B else "no significativo"
            print(f"  {ni} vs {nj}: |{medias_B[ni]:.4f}-{medias_B[nj]:.4f}| = {dif:.4f} {'>' if dif>T_alpha_B else '<'} {T_alpha_B:.4f} -> {sig}")

# ============================================================
# Helper: grafica de intervalos Tukey
# ============================================================
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
# FIGURA 1: Efectos principales, interaccion y Tukey
# ============================================================
COLORES = ['#1f77b4','#ff7f0e','#2ca02c','#d62728','#9467bd','#8c564b']
media_g = df['Y'].mean()

fig = plt.figure(figsize=(18, 13))
fig.suptitle(TITULO + f"\n(Variable respuesta: {RESPUESTA})", fontsize=14, fontweight='bold')
gs = gridspec.GridSpec(2, 3, figure=fig, hspace=0.45, wspace=0.35,
                       top=0.83, bottom=0.07, left=0.07, right=0.97)

ax1 = fig.add_subplot(gs[0, 0])
mA = df.groupby(NOMBRE_A, observed=True)['Y'].mean()[NIVELES_A]
ax1.bar(NIVELES_A, mA.values, color='steelblue', edgecolor='black')
ax1.axhline(media_g, color='red', linestyle='--', linewidth=1.5, label='Media global')
ax1.set_title(f'Efecto Principal\n{NOMBRE_A}', fontweight='bold')
ax1.set_xlabel(NOMBRE_A); ax1.set_ylabel(f'Media {RESPUESTA}')
ax1.tick_params(axis='x', rotation=20)
ax1.legend(fontsize=8); ax1.grid(axis='y', alpha=0.3)

ax2 = fig.add_subplot(gs[0, 1])
mB = df.groupby(NOMBRE_B, observed=True)['Y'].mean()[NIVELES_B]
ax2.bar(NIVELES_B, mB.values, color='coral', edgecolor='black')
ax2.axhline(media_g, color='red', linestyle='--', linewidth=1.5, label='Media global')
ax2.set_title(f'Efecto Principal\n{NOMBRE_B}', fontweight='bold')
ax2.set_xlabel(NOMBRE_B); ax2.set_ylabel(f'Media {RESPUESTA}')
ax2.legend(fontsize=8); ax2.grid(axis='y', alpha=0.3)

ax3 = fig.add_subplot(gs[0, 2])
for i, nivel_b in enumerate(NIVELES_B):
    meds = df[df[NOMBRE_B] == nivel_b].groupby(NOMBRE_A, observed=True)['Y'].mean()[NIVELES_A]
    ax3.plot(NIVELES_A, meds.values, marker='o', linewidth=2,
             color=COLORES[i % len(COLORES)], label=f'{nivel_b}')
ax3.set_title(f'Grafica de Interaccion\n{NOMBRE_A} x {NOMBRE_B}', fontweight='bold')
ax3.set_xlabel(NOMBRE_A); ax3.set_ylabel(f'Media {RESPUESTA}')
ax3.tick_params(axis='x', rotation=20)
ax3.legend(fontsize=8, title=NOMBRE_B); ax3.grid(alpha=0.3)

ax4 = fig.add_subplot(gs[1, 0:2])
_tukey_plot(ax4, medias_A, T_alpha_A, f'Prueba de Tukey - {NOMBRE_A} (IC 95% manual correcto)')

ax5 = fig.add_subplot(gs[1, 2])
_tukey_plot(ax5, medias_B, T_alpha_B, f'Prueba de Tukey - {NOMBRE_B} (IC 95% manual correcto)')

BASE = os.path.dirname(os.path.abspath(__file__)) if '__file__' in dir() else r'C:\Users\ASUS\Desktop\CONTROL PC3'
SELLO_PY = "Generado en Python  |  matplotlib  |  statsmodels (ANOVA) + scipy (Tukey)"
fig.text(0.5, 0.012, SELLO_PY, ha='center', va='bottom', fontsize=13,
         style='italic', fontweight='bold', color='#1a5276',
         bbox=dict(boxstyle='round,pad=0.4', facecolor='#eaf2f8', edgecolor='#1a5276', linewidth=1.2))
ruta1 = os.path.join(BASE, 'python_1.png')
plt.savefig(ruta1, dpi=150, bbox_inches='tight'); plt.close()
print(f"\nGrafica guardada: {ruta1}")

# ============================================================
# FIGURA 2: Tabla ANOVA (imagen separada)
# ============================================================
sc_A  = tabla_anova.loc[key_A,  'sum_sq']
sc_B  = tabla_anova.loc[key_B,  'sum_sq']
sc_AB = tabla_anova.loc[key_AB, 'sum_sq']
sc_E  = sc_E_v
sc_T  = sc_A + sc_B + sc_AB + sc_E

dec_A  = 'Significativo ***' if Fc_A  > ft_A  else 'No significativo'
dec_B  = 'Significativo ***' if Fc_B  > ft_B  else 'No significativo'
dec_AB = 'Significativo ***' if Fc_AB > ft_AB else 'No significativo'

encab = ['Fuente de Variacion', 'GL', 'SC', 'CM', 'Fc', 'Ft (a=5%)', 'Conclusion']
filas = [
    [f'{NOMBRE_A} (Estrategia)', str(gl_A),  f'{sc_A:.4f}',  f'{sc_A/gl_A:.4f}',   f'{Fc_A:.4f}',  f'{ft_A:.4f}',  dec_A ],
    [f'{NOMBRE_B} (Regimen)',    str(gl_B),  f'{sc_B:.4f}',  f'{sc_B/gl_B:.4f}',   f'{Fc_B:.4f}',  f'{ft_B:.4f}',  dec_B ],
    ['Interaccion AxB',          str(gl_AB), f'{sc_AB:.4f}', f'{sc_AB/gl_AB:.4f}', f'{Fc_AB:.4f}', f'{ft_AB:.4f}', dec_AB],
    ['Error (Residual)',          str(gl_E),  f'{sc_E:.4f}',  f'{sc_E/gl_E:.4f}',   '-',            '-',            '-'   ],
    ['Total',                    str(N-1),   f'{sc_T:.4f}',  '-',                  '-',            '-',            '-'   ],
]
todas = [encab] + filas

fig2, ax_t = plt.subplots(figsize=(16, 4))
ax_t.set_xlim(0, 1); ax_t.set_ylim(0, 1); ax_t.axis('off')
fig2.suptitle(f'Tabla ANOVA - Diseño Factorial 4x3\n{TITULO}',
              fontsize=13, fontweight='bold', y=0.98)

col_x = [0.00, 0.30, 0.36, 0.48, 0.58, 0.68, 0.80, 1.00]
n_fil = len(todas); row_h = 0.82 / n_fil; y_start = 0.88
sig_map = [Fc_A > ft_A, Fc_B > ft_B, Fc_AB > ft_AB]

for i, fila in enumerate(todas):
    y_top = y_start - i * row_h; y_bot = y_top - row_h; y_mid = (y_top + y_bot) / 2
    if   i == 0:        bg, fg, fw = '#2c3e50', 'white', 'bold'
    elif 1 <= i <= 3:   bg, fg, fw = ('#d5f5e3' if sig_map[i-1] else '#ebebeb'), 'black', 'normal'
    elif i == 4:        bg, fg, fw = '#fdfefe', 'black', 'normal'
    else:               bg, fg, fw = '#eaecee', 'black', 'normal'
    for j, texto in enumerate(fila):
        x0, x1 = col_x[j], col_x[j+1]
        rect = plt.Rectangle((x0,y_bot), x1-x0, row_h, facecolor=bg,
                              edgecolor='#555555', linewidth=0.8,
                              transform=ax_t.transAxes, clip_on=True)
        ax_t.add_patch(rect)
        ax_t.text((x0+x1)/2, y_mid, texto, ha='center', va='center', fontsize=10,
                  color=fg, fontweight=fw, transform=ax_t.transAxes, clip_on=True)

fig2.text(0.5, 0.01, SELLO_PY, ha='center', va='bottom', fontsize=12,
          style='italic', fontweight='bold', color='#1a5276',
          bbox=dict(boxstyle='round,pad=0.4', facecolor='#eaf2f8', edgecolor='#1a5276', linewidth=1.2))
ruta2 = os.path.join(BASE, 'python_2.png')
plt.savefig(ruta2, dpi=150, bbox_inches='tight'); plt.close()
print(f"Tabla ANOVA guardada: {ruta2}")
