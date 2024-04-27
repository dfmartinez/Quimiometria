#
# library(dplyr)
# library(tidyr)
# library(readr)
# library(readxl)
# library(stringr)
# library(arrow)
# library(profvis)
library(patchwork)

source("Soporte.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  pendientes <- reactive({
    ds |> # resultados |>
      filter(ANALYSIS %in% c("TAN", "TBN", "TBN47") & YEAR %in% input$filtroano & MODEL == FALSE) |>
      # to_duckdb() |>
      # mutate(YEAR = year(SAMPLE_DATE_AUTHORISED)) |>
      group_by(ANALYSIS, PRODUCT_NAME, LUBRICANTNUMBER) 
    # |>
    #   # summarise(PRODUCT_NAME = n())
    #   collect()
  })
#  
  modelados <- reactive({
    ds |> # resultados |>
      filter(YEAR %in% input$filtroano & MODEL == TRUE) |>
      # to_duckdb() |>
      mutate(TEST = case_when(
          str_detect(ANALYSIS, "TAN") ~ "AN",
          str_detect(ANALYSIS, ".*7$") ~ "BN47",
          str_detect(ANALYSIS, "DAC") ~ "DAC",
          str_detect(ANALYSIS, "TBN") ~ "BN28",
          TRUE ~ ANALYSIS
      ))
  })
#     
  output$creargraf <- renderEcharts4r({
     pendientes()  |>
      summarise(value = n()) |>
      select(-LUBRICANTNUMBER) |>
      collect() |>
      rename(name = PRODUCT_NAME) |>
      group_by(ANALYSIS) |>
      mutate(value2 = sum(value)) |>
      group_by(ANALYSIS, value2) |>
      nest(.key = "children") |>
      rename(name = ANALYSIS, value = value2) |>
      ungroup() |>
      e_charts() |>
      e_sunburst(label = list(fontSize = 10), itemStyle = list(borderRadius= 7, borderWidth= 2)) |>
      e_tooltip()
  })
  output$creartabla <- renderReactable({
    pendientes()  |>
      # unite("PRODUCT",c(LUBRICANTNUMBER,PRODUCT_NAME)) |>
      count(sort = TRUE, name = "SAMPLES") |>
      collect() |>
      # slice_head(n = 10) |>
      reactable(searchable = TRUE, selection = "single", onClick = "select")
  })
  output$modelograf <- renderEcharts4r({
     modelos |>
      count(Type) |>
      e_charts(Type) |>
      e_pie(n, roseType = "radius", itemStyle = list(borderRadius = 5)) |>
      e_tooltip()
  })
  output$reportemodelo <- renderEcharts4r({
    modelados() |>
      filter(str_detect(ANALYSIS, "IR")) |>
      count(ANALYSIS) |>
      collect() |>
      # mutate(n = n/sum(n)) |>
      # group_by(TEST) |>
      # summarise(Reporte = round(n/sum(n)*100, digits = 1)) |>
      e_charts(ANALYSIS) |>
      e_pie(n, roseType = "radius", itemStyle = list(borderRadius = 5)) |>
      e_tooltip(
        # formatter = e_tooltip_item_formatter(style = "percent", digits = 1)
        # htmlwidgets::JS("
        #                             function(params){
        #                                 return('<strong>' + params.name +
        #                                 '</strong><br />' + value[0] +
        #                                 '<br />' +  value[1]  )   }
        #                             ")
      )
  })
  output$modelotabla <- renderReactable({
    modelados() |>
      filter(ANALYSIS %in% analisistit) |>
    count(ANALYSIS, LUBRICANTNUMBER, PRODUCT_NAME, TEST) |>
      collect() |>
      # group_by(TEST, LUBRICANTNUMBER) |>
      unite("LUBRICANT", LUBRICANTNUMBER:PRODUCT_NAME) |>
      mutate(TipoA = case_when(
        str_detect(ANALYSIS, "IR") ~ "FTIR",
        TRUE ~ "Titulación"
      )) |>
      select(-ANALYSIS) |>
      pivot_wider(names_from = TipoA, values_from = n, values_fill = 0) |>
      group_by(TEST, LUBRICANT) |>
      summarise(`% Reporte` = round(FTIR/sum(FTIR, `Titulación`),digits = 1), FTIR = FTIR,
                `Titulación` = `Titulación`) |>
      relocate(`% Reporte`, .after = `Titulación`) |>
      reactable(
        searchable = TRUE,
        groupBy = "TEST",
        columns = list(
          FTIR = colDef(aggregate = "sum"),
          `Titulación` = colDef(aggregate = "sum"),
          `% Reporte` = colDef(aggregate = "mean", format = colFormat(digits = 1, percent = TRUE))
        )
      )
  })
