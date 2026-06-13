# ============================================================
# PROBLEMA #3 - Cuadrado Latino 5x5 con Dato Perdido
# DefendNet Alliance — Tasa de Deteccion de Amenazas (%)
# ============================================================
library(ggplot2); library(dplyr); library(gridExtra)

TITULO      <- "PROBLEMA #3 - Cuadrado Latino 5x5 con Dato Perdido - DefendNet Alliance"
NOMBRE_FIL  <- "Vector"
NOMBRE_COL  <- "Analista"
NOMBRE_TRAT <- "Protocolo"
RESPUESTA   <- "Tasa de Deteccion de Amenazas (%)"

p <- 5
filas_idx <- c("Phishing","Ransomware","DDoS","Zeroday","Supply_ch")
cols_idx  <- c("A1","A2","A3","A4","A5")

# Cuadrado Latino 5x5 ciclico (NA en V2/A3 = Protocolo D perdido)
cuadrado <- matrix(c(
  "A","B","C","D","E",
  "B","C","D","E","A",
  "C","D","E","A","B",
  "D","E","A","B","C",
  "E","A","B","C","D"
), nrow=p, byrow=TRUE)

y_mat <- matrix(c(
  88.47, 85.09, 92.44, 82.82, 96.33,
  86.32, 93.75, NA,    96.65, 88.04,   # NA = dato perdido
  91.82, 82.35, 96.15, 86.84, 85.26,
  83.87, 95.64, 88.62, 87.08, 93.18,
  95.72, 87.84, 86.54, 92.37, 82.23
), nrow=p, byrow=TRUE)

# Construir data frame
N_orig <- p * p
fila_v <- rep(filas_idx, each=p)
col_v  <- rep(cols_idx,  times=p)
trat_v <- as.vector(t(cuadrado))
y_v    <- as.vector(t(y_mat))

df_full <- data.frame(
  Fila    = factor(fila_v, levels=filas_idx),
  Columna = factor(col_v,  levels=cols_idx),
  Trat    = factor(trat_v),
  Y       = y_v
)
names(df_full)[1:3] <- c(NOMBRE_FIL, NOMBRE_COL, NOMBRE_TRAT)

# Dato perdido
idx_na <- which(is.na(df_full$Y))
cat("Dato perdido: fila", as.character(df_full[idx_na, NOMBRE_FIL]),
    "| col", as.character(df_full[idx_na, NOMBRE_COL]),
    "| trat", as.character(df_full[idx_na, NOMBRE_TRAT]), "\n")

# FORMULA DE YATES
df_sin <- df_full[!is.na(df_full$Y), ]
G      <- sum(df_sin$Y)
fila_p <- as.character(df_full[idx_na, NOMBRE_FIL])
col_p  <- as.character(df_full[idx_na, NOMBRE_COL])
trat_p <- as.character(df_full[idx_na, NOMBRE_TRAT])

R     <- sum(df_sin$Y[df_sin[[NOMBRE_FIL]] == fila_p])
C_col <- sum(df_sin$Y[df_sin[[NOMBRE_COL]] == col_p])
T_t   <- sum(df_sin$Y[df_sin[[NOMBRE_TRAT]] == trat_p])

Y_prima <- (p*(R + C_col + T_t) - 2*G) / ((p-1)*(p-2))
cat(sprintf("G=%.4f  R=%.4f  C_col=%.4f  T_t=%.4f\n", G, R, C_col, T_t))
cat(sprintf("Y' = (p*(R+C_col+T_t) - 2*G) / ((p-1)*(p-2)) = %.6f\n", Y_prima))

df_full$Y[idx_na] <- Y_prima
df <- df_full

# ANOVA (gl_Error = (p-1)*(p-2) - 1 = 11 ajustado)
formula_m <- as.formula(paste("Y ~", NOMBRE_FIL, "+", NOMBRE_COL, "+", NOMBRE_TRAT))
modelo    <- aov(formula_m, data=df)
resumen   <- summary(modelo)[[1]]

sc_F <- resumen[1,"Sum Sq"]; sc_C <- resumen[2,"Sum Sq"]
sc_T <- resumen[3,"Sum Sq"]; sc_E <- resumen[4,"Sum Sq"]
sc_Tot <- sc_F + sc_C + sc_T + sc_E

gl_F <- p-1; gl_C <- p-1; gl_T <- p-1
gl_E <- (p-1)*(p-2) - 1    # = 11
cm_E <- sc_E / gl_E

alpha  <- 0.05
ft     <- qf(1-alpha, gl_F, gl_E)
Fc_F   <- (sc_F/gl_F) / cm_E
Fc_C   <- (sc_C/gl_C) / cm_E
Fc_T   <- (sc_T/gl_T) / cm_E

cat(strrep("=",70), "\nTABLA ANOVA AJUSTADA -", TITULO, "\n")
cat(sprintf("(gl_Error ajustado = %d, Y' = %.4f)\n", gl_E, Y_prima))
cat(strrep("=",70), "\n")
cat(sprintf("%-14s GL=%d SC=%.4f CM=%.4f Fc=%.4f Ft=%.4f %s\n",
    NOMBRE_FIL, gl_F, sc_F, sc_F/gl_F, Fc_F, ft, ifelse(Fc_F>ft,"SIGNIFICATIVO","no sig.")))
cat(sprintf("%-14s GL=%d SC=%.4f CM=%.4f Fc=%.4f Ft=%.4f %s\n",
    NOMBRE_COL, gl_C, sc_C, sc_C/gl_C, Fc_C, ft, ifelse(Fc_C>ft,"SIGNIFICATIVO","no sig.")))
cat(sprintf("%-14s GL=%d SC=%.4f CM=%.4f Fc=%.4f Ft=%.4f %s\n",
    NOMBRE_TRAT,gl_T, sc_T, sc_T/gl_T, Fc_T, ft, ifelse(Fc_T>ft,"SIGNIFICATIVO","no sig.")))
cat(sprintf("%-14s GL=%d SC=%.4f CM=%.4f\n", "Error", gl_E, sc_E, cm_E))
cat(sprintf("%-14s GL=%d SC=%.4f\n", "Total", N_orig-2, sc_Tot))

# PRUEBA DE TUKEY MANUAL (gl_E ajustado = 11)
k       <- p
n_grupo <- p

tukey_manual <- function(factor_name) {
  cat(sprintf("\n--- Tukey Manual - %s ---\n", factor_name))
  q_crit  <- qtukey(0.95, k, gl_E)
  T_alpha <- q_crit * sqrt(cm_E / n_grupo)
  medias  <- sort(tapply(df$Y, df[[factor_name]], mean), decreasing=TRUE)
  cat(sprintf("q(0.05,%d,%d)=%.4f  T_alpha=%.4f\n", k, gl_E, q_crit, T_alpha))
  nivs <- names(medias)
  for (i in seq_along(nivs)) {
    for (j in seq_along(nivs)) {
      if (j > i) {
        ni <- nivs[i]; nj <- nivs[j]
        dif <- abs(medias[ni] - medias[nj])
        sig <- ifelse(dif > T_alpha, "SIGNIFICATIVO *", "no significativo")
        cat(sprintf("  %s vs %s: |%.4f - %.4f| = %.4f %s %.4f -> %s\n",
            ni, nj, medias[ni], medias[nj], dif,
            ifelse(dif > T_alpha, ">", "<"), T_alpha, sig))
      }
    }
  }
}

if (Fc_F > ft) tukey_manual(NOMBRE_FIL)
if (Fc_T > ft) tukey_manual(NOMBRE_TRAT)

# ============================================================
# GRAFICAS (ESTILO R: serif + viridis 5 colores + sello)
# ============================================================
theme_R <- theme_minimal(base_family = "serif", base_size = 12) +
  theme(plot.title       = element_text(face = "bold", color = "#4b0082"),
        panel.background = element_rect(fill = "#faf7fb", color = NA),
        panel.grid.minor = element_blank(),
        legend.position  = "bottom")
PALETA_R <- c("#440154","#3b528b","#21918c","#5ec962","#fde725")
ACCENT_R <- "#4b0082"
SELLO_R  <- "Generado en R 4.6  |  ggplot2  |  aov + Yates + Tukey manual (gl_E ajustado)"
mg <- mean(df$Y)

