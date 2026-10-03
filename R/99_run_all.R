# 99_run_all.R · ejecuta todo el análisis en orden, desde la raíz del proyecto
#   Rscript R/99_run_all.R

inicio <- Sys.time()
for (script in c("00_setup.R", "01_descargar_datos.R", "02_importar.R", "03_disenos.R",
                 "04_estimaciones.R", "05_verificaciones.R", "06_figuras.R")) {
  message("\n== ", script)
  source(file.path("R", script), encoding = "UTF-8")
}
message("\nListo en ", round(difftime(Sys.time(), inicio, units = "mins"), 2), " min.")
