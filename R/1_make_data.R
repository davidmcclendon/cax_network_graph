library(tidyverse)
library(here)
library(jsonlite)

clean_data <- read_csv(here::here("build", "clean_data.csv"))


graph_data <- clean_data %>% 
  select(ServiceProvider, ServiceProviderCategory) %>% 
  group_by(ServiceProvider, ServiceProviderCategory) %>% 
  summarise(
    num_clients = n()
  ) %>% 
  ungroup() %>% 
  group_by(ServiceProvider) %>% 
  mutate(
    size_sp = sum(num_clients, na.rm=T)
  ) %>% 
  ungroup() %>% 
  group_by(ServiceProviderCategory) %>% 
  mutate(
    size_cat = sum(num_clients, na.rm=T)
  ) %>% 
  filter(!is.na(ServiceProvider) & !is.na(ServiceProviderCategory)) %>% 
  data.frame()

connection_names <- c(source="ServiceProviderCategory", target="ServiceProvider", value="num_clients")

graph_data %>%
  select(connection_names) %>% 
  jsonlite::toJSON(auto_unbox=T) %>% 
  write(here::here("build", "connections-data.json"))

provider_nodes <- graph_data %>% 
  dplyr::select(ServiceProvider, size_sp) %>% 
  unique(.) %>% 
  mutate(group = 1) %>% 
  dplyr::select(id = "ServiceProvider", group, num_clients = "size_sp")

provider_nodes %>%
  jsonlite::toJSON(auto_unbox=T) %>%
  write(here::here("build", "provider-nodes-data.json"))

service_nodes <- graph_data %>% 
  dplyr::select(ServiceProviderCategory, size_cat) %>% 
  unique(.) %>% 
  mutate(group = 2) %>% 
  dplyr::select(id = "ServiceProviderCategory", group, num_clients = "size_cat")

service_nodes %>%
  jsonlite::toJSON(auto_unbox=T) %>%
  write(here::here("build", "service-nodes-data.json"))








