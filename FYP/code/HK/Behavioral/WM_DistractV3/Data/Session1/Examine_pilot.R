# Sherlock / WM_Distract plots
library(tidyverse)

data1 <-read_csv('WM_pilot.csv')

# columns are set size, orient1, orient2, position1, position2, contrast, test, testorient, correctresp, sub, resp, respRT, conf, confRT
# NaNs for no response
# orient2 and position2 are NA for set size 1
glimpse(data1)
spec(data1)
# organize some things
class(data1$setsize) # make sure this is numeric
setsize1data <- data1 %>% filter(setsize == 1)
setsize2data <- data1 %>% filter(setsize ==2)
class(data1$testorient)
ontarget <- data1 %>% filter(!is.nan(testorient))
offtarget <- data1 %>% filter(is.nan(testorient))


## confidence stuff

# compare distribution of confidences at set size 1 and set size 2
plot1 <- data1 %>% 
  ggplot(aes(x = conf,  group = setsize, fill = factor(setsize)))+
  geom_histogram(position = "dodge", binwidth = 0.5)+
  labs(x = 'Confidence', y = 'Count', title = "Distribution of confidence",tag = 'Plot 1', fill = 'Set Size')+
  scale_x_continuous(breaks = seq(1,3,1))+
  theme(plot.title = element_text(hjust = 0.5))
# distribution of confidences when probe on target 
plot2 <- ontarget %>% 
  ggplot(aes(x = conf,  group = setsize, fill = factor(setsize)))+
  geom_histogram(position = "dodge", binwidth = 0.5)+
  labs(x = 'Confidence', y = 'Count', title = "Distribution of confidence when probe is on target",tag = 'Plot 2', fill = 'Set Size')+
  scale_x_continuous(breaks = seq(1,3,1))+
  theme(plot.title = element_text(hjust = 0.5))
  
# distribution of confidences when probe off target
plot3 <- offtarget %>% 
  ggplot(aes(x = conf,  group = setsize, fill = factor(setsize)))+
  geom_histogram(position = "dodge", binwidth = 0.5)+
  labs(x = 'Confidence', y = 'Count', title = "Distribution of confidence when probe is off target",tag = 'Plot 3', fill = 'Set Size')+
  scale_x_continuous(breaks = seq(1,3,1))+
  theme(plot.title = element_text(hjust = 0.5))

# create plot comparing both
target<- data1%>%
  mutate(testorient = case_when(!is.nan(testorient) ~ 1, is.nan(testorient) ~ 0))
target <- target %>% rename(targetonoff = testorient)
data1$targets <- target$targetonoff
data1 <- data1 %>% rename(targetonoff = targets$targetonoff)

plot4 <- data1 %>%
  #mutate(targets = recode(targets,1="On",  0="Off"))%>%
  ggplot(aes(x= conf, group = targets, fill = factor(targets)))+
  geom_histogram(position = "dodge", binwidth = 0.5)+
  labs(x = 'Confidence', y = 'Count', title = "Distribution of confidence when probe is on and off target",tag = 'Plot 4', fill = 'Off/On Target')+
  scale_x_continuous(breaks = seq(1,3,1))+
  theme(plot.title = element_text(hjust = 0.5))

## hit stuff
hit<- data1%>%
  mutate(correctresp = case_when(correctresp == resp ~ 1, correctresp != resp ~ 0))
hit <- hit %>% rename(hits = correctresp)
data1$hits <- hit$hits
data1 <- data1 %>% rename(hits= hit$hits)
data1 <- data1 %>% rename(subject= sub)
hitn <- data1 %>% group_by(subject) %>% count(hits)
totals <- rowsum(hitn$n, rep(1:8, each = 3))
trials <- rep(totals, each = 3)
hitn$rate <- hitn$n/trials


# distribution of hits
plot5 <- hitn %>% 
  filter(hits == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Distribution of hit rates",tag = 'Plot 5')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')
plot5
# distribution of hits at set size 1
ss1hit <- data1 %>% group_by(subject) %>% filter(setsize == 1) %>% count(hits)
totals <- rowsum(ss1hit$n, rep(1:8, each = 3))
trial <- rep(totals, each = 3)
ss1hit$rate <- ss1hit$n/trial

plot6 <- ss1hit %>% 
  filter(hits == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Distribution of hit rates at set size 1",tag = 'Plot 6')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')

# distribution of hits at set size 2
ss2hit <- data1 %>% group_by(subject) %>% filter(setsize == 2) %>% count(hits)
totals <- rowsum(ss2hit$n, rep(1:8, each = 3))
trial <- rep(totals, each = 3)
ss2hit$rate <- ss2hit$n/trial

plot7 <- ss2hit %>% 
  filter(hits == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Distribution of hit rates at set size 2",tag = 'Plot 6')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')

# distribution of hits when probe on target
ontargethit <- data1 %>% group_by(subject) %>% filter(!is.nan(testorient)) %>% count(hits)
totals <- rowsum(ontargethit$n, rep(1:8, each = 3))
trial <- rep(totals, each = 3)
ontargethit$rate <- ontargethit$n/trial

plot8 <- ontargethit %>% 
  filter(hits == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Distribution of hit rates when probe is on target",tag = 'Plot 8')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')


# distribution of hits when probe off target
offtargethit <- data1 %>% group_by(subject) %>% filter(is.nan(testorient)) %>% count(hits)
totals <- rowsum(offtargethit$n, rep(1:8, each = 3))
trial <- rep(totals, each = 3)
offtargethit$rate <- offtargethit$n/trial

plot9 <- offtargethit %>% 
  filter(hits == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Distribution of hit rates when probe is off target",tag = 'Plot 9')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')


## false report stuff

falserep<- data1%>%
  filter(correctresp == 5) %>%
  mutate(correctresp = case_when(correctresp == resp  ~ 0, correctresp != resp  ~ 1))
falserep <- falserep %>% rename(falsereps = correctresp)
data1fp <- data1%>% filter(correctresp == 5)
data1fp$falsereps <- falserep$falsereps
data1fp <- data1fp %>% rename(falserep= falserep$falsereps)
falserepn <- data1fp %>% group_by(subject) %>% count(falsereps)
totals <- rowsum(falserepn$n, rep(1:8, each = 3))
trials <- rep(totals, each = 3)
falserepn$rate <- falserepn$n/trials

# distribution of false reports 

plot10<- falserepn %>% 
  filter(falsereps == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'False Report Rate',  title = "Distribution of False Report rates",tag = 'Plot 10')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')

# distribution of false reports at setsize 1
fpss1 <- data1fp %>% group_by(subject) %>% filter(setsize == 1) %>% count(falsereps)
missing <- data.frame(5, NA ,0)
names(missing) <- c('subject', 'falsereps', 'n')
fpss1<- rbind(fpss1, missing)
totals <- rowsum(fpss1$n, rep(1:8, each = 3))
trials <- rep(totals, each = 3)
fpss1$rate <- fpss1$n/trials

plot11 <- fpss1 %>% 
  filter(falsereps == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'False Report rate',  title = "Distribution of false reports at set size 1",tag = 'Plot 11')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')


# distribution of false reports at setsize 2
fpss2 <- data1fp %>% group_by(subject) %>% filter(setsize == 2) %>% count(falsereps)
missing <- data.frame(5, NA ,0)
names(missing) <- c('subject', 'falsereps', 'n')
fpss2<- rbind(fpss2, missing)
totals <- rowsum(fpss2$n, rep(1:8, each = 3))
trials <- rep(totals, each = 3)
fpss2$rate <- fpss2$n/trials

plot12 <- fpss2 %>% 
  filter(falsereps == 1)%>%
  ggplot(aes( x = subject, y = rate,  group = subject))+
  geom_col()+
  labs(x = 'Subject', y = 'False Report rate',  title = "Distribution of false reports at set size 2",tag = 'Plot 12')+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')

# look for swaps -- are false reports matching targets?

