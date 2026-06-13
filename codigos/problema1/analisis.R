# ============================================================
# PROBLEMA #1 - Factorial 4x3 - QuantEdge Capital
# Factor A = Estrategia (4 niveles) x Factor B = Regimen (3 niveles), n=3
# ============================================================
library(ggplot2); library(dplyr); library(gridExtra)

TITULO    <- "PROBLEMA #1 - Factorial: Estrategia x Regimen Volatilidad"
NOMBRE_A  <- "Estrategia"
NOMBRE_B  <- "Regimen"
RESPUESTA <- "Sharpe Ratio mensual"

niveles_A <- c("Mkt.Making", "Arb.Triang", "Momentum", "Mean Rev.")
niveles_B <- c("Baja", "Media", "Alta")
n         <- 3

datos <- c(
  # A = Market Making: Baja(3), Media(3), Alta(3)
  0.77, 0.80, 0.83,   1.17, 1.20, 1.23,   1.72, 1.75, 1.78,
  # A = Arbitraje Triangular
  1.32, 1.35, 1.38,   1.82, 1.85, 1.88,   2.52, 2.55, 2.58,
  # A = Momentum
  1.07, 1.10, 1.13,   1.52, 1.55, 1.58,   2.12, 2.15, 2.18,
  # A = Mean Reversion
  1.62, 1.65, 1.68,   2.17, 2.20, 2.23,   2.97, 3.00, 3.03
)

a <- length(niveles_A); b <- length(niveles_B); N <- a * b * n

fA <- rep(niveles_A, each = b * n)
fB <- rep(rep(niveles_B, each = n), times = a)
df <- data.frame(
  A = factor(fA, levels = niveles_A),
  B = factor(fB, levels = niveles_B),
  Y = datos
)
names(df)[1:2] <- c(NOMBRE_A, NOMBRE_B)

# ============================================================
# ANOVA
# ============================================================
formula_modelo <- as.formula(paste("Y ~", NOMBRE_A, "*", NOMBRE_B))
modelo  <- aov(formula_modelo, data = df)
resumen <- summary(modelo)[[1]]

cat(strrep("=",65),"\nTABLA ANOVA -", TITULO, "\n", strrep("=",65),"\n")
print(summary(modelo))

alpha <- 0.05
gl_A  <- a - 1; gl_B <- b - 1; gl_AB <- gl_A * gl_B; gl_E <- a * b * (n - 1)
ft_A  <- qf(1-alpha, gl_A,  gl_E)
ft_B  <- qf(1-alpha, gl_B,  gl_E)
ft_AB <- qf(1-alpha, gl_AB, gl_E)
Fc_A  <- resumen[1,"F value"]; Fc_B <- resumen[2,"F value"]; Fc_AB <- resumen[3,"F value"]

cat(sprintf("\nFt Factor A  (%d,%d) = %.4f | Fc = %.4f -> %s\n", gl_A,  gl_E, ft_A,  Fc_A,  ifelse(Fc_A >ft_A, "SIGNIFICATIVO","no significativo")))
cat(sprintf("Ft Factor B  (%d,%d) = %.4f | Fc = %.4f -> %s\n", gl_B,  gl_E, ft_B,  Fc_B,  ifelse(Fc_B >ft_B, "SIGNIFICATIVO","no significativo")))
cat(sprintf("Ft Inter AxB (%d,%d) = %.4f | Fc = %.4f -> %s\n", gl_AB, gl_E, ft_AB, Fc_AB, ifelse(Fc_AB>ft_AB,"SIGNIFICATIVO","no significativo")))

# ============================================================
# TUKEY
# ============================================================
cat("\n--- Tukey Factor A:", NOMBRE_A,"---\n")
tukey_A <- TukeyHSD(modelo, NOMBRE_A); print(tukey_A)
cat("\n--- Tukey Factor B:", NOMBRE_B,"---\n")
tukey_B <- TukeyHSD(modelo, NOMBRE_B); print(tukey_B)