df_pF <- data.frame(Niv=factor(filas_idx, filas_idx), Med=tapply(df$Y, df[[NOMBRE_FIL]], mean)[filas_idx])
df_pC <- data.frame(Niv=factor(cols_idx,  cols_idx),  Med=tapply(df$Y, df[[NOMBRE_COL]], mean)[cols_idx])
df_pT <- data.frame(Niv=factor(sort(unique(trat_v)), sort(unique(trat_v))),
                    Med=tapply(df$Y, df[[NOMBRE_TRAT]], mean)[sort(unique(trat_v))])

p1 <- ggplot(df_pF,aes(x=Niv,y=Med)) +
  geom_bar(stat="identity",fill=PALETA_R[1],color="black") +
  geom_hline(yintercept=mg,color="red",linetype="dashed",linewidth=1.2) +
  labs(title=paste("Medias por",NOMBRE_FIL),x=NOMBRE_FIL,y=RESPUESTA) +
  theme_R + theme(plot.title=element_text(size=10), axis.text.x=element_text(angle=20,hjust=1))

p2 <- ggplot(df_pC,aes(x=Niv,y=Med)) +
  geom_bar(stat="identity",fill=PALETA_R[3],color="black") +
  geom_hline(yintercept=mg,color="red",linetype="dashed",linewidth=1.2) +
  labs(title=paste("Medias por",NOMBRE_COL),x=NOMBRE_COL,y=RESPUESTA) +
  theme_R + theme(plot.title=element_text(size=10))

p3 <- ggplot(df_pT,aes(x=Niv,y=Med)) +
  geom_bar(stat="identity",fill=PALETA_R[4],color="black") +
  geom_hline(yintercept=mg,color="red",linetype="dashed",linewidth=1.2) +
  labs(title=paste("Medias por",NOMBRE_TRAT,"(con Y')"),x=NOMBRE_TRAT,y=RESPUESTA) +
  theme_R + theme(plot.title=element_text(size=10))

# Helper Tukey comparaciones
make_tukey_comps <- function(factor_name) {
  T_a  <- qtukey(0.95, k, gl_E) * sqrt(cm_E / n_grupo)
  meds <- tapply(df$Y, df[[factor_name]], mean)
  nv   <- names(meds)
  out  <- data.frame(Comp=character(), diff=numeric(), lwr=numeric(), upr=numeric(), Sig=logical(), stringsAsFactors=FALSE)
  for (i in 1:(length(nv)-1)) for (j in (i+1):length(nv)) {
    d <- meds[nv[i]] - meds[nv[j]]
    out <- rbind(out, data.frame(Comp=paste0(nv[i],"-",nv[j]), diff=d, lwr=d-T_a, upr=d+T_a, Sig=abs(d)>T_a, stringsAsFactors=FALSE))
  }
  out
}

# p4 - Tukey Vector (Filas, significativo)
comps_F <- make_tukey_comps(NOMBRE_FIL)
p4 <- ggplot(comps_F,aes(y=reorder(Comp,diff),x=diff)) +
  geom_errorbarh(aes(xmin=lwr,xmax=upr,color=Sig),height=0.4,linewidth=1) +
  geom_point(aes(color=Sig),size=3) + geom_vline(xintercept=0,linetype="dashed") +
  scale_color_manual(values=c("TRUE"="#c2185b","FALSE"="#3b528b"),
                     labels=c("TRUE"="Sig.","FALSE"="No sig."),name="") +
  labs(title=paste("Tukey manual -",NOMBRE_FIL,"(gl_E =",gl_E,")"),x="Dif. medias",y="") +
  theme_R + theme(plot.title=element_text(size=10))

# p5 - Tukey Protocolo (Tratamiento, significativo)
comps_T <- make_tukey_comps(NOMBRE_TRAT)
p5 <- ggplot(comps_T,aes(y=reorder(Comp,diff),x=diff)) +
  geom_errorbarh(aes(xmin=lwr,xmax=upr,color=Sig),height=0.4,linewidth=1) +
  geom_point(aes(color=Sig),size=3) + geom_vline(xintercept=0,linetype="dashed") +
  scale_color_manual(values=c("TRUE"="#c2185b","FALSE"="#21918c"),
                     labels=c("TRUE"="Sig.","FALSE"="No sig."),name="") +
  labs(title=paste("Tukey manual -",NOMBRE_TRAT,"(gl_E =",gl_E,")"),x="Dif. medias",y="") +
  theme_R + theme(plot.title=element_text(size=10))

