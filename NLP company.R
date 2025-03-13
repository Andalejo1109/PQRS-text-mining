#http://rpubs.com/LuizFelipeBrito/NLP_Text_Mining_001
#https://www.youtube.com/watch?v=m8r7WtZ0voQ


#--------------------------------------------------------------------------------------
# 1. Paso - Limpiar el area de trabajo
# -----------------------------------------------------------------------------------
rm(list = ls())   

# -----------------------------------------------------------------------------------
# 2. Paso - limpiar la consola
# -----------------------------------------------------------------------------------
cat("\014")      

# -----------------------------------------------------------------------------------
# 3. Paso - Los siguientes paquetes deben ser instalados.
#           Una vez instalados, comente con # las l?neas de c?digo.
# -----------------------------------------------------------------------------------
install.packages("dplyr")           # A Grammar of Data Manipulation
install.packages("ggplot2")         # Create Elegant Data Visualisations Using the Grammar of Graphics
install.packages("tidytext")        # Text Mining using 'dplyr', 'ggplot2', and Other Tidy Tools
install.packages("stringr")         # Simple, Consistent Wrappers for Common String Operations
install.packages("tidyr")           # Easily Tidy Data with 'spread()' and 'gather()' Functions
install.packages("wordcloud")       # Words Clouds
install.packages("reshape2")        # Flexibly Reshape Data: A Reboot of the Reshape Package
install.packages("hunspell")        # High-Performace Stemmer, Tokenizer, and Spell Checker
install.packages("SnowballC")       # Stemmer based on the C 'libstemmer' UTF-8 Library
install.packages("textdata") 
install.packages("readxl") 
install.packages("RColorBrewer") 


# -----------------------------------------------------------------------------------
# 4. Paso - Cargar las librarias.
# -----------------------------------------------------------------------------------
library(dplyr)           # A Grammar of Data Manipulation
library(ggplot2)         # Create Elegant Data Visualisations Using the Grammar of Graphics
library(tidytext)        # Text Mining using 'dplyr', 'ggplot2', and Other Tidy Tools
library(stringr)         # Simple, Consistent Wrappers for Common String Operations
library(tidyr)           # Easily Tidy Data with 'spread()' and 'gather()' Functions
library(RColorBrewer)
library(wordcloud)       # Words Clouds
library(reshape2)        # Flexibly Reshape Data: A Reboot of the Reshape Package
library(hunspell)        # High-Performace Stemmer, Tokenizer, and Spell Checker
library(SnowballC)       # Stemmer based on the C 'libstemmer' UTF-8 Library
library(readxl)
library(textdata)
library(stringi)

# -----------------------------------------------------------------------------------
# 5. Paso - Defina el directorio de trabajo.
# -----------------------------------------------------------------------------------
setwd("D:/QCSCONS5/Desktop/Personal/Text_Mining")

# -----------------------------------------------------------------------------------
# 6. Paso - lea la base de datos.
# -----------------------------------------------------------------------------------

Homologaciones_PQRS_Salud_1_ <- read_excel("D:/QCSCONS5/Downloads/Homologaciones PQRS Salud (1).xlsx")
View(Homologaciones_PQRS_Salud_1_)

# -----------------------------------------------------------------------------------
# 7. Paso - Sólo utilizamos 4 atributos.
#           mantenemos las otras columnas para los analisis.
# -----------------------------------------------------------------------------------
names(Homologaciones_PQRS_Salud_1_)[names(Homologaciones_PQRS_Salud_1_) == "Número Radicado"]      <- "id_radicado"
names(Homologaciones_PQRS_Salud_1_)[names(Homologaciones_PQRS_Salud_1_) == "Contenido de la PQRS"] <- "text_PQRS"
names(Homologaciones_PQRS_Salud_1_)[names(Homologaciones_PQRS_Salud_1_) == "Motivo Solicitud"]    <- "Motivo"
names(Homologaciones_PQRS_Salud_1_)[names(Homologaciones_PQRS_Salud_1_) == "Asunto Solicitud"]    <- "Asunto"

Homologaciones_PQRS_Salud_1_ <- Homologaciones_PQRS_Salud_1_ %>% select(id_radicado, text_PQRS, Motivo, Asunto)

# -----------------------------------------------------------------------------------
# 8. Paso - Preprocesamiento de texto
#           
# -----------------------------------------------------------------------------------

cleaned_text <- Homologaciones_PQRS_Salud_1_ %>%
  filter(str_detect(Homologaciones_PQRS_Salud_1_, "^[^>]+[A-Za-z\\d]") | text_PQRS !="") 

cleaned_text$text_PQRS <- gsub("[_]", "", cleaned_text$text_PQRS)
cleaned_text$text_PQRS <- gsub("<br />", "", cleaned_text$text_PQRS)
cleaned_text$text_PQRS <- tolower(stri_trans_general(cleaned_text$text_PQRS,"Latin-ASCII"))


# -----------------------------------------------------------------------------------
# 9. Paso -  Tokenization - separaremos el texto en "tokens" individuales
#             y lo transformamos en una estructura ordenada
#             Cada token es una unidad de texto, mas comunmente palabras que usaremos en análisis posteriores
#             # -----------------------------------------------------------------------------------
text_df <- tibble(id_radicado = cleaned_text$id_radicado , text_PQRS = cleaned_text$text_PQRS)

text_df <- text_df %>%  unnest_tokens(word, text_PQRS)

# -----------------------------------------------------------------------------------
# 10. Step - Stemming Words - Despues de tokenizar, necesitamos analizar cada palabra llegando a sus raices 
#            (stemming o derivar) y su conjugación. Separamos cada fila en tokens (palabras) en la nueva tabla de datos
#            Se retiraron los signos de puntuación.
#            Las palabras se convirtieron en minusculas para hacer más sencilla la comparación o la combinación con otros datasets.
# -----------------------------------------------------------------------------------

#View(getStemLanguages())

text_df$word <- wordStem(text_df$word,  language = "spanish")



# -----------------------------------------------------------------------------------
# 11? Step - Stop Words - Often in text analysis, we will want to remove stop words, 
#            which are words that are not useful for an analysis, typically extremely
#            common words such as "the", "of", "to", and so forth in English.         
# -----------------------------------------------------------------------------------

spanish <- read_excel("esstopwords.xlsx")

text_df <- text_df %>% 
  anti_join(spanish, "word")

# -----------------------------------------------------------------------------------
# 12. Paso - Sentiment Analysis - Podemos usar herrramientas de text mining para acercanos al contenido emocional de textos.
#            Una forma de analizar sentimientos de un texto es considerando el texto como una combinacion de cada palabra 
#            y el sentimiento de cada frase en todo el texto 
# -----------------------------------------------------------------------------------
Sentiment_Analysis <- text_df %>% 
  inner_join(get_sentiments("bing"), "word") %>% 
  count(id_radicado, sentiment) %>% 
  spread(sentiment, n, fill = 0) %>% 
  mutate(sentiment = positive - negative)



# 13. Paso - tf-idf - The statistic tf-idf is intended to mesure how important a word
#            is to a document in a collection (corpus) of documents .
#            Term Frequency (tf) It is one measure of how important a word may be and           
#            how frenquently a word occurs in a document.
#            Inverse Document Frequency (idf) It decreases the weight for commonly 
#            used words and increases the weight for words that are not used very 
#            much in a collection of documents.
#            Calculating tf-idf attemps to find the words that are important
#            in a text, but not too common.
# -----------------------------------------------------------------------------------
term_frequency_review <- text_df %>% count(word, sort = TRUE)

term_frequency_review$total_words <- as.numeric(term_frequency_review %>% summarize(total = sum(n)))

term_frequency_review$document <- as.character("PQRS")

term_frequency_review <- term_frequency_review %>% 
  bind_tf_idf(word, document, n)