# 
#   
# 
# # Rechazos Quimiometría ---------------------------------------------------

output$failure_graf <- renderEcharts4r({
  failures |>
    count(Test) |>
    arrange(n) |>
    e_charts(Test) |>
    e_pie(n, roseType = "radius", itemStyle = list(borderRadius = 5)) |>
    e_tooltip()
})
# 
output$faildist <- renderEcharts4r({
  failures |>
    separate_longer_delim(`Failure Reasons`, "|") |>
    count(Test, `Failure Reasons`) |>
    arrange(n) |>
    # group_by(Test) |>
    e_charts(`Failure Reasons`) |>
    e_pie(n, roseType = "radius",  itemStyle = list(borderRadius = 5)) |>
    e_tooltip()
})
output$failure_res <- renderReactable({
  failures |>
    separate_longer_delim(`Failure Reasons`, "|") |>
    count(Test, Model, `Failure Reasons`, name = "#Failures") |> 
    reactable(
      groupBy = c("Test", "Model"),
      columns = list(
        Model = colDef(aggregate = "unique"),
        `Failure Reasons` = colDef(aggregate = "unique"),
        `#Failures` = colDef(aggregate = "sum")
      )
    )
})

# # Creación Carpetas y Copia Espectros -------------------------------------
res_humedo <- reactive({
  ds |> # resultados |>
    filter(YEAR %in% input$filtroano  &
             ANALYSIS %in% c(!!input$propiedad, "OXID", "SOOT", "WATER", "OXID3P", "SOOT3P", "WATER3P"))  |>
    select(ID_NUMERIC, LOGIN_DATE, ID_TEXT, ANALYSIS, RESULT_VALUE, LUBRICANTNUMBER, PRODUCT_NAME) |>
    # inner_join(productos(), by = c("ID_NUMERIC" = "SAMPLE")) |>
    collect() |>
    mutate(IdEspectro = str_sub(ID_TEXT, start = -6))
})
datomodelo <- reactive(
  {
    model <- getReactableState("creartabla", name = "selected")
    if(is.null(model)){
      return(NULL)
    } else{
      pendientes()  |>
        count(sort = TRUE, name = "SAMPLES") |>
        collect() |>
        ungroup() |>
        slice(model)
    }

   })

  bindEvent(observe({
    updateSelectizeInput(inputId = "producto", choices = datomodelo()$LUBRICANTNUMBER)
    updateSelectInput(inputId = "year", choices = input$filtroano)
    updateSelectizeInput(inputId = "propiedad", selected = datomodelo()$ANALYSIS)
  }),
  datomodelo(), ignoreInit = TRUE)

observeEvent(input$crear,
             {
               purrr::walk(input$filtroano, ~ {
                 # browser()
                 dirmodelo <- file.path("Modelos", input$nmodelo, "modelo", "original")
                 dirvalida <- file.path("Modelos", input$nmodelo, "validacion", "original")
                 if(!dir.exists(dirmodelo)){
                   dir.create(dirmodelo, recursive = TRUE)
                 }
                 if(!dir.exists(dirvalida)){
                   dir.create(dirvalida, recursive = TRUE)
                 }

                 espectro_total <- list.files(file.path(espectros, .x, input$producto), ".sp")
                 # datos <- resultados() |> mutate(Espectro = paste0(ID_TEXT, ".sp"))
                 # espectro_total <- res_humedo() |> pull(ID_TEXT)
                 espectro_modelo <- sample(espectro_total, length(espectro_total)*0.7)
                 espectro_val <- base::setdiff(espectro_total, espectro_modelo)


                 file.copy(file.path(espectros, .x, input$producto, espectro_modelo), # paste0(espectro_modelo, ".sp")
                           dirmodelo)
                 file.copy(file.path("Modelos", input$nmodelo, "modelo", "original", espectro_modelo), # paste0(espectro_modelo, ".sp")
                           file.path(dirname(dirmodelo), str_sub(espectro_modelo, start = 5)) #paste0(str_sub(espectro_modelo, start = ),".sp")
                 )
                 file.copy(
                   file.path(espectros, .x, input$producto, espectro_val), #paste0(espectro_val, ".sp")
                   dirvalida
                 )
                 file.copy(file.path(dirvalida, espectro_val), #paste0(espectro_val, ".sp")
                           file.path(dirname(dirvalida), str_sub(espectro_val, start = 5)) #paste0(str_sub(espectro_val, start = -6), ".sp")
                 )

                 espectro_modelo <- list.files(dirmodelo, ".sp") |>
                   str_extract("[^/]*(?=\\.[^.]+($|\\?))")
                 exportar <- tribble(~ "muestra", ~ "idmuestra", ~ "resultado", ~ "normalizacion",
                                     "VALIDATn" , "Property", "Property_1", "NORMALIZATn",
                                     "FULL" , "STANDARDS", "mgKOH", "FACTOR")
                 temp_export <- res_humedo() |>
                   filter(ID_TEXT %in% espectro_modelo & ANALYSIS == input$propiedad) |>
                   dplyr::distinct(IdEspectro, .keep_all = TRUE) |> 
                   mutate(idmuestra = str_sub(ID_TEXT, start = -6), muestra = as.character(row_number()),
                          normalizacion = as.character(1L), resultado = as.character(RESULT_VALUE)) |>
                   select(muestra, idmuestra, resultado, normalizacion)
                 exportar <- bind_rows(exportar, temp_export)

                 write_excel_csv(exportar,
                                 file.path(dirname(dirmodelo), "Modelado.csv"),  
                                 col_names = FALSE, append = TRUE
                 )
                 espectro_val <- list.files(dirvalida, ".sp") |>
                   str_extract("[^/]*(?=\\.[^.]+($|\\?))")
                 exportar <- res_humedo() |>
                   filter(ID_TEXT %in% espectro_val) |> 
                   distinct(IdEspectro, .keep_all = TRUE) |> 
                 write_excel_csv(
                   exportar,
                   file.path(dirname(dirvalida), "validacion.csv", append = TRUE)
                 )
               })
               # browser()
             }
)