# Tabla ANOVA grob
tbl_df <- data.frame(
  "Fuente"   = c(NOMBRE_FIL, NOMBRE_COL, NOMBRE_TRAT, paste0("Error (gl=",gl_E,")"), "Total"),
  "GL"       = c(gl_F, gl_C, gl_T, gl_E, N_orig-2),
  "SC"       = round(c(sc_F,sc_C,sc_T,sc_E,sc_Tot),4),
  "CM"       = c(round(sc_F/gl_F,4),round(sc_C/gl_C,4),round(sc_T/gl_T,4),round(cm_E,4),"-"),
  "Fc"       = c(round(Fc_F,4),round(Fc_C,4),round(Fc_T,4),"-","-"),
  "Ft"       = c(round(ft,4),round(ft,4),round(ft,4),"-","-"),
  "Decision" = c(ifelse(Fc_F>ft,"Sig ***","No sig"),ifelse(Fc_C>ft,"Sig ***","No sig"),
                 ifelse(Fc_T>ft,"Sig ***","No sig"),"-","-"),
  check.names=FALSE, stringsAsFactors=FALSE)

anova_fills <- c(
  ifelse(Fc_F > ft, "#d9f2ee", "#efeaf5"),
  ifelse(Fc_C > ft, "#d9f2ee", "#efeaf5"),
  ifelse(Fc_T > ft, "#d9f2ee", "#efeaf5"),
  "#faf7fb", "#e8e4f0"
)
tema <- gridExtra::ttheme_default(
  core   =list(bg_params=list(fill=anova_fills),fg_params=list(fontsize=9,fontfamily="serif")),
  colhead=list(bg_params=list(fill="#4b0082"),fg_params=list(col="white",fontsize=9.5,fontface="bold",fontfamily="serif")))
p_tbl <- gridExtra::arrangeGrob(
  grid::textGrob(paste0("Tabla ANOVA - CL 5x5 con Dato Perdido (Y'=",round(Y_prima,4),")"),
                 gp=grid::gpar(fontsize=11,fontface="bold",fontfamily="serif",col="#4b0082")),
  gridExtra::tableGrob(tbl_df,rows=NULL,theme=tema), ncol=1, heights=c(0.14,1))

# Rutas de salida
get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  m <- grep("^--file=", args)
  if (length(m) > 0) return(dirname(normalizePath(sub("^--file=", "", args[m]))))
  for (i in sys.nframe():1) {
    of <- sys.frame(i)$ofile
    if (!is.null(of)) return(dirname(normalizePath(of)))
  }
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    pth <- rstudioapi::getSourceEditorContext()$path
    if (!is.null(pth) && nzchar(pth)) return(dirname(normalizePath(pth)))
  }
  getwd()
}
base_dir <- get_script_dir()
ruta   <- file.path(base_dir, "r_1.png")
ruta_t <- file.path(base_dir, "r_2.png")

titulo_g <- grid::textGrob(TITULO, gp=grid::gpar(fontsize=11,fontface="bold",fontfamily="serif",col="#4b0082"))
sello_g  <- grid::textGrob(SELLO_R, gp=grid::gpar(fontsize=10,fontface="italic",fontfamily="serif",col=ACCENT_R))

# Paneles reordenados (Tukey arriba) para diferenciar de Python
png(ruta, width=1700, height=1250, res=130)
print(grid.arrange(p1,p2,p3,p4,p5, layout_matrix=rbind(c(4,4,5),c(1,2,3)), top=titulo_g, bottom=sello_g))
dev.off()
cat("\nGrafica guardada:", ruta, "\n")

png(ruta_t, width=1200, height=440, res=130)
print(grid.arrange(p_tbl, bottom=sello_g))
dev.off()
cat("Tabla  guardada:", ruta_t, "\n")
