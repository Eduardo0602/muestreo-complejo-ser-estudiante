# 04_estimaciones.R · medias, errores estándar y efecto de diseño por grado y campo

sest <- readRDS(RUTAS$procesado)

#' Estimación de la media de `campo` con los tres diseños
estimar_media <- function(g, campo, fx) {
  d <- datos_de(sest, g, fx)
  if (all(is.na(d[[campo]]))) return(NULL)        # p. ej. icn no existe en BGU
  disenos <- construir_disenos(d, fx)
  f_y <- as.formula(paste0("~", campo))
  purrr::imap_dfr(disenos, function(des, nombre) {
    est <- svymean(f_y, des, na.rm = TRUE, deff = TRUE)
    ic <- confint(est, df = degf(des))
    tibble(
      grado = g, campo = campo, diseno = nombre,
      n = sum(!is.na(d[[campo]])),
      upm = if (nombre == "completo") n_distinct(d$amie) else sum(!is.na(d[[campo]])),
      media = as.numeric(coef(est)), ee = as.numeric(SE(est)),
      li = ic[1, 1], ls = ic[1, 2],
      deff = as.numeric(deff(est))
    )
  })
}

combinaciones <- tidyr::expand_grid(grado = c(4, 7, 10, 3), CAMPOS)
resultados <- purrr::pmap_dfr(
  list(combinaciones$grado, combinaciones$campo, combinaciones$factor),
  estimar_media
) |>
  left_join(CAMPOS |> select(campo, nombre), by = "campo") |>
  mutate(grado_txt = factor(GRADOS[as.character(grado)], levels = GRADOS))

write_csv(resultados, file.path(RUTAS$tablas, "medias_por_diseno.csv"))

# Comparación central: ¿cuánto cambia el error estándar según el diseño?
comparacion <- resultados |>
  select(grado_txt, nombre, diseno, n, upm, media, ee, deff) |>
  pivot_wider(names_from = diseno, values_from = c(upm, media, ee, deff), names_sep = ".") |>
  select(-upm.ingenuo, -upm.solo_pesos, -deff.ingenuo) |>  # deff del diseño ingenuo no tiene sentido
  mutate(
    razon_ee_completo_vs_pesos   = ee.completo / ee.solo_pesos,
    razon_ee_completo_vs_ingenuo = ee.completo / ee.ingenuo,
    n_efectivo                   = n / deff.completo,
    # Aproximación de Kish: deff ~ (efecto de los pesos) x (1 + (m - 1) rho),
    # con m = estudiantes por institución. Se despeja rho (correlación intraclase).
    m_por_upm                    = n / upm.completo,
    rho_kish                     = (deff.completo / deff.solo_pesos - 1) / (m_por_upm - 1)
  ) |>
  arrange(grado_txt, nombre)

write_csv(comparacion, file.path(RUTAS$tablas, "comparacion_disenos.csv"))

# Dominios (solo con el diseño completo): sostenimiento, área y régimen
dominios <- purrr::map_dfr(c(4, 7, 10, 3), function(g) {
  purrr::map_dfr(c("imat", "ilyl"), function(campo) {
    fx <- CAMPOS$factor[CAMPOS$campo == campo]
    des <- construir_disenos(datos_de(sest, g, fx), fx)$completo
    purrr::map_dfr(c("sostenimiento", "area", "regimen"), function(dom) {
      r <- svyby(as.formula(paste0("~", campo)), as.formula(paste0("~", dom)),
                 des, svymean, na.rm = TRUE, vartype = c("se", "ci"))
      medias <- r[[campo]]   # se extrae antes: dentro de tibble() `campo` sería la columna
      tibble(grado = g, campo = campo, dominio = dom,
             categoria = as.character(r[[dom]]),
             media = medias, ee = r$se, li = r$ci_l, ls = r$ci_u)
    })
  })
}) |>
  mutate(grado_txt = factor(GRADOS[as.character(grado)], levels = GRADOS))

write_csv(dominios, file.path(RUTAS$tablas, "dominios.csv"))

# Distribución por nivel de logro en Matemática (0 Insuficiente, 1 Elemental,
# 2 Satisfactorio, 3 Excelente; diccionario oficial), con los dos diseños con pesos.
# Se usa svymean sobre el factor: con proporciones cercanas a 0 (p. ej. BGU no
# tiene estudiantes en nivel Insuficiente) el intervalo logit de svyciprop no converge.
NIVELES <- c("0" = "Insuficiente", "1" = "Elemental", "2" = "Satisfactorio", "3" = "Excelente")
niveles <- purrr::map_dfr(c(4, 7, 10, 3), function(g) {
  des <- construir_disenos(datos_de(sest, g, "fex_imat"), "fex_imat")  # se restringe el diseño, no los datos
  purrr::imap_dfr(des[c("solo_pesos", "completo")], function(d, nombre) {
    est <- svymean(~factor(nl_imat, levels = 0:3), d, na.rm = TRUE)
    tibble(grado = g, diseno = nombre, nivel = unname(NIVELES),
           proporcion = as.numeric(coef(est)), ee = as.numeric(SE(est)))
  })
}) |>
  mutate(grado_txt = factor(GRADOS[as.character(grado)], levels = GRADOS))

write_csv(niveles, file.path(RUTAS$tablas, "niveles_logro_matematica.csv"))
message("Tablas escritas en ", RUTAS$tablas)
