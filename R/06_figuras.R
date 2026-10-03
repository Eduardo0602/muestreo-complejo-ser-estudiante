# 06_figuras.R · figuras del README y del informe

comparacion <- read_csv(file.path(RUTAS$tablas, "comparacion_disenos.csv"), show_col_types = FALSE) |>
  mutate(grado_txt = factor(grado_txt, levels = GRADOS))
resultados <- read_csv(file.path(RUTAS$tablas, "medias_por_diseno.csv"), show_col_types = FALSE) |>
  mutate(grado_txt = factor(grado_txt, levels = GRADOS))
dominios <- read_csv(file.path(RUTAS$tablas, "dominios.csv"), show_col_types = FALSE) |>
  mutate(grado_txt = factor(grado_txt, levels = GRADOS))

tema <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), plot.title.position = "plot")
etiq_diseno <- c(ingenuo = "Ingenuo (sin pesos)", solo_pesos = "Solo pesos", completo = "Diseño completo")
colores <- c("Ingenuo (sin pesos)" = "#9AA5B1", "Solo pesos" = "#E39B3D", "Diseño completo" = "#0F5E7A")

# 1. Cuánto se subestima el error estándar al ignorar los conglomerados
g1 <- ggplot(comparacion, aes(x = razon_ee_completo_vs_pesos, y = grado_txt, color = nombre)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
  geom_point(size = 3) +
  labs(title = "Error estándar del diseño completo dividido para el de 'solo pesos'",
       subtitle = "Un valor de 2 significa que ignorar los conglomerados reporta la mitad de la incertidumbre real",
       x = "Razón de errores estándar", y = NULL, color = "Campo") +
  tema
ggsave(file.path(RUTAS$figuras, "razon_errores_estandar.png"), g1, width = 8, height = 4.5, dpi = 150)

# 2. Intervalos de confianza al 95 % de la media de Matemática según el diseño
g2 <- resultados |>
  filter(campo == "imat") |>
  mutate(diseno = factor(etiq_diseno[diseno], levels = etiq_diseno)) |>
  ggplot(aes(x = media, y = diseno, xmin = li, xmax = ls, color = diseno)) +
  geom_pointrange() +
  facet_wrap(~grado_txt, scales = "free_x", ncol = 2) +
  scale_color_manual(values = colores, guide = "none") +
  labs(title = "Media de Matemática e IC 95 % según cómo se declara la muestra",
       x = "Puntaje medio", y = NULL) +
  tema
ggsave(file.path(RUTAS$figuras, "ic_matematica_por_diseno.png"), g2, width = 8, height = 5, dpi = 150)

# 3. Brecha por sostenimiento (diseño completo), Matemática
g3 <- dominios |>
  filter(campo == "imat", dominio == "sostenimiento") |>
  ggplot(aes(x = media, y = categoria, xmin = li, xmax = ls)) +
  geom_pointrange(color = "#0F5E7A") +
  facet_wrap(~grado_txt, ncol = 2) +
  labs(title = "Matemática por sostenimiento de la institución (diseño completo, IC 95 %)",
       x = "Puntaje medio", y = NULL) +
  tema
ggsave(file.path(RUTAS$figuras, "matematica_por_sostenimiento.png"), g3, width = 8, height = 5, dpi = 150)
message("Figuras escritas en ", RUTAS$figuras)
