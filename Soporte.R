library(tidyverse)
library(odbc)
# library(pool)
library(DBI)
# library(dbplyr)
library(readxl)
library(arrow)

## Revisión Muestras
espectros <- "//158.30.27.240/Repositorio Lab/Informacion/FTIR/Scans"

## Conexión BD Modelos
mdb <- "datos/Chemometrics.mdb"
chemcon <- dbConnect(drv = odbc(), 
                     .connection_string = glue::glue("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                                     "-|mdb|-;", .open = "-|", .close = "|-"))


# Lectura Archivos --------------------------------------------------------

# Variable Generales ------------------------------------------------------

analisistit <- c("TAN", "TBN", "TBN47", "TBNIR7", "TBNIR", "TANIR", "DACIR", "DAC")

# Lectura Datos -----------------------------------------------------------
uoa_products <- read_parquet("datos/uoa_products.parquet")

modelos <- chemcon |>  #  read_excel("datos/Quant_Models.xlsx") |> 
  tbl("Quant_Models") |> 
  collect() |> 
  mutate(GroupID = str_to_upper(GroupID)) |>
  filter(GroupID == 'BOGOTA') |> 
  inner_join(uoa_products, by = c("Product_Number" = "PRODUCT_NUMBER")) |>
  select(PRODUCT_NAME, Product_Number, Model_Name, Type, F_Value_Limit)

# resultados <- read_parquet("datos/humedo.parquet", as_data_frame = FALSE) |>
#   mutate(
#     # MODEL = case_when(
#     # LUBRICANTNUMBER %in% modelos$Product_Number ~ TRUE,
#     # TRUE ~ FALSE
#     # ), 
#     YEAR = lubridate::year(SAMPLE_DATE_AUTHORISED)
#   )
failures <- read_csv("datos/2023_Chemometrics Failures.txt") 

ds <- open_dataset("datos/Resultados") |> 
  mutate(
    YEAR = lubridate::year(SAMPLE_DATE_AUTHORISED)
  )

# Muestras para quimiometría ----------------------------------------------
# limscon <- try(
#   dbPool(
#   drv = odbc(),
#   dsn = "BOXER",
#   UID = "lims",
#   PWD = "lims"
#   )
# )
# onStop(function() {
  
# })

# print("Conexión Exitosa")

# limscon <- dbConnect(odbc(), "BOXER", UID = "lims", PWD = "lims")


# Modelos Creadors --------------------------------------------------------
# if(!class(limscon) == 'try-error'){
  # product_name <- productos <- tbl(limscon, "UOA_PRODUCTS") |>
  #   select(PRODUCT_NUMBER, PRODUCT_NAME) |>
  #   collect()
  # write_parquet(product_name, "uoa_products.parquet")
  # 
  # modelos <- read_excel("Quant_Models.xlsx") |>
  #   mutate(GroupID = str_to_upper(GroupID)) |>
  #   filter(GroupID == 'BOGOTA') |>
  #   inner_join(product_name, by = c("Product_Number" = "PRODUCT_NUMBER")) |>
  #   select(PRODUCT_NAME, Product_Number, Model_Name, Type, F_Value_Limit)
  # 
  # # Descarga datos desde BD -------------------------------------------------
  # 
  # muestras <- tbl(limscon, "C_UOA_SAMPLE") |>
  #   select(SAMPLE, LUBRICANTNUMBER)
  # productos <- tbl(limscon, "UOA_PRODUCTS") |>
  #   select(PRODUCT_NUMBER, PRODUCT_NAME)
  # 
  # resultados <- tbl(limscon, in_schema("VGSM", "C_SAMP_TEST_RESULT")) |>
  #   filter(SAMPLE_DATE_AUTHORISED > "1/1/2022" & RESULT_TYPE %in% c("K", "N"))  |>
  #   select(ID_NUMERIC, SAMPLE_DATE_AUTHORISED, LOGIN_DATE, ID_TEXT, ANALYSIS, RESULT_VALUE) |>
  #   inner_join(muestras, by = c("ID_NUMERIC" = "SAMPLE")) |>
  #   inner_join(productos, by = c("LUBRICANTNUMBER" = "PRODUCT_NUMBER"))
  # 
  # resultados <- resultados |>
  #   collect() |>
  #   mutate(MODEL = case_when(
  #     LUBRICANTNUMBER %in% modelos$Product_Number ~ TRUE,
  #     TRUE ~ FALSE
  #   ))
  # 
  # write_parquet(resultados, "humedo.parquet")
#  } else{
#   resultados <- read_parquet("humedo.parquet") |> 
#     mutate(MODEL = case_when(
#       LUBRICANTNUMBER %in% modelos$Product_Number ~ TRUE,
#       TRUE ~ FALSE
#     ))
# }

# resultados <- read_parquet("humedo.parquet") |> 
#   mutate(MODEL = case_when(
#         LUBRICANTNUMBER %in% modelos$Product_Number ~ TRUE,
#         TRUE ~ FALSE
#       ), YEAR = lubridate::year(SAMPLE_DATE_AUTHORISED)
#   )

# pendientes <- resultados |> 
#   filter(ANALYSIS %in% c("TAN", "TBN", "TBN47") & MODEL == FALSE) |> 
#   count(ANALYSIS, PRODUCT_NAME, LUBRICANTNUMBER) |>
#   arrange(desc(n))





# readr::write_csv(total, "MuestrasQuimimetria.csv")

# archivos <- list.files("C:/Users/diego.martinez/Downloads/52036", ".sp")
# archivos <- sample(archivos, 620)
# 
# muestras <- str_extract(archivos, "(.{0,8}$)")
# file.copy(file.path("C:/Users/diego.martinez/Downloads/52036",archivos),
#           file.path("C:/Users/diego.martinez/Downloads/52036/validacion",muestras))
# file.remove(file.path("C:/Users/diego.martinez/Downloads/52036",archivos))
# validacion <-  tibble(archivos = archivos, muestras = str_ex)
  # poolClose(limscon)

# ds_data <- ds |>
#   filter(YEAR == 2024 & ANALYSIS == 'TBN47' & LUBRICANTNUMBER == '40074') |>
#   collect()
# ds_data |>
#   ggplot(aes(y = ANALYSIS, x = RESULT_VALUE)) +
#   geom_boxplot(width = 0.2, colour = "#1C86EE") +
#   ggdist::stat_dist_halfeye(adjust = .3, position = position_nudge(y= 0.15),
#                             fill = "deepskyblue", alpha = 0.5) +
#   theme(panel.border = element_rect(colour = "grey70", fill = NA), 
#         panel.grid = element_line(colour = "grey88", linetype = 3))
