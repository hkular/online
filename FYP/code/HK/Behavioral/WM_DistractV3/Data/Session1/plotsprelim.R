# Sherlock / WM_Distract plots
library(tidyverse)

data1 <-read_csv('Alldata.csv')

glimpse(data1)

## plot accuracy (hits)
# all data including 24 and 30 trial runs
plot1 <-data1 %>%
  ggplot(aes(x = run, y = hitsn, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'Hits (count)', title = "Number of correct responses per run",tag = 'Plot 1', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

# 24 trial runs
data24<- data1 %>%
  filter(subject <4)
plot2 <-data24 %>%
  ggplot(aes(x = run, y = hitsn, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'Hits (count)', title = "Number of correct responses per run",tag = 'Plot 2', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

# 30 trial runs
data30<- data1 %>%
  filter(subject >3)
plot3 <-data30 %>%
  ggplot(aes(x = run, y = hitsn, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'Hits (count)', title = "Number of correct responses per run",tag = 'Plot 3', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

## plot false reports
# all data including 24 and 30 trial runs
plot4 <-data1 %>%
  ggplot(aes(x = run, y = falsereportn, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'False reports (count)', title = "Number of false reports per run",tag = 'Plot 4', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

# 24 trial runs
data24<- data1 %>%
  filter(subject <4)
plot5 <-data24 %>%
  ggplot(aes(x = run, y = falsereportn, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'False reports (count)', title = "Number of false reports per run",tag = 'Plot 5', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

# 30 trial runs
data30<- data1 %>%
  filter(subject >3)
plot6 <-data30 %>%
  ggplot(aes(x = run, y = falsereportn, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'False reports (count)', title = "Number of false reports per run",tag = 'Plot 6', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

## plot non response
# all data including 24 and 30 trial runs
plot7 <-data1 %>%
  ggplot(aes(x = run, y = nonresponse, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'Non response (count)', title = "Number of non response per run",tag = 'Plot 7', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

# 24 trial runs , less practice
data24<- data1 %>%
  filter(subject <4)
plot8 <-data24 %>%
  ggplot(aes(x = run, y = nonresponse, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'Non response (count)', title = "Number of non response per run",tag = 'Plot 8', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))

# 30 trial runs, more practice
data30<- data1 %>%
  filter(subject >3)
plot9 <-data30 %>%
  ggplot(aes(x = run, y = nonresponse, color = subject))+
  geom_jitter()+
  labs(x = 'Run #', y = 'Non response (count)', title = "Number of non response per run",tag = 'Plot 9', color = 'subject')+
  theme(plot.title = element_text(hjust = 0.5))
