# ==============================================================================
# 00_genera_dati_sintetici.R
#
# Genera il dataset SINTETICO `data/biomassa.xlsx` usato per rendere la pipeline
# completamente riproducibile senza distribuire i dati sperimentali reali.
#
# IMPORTANTISSIMO
#   I dati prodotti da questo script sono FITTIZI. Il disegno sperimentale
#   (combinazioni I/D/P, tempi, struttura del file) e' identico a quello reale,
#   ma le RELAZIONI tra covariate e resa (OD) sono inventate e NON riproducono
#   le conclusioni dell'analisi originale. Qualsiasi risultato ottenuto girando
#   la pipeline su questi dati e' privo di significato biologico: serve solo a
#   verificare che il codice giri end-to-end.
#
# Layout del file scritto: identico a quello dei dati reali (banner su 2 righe,
# intestazioni a riga 3, dati da riga 4, colonna A vuota) cosi' che
# `read_xlsx(..., skip = 2)` in 01_esplorative.R funzioni senza modifiche.
# Per usare i dati reali, basta sostituire data/biomassa.xlsx con il file vero.
# ==============================================================================

# ------------------------------------------------------------------------------
# Percorsi del progetto (robusti: funzionano in RStudio e con Rscript)
# ------------------------------------------------------------------------------
.script_dir <- local({
  args <- commandArgs(FALSE)
  f <- grep("^--file=", args, value = TRUE)
  if (length(f)) return(dirname(normalizePath(sub("^--file=", "", f[1]))))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- tryCatch(rstudioapi::getActiveDocumentContext()$path, error = function(e) "")
    if (nzchar(p)) return(dirname(normalizePath(p)))
  }
  normalizePath(getwd())
})
ROOT_DIR  <- dirname(.script_dir)                 # R/ -> radice del repo
DATA_DIR  <- file.path(ROOT_DIR, "data")
DATA_FILE <- file.path(DATA_DIR, "biomassa.xlsx")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)

library(openxlsx)

# ------------------------------------------------------------------------------
# Disegno sperimentale reale: 53 curve, 17 combinazioni (I, D, P).
# Il disegno e' un RSM Central-Composite Face-Centered standard, non sensibile.
# ------------------------------------------------------------------------------
I <- c(90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,90,
       280,280,280,280,280,280,280,280,280,280,280,280,280,280,280,280,280,280,280,280,280,
       470,470,470,470,470,470,470,470,470,470,470,470,470)
D <- c(12,12,12,12,12,12,18,18,18,24,24,24,24,24,24,24,24,24,
       12,12,12,12,18,18,18,18,18,18,18,18,18,18,18,18,18,18,24,24,24,
       12,12,12,12,12,18,18,18,24,24,24,24,24,24)
P <- c(1,1,1,50,50,50,25.5,25.5,25.5,1,1,1,25.5,25.5,25.5,50,50,50,
       25.5,25.5,25.5,25.5,1,1,1,25.5,25.5,25.5,25.5,25.5,25.5,25.5,25.5,50,50,50,25.5,25.5,25.5,
       1,1,1,50,50,25.5,25.5,25.5,1,1,25.5,25.5,50,50)
stopifnot(length(I) == 53, length(D) == 53, length(P) == 53)

TEMPI <- 0:6                # stessi tempi del file reale
set.seed(20250101)

# ------------------------------------------------------------------------------
# Modello generatore VOLUTAMENTE FITTIZIO
#   Curva di Gompertz OD(t) = A * exp(-B * C^t) con effetti covariata inventati:
#   - effetto luce (I) NEGATIVO con curvatura  -> opposto/interno rispetto al vero
#   - durata (D) quasi trascurabile
#   - fosforo (P) monotono
#   Nessuno di questi rispecchia i risultati reali.
# ------------------------------------------------------------------------------
rows <- vector("list", 53 * length(TEMPI))
r <- 1
for (k in seq_len(53)) {
  xI <- (I[k] - 280) / 190
  xD <- (D[k] - 18)  / 6
  xP <- (P[k] - 25.5) / 24.5

  logA   <- 1.55 - 0.35 * xI + 0.18 * xI^2 + 0.30 * xP + 0.08 * xD
  logB   <- 0.65 + 0.05 * xD
  v_i    <- rnorm(1, 0, 0.08)                      # effetto casuale per curva
  logitC <- 0.55 + 0.20 * xI - 0.15 * xP + v_i

  A <- exp(logA); B <- exp(logB); C <- plogis(logitC)

  for (t in TEMPI) {
    tt <- t + 1
    mu <- A * exp(-B * C^tt)
    sd <- 0.12 * max(mu, 1e-3)^0.6                 # errore eteroschedastico
    od <- max(mu + rnorm(1, 0, sd), 0.05)
    if (runif(1) < 0.015) od <- NA                 # ~1.5% mancanti come nel reale
    rows[[r]] <- data.frame(row_id = r, I = I[k], D = D[k], P = P[k],
                            tempo = t, OD = if (is.na(od)) NA else round(od, 3))
    r <- r + 1
  }
}
dati_sint <- do.call(rbind, rows)

# ------------------------------------------------------------------------------
# Scrittura xlsx nel layout dei dati reali (colonna A vuota, banner, header riga 3)
# ------------------------------------------------------------------------------
wb <- createWorkbook()
addWorksheet(wb, "Foglio1")
writeData(wb, 1, data.frame("#", "fattori input"),        startCol = 2, startRow = 2, colNames = FALSE)
writeData(wb, 1, data.frame("Var. T", "Var. Y"),          startCol = 6, startRow = 2, colNames = FALSE)
writeData(wb, 1, t(c("I", "D", "P", "Tempo (d)", "OD")),  startCol = 3, startRow = 3, colNames = FALSE)
writeData(wb, 1, dati_sint,                               startCol = 2, startRow = 4, colNames = FALSE)
saveWorkbook(wb, DATA_FILE, overwrite = TRUE)

cat("Scritto dataset sintetico:", DATA_FILE, "\n")
cat("Righe:", nrow(dati_sint), "| curve:", length(unique(dati_sint$row_id)),
    "| NA in OD:", sum(is.na(dati_sint$OD)), "\n")
