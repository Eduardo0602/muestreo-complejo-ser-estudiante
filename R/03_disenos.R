# 03_disenos.R · las tres formas de declarar la muestra que se comparan
#
#   ingenuo    : se trata la muestra como si fuera aleatoria simple (sin pesos).
#   solo_pesos : se usa el factor de expansión, pero cada estudiante cuenta como
#                una unidad independiente (así se declaró el SEST en clase).
#   completo   : diseño oficial: estratos (régimen x área x sostenimiento),
#                conglomerados (instituciones, `amie`) y factor de expansión.
#
# Los tres dan errores estándar distintos; solo el completo respeta cómo se
# seleccionó realmente la muestra.

#' Subconjunto de un grado con el factor de expansión del campo disponible
datos_de <- function(sest, g, fx) {
  sest |>
    filter(grado == g, !is.na(.data[[fx]])) |>
    mutate(peso_uno = 1)
}

#' Lista con los tres diseños para un grado y un campo
construir_disenos <- function(d, fx) {
  f_peso <- as.formula(paste0("~", fx))
  list(
    ingenuo    = svydesign(ids = ~1, weights = ~peso_uno, data = d),
    solo_pesos = svydesign(ids = ~1, weights = f_peso, data = d),
    completo   = svydesign(ids = ~amie, strata = ~estrato, weights = f_peso,
                           data = d, nest = TRUE)
  )
}
