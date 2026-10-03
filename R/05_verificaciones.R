# 05_verificaciones.R · se recalculan a mano las cifras de survey
#
# Cada fórmula del README se implementa aquí desde cero y se compara con lo
# que devuelve survey. Si alguna diferencia supera la tolerancia, se detiene.

sest <- readRDS(RUTAS$procesado)
TOL <- 1e-8

#' Varianza por linealización del estimador de Hájek, con UPM seleccionadas
#' con reemplazo dentro de cada estrato (la aproximación que usa survey).
#'   u_k  = w_k (y_k - media) / N_hat
#'   z_hi = suma de u_k en la UPM i del estrato h
#'   V    = sum_h n_h/(n_h - 1) * sum_i (z_hi - zbarra_h)^2
varianza_hajek <- function(y, w, upm, estrato) {
  ok <- !is.na(y)
  y <- y[ok]; w <- w[ok]; upm <- upm[ok]; estrato <- estrato[ok]
  N_hat <- sum(w)
  media <- sum(w * y) / N_hat
  u <- w * (y - media) / N_hat
  tibble(u, upm, estrato) |>
    group_by(estrato, upm) |> summarise(z = sum(u), .groups = "drop") |>
    group_by(estrato) |>
    summarise(aporte = n() / (n() - 1) * sum((z - mean(z))^2), .groups = "drop") |>
    pull(aporte) |> sum()
}

verif <- list()
for (g in c(4, 7, 10, 3)) {
  for (i in seq_len(nrow(CAMPOS))) {
    campo <- CAMPOS$campo[i]; fx <- CAMPOS$factor[i]
    d <- datos_de(sest, g, fx)
    if (all(is.na(d[[campo]]))) next
    des <- construir_disenos(d, fx)
    y <- d[[campo]]; w <- d[[fx]]; ok <- !is.na(y)
    f_y <- as.formula(paste0("~", campo))

    m_c <- svymean(f_y, des$completo, na.rm = TRUE)
    m_p <- svymean(f_y, des$solo_pesos, na.rm = TRUE)
    m_i <- svymean(f_y, des$ingenuo, na.rm = TRUE)
    hajek <- sum(w[ok] * y[ok]) / sum(w[ok])

    v_c <- varianza_hajek(y, w, d$amie, d$estrato)
    v_p <- varianza_hajek(y, w, seq_along(y), rep(1, length(y)))
    ee_mas <- sd(y[ok]) / sqrt(sum(ok))   # MAS con reemplazo, sin pesos

    estratos_1upm <- d |> distinct(estrato, amie) |> count(estrato) |> filter(n == 1) |> nrow()

    verif[[length(verif) + 1]] <- tibble(
      grado = g, campo = campo,
      hajek_igual_svymean     = abs(hajek - as.numeric(coef(m_c))) < TOL * hajek,
      completo_igual_pesos    = abs(as.numeric(coef(m_c)) - as.numeric(coef(m_p))) < TOL * hajek,
      ingenuo_igual_promedio  = abs(as.numeric(coef(m_i)) - mean(y[ok])) < TOL * hajek,
      var_completo_a_mano     = abs(sqrt(v_c) - as.numeric(SE(m_c))) < 1e-6 * as.numeric(SE(m_c)),
      var_pesos_a_mano        = abs(sqrt(v_p) - as.numeric(SE(m_p))) < 1e-6 * as.numeric(SE(m_p)),
      ee_ingenuo_a_mano       = abs(ee_mas - as.numeric(SE(m_i))) < 1e-3 * as.numeric(SE(m_i)),
      sin_estratos_de_una_upm = estratos_1upm == 0,
      N_hat = sum(w)
    )
  }
}
verificaciones <- bind_rows(verif)
write_csv(verificaciones, file.path(RUTAS$tablas, "verificaciones.csv"))

checks <- verificaciones |> select(where(is.logical))
if (!all(unlist(checks))) {
  print(verificaciones |> filter(if_any(where(is.logical), ~ !.x)))
  stop("Alguna verificación falló: revisar outputs/tablas/verificaciones.csv")
}
message("Verificaciones: ", sum(unlist(checks)), " de ", length(unlist(checks)), " correctas.")