# ============================================================
# GRAFICAS -> PNG  (estilo R: serif + viridis + sello)
# ============================================================
theme_R <- theme_minimal(base_family = "serif", base_size = 12) +
  theme(plot.title       = element_text(face = "bold", color = "#4b0082"),
        panel.background = element_rect(fill = "#faf7fb", color = NA),
        panel.grid.minor = element_blank(),
        legend.position  = "bottom")
PALETA_R <- c("#440154","#3b528b","#21918c","#5ec962","#fde725","#fca50a")
ACCENT_R <- "#4b0082"
SELLO_R  <- "Generado en R 4.6  |  ggplot2  |  aov + TukeyHSD"
mg <- mean(df$Y)

df_pA <- data.frame(Niv=factor(niveles_A,niveles_A), Med=tapply(df$Y,df[[NOMBRE_A]],mean))
df_pB <- data.frame(Niv=factor(niveles_B,niveles_B), Med=tapply(df$Y,df[[NOMBRE_B]],mean))

p1 <- ggplot(df_pA,aes(x=Niv,y=Med))+geom_bar(stat="identity",fill=PALETA_R[1],color="black")+
  geom_hline(yintercept=mg,color="red",linetype="dashed",linewidth=1.2)+
  labs(title=paste("Efecto Principal -",NOMBRE_A),x=NOMBRE_A,y=RESPUESTA)+theme_R+
  theme(plot.title=element_text(size=11), axis.text.x=element_text(angle=20,hjust=1))

p2 <- ggplot(df_pB,aes(x=Niv,y=Med))+geom_bar(stat="identity",fill=PALETA_R[3],color="black")+
  geom_hline(yintercept=mg,color="red",linetype="dashed",linewidth=1.2)+
  labs(title=paste("Efecto Principal -",NOMBRE_B),x=NOMBRE_B,y=RESPUESTA)+theme_R+
  theme(plot.title=element_text(size=11))

int_tab <- tapply(df$Y,list(df[[NOMBRE_B]],df[[NOMBRE_A]]),mean)
df_int  <- as.data.frame(as.table(int_tab)); names(df_int)<-c("B","A","Med")
df_int$A<-factor(df_int$A,niveles_A); df_int$B<-factor(df_int$B,niveles_B)
p3 <- ggplot(df_int,aes(x=A,y=Med,color=B,group=B))+geom_line(linewidth=1.4)+geom_point(size=3)+
  scale_color_manual(values=PALETA_R)+
  labs(title="Interaccion AxB",x=NOMBRE_A,y=RESPUESTA,color=NOMBRE_B)+theme_R+
  theme(plot.title=element_text(size=11), axis.text.x=element_text(angle=20,hjust=1))

tk_A_df <- as.data.frame(tukey_A[[NOMBRE_A]]); colnames(tk_A_df)<-c("diff","lwr","upr","p_adj"); tk_A_df$Comp<-rownames(tk_A_df); tk_A_df$Sig<-tk_A_df$p_adj<0.05
p4 <- ggplot(tk_A_df,aes(y=reorder(Comp,diff),x=diff))+
  geom_errorbarh(aes(xmin=lwr,xmax=upr,color=Sig),height=0.5,linewidth=1)+
  geom_point(aes(color=Sig),size=3)+geom_vline(xintercept=0,linetype="dashed")+
  scale_color_manual(values=c("TRUE"="#c2185b","FALSE"="#3b528b"),
                     labels=c("TRUE"="Sig.","FALSE"="No sig."),name="")+
  labs(title=paste("Tukey HSD -",NOMBRE_A),x="Dif. medias (IC 95%)",y="")+
  theme_R+theme(plot.title=element_text(size=11))

