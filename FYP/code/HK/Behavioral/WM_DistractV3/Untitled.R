# Sherlock / WM_Distract plots
library(tidyverse)

data <-read_csv('Alldata.csv')

glimpse(data)


# plot accuracy (hits)

plot1 <-data %>%
  mutate(corral = factor(corral, levels = c(10:0)))%>%
  ggplot(aes(x = run, y = hitsn, group = subject, color = subject))+
  geom_point(data = Ed_Vul, color = 'red', size = 2)+
  labs(x = 'Run #', y = 'Hits (count)', title = "Number of correct responses per run",tag = 'Plot 1', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))


