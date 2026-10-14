# ==============================================================================
# requirements.R — installazione delle dipendenze del progetto
#
# Uso:  Rscript requirements.R      (oppure eseguire riga per riga in RStudio)
#
# NB: cmdstanr non e' sul CRAN standard e richiede un toolchain C++ e CmdStan.
#     Vedere le istruzioni sotto e nel README.
# ==============================================================================

# --- Pacchetti CRAN usati dalla pipeline ---
cran_pkgs <- c(
  "readxl",      # lettura del file .xlsx
  "openxlsx",    # scrittura del dataset sintetico (00_genera_dati_sintetici.R)
  "dplyr",       # manipolazione dati
  "tidyr",       # reshape
  "ggplot2",     # grafici
  "gridExtra",   # composizione grafici (analisi esplorativa)
  "patchwork",   # composizione grafici (modello/ottimizzazione)
  "minpack.lm",  # nlsLM: stime Gompertz robuste in fase esplorativa
  "posterior",   # gestione dei draw posteriori
  "bayesplot",   # diagnostiche grafiche MCMC
  "rstudioapi"   # rilevamento percorso script in RStudio (opzionale)
)

to_install <- setdiff(cran_pkgs, rownames(installed.packages()))
if (length(to_install)) install.packages(to_install)

# --- cmdstanr + CmdStan (interfaccia a Stan) ---
# cmdstanr non e' su CRAN: si installa dal repository Stan.
if (!requireNamespace("cmdstanr", quietly = TRUE)) {
  install.packages("cmdstanr",
                   repos = c("https://stan-dev.r-universe.dev", getOption("repos")))
}
# Dopo l'installazione del pacchetto, installare il backend CmdStan una volta:
#   cmdstanr::check_cmdstan_toolchain(fix = TRUE)
#   cmdstanr::install_cmdstan()

cat("Setup completato. Ricordarsi di eseguire cmdstanr::install_cmdstan() se serve.\n")
