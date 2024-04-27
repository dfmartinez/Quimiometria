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

# Define UI for application that draws a histogram
# dashboardPage(
#   dashboardHeader(
#     title = "Creación Modelos Quimiométricos"
#   ),
#   dashboardSidebar(
#     collapsed = FALSE,
#     sidebarMenu(
#       menuItem(
#         text = "Estadísticas Modelos",
#         tabName = "resumen",
#         icon = icon("chart-pie")
#       ),
#       menuItem(
#         text = "Estadísticas Rechazos",
#         tabName = "rechazos",
#         icon = icon("wrench")
#       ),
#       menuItem(
#         text = "Creación Modelo",
#         tabName = "params",
#         icon = icon("helmet-safety")
#       ),
#       menuItem(
#         text = "Validación Modelo",
#         tabName = "creacion",
#         icon = icon("circle-check")
#       ),
#       selectizeInput("filtroano", "Seleccionar el Año para Mostrar",
#                      choices = seq(2020, year(Sys.Date())),
#                      selected = year(Sys.Date()),  multiple = TRUE)
#     )
#   ),
#   dashboardBody(
#     tabItems(
#         tabItem(
#           tabName = "resumen",
#           navbarPage(
#             title = h2("Productos Candidatos para Creación de Modelos"),
#             id = "titulocreacion"
#           ),
#           fluidRow(
#             box(
#               title = "Distribución Análisis Húmedos",
#               echarts4rOutput(
#                   "creargraf"
#               )
#             ),
#             box(
#               title = "Productos para Modelar",
#               reactableOutput("creartabla")
#             )
#           ),
#           navbarPage(
#             title = h2("Modelos Creados")
#           ),
#           fluidRow(
#             box(title = "Número Modelos Creados por Análisis", solidHeader = TRUE, status = "warning",
#               echarts4rOutput("modelograf")
#             ),
#             box(
#               title = "Reportabilidad Modelos", solidHeader = TRUE, status = "warning",
#               echarts4rOutput("reportemodelo")
#             )
#           ),
#           fluidRow(
#             column(
#               width = 12,
#               reactableOutput("modelotabla")
#             )
#           )
#         ),
#       tabItem(
#         tabName = "rechazos",
#         tabsetPanel(
#       #     id = "failures",
#       #     selected = "Resumen",
#           tabPanel(
#             title = "Resumen",
#             fluidRow(
#               box(
#                 solidHeader = FALSE,
#                 title = "Rechazos por Análisis",
#                 echarts4rOutput("failure_graf")
#               ),
#               box(
#                 solidHeader = FALSE,
#                 title = "Distribución de Rechazos",
#                 echarts4rOutput("faildist")
#               )
#             ),
#             fluidRow(
#               column(
#                 width = 12,
#                 reactableOutput("failure_res")
#               )
#             )
#           )
#         )
#       ),
#         tabItem(
#           tabName = "params",
#           fluidRow(
#             # column( width=8,
#               box(
#                 title = "Datos Modelos",
#                 selectizeInput("producto", "Ingresar el número de Producto", choices = NULL),
#                 selectizeInput("propiedad", label = "Seleccionar el Método a Modelar", choices = c("TAN", "TBN", "TBN47"), selected = NULL),
#                 selectizeInput("year", "Ingresar el año para el que se recolectan los espectros", choices = NULL),
#                 textInput("nmodelo", "Ingresar el nombre del Modelo"),
#                 bs4Dash::actionButton("crear", "Obtener Datos", icon("pen-to-square"))
#               # )
#             ),
#             box(
#               title = "Distribución Resultados",
#               plotOutput("histograma")
#             ),
#             # box(
#             #   title = "Estadísticas",
#             #   reactable::reactableOutput("estadistica")
#             # )
#             fluidRow(
#               infoBoxOutput("media"),
#               infoBoxOutput("mediana"),
#               infoBoxOutput("max"),
#               infoBoxOutput("min")
#             )
#           )
#         ),
#       tabItem(
#         tabName = "creacion",
#         fluidPage(
#           title = "validación Métodos",
#           br(),
#           h1("Trabajo en proceso ...")
#         )
#       )
#     )
#     ,
#     fluidRow(
#       verbatimTextOutput("prueba")
#     )
#   )
# )
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
    layout_column_wrap(
      card(
        
      )
    )
  )
)