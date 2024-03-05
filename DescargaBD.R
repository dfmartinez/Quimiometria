##
## Lectura Muestras desde BD
## Guardar en Archivo local
##

library(tidyverse)
library(lubridate)
library(odbc)
library(pool)
library(DBI)
library(dbplyr)
library(arrow)
library(readxl)


# Muestras para quimiometría ----------------------------------------------
 limscon <- try(
   dbPool(
   drv = odbc(),
   dsn = "BOXER",
   UID = "lims",
   PWD = "lims"
   )
 )
 

 ## Conexión BD Modelos
 mdb <- "//158.30.27.240/Repositorio Lab/Informacion/SoftwareUpdates/Chemometrics.mdb"
 chemcon <- dbConnect(drv = odbc(), 
                      .connection_string = glue::glue("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                                      "-|mdb|-;", .open = "-|", .close = "|-"))

 
# Modelos Creadors --------------------------------------------------------
if(class(limscon)[[1]] == 'try-error') {
  print("No se pudo establecer conexión a la BD")
  stop("Error conexión")
}
  
 print("Conectado a la BD de Oracle")
 
product_name <- productos <- tbl(limscon, "UOA_PRODUCTS") |>
  select(PRODUCT_NUMBER, PRODUCT_NAME) |>
  collect()

write_parquet(product_name, "datos/uoa_products.parquet")

print("Tabla de productos guardada")
#
# modelos <- read_excel("datos/Quant_Models.xlsx") |>
#   mutate(GroupID = str_to_upper(GroupID)) |>
#   filter(GroupID == 'BOGOTA') |>
#   inner_join(product_name, by = c("Product_Number" = "PRODUCT_NUMBER")) |>
#   select(PRODUCT_NAME, Product_Number, Model_Name, Type, F_Value_Limit)
modelos <- chemcon |>  #  read_excel("datos/Quant_Models.xlsx") |> 
  tbl("Quant_Models") |> 
  collect() |> 
  mutate(GroupID = str_to_upper(GroupID)) |>
  filter(GroupID == 'BOGOTA') |> 
  inner_join(product_name, by = c("Product_Number" = "PRODUCT_NUMBER")) |>
  select(PRODUCT_NAME, Product_Number, Model_Name, Type, F_Value_Limit)

print("Modelos Quimiométricos Actualizados")

# Descarga datos desde BD -------------------------------------------------

print(glue::glue( "Datos para el año: {year(Sys.Date())}"))

muestras <- tbl(limscon, "C_UOA_SAMPLE") |>
  select(SAMPLE, LUBRICANTNUMBER)


productos <- tbl(limscon, "UOA_PRODUCTS") |>
  select(PRODUCT_NUMBER, PRODUCT_NAME)

resultados <- tbl(limscon, in_schema("VGSM", "C_SAMP_TEST_RESULT")) |>
  filter(SAMPLE_DATE_AUTHORISED > glue::glue("01/01/{year(Sys.Date())}") & SAMPLE_DATE_AUTHORISED < glue::glue("01/01/{year(Sys.Date()) + 1}") 
         & RESULT_TYPE %in% c("K", "N"))  |>
  select(ID_NUMERIC, SAMPLE_DATE_AUTHORISED, LOGIN_DATE, ID_TEXT, ANALYSIS, RESULT_VALUE) |>
  inner_join(muestras, by = c("ID_NUMERIC" = "SAMPLE")) |>
  inner_join(productos, by = c("LUBRICANTNUMBER" = "PRODUCT_NUMBER"))

print(glue::glue("{nrow(resultados)} Resultados descargados ..."))

resultados <- resultados |>
  collect() |>
  mutate(MODEL = case_when(
    LUBRICANTNUMBER %in% modelos$Product_Number ~ TRUE,
    TRUE ~ FALSE
  ))

print("Resultados Descargados")

write_parquet(resultados, glue::glue("datos/Resultados/Resultados_{year(Sys.Date())}.parquet"))

print("Archivo parquet Creado")

file.copy(file.path("//158.30.27.240/Repositorio Lab/Informacion/SoftwareUpdates/Rechazos", 
                    glue::glue("{year(Sys.Date())}_Chemometrics Failures.txt")), "datos", overwrite = TRUE)

print("Archivo de rechazos copiado")

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

print("¡FIN!")
poolClose(limscon)