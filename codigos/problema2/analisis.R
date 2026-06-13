# ============================================================
# PROBLEMA #2 - Cuadrado Latino 4x4 - GreenBuild Smart Towers
# Factor Fila = Zona, Factor Columna = Estacion, Tratamiento = Sistema
# Variable respuesta: Ahorro Energetico (%)
# ============================================================
library(ggplot2); library(dplyr); library(gridExtra)

TITULO      <- "PROBLEMA #2 - Cuadrado Latino 4x4 - GreenBuild Smart Towers"
NOMBRE_FIL  <- "Zona"
NOMBRE_COL  <- "Estacion"
NOMBRE_TRAT <- "Sistema"
RESPUESTA   <- "Ahorro Energetico (%)"

p <- 4
NIVELES_FIL  <- c("Norte", "Sur", "Este", "Oeste")
NIVELES_COL  <- c("Verano", "Otono", "Invierno", "Primavera")
NIVELES_TRAT <- c("A", "B", "C", "D")

# Cuadrado Latino: fila=Zona, columna=Estacion
cuadrado <- matrix(c(
  "A","B","C","D",   # Norte
  "B","C","D","A",   # Sur
  "C","D","A","B",   # Este
  "D","A","B","C"    # Oeste
), nrow=p, byrow=TRUE)

y_mat <- matrix(c(
  12.03, 16.07, 20.76, 14.21,
  17.34, 20.59, 15.48, 13.03,
  19.70, 13.08, 12.07, 16.24,
  14.29, 11.83, 17.38, 20.74
), nrow=p, byrow=TRUE)

N    <- p * p
fila <- rep(NIVELES_FIL,  each=p)
col  <- rep(NIVELES_COL,  times=p)
trat <- as.vector(t(cuadrado))
y    <- as.vector(t(y_mat))

df <- data.frame(
  Zona     = factor(fila, levels=NIVELES_FIL),
  Estacion = factor(col,  levels=NIVELES_COL),
  Sistema  = factor(trat, levels=NIVELES_TRAT),
  Y        = y
)
names(df)[1:3] <- c(NOMBRE_FIL, NOMBRE_COL, NOMBRE_TRAT)

# ============================================================
# ANOVA - Cuadrado Latino
# ============================================================
formula_m <- as.formula(paste("Y ~", NOMBRE_FIL, "+", NOMBRE_COL, "+", NOMBRE_TRAT))
modelo    <- aov(formula_m, data=df)
resumen   <- summary(modelo)[[1]]

cat(strrep("=",65), "\nTABLA ANOVA -", TITULO, "\n", strrep("=",65), "\n")
print(summary(modelo))

alpha <- 0.05
gl_F  <- p - 1; gl_C <- p - 1; gl_T <- p - 1; gl_E <- (p-1)*(p-2)
ft_F  <- qf(1-alpha, gl_F, gl_E)
ft_C  <- qf(1-alpha, gl_C, gl_E)
ft_T  <- qf(1-alpha, gl_T, gl_E)
Fc_F  <- resumen[1,"F value"]
Fc_C  <- resumen[2,"F value"]
Fc_T  <- resumen[3,"F value"]

cat(sprintf("\nFt Zona     (%d,%d) = %.4f | Fc = %.4f -> %s\n", gl_F, gl_E, ft_F, Fc_F, ifelse(Fc_F>ft_F,"SIGNIFICATIVO","no significativo")))
cat(sprintf("Ft Estacion (%d,%d) = %.4f | Fc = %.4f -> %s\n", gl_C, gl_E, ft_C, Fc_C, ifelse(Fc_C>ft_C,"SIGNIFICATIVO","no significativo")))
cat(sprintf("Ft Sistema  (%d,%d) = %.4f | Fc = %.4f -> %s\n", gl_T, gl_E, ft_T, Fc_T, ifelse(Fc_T>ft_T,"SIGNIFICATIVO","no significativo")))

# ============================================================
# PRUEBA DE TUKEY (solo Sistema = tratamiento de interes)
# ============================================================
cat("\n--- Tukey Sistema ---\n")
tukey_T <- TukeyHSD(modelo, NOMBRE_TRAT); print(tukey_T)

# ============================================================
# GRAFICAS -> PNG  (ESTILO R: serif + viridis + sello)
# ============================================================
theme_R <- theme_minimal(base_family = "serif", base_size = 12) +
  theme(plot.title       = element_text(face = "bold", color = "#4b0082"),
        panel.background = element_rect(fill = "#faf7fb", color = NA),
        panel.grid.minor = element_blank(),
        legend.position  = "bottom")
PALETA_R <- c("#440154","#3b528b","#21918c","#5ec962")
ACCENT_R <- "#4b0082"
SELLO_R  <- "Generado en R 4.6  |  ggplot2  |  aov + TukeyHSD"
mg <- mean(df$Y)

# p1 - Medias por Zona
df_pF <- data.frame(Niv=factor(NIVELES_FIL, NIVELES_FIL),
                    Med=tapply(df$Y, df[[NOMBRE_FIL]], mean)[NIVELES_FIL])
p1 <- ggplot(df_pF, aes(x=Niv, y=Med)) +
  geom_bar(stat="identity", fill=PALETA_R[1], color="black") +
  geom_hline(yintercept=mg, color="red", linetype="dashed", linewidth=1.2) +
  labs(title=paste("Medias por", NOMBRE_FIL), x=NOMBRE_FIL, y=RESPUESTA) +
  theme_R + theme(plot.title=element_text(size=12))

# p2 - Medias por Estacion
df_pC <- data.frame(Niv=factor(NIVELES_COL, NIVELES_COL),
                    Med=tapply(df$Y, df[[NOMBRE_COL]], mean)[NIVELES_COL])
