#

library(shiny)
library(bslib)
library(bsicons)
# library(bs4Dash)
# library(shinycssloaders)
library(echarts4r)
library(reactable)
library(lubridate)



# Funciones para manejo archivos ------------------------------------------

# copiaespectro <- function(ruta, tipo){
#   
# }

page_navbar(
  title = "Creación Modelos Quimiométricos",
  underline = TRUE,
  collapsible = FALSE,
  fillable = FALSE,
  sidebar = sidebar(
    title = "Escala de Tiempo",
    accordion(
      accordion_panel(
        title = "Seleccionar el Año",
        selectizeInput("filtroano", "Seleccionar el Año para Mostrar",
                       choices = seq(2020, year(Sys.Date())),
                       selected = year(Sys.Date()),  multiple = TRUE)
      ),
      accordion_panel(
        title = "Datos Modelo",
        selectizeInput("producto", "Ingresar el número de Producto", choices = NULL),
        selectizeInput("propiedad", label = "Seleccionar el Método a Modelar", choices = c("TAN", "TBN", "TBN47"), selected = NULL),
        selectizeInput("year", "Ingresar el año para el que se recolectan los espectros", choices = NULL),
        textInput("nmodelo", "Ingresar el nombre del Modelo"),
        nav_spacer(),
        actionButton("crear", "Obtener Datos", icon("pen-to-square"))
      )
    )
  ),
  nav_panel("Estadísticas Modelos",
    layout_column_wrap(
      card(
          verbatimTextOutput("prueba")
      )
    ),
    layout_column_wrap(
      heights_equal = "row",
      height = 800,
      card(
        # fill = FALSE,
        card_title("Distribución Análisis Húmedos"),
        echarts4rOutput(
          "creargraf"
        )
      ),
      card(
        card_title("Productos para Modelar"),
        reactableOutput("creartabla")
      )
    ), 
    layout_column_wrap(
      heights_equal = "row",
      card(
        card_title("Modelos Creados"),
        echarts4rOutput("modelograf")
      ),
      card(
        card_title("Reportabilidad Modelos"),
        echarts4rOutput("reportemodelo")
      )
    ),
    card(
      # min_height = 600,
      card_title("Modelos Creados por Análisis"),
      reactableOutput("modelotabla")
    )
  ),
  nav_panel("Creación Modelos",
    layout_column_wrap(
      card(
        width = 3,
        card_title("Resumen Resultados"),
        reactableOutput("modelotbl")
      ),
      card(
        card_title("Distribución Resultados"),
        plotOutput("histograma")
      )
    )
  ),
  nav_panel("Validación Modelos",
    # layout_column_wrap(
    #   card(
    #     card_title("Archivos de Validación"),
    #     radioButtons("archivo", "Versión Quant", c("1.0", "2.0"), "1.0", TRUE),
    #     fileInput("archivovalida", "Seleccionar Archivo de Resultados", accept = ".csv")
    #   )
    # ),
    layout_column_wrap(
      card(
        card_title("Validación"),
        layout_sidebar(
          sidebar = sidebar(
            title = "Carga Archivo Validación",
            radioButtons("archivo", "Versión Quant", c("1.0", "2.0"), "1.0", TRUE),
            fileInput("archivovalida", "Seleccionar Archivo de Resultados", accept = ".csv")
          )
        ),
        # verbatimTextOutput("val")
        reactableOutput("dataval")
      )
    )
  )
)