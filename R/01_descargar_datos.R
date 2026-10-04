# 01_descargar_datos.R · descarga los microdatos oficiales si no están en disco
#
# Fuente: Instituto Nacional de Evaluación Educativa (Ineval), "Ser Estudiante
# 2024-2025", portal de datos abiertos del Ecuador (publicado el 2025-12-15).
# Los datos NO se incluyen en el repositorio: se descargan de la fuente oficial.
# Respaldo: el portal responde 403 a los servidores de GitHub, así que si falla
# se usa la copia sin modificar (licencia CC BY, autoría del Ineval) publicada
# como release de este repositorio.

descargar <- function(url) {
  ok <- tryCatch({
    suppressWarnings(download.file(url, RUTAS$crudo, mode = "wb", quiet = TRUE))
    TRUE
  }, error = function(e) FALSE)
  if (!ok && file.exists(RUTAS$crudo)) file.remove(RUTAS$crudo)
  ok
}

if (!file.exists(RUTAS$crudo)) {
  dir.create(dirname(RUTAS$crudo), recursive = TRUE, showWarnings = FALSE)
  message("Descargando microdatos del Ineval (~11 MB)...")
  if (!descargar(URL_DATOS)) {
    message("El portal oficial no respondió; usando la copia CC BY del repositorio.")
    stopifnot("No se pudieron descargar los datos" = descargar(URL_COPIA))
  }
}

# Huella de control: si el Ineval publica una versión distinta, estas cifras
# cambian y el análisis se detiene en vez de producir resultados de otra base.
# (Los códigos anónimos de estudiante cambian entre descargas; las cifras no.)
cabecera <- readLines(RUTAS$crudo, n = 1, encoding = "UTF-8")
stopifnot(
  "El archivo no tiene las 76 columnas esperadas" =
    length(strsplit(cabecera, ";")[[1]]) == 76,
  "El archivo no tiene 50 578 registros" =
    length(readLines(RUTAS$crudo, encoding = "UTF-8")) - 1 == 50578
)
message("Microdatos verificados: ", RUTAS$crudo)