p2 <- ggplot(df_pC, aes(x=Niv, y=Med)) +
  geom_bar(stat="identity", fill=PALETA_R[3], color="black") +
  geom_hline(yintercept=mg, color="red", linetype="dashed", linewidth=1.2) +
  labs(title=paste("Medias por", NOMBRE_COL), x=NOMBRE_COL, y=RESPUESTA) +
  theme_R + theme(plot.title=element_text(size=12),
                  axis.text.x=element_text(angle=15, hjust=1))

# p3 - Medias por Sistema
df_pT <- data.frame(Niv=factor(NIVELES_TRAT, NIVELES_TRAT),
                    Med=tapply(df$Y, df[[NOMBRE_TRAT]], mean)[NIVELES_TRAT])
p3 <- ggplot(df_pT, aes(x=Niv, y=Med)) +
  geom_bar(stat="identity", fill=PALETA_R[4], color="black") +
  geom_hline(yintercept=mg, color="red", linetype="dashed", linewidth=1.2) +
  labs(title=paste("Medias por", NOMBRE_TRAT), x=NOMBRE_TRAT, y=RESPUESTA) +
  theme_R + theme(plot.title=element_text(size=12))

# p4 - Tukey Sistema
tk_T_df <- as.data.frame(tukey_T[[NOMBRE_TRAT]])
colnames(tk_T_df) <- c("diff","lwr","upr","p_adj")
tk_T_df$Comp <- rownames(tk_T_df)
tk_T_df$Sig  <- tk_T_df$p_adj < 0.05
p4 <- ggplot(tk_T_df, aes(y=reorder(Comp,diff), x=diff)) +
  geom_errorbarh(aes(xmin=lwr, xmax=upr, color=Sig), height=0.4, linewidth=1) +
  geom_point(aes(color=Sig), size=3) +
  geom_vline(xintercept=0, linetype="dashed") +
  scale_color_manual(values=c("TRUE"="#c2185b","FALSE"="#3b528b"),
                     labels=c("TRUE"="Sig.","FALSE"="No sig."), name="") +
  labs(title=paste("Tukey HSD -", NOMBRE_TRAT), x="Dif. medias (IC 95%)", y="") +
  theme_R + theme(plot.title=element_text(size=12))

# Tabla ANOVA grob
sc_F_r <- resumen[1,"Sum Sq"]; sc_C_r <- resumen[2,"Sum Sq"]
sc_T_r <- resumen[3,"Sum Sq"]; sc_E_r <- resumen[4,"Sum Sq"]
sc_Tot_r <- sc_F_r + sc_C_r + sc_T_r + sc_E_r

tbl_df <- data.frame(
  "Fuente"   = c(NOMBRE_FIL, NOMBRE_COL, NOMBRE_TRAT, "Error", "Total"),
  "GL"       = c(gl_F, gl_C, gl_T, gl_E, N-1),
  "SC"       = round(c(sc_F_r, sc_C_r, sc_T_r, sc_E_r, sc_Tot_r), 4),
  "CM"       = c(round(sc_F_r/gl_F,4), round(sc_C_r/gl_C,4), round(sc_T_r/gl_T,4), round(sc_E_r/gl_E,4), "-"),
  "Fc"       = c(round(Fc_F,4), round(Fc_C,4), round(Fc_T,4), "-", "-"),
  "Ft"       = c(round(ft_F,4), round(ft_C,4), round(ft_T,4), "-", "-"),
  "Decision" = c(ifelse(Fc_F>ft_F,"Sig ***","No sig"), ifelse(Fc_C>ft_C,"Sig ***","No sig"),
                 ifelse(Fc_T>ft_T,"Sig ***","No sig"), "-", "-"),
  check.names=FALSE, stringsAsFactors=FALSE)

anova_fills <- c(
  ifelse(Fc_F > ft_F, "#d9f2ee", "#efeaf5"),
  ifelse(Fc_C > ft_C, "#d9f2ee", "#efeaf5"),
  ifelse(Fc_T > ft_T, "#d9f2ee", "#efeaf5"),
  "#faf7fb", "#e8e4f0"
)
tema <- gridExtra::ttheme_default(
  core   =list(bg_params=list(fill=anova_fills),
               fg_params=list(fontsize=9,fontfamily="serif")),
  colhead=list(bg_params=list(fill="#4b0082"),fg_params=list(col="white",fontsize=9.5,fontface="bold",fontfamily="serif")))
p_tbl <- gridExtra::arrangeGrob(
  grid::textGrob("Tabla ANOVA - Cuadrado Latino 4x4", gp=grid::gpar(fontsize=11,fontface="bold",fontfamily="serif",col="#4b0082")),
  gridExtra::tableGrob(tbl_df, rows=NULL, theme=tema), ncol=1, heights=c(0.12,1))

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

titulo_g <- grid::textGrob(TITULO, gp=grid::gpar(fontsize=12, fontface="bold",fontfamily="serif",col="#4b0082"))
sello_g  <- grid::textGrob(SELLO_R, gp=grid::gpar(fontsize=11, fontface="italic",fontfamily="serif",col=ACCENT_R))

# Paneles reordenados (Tukey arriba) para diferenciar del layout de Python
png(ruta, width=1500, height=1050, res=130)
print(grid.arrange(p1,p2,p3,p4, layout_matrix=rbind(c(4,4,4),c(1,2,3)), top=titulo_g, bottom=sello_g))
dev.off()
cat("\nGrafica guardada:", ruta, "\n")

png(ruta_t, width=1200, height=420, res=130)
print(grid.arrange(p_tbl, bottom=sello_g))
dev.off()
cat("Tabla  guardada:", ruta_t, "\n")