# 
  output$histograma <- renderPlot({
    req(input$producto)
    tema <- theme(axis.title.y = element_blank(), axis.ticks.y = element_blank(),
                          axis.text.y = element_blank(), panel.background = element_blank(), 
                          # panel.border = element_rect(colour = "white", fill = NA), 
                  panel.border = element_rect(colour = "grey70", fill = NA), 
                  panel.grid.major.x = element_line(colour = "grey88", linetype = 2))

    datos <- res_humedo() |>
      filter(ANALYSIS == input$propiedad & LUBRICANTNUMBER == input$producto) |>
      ungroup()
    p1 <- datos |> 
      ggplot(aes(y = ANALYSIS, x = RESULT_VALUE)) +
      geom_boxplot(width = 0.2, colour = "#1C86EE") +
      ggdist::stat_dist_halfeye(adjust = .3, position = position_nudge(y= 0.12), 
                                fill = "deepskyblue", alpha = 0.5) +
      tema
    p2 <- datos |> 
      ggplot(aes(RESULT_VALUE)) +
      geom_boxplot(colour = "#1C86EE", fill = "deepskyblue") + 
      labs(x = "RESULTADOS") +
      tema
    
    # p2/p1
    p1
    
      # e_histogram(RESULT_VALUE) |>
      # e_tooltip()
  }, res = 96)
  output$modelotbl <- renderReactable({
    req(input$producto)
    
    res_humedo() |>
      filter(ANALYSIS == input$propiedad & LUBRICANTNUMBER == input$producto) |>
      ungroup() |> 
      summarise(Media = mean(RESULT_VALUE, rm.na = TRUE), Desviacion = sd(RESULT_VALUE), 
                Muestras = n(), `Máximo` = max(RESULT_VALUE), `Mínimo` = 
                  min(RESULT_VALUE)) |>
      mutate(across(everything(), \(x) round(x, digits = 2)))
      pivot_longer(Media:`Mínimo`, names_to = "Propiedad", values_to = "Resultado") |> 
      reactable()
  })
  # output$media <- renderInfoBox({
  #   datos <- res_humedo() |>
  #     filter(ANALYSIS == input$propiedad & LUBRICANTNUMBER == input$producto) |>
  #     ungroup() |> 
  #     pull(RESULT_VALUE) |> 
  #     summary()
  #   
  #   infoBox(value = datos["Min."])
  # })
#   output$estadistica <- renderReactable({
#     req(input$producto)
#     
#     res_humedo() |> 
#       filter(LUBRICANTNUMBER == input$producto & ANALYSIS == input$propiedad) |> 
#       mutate(Media = mean(RESULT_VALUE, na.rm = TRUE),
#              Mediana = median(RESULT_VALUE, na.rm = TRUE),
#              Minimo = min(RESULT_VALUE),
#              Maximo = max(RESULT_VALUE)) |> 
#       pivot_longer(Media:Maximo, values_to = "Valor", names_to = "Estadístico") |>
#       # pull(RESULT_VALUE) |>
#       # summary() |> 
#       reactable()
#   })

  # output$prueba <- renderPrint({
  #   failures |> 
  #     separate_longer_delim(`Failure Reasons`, "|")
  # })
})
