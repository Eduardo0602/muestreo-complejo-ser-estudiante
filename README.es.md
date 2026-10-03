<p align="right"><a href="README.md">English</a> · <b>Español</b></p>

# ¿Cuánto se equivoca quien ignora el diseño muestral? Evidencia con la evaluación Ser Estudiante del Ecuador

Análisis en R de los microdatos oficiales de **Ser Estudiante 2024-2025** (Ineval, 50 578 estudiantes, 1 197 instituciones) que compara tres formas de declarar la misma muestra y muestra, con las fórmulas y verificaciones a mano, por qué solo una de ellas es correcta.

[![verificaciones](https://github.com/Eduardo0602/muestreo-complejo-ser-estudiante/actions/workflows/verificaciones.yml/badge.svg)](https://github.com/Eduardo0602/muestreo-complejo-ser-estudiante/actions/workflows/verificaciones.yml) ![R](https://img.shields.io/badge/R-4.5-276DC3?logo=r&logoColor=white) ![survey](https://img.shields.io/badge/survey-4.5-0F5E7A) ![tidyverse](https://img.shields.io/badge/tidyverse-1A162D?logo=tidyverse) ![renv](https://img.shields.io/badge/renv-bloqueado-7A1F2B) ![Licencia](https://img.shields.io/badge/licencia-MIT-green)

## El problema

La evaluación Ser Estudiante no es una muestra aleatoria simple. Según la ficha metodológica del Ineval, es un diseño **probabilístico, estratificado y bietápico**: primero se seleccionan instituciones educativas (con probabilidad proporcional al tamaño) dentro de 16 estratos (régimen × área × sostenimiento) y luego hasta 35 estudiantes por institución y nivel. Cada estudiante trae un **factor de expansión** por campo evaluado.

Es común analizar estos datos de dos formas incorrectas:

| Forma | Qué hace | Qué ignora |
|---|---|---|
| **Ingenua** | Promedio simple de la muestra | Los pesos y el diseño |
| **Solo pesos** | Usa el factor de expansión, cada estudiante como unidad independiente | Que los estudiantes vienen agrupados en instituciones y estratos |
| **Diseño completo** | Estratos, conglomerados (`amie`) y pesos | Nada esencial (ver Limitaciones) |

Pregunta: **¿cuánto cambian la estimación y su incertidumbre según la forma elegida?**

## Datos

Instituto Nacional de Evaluación Educativa (Ineval), *Ser Estudiante 2024-2025*, publicado el 15 de diciembre de 2025 en el [portal de datos abiertos del Ecuador](https://www.datosabiertos.gob.ec/dataset/da1aeddc-3bd6-4399-a840-2f5ec67ba64e). Los datos **no se incluyen** en este repositorio: el script los descarga de la fuente oficial. Los códigos anónimos de estudiante cambian entre descargas, pero las estimaciones no.

## Fundamento matemático

Sea $`U`$ la población de $`N`$ estudiantes y $`y_k`$ el puntaje del estudiante $`k`$. El parámetro es la media poblacional $`\bar{Y} = \frac{1}{N}\sum_{k\in U} y_k`$. Cada estudiante de la muestra $`s`$ tiene un peso $`w_k`$ (el factor de expansión: el inverso de su probabilidad de inclusión, ajustado por no respuesta).

**Estimadores.** El estimador de Horvitz–Thompson del total y del tamaño poblacional, y el de Hájek de la media, son

```math
\hat{Y} = \sum_{k\in s} w_k\, y_k, \qquad \hat{N} = \sum_{k\in s} w_k, \qquad \bar{y}_w = \frac{\hat{Y}}{\hat{N}}.
```

$`\bar{y}_w`$ es un cociente de dos estimadores insesgados, por lo que no es insesgado, pero es consistente y es el que usa `svymean`. Los modos *solo pesos* y *diseño completo* dan **exactamente la misma estimación puntual**; difieren solo en la varianza.

**Varianza por linealización.** Una expansión de Taylor de primer orden del cociente da $`\bar{y}_w - \bar{Y} \approx \frac{1}{N}\sum_{k\in s} w_k (y_k - \bar{Y})`$. Con $`u_k = w_k (y_k - \bar{y}_w)/\hat{N}`$ y $`z_{hi}`$ la suma de los $`u_k`$ de la institución $`i`$ del estrato $`h`$, el estimador de varianza (instituciones tratadas como seleccionadas con reemplazo dentro de cada estrato) es

```math
\hat{V}(\bar{y}_w) = \sum_{h=1}^{H} \frac{n_h}{n_h - 1} \sum_{i=1}^{n_h} \left(z_{hi} - \bar{z}_h\right)^2,
```

donde $`n_h`$ es el número de instituciones del estrato $`h`$. El modo *solo pesos* es el caso particular $`H = 1`$ con cada estudiante como su propia "institución", y el ingenuo es $`s^2/n`$.

**Efecto de diseño.** $`\text{DEFF} = \hat{V}_{\text{diseño}} / \hat{V}_{\text{MAS}}`$ mide cuántas veces más varianza tiene el diseño frente a un muestreo aleatorio simple del mismo tamaño, y $`n_{\text{ef}} = n / \text{DEFF}`$ es el tamaño de muestra "equivalente". La aproximación de Kish separa sus dos causas:

```math
\text{DEFF} \approx \underbrace{\left(1 + \text{CV}_w^2\right)}_{\text{pesos desiguales}} \times \underbrace{\left(1 + (\bar{m} - 1)\,\rho\right)}_{\text{conglomerados}},
```

con $`\bar{m}`$ estudiantes por institución y $`\rho`$ la correlación intraclase: cuánto se parecen entre sí los estudiantes de una misma institución.

## Resultados

**1. Sin pesos, la media está sesgada.** El área rural está sobrerrepresentada en la muestra (34,88 % de la muestra frente a 20,12 % de la población estimada). La media ingenua supera a la ponderada entre **+0,4744 y +10,2424 puntos** según grado y campo.

**2. Sin conglomerados, la incertidumbre se subestima de 1,8 a 3,8 veces.** El error estándar del diseño completo es entre **1,7843 y 3,7558 veces** el que se obtiene declarando solo pesos.

![Razón de errores estándar](outputs/figuras/razon_errores_estandar.png)

Ejemplo, Matemática de 4.º EGB (12 129 estudiantes en 426 instituciones):

| Forma | Media | Error estándar | IC 95 % |
|---|---:|---:|---|
| Ingenua | 678,43243 | 0,55563 | [677,34331; 679,52156] |
| Solo pesos | 671,64233 | 0,87174 | [669,93359; 673,35107] |
| **Diseño completo** | **671,64233** | **3,10976** | **[665,52927; 677,75540]** |

El intervalo correcto es 3,57 veces más ancho que el de "solo pesos", y el ingenuo ni siquiera contiene la estimación correcta.

![IC por diseño](outputs/figuras/ic_matematica_por_diseno.png)

**3. ¿Por qué tanto?** En 4.º EGB el efecto de diseño completo llega a 32,64 en Matemática (hasta 38,44 en Ciencias Naturales): los 12 129 estudiantes equivalen a unos **372 elegidos al azar**. Despejando la aproximación de Kish, la correlación intraclase es $`\hat{\rho} \approx 0{,}43`$ (0,42683 redondeado a 2 decimales): los estudiantes de una misma institución se parecen mucho, así que cada institución adicional aporta mucha más información que cada estudiante adicional. En 10.º EGB y bachillerato $`\hat{\rho}`$ baja a valores entre 0,0698 y 0,1639 (aproximación, ver Limitaciones).

**4. Comparaciones entre dominios con la incertidumbre correcta.** Por ejemplo, en Matemática de 4.º EGB las instituciones particulares (692,49; IC 95 % [686,53; 698,45]) superan a las fiscales (665,58; [657,55; 673,61]). Con el diseño completo los intervalos siguen sin superponerse; en ese mismo grado y campo, las comparaciones por área y por régimen tienen intervalos que sí se superponen y no permiten afirmar diferencias.

![Matemática por sostenimiento](outputs/figuras/matematica_por_sostenimiento.png)

Todas las tablas están en [`outputs/tablas/`](outputs/tablas/): medias por diseño, comparación, dominios, niveles de logro y verificaciones.

## Verificación

[`R/05_verificaciones.R`](R/05_verificaciones.R) recalcula desde cero, para cada grado y campo, la media de Hájek, el error estándar de los tres diseños con la fórmula de arriba y la ausencia de estratos con una sola institución, y detiene el análisis si algo no coincide con `survey`: **98 de 98 comprobaciones correctas**. Un [flujo de GitHub Actions](.github/workflows/verificaciones.yml) repite todo en un equipo limpio, con las versiones exactas de los paquetes, en cada cambio y el día 1 de cada mes.

## Cómo reproducir

```r
# En R 4.5, desde la raíz del proyecto (o abriendo el .Rproj en RStudio):
install.packages("renv")
renv::restore()            # instala las versiones exactas de renv.lock
source("R/99_run_all.R")   # descarga los datos oficiales y genera tablas y figuras (~1 min)
```

| Script | Qué hace |
|---|---|
| `00_setup.R` | Paquetes, rutas, campos y grados |
| `01_descargar_datos.R` | Descarga el CSV oficial y verifica columnas y registros |
| `02_importar.R` | Lee, etiqueta con el diccionario oficial y construye los estratos |
| `03_disenos.R` | Declara los tres diseños |
| `04_estimaciones.R` | Medias, errores estándar, DEFF, dominios y niveles de logro |
| `05_verificaciones.R` | Recalcula todo a mano |
| `06_figuras.R` | Figuras |

## Estructura del proyecto

```
muestreo-complejo-ser-estudiante/
├── R/                    # 00 → 06 y 99_run_all.R
├── outputs/tablas/       # resultados en CSV (incluye verificaciones.csv)
├── outputs/figuras/      # 3 figuras
├── data/                 # se crea al ejecutar (no se versiona)
├── renv.lock             # versiones exactas de los paquetes
├── .github/workflows/    # verificación automática
├── muestreo-complejo-ser-estudiante.Rproj
└── LICENSE
```

## Limitaciones

- La varianza trata a las instituciones como seleccionadas **con reemplazo** y no usa la corrección por población finita ni la selección proporcional al tamaño exacta: es la aproximación estándar cuando no se publican las probabilidades de cada etapa y suele ser algo conservadora.
- Los factores de expansión ya incluyen ajustes por no respuesta que no se pueden replicar sin información adicional del Ineval; aquí se toman como dados.
- La descomposición de Kish es una aproximación; $`\hat{\rho}`$ debe leerse como orden de magnitud, no como estimación exacta.
- Por recomendación del Ineval se analiza cada campo con su propio factor y no se usa el promedio global.

## Lo que aprendí

- Los pesos y el diseño resuelven problemas distintos: los pesos corrigen el **sesgo**, los conglomerados y estratos corrigen la **varianza**. Usar solo pesos da una estimación puntual correcta con una precisión ficticia.
- Un DEFF de 30 significa que miles de observaciones valen como unos cientos: la unidad que aporta información es la institución, no el estudiante.
- Verificar cada salida de `survey` contra su fórmula es la mejor forma de entender qué hace el paquete (y de detectar un diseño mal declarado).

---

### Portafolio *De Matemático a Data Scientist*

| Proyecto | Pregunta | Herramientas |
|---|---|---|
| **Muestreo complejo con Ser Estudiante** (este repositorio) | ¿Cuánto se equivoca quien ignora el diseño muestral? | R, survey |
| [EDA con datos sucios: defunciones 2021](https://github.com/Eduardo0602/eda-limpieza-defunciones-ecuador-pandas-sql/blob/master/README.es.md) | ¿Qué hay que corregir antes de confiar en un registro oficial? | Python, pandas, SQL |
| [Regresión lineal desde cero](https://github.com/Eduardo0602/regresion-lineal-numpy-desde-cero/blob/main/README.es.md) | ¿Puede un plano predecir la profundidad de los sismos de Ecuador? | Python, NumPy |
| [Álgebra lineal visual](https://github.com/Eduardo0602/algebra-lineal-visual-numpy/blob/main/README.es.md) | ¿Qué hace geométricamente una matriz? | Python, NumPy |

Eduardo Araque · Matemático (Universidad Central del Ecuador) · [GitHub](https://github.com/Eduardo0602) · [LinkedIn](https://www.linkedin.com/in/eduardo-araque-j%C3%A1come-311b93235)
