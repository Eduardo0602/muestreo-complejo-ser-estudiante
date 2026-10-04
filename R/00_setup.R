# 00_setup.R · paquetes, opciones y rutas comunes a todos los scripts
#
# Ejecutar los scripts desde la raíz del proyecto (abrir el .Rproj en RStudio
# o usar Rscript R/99_run_all.R desde esa carpeta).

suppressPackageStartupMessages({
  library(readr)    # lectura del CSV oficial (separador ";" y coma decimal)
  library(dplyr)    # transformación de datos
  library(tidyr)    # reorganizar tablas de resultados
  library(survey)   # estimación con diseños muestrales complejos
  library(ggplot2)  # figuras
})

set.seed(20251215)  # no se usa azar en el análisis; se fija por reproducibilidad

# Si algún estrato quedara con una sola UPM, survey no puede estimar su varianza.
# En estos datos no ocurre (se verifica en 05_verificaciones.R); se declara la
# opción conservadora para que el código no falle con otros subconjuntos.
options(survey.lonely.psu = "adjust")

RUTAS <- list(
  crudo       = "data/raw/ineval_serestudiante2024_2025_2025diciembre.csv",
  procesado   = "data/processed/sest25.rds",
  tablas      = "outputs/tablas",
  figuras     = "outputs/figuras"
)

URL_DATOS <- paste0(
  "https://www.datosabiertos.gob.ec/dataset/da1aeddc-3bd6-4399-a840-2f5ec67ba64e/",
  "resource/186950ed-7318-483b-be0f-c87dd857e991/download/",
  "ineval_serestudiante2024_2025_2025diciembre.csv"
)

# Copia sin modificar de los mismos datos (CC BY, Ineval), solo como respaldo.
URL_COPIA <- paste0(
  "https://github.com/Eduardo0602/muestreo-complejo-ser-estudiante/releases/download/",
  "datos-2025-12/ineval_serestudiante2024_2025_2025diciembre.csv"
)

# Campos de evaluación de EGB (4.º, 7.º y 10.º) y bachillerato (3.º BGU).
# Cada puntaje se estima SOLO con su propio factor de expansión.
CAMPOS <- tibble::tribble(
  ~campo, ~factor,    ~nombre,
  "imat", "fex_imat", "Matemática",
  "ilyl", "fex_ilyl", "Lengua y Literatura",
  "icn",  "fex_icn",  "Ciencias Naturales",
  "ies",  "fex_ies",  "Estudios Sociales"
)

GRADOS <- c("4" = "4.º EGB", "7" = "7.º EGB", "10" = "10.º EGB", "3" = "3.º BGU")

dir.create(RUTAS$tablas, recursive = TRUE, showWarnings = FALSE)
dir.create(RUTAS$figuras, recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