tk_B_df <- as.data.frame(tukey_B[[NOMBRE_B]]); colnames(tk_B_df)<-c("diff","lwr","upr","p_adj"); tk_B_df$Comp<-rownames(tk_B_df); tk_B_df$Sig<-tk_B_df$p_adj<0.05
p5 <- ggplot(tk_B_df,aes(y=reorder(Comp,diff),x=diff))+
  geom_errorbarh(aes(xmin=lwr,xmax=upr,color=Sig),height=0.35,linewidth=1)+
  geom_point(aes(color=Sig),size=3)+geom_vline(xintercept=0,linetype="dashed")+
  scale_color_manual(values=c("TRUE"="#c2185b","FALSE"="#21918c"),
                     labels=c("TRUE"="Sig.","FALSE"="No sig."),name="")+
  labs(title=paste("Tukey HSD -",NOMBRE_B),x="Dif. medias (IC 95%)",y="")+
  theme_R+theme(plot.title=element_text(size=11))

# Tabla ANOVA grob
sc_A<-resumen[1,"Sum Sq"]; sc_B<-resumen[2,"Sum Sq"]; sc_AB<-resumen[3,"Sum Sq"]; sc_E<-resumen[4,"Sum Sq"]
tbl_df <- data.frame(
  "Fuente"=c(NOMBRE_A,NOMBRE_B,"Interaccion AxB","Error","Total"),
  "GL"=c(gl_A,gl_B,gl_AB,gl_E,N-1),
  "SC"=round(c(sc_A,sc_B,sc_AB,sc_E,sc_A+sc_B+sc_AB+sc_E),4),
  "CM"=c(round(sc_A/gl_A,4),round(sc_B/gl_B,4),round(sc_AB/gl_AB,4),round(sc_E/gl_E,4),"-"),
  "Fc"=c(round(Fc_A,4),round(Fc_B,4),round(Fc_AB,4),"-","-"),
  "Ft"=c(round(ft_A,4),round(ft_B,4),round(ft_AB,4),"-","-"),
  "Decision"=c(ifelse(Fc_A>ft_A,"Sig ***","No sig"),ifelse(Fc_B>ft_B,"Sig ***","No sig"),
               ifelse(Fc_AB>ft_AB,"Sig ***","No sig"),"-","-"),
  check.names=FALSE, stringsAsFactors=FALSE)

anova_fills <- c(
  ifelse(Fc_A  > ft_A,  "#d9f2ee", "#efeaf5"),
  ifelse(Fc_B  > ft_B,  "#d9f2ee", "#efeaf5"),
  ifelse(Fc_AB > ft_AB, "#d9f2ee", "#efeaf5"),
  "#faf7fb", "#e8e4f0"
)
tema <- gridExtra::ttheme_default(
  core=list(bg_params=list(fill=anova_fills),fg_params=list(fontsize=9,fontfamily="serif")),
  colhead=list(bg_params=list(fill="#4b0082"),fg_params=list(col="white",fontsize=9.5,fontface="bold",fontfamily="serif")))
p_tbl <- gridExtra::arrangeGrob(
  grid::textGrob("Tabla ANOVA - Diseño Factorial 4x3", gp=grid::gpar(fontsize=11,fontface="bold",fontfamily="serif",col="#4b0082")),
  gridExtra::tableGrob(tbl_df,rows=NULL,theme=tema), ncol=1, heights=c(0.12,1))

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

titulo_g <- grid::textGrob(TITULO, gp=grid::gpar(fontsize=12,fontface="bold",fontfamily="serif",col="#4b0082"))
sello_g  <- grid::textGrob(SELLO_R, gp=grid::gpar(fontsize=11,fontface="italic",fontfamily="serif",col=ACCENT_R))

# Paneles reordenados (Tukey arriba) para diferenciar del layout de Python
png(ruta, width=1600, height=1100, res=130)
print(grid.arrange(p1,p2,p3,p4,p5, layout_matrix=rbind(c(4,4,5),c(1,2,3)), top=titulo_g, bottom=sello_g))
dev.off()
cat("\nGrafica guardada:", ruta, "\n")

png(ruta_t, width=1300, height=470, res=130)
print(grid.arrange(p_tbl, bottom=sello_g))
dev.off()
cat("Tabla  guardada:", ruta_t, "\n")
