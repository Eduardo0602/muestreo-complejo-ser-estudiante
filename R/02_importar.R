# 02_importar.R · lectura, etiquetas oficiales y variable de estrato
#
# Etiquetas tomadas del diccionario oficial del Ineval
# (ineval_serestudiante2024_2025_dd_2025diciembre.ods).

crudo <- read_delim(
  RUTAS$crudo, delim = ";",
  locale = locale(decimal_mark = ",", encoding = "UTF-8"),
  show_col_types = FALSE, guess_max = 60000
)

sest <- crudo |>
  select(grado, estado_eval, amie, es_regeva, tp_area, sostenimiento,
         all_of(CAMPOS$campo), all_of(CAMPOS$factor),
         nl_imat, nl_ilyl) |>
  mutate(
    grado_txt = factor(GRADOS[as.character(grado)], levels = GRADOS),
    regimen = factor(es_regeva, 1:2, c("Costa-Galápagos", "Sierra-Amazonía")),
    area = factor(tp_area, 1:2, c("Rural", "Urbana")),
    sostenimiento = factor(sostenimiento, 1:4,
                           c("Particular", "Municipal", "Fiscomisional", "Fiscal")),
    # Estratos del diseño según la ficha metodológica oficial:
    # régimen x área x sostenimiento (2 x 2 x 4 = 16 estratos por grado).
    estrato = interaction(regimen, area, sostenimiento, sep = " | ", drop = TRUE)
  )

# Controles: si algo de esto falla, el resto del análisis no tiene sentido.
stopifnot(
  nrow(sest) == 50578,
  all(sest$grado %in% c(3, 4, 7, 10)),
  !anyNA(sest$regimen), !anyNA(sest$area), !anyNA(sest$sostenimiento),
  # Cada institución pertenece a un único estrato (necesario para nest = TRUE).
  sest |> distinct(grado, amie, estrato) |> count(grado, amie) |> pull(n) |> max() == 1
)

saveRDS(sest, RUTAS$procesado)
message("Base procesada: ", nrow(sest), " filas, ", n_distinct(sest$amie), " instituciones.")
