# look at Pilot 4/5/22 after meeting with John
library(tidyverse)

setwd('/Users/hollykular/documents/FYP/code/HK/Behavioral/WM_DistractV3/Data/V10')
data1 <-read_csv('WM_pilot_220413.csv')
# data wrangling


# add column describing hit 1 or 0 
hit <- data1 %>% mutate(hits = case_when(correctresp == resp ~ 1, correctresp != resp ~ 0))
data1$hit <- hit$hits
# add column describing false report 1 or 0
falserep <- data1 %>%  
  mutate(falsereps = case_when(correctresp != 5 ~ 0 , correctresp == 5 && correctresp != resp  ~ 1))
data1$falserep <- falserep$falsereps

rm(falserep, hit)
# individual subject quality check

respbias<- data1%>% group_by(subject) %>% count(resp, .drop = FALSE)
# missing <- data.frame(5, NaN,0)
# names(missing) <- c('subject', 'resp', 'n')
# respbias<- rbind(respbias, missing)

respbias <- respbias %>% group_by(subject)
respbias<- respbias[order(respbias$subject),] # reorganizes
totals <-  rowsum(respbias$n, rep(1:7, each = 6))
trials <- rep(totals, each = 6)
respbias$p <-  respbias$n/trials

respbias %>% 
  ggplot(aes(x = subject, y = p, fill = factor(resp)))+
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'Proportion', title = "Distribution of responses",fill = 'Response type')+
  scale_x_continuous(breaks = seq(1,9,1))+
  scale_fill_discrete(labels = c('CCW V', 'CCW H', 'CW H', 'CW V', 'nothing', 'non-resp'))+
  theme(plot.title = element_text(hjust = 0.5))


# flag subjects without a distributed response for confidence and task response, visual check looks fine

# part 1: accuracy
# if object was there how often were they correct
hitn <- data1 %>% filter(!is.nan(testorient)) %>% group_by(subject) %>% count(hit)
hitn <- hitn %>% filter(!is.na(hit))
totals <- rowsum(hitn$n, rep(1:7, each = 2)) 
trials <- rep(totals, each = 2)
hitn$rate <- hitn$n/trials

hitn %>% filter(hit == 1)%>%
  ggplot(aes(x = subject, y = rate))+
  geom_col()+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Accuracy: hit rates when probe is on target")+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')

FAn <- data1 %>% filter(is.nan(testorient)) %>% group_by(subject) %>% count(hit)
# add row for hit = 1 for subject n
missing <- data.frame(4, 0 ,0)
names(missing) <- c('subject', 'hit', 'n')
FAn<- rbind(FAn, missing)
missing <- data.frame(7, 0 ,0)
names(missing) <- c('subject', 'hit', 'n')
FAn<- rbind(FAn, missing)
FAn<- FAn %>% filter(!is.na(hit))
FAn<- FAn[order(FAn$subject),] # reorganizes
totals <- rowsum(FAn$n, rep(1:7, each = 2)) 
trials <- rep(totals, each = 2)
FAn$rate <- FAn$n/trials


FAn %>% filter(hit == 0)%>%
  ggplot(aes(x = subject, y = rate))+
  geom_col()+
  labs(x = 'Subject', y = 'FA Rate',  title = "False alarm rate: when probe off target")+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')

# part 2: detection sensitivity
# d' - responded to stimulus as if it was there (regardless of correct or not)
H <- data1 %>% filter(!is.nan(testorient)) %>% group_by(subject) %>% count(hit)
H <- H %>% filter(!is.na(hit))
H<- H[order(H$subject),] # reorganizes
totals <-  rowsum(H$n, rep(1:7, each = 2)) 
trials <- rep(totals, each = 2)
H$Hrate <- H$n/trials
FA <- data1 %>% filter(is.nan(testorient)) %>% group_by(subject) %>% count(hit)
# add row for hit = 1 for subject n
missing <- data.frame(4, 0 ,0)
names(missing) <- c('subject', 'hit', 'n')
FA<- rbind(FA, missing)
missing <- data.frame(7, 0 ,0)
names(missing) <- c('subject', 'hit', 'n')
FA<- rbind(FA, missing)
FA<- FA %>% filter(!is.na(hit))
FA<- FA[order(FA$subject),] # reorganizes
totals <- rowsum(FA$n, rep(1:9, each = 2)) 
trials <- rep(totals, each = 2)
FA$FArate <- FA$n/trials

HH<- H%>%filter(hit ==1) # number of hits
MM <- H%>%filter(hit ==0) # number of misses
FFA <- FA %>%filter(hit == 0) # number of false alarms
CR<- FA %>%filter(hit == 1 ) # number of correct rejections

# create dataframe for calculating d': hits, misses, false alarms, correct rejections
dataD<- cbind(HH$subject, HH$n, MM$n, FFA$n, CR$n)
dataD<-data.frame(dataD)
names(dataD) <- c('subject', 'hits','misses', 'false_alarms', 'correct_rejections')
dataD$targets<- dataD$hits + dataD$misses
dataD$distractors <- dataD$false_alarms + dataD$correct_rejections
dataD$Hrate<- HH$Hrate
dataD$FArate <- FFA$FArate 

dataD$d<- qnorm(dataD$Hrate) - qnorm(dataD$FArate) # calculate by hand

d<-dprime(dataD$hits, dataD$false_alarms, dataD$misses, dataD$correct_rejections, dataD$targets, dataD$distractors) # this is a package from psycho

# plot d' 
dataD %>%
  filter(subject == c(1, 2, 3, 4, 5, 6, 7))%>% # can exclude subjects with 0 FA
  ggplot(aes(x = subject, y = d)) +
  geom_col()+
  labs(x = 'Subject', y = "d'",  title = "Detection sensitivity")+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5), legend.position = 'none')


# part 3: effect of noise contrast
# calculate d' across contrast levels
Hc <- data1 %>% filter(!is.nan(testorient)) %>% group_by(subject,contrast) %>% count(hit)
Hc<- Hc %>% filter(!is.na(hit))
Hc<- Hc[order(Hc$subject),] # reorganizes
totals <-  rowsum(Hc$n, rep(1:7, each = 4)) 
trials <- rep(totals, each = 4)
Hc$Hrate <- Hc$n/trials
FAc <- data1 %>% filter(is.nan(testorient)) %>% group_by(subject, contrast) %>% count(hit, .drop = FALSE)
FAc<- FAc %>% filter(!is.na(hit))
# add row for hit = 1 for subject n
missing <- data.frame(1, .5 ,0, 0)
names(missing) <- c('subject', 'contrast','hit', 'n')
FAc<- rbind(FAc, missing)
missing <- data.frame(4 ,.5 ,0, 0)
names(missing) <- c('subject', 'contrast','hit', 'n')
FAc<- rbind(FAc, missing)
missing<- data.frame(4, .8 ,0, 0)
names(missing) <- c('subject', 'contrast','hit', 'n')
FAc<- rbind(FAc, missing)
missing <- data.frame(5, .8 ,0, 0)
names(missing) <- c('subject', 'contrast','hit', 'n')
FAc<- rbind(FAc, missing)
missing <- data.frame(7, .8 ,0, 0)
names(missing) <- c('subject', 'contrast','hit', 'n')
FAc<- rbind(FAc, missing)
missing <- data.frame(7, .5 ,0, 0)
names(missing) <- c('subject', 'contrast','hit', 'n')
FAc<- rbind(FAc, missing)

FAc<- FAc[order(FAc$subject),] # reorganizes
totals <- rowsum(FAc$n, rep(1:7, each = 4)) 
trials <- rep(totals, each = 4)
FAc$FAcrate <- FAc$n/trials

HHc<- Hc%>%filter(hit ==1) # number of hits
MMc <- Hc%>%filter(hit ==0) # number of misses
FFAc <- FAc %>%filter(hit == 0) # number of false alarms
CRc<- FAc %>%filter(hit == 1 ) # number of correct rejections

dataC<- cbind(HHc$subject, HHc$contrast, HHc$n, MMc$n, FFAc$n, CRc$n)
dataC<-data.frame(dataC)
names(dataC) <- c('subject', 'contrast','hits','misses', 'false_alarms', 'correct_rejections')
dataC$targets<- dataC$hits + dataC$misses
dataC$distractors <- dataC$false_alarms + dataC$correct_rejections
dataC$Hrate<- HHc$Hrate
dataC$FArate <- FFAc$FAcrate

dataC$d<- qnorm(dataC$Hrate) - qnorm(dataC$FArate) # calculate by hand

# plot d' correct
dataC %>%
  #filter(subject != c(7,7,8,9))%>% # can exclusde subjects with 0 FA
  ggplot(aes(x =subject, y = d, fill = factor(contrast))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = "d'",  title = "Detection sensitivity", fill = 'contrast')+
  scale_x_continuous(breaks = seq(1,6,1))+
  theme(plot.title = element_text(hjust = 0.5))

# compare hit rate and FA rate across contrast levels
dataC %>%
  ggplot(aes(x =subject, y = Hrate, fill = factor(contrast))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'rate',  title = "Hit rate when probe is on target", fill = 'contrast')+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))

dataC %>%
  ggplot(aes(x =subject, y = FArate, fill = factor(contrast))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'rate',  title = "FA rate when probe is on target", fill = 'contrast')+
  scale_x_continuous(breaks = seq
                     (1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))

## stuff based on meeting 4.8.22
# plot d' correct discriminate something there or not
# recode hit as resp = 1-4 on something there trial
disc <- data1 %>% filter(!is.nan(testorient)) %>%mutate(hit = case_when(resp == 1 ~ 1, resp == 2 ~ 1, resp == 3 ~1, resp == 4 ~ 1, resp == 5 ~ 0))

discrim<- disc %>% group_by(subject, .drop = FALSE) %>% count(hit)
discrim<- discrim%>% filter(!is.na(hit))
# missing <- data.frame(4, 0, 0)
# names(missing) <- c('subject', 'hit', 'n')
# discrim<- rbind(discrim, missing)
discrim<- discrim[order(discrim$subject),] # reorganizes

totals <- rowsum(discrim$n, rep(1:7, each = 2)) 
trials <- rep(totals, each = 2)
discrim$Hrate <- discrim$n/trials

# FA still the same

hitr<- discrim%>%filter(hit ==1) # number of hits
missr<- discrim%>%filter(hit ==0) # number of misses
FFA <- FA %>%filter(hit == 0) # number of false alarms
CR<- FA %>%filter(hit == 1 ) # number of correct rejections

dataV<- cbind(hitr$subject, hitr$n, missr$n, FFA$n, CR$n)
dataV<-data.frame(dataV)
names(dataV) <- c('subject', 'hits','misses', 'false_alarms', 'correct_rejections')
dataV$targets<- dataV$hits + dataV$misses
dataV$distractors <- dataV$false_alarms + dataV$correct_rejections
dataV$Hrate<- hitr$Hrate
dataV$FArate <- FFA$FArate


dataV$d<- qnorm(dataV$Hrate) - qnorm(dataV$FArate) # calculate by hand

dataV %>%
  ggplot(aes(x =subject, y = d)) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = "d'",  title = "Detection Sensitivity")+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))


dataV %>%
  ggplot(aes(x =subject, y = Hrate)) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'rate',  title = "Hit rate when probe is on target, hit = any 1 key")+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))

dataV %>%
  ggplot(aes(x =subject, y = FArate)) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'rate',  title = "False alarm rate when probe is on target")+
  scale_x_continuous(breaks = seq
                     (1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))

# repeat for contrast conditions
discrimC<- disc %>% group_by(subject, contrast, .drop = FALSE) %>% count(hit)
discrimC<- discrimC%>% filter(!is.na(hit))
 missing <- data.frame(1,0.5, 0, 0)
 names(missing) <- c('subject','contrast', 'hit', 'n')
 discrimC<- rbind(discrimC, missing)
 missing <- data.frame(7,0.8, 0, 0)
 names(missing) <- c('subject','contrast', 'hit', 'n')
 discrimC<- rbind(discrimC, missing)
discrimC<- discrimC[order(discrimC$subject),] # reorganizes

totals <- rowsum(discrimC$n, rep(1:7, each = 4))
trials <- rep(totals, each = 4)
discrimC$Hrate <- discrimC$n/trials

# FA still the same

hitr<- discrimC%>%filter(hit ==1) # number of hits
missr<- discrimC%>%filter(hit ==0) # number of misses
FFAc <- FAc %>%filter(hit == 0) # number of false alarms
CR<- FAc %>%filter(hit == 1 ) # number of correct rejections

dataCR<- cbind(hitr$subject, hitr$contrast, hitr$n, missr$n, FFAc$n, CR$n)
dataCR<-data.frame(dataCR)
names(dataCR) <- c('subject', 'contrast','hits','misses', 'false_alarms', 'correct_rejections')
dataCR$targets<- dataCR$hits + dataCR$misses
dataCR$distractors <- dataCR$false_alarms + dataCR$correct_rejections
dataCR$Hrate<- hitr$Hrate
dataCR$FArate <- FFAc$FAcrate


dataCR$d<- qnorm(dataCR$Hrate) - qnorm(dataCR$FArate) # calculate by hand


# add SE bars
dataCR %>%
  ggplot(aes(x =subject, y = d, fill = factor(contrast))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = "d'",  title = "Detection Sensitivity", fill = 'contrast')+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))


dataCR %>%
  ggplot(aes(x =subject, y = Hrate, fill = factor(contrast))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'rate',  title = "Hit rate when probe is on target, hit = any 1 key", fill = 'contrast')+
  scale_x_continuous(breaks = seq(1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))

dataCR %>%
  ggplot(aes(x =subject, y = FArate, fill = factor(contrast))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'rate',  title = "False alarm rate when probe is on target", fill = 'contrast')+
  scale_x_continuous(breaks = seq
                     (1,9,1))+
  theme(plot.title = element_text(hjust = 0.5))

## looking at confidence ratings during hits and FA
conf <- disc %>% group_by(subject, conf, .drop = FALSE) %>% count(hit)
conf<- conf %>% filter(!is.na(hit))
conf<- conf %>% filter(!is.na(conf))
# there's gotta be a faster way to include the values that are 0
missing <- data.frame(1,1, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(1,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(4,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(4,3, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(5,1, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(5,3, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(7,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(7,3, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)
missing <- data.frame(6,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
conf<- rbind(conf, missing)

conf<- conf[order(conf$subject, conf$conf),] # reorganizes


totals <- rowsum(conf$n, rep(1:7, each = 6))
trials <- rep(totals, each = 6)
conf$prop <- conf$n/trials

conf %>% filter(hit == 1)%>%
  ggplot(aes(x =subject, y = prop, fill = factor(conf))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'proportion',  title = "Confidence levels with hits", fill = 'confidence')+
  scale_x_continuous(breaks = seq
                     (1,7,1))+
  theme(plot.title = element_text(hjust = 0.5))

# confidence with false alarms
confa <- data1 %>% filter(is.nan(testorient)) %>% group_by(subject, conf) %>% count(hit, .drop = FALSE)
confa<- confa %>% filter(!is.na(hit))
confa<- confa %>% filter(!is.na(conf))

missing <- data.frame(1,1, 1, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(1,2, 1, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(1,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(1,3, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(4,1, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(4,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(4,3, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(5,1, 1, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(5,1, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(5,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(6,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(7,1, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(7,2, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)
missing <- data.frame(7,3, 0, 0)
names(missing) <- c('subject','conf', 'hit', 'n')
confa<- rbind(confa, missing)

confa<- confa[order(confa$subject, confa$conf),] # reorganizes

totals <- rowsum(confa$n, rep(1:7, each = 6))
trials <- rep(totals, each = 6)
confa$prop <- confa$n/trials

confa %>% filter(hit == 1)%>%
  ggplot(aes(x =subject, y = prop, fill = factor(conf))) +
  geom_col(position = position_dodge())+
  labs(x = 'Subject', y = 'proportion',  title = "Confidence levels with false alarms", fill = 'confidence')+
  scale_x_continuous(breaks = seq
                     (1,7,1))+
  theme(plot.title = element_text(hjust = 0.5))


# compare vertical and horizontal error
# create columns in data1 with labels for h or v 
# data1$meridian <- data1 %>% mutate(meridian = case_when(90 < testorient < 120 && 50 < testorient < 90  ~ 'v',   300 < testorient < 360 && 0 < testorient < 30 ~ 'h'))
#install.packages('extraoperators')
library(extraoperators)

meridian <- data1 %>% mutate(meridian = case_when(testorient %gl% c(50,120) ~ 'v',   testorient %gl% c(0,30) ~ 'h', testorient %gl% c(300,360) ~ 'h'))
data1$meridian <- meridian$meridian

rm(meridian)

# hit rate 
Hm <- data1 %>% filter(!is.nan(testorient)) %>% group_by(subject,meridian) %>% count(hit)
Hm<- Hm %>% filter(!is.na(hit))
Hm<- Hm[order(Hm$subject),] # reorganizes
totals <-  rowsum(Hm$n, rep(1:7, each = 4)) 
trials <- rep(totals, each = 4)
Hm$Hrate <- Hm$n/trials
# FAm <- data1 %>% filter(is.nan(testorient)) %>% group_by(subject,meridian) %>% count(hit)
# FAm<- FAm %>% filter(!is.na(hit))
# # add back subject 4 and 7 getting 0 FA
# missing <- data.frame(4, 0 ,0)
# names(missing) <- c('subject', 'hit', 'n')
# FAm<- rbind(FAm, missing)
# missing <- data.frame(7, 0 ,0)
# names(missing) <- c('subject', 'hit', 'n')
# FAm<- rbind(FAm, missing)
# FAm<- FAm[order(FAm$subject),] # reorganizes
# totals <- rowsum(FAm$n, rep(1:7, each = 2)) 
# trials <- rep(totals, each = 2)
# FAm$FArate <- FAm$n/trials

Hm %>% filter(hit == 1)%>%
  ggplot(aes(x = subject, y = Hrate, fill = factor(meridian)))+
  geom_col(position = 'dodge')+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Accuracy: hit rates when probe is on target across meridian", fill = 'meridian')+
  scale_x_continuous(breaks = seq(1,7,1))+
  theme(plot.title = element_text(hjust = 0.5))


# compare CW and CCW error
# create columns in data1 with labels for cw or ccw 
clocks <- data1 %>% mutate(clock = case_when(testorient %gl% c(0, 30) ~ 'ccw', testorient %gl% c(300, 360) ~ 'cw', testorient %gl% c(50, 90) ~ 'cw', testorient %gl% c(90, 120) ~ 'ccw'))
data1$clock <- clocks$clock

rm(clocks)


# hit rate 
Hcl <- data1 %>% filter(!is.nan(testorient)) %>% group_by(subject,clock) %>% count(hit)
Hcl<- Hcl %>% filter(!is.na(hit))
Hcl<- Hcl[order(Hm$subject),] # reorganizes
totals <-  rowsum(Hcl$n, rep(1:7, each = 4)) 
trials <- rep(totals, each = 4)
Hcl$Hrate <- Hcl$n/trials
# FAm <- data1 %>% filter(is.nan(testorient)) %>% group_by(subject,meridian) %>% count(hit)
# FAm<- FAm %>% filter(!is.na(hit))
# # add back subject 4 and 7 getting 0 FA
# missing <- data.frame(4, 0 ,0)
# names(missing) <- c('subject', 'hit', 'n')
# FAm<- rbind(FAm, missing)
# missing <- data.frame(7, 0 ,0)
# names(missing) <- c('subject', 'hit', 'n')
# FAm<- rbind(FAm, missing)
# FAm<- FAm[order(FAm$subject),] # reorganizes
# totals <- rowsum(FAm$n, rep(1:7, each = 2)) 
# trials <- rep(totals, each = 2)
# FAm$FArate <- FAm$n/trials

library(ggthemes)
Hcl %>% filter(hit == 1)%>%
  ggplot(aes(x = subject, y = Hrate, fill = factor(clock)))+
  geom_col(position = 'dodge')+
  labs(x = 'Subject', y = 'Hit Rate',  title = "Accuracy: hit rates when probe is on target", fill = 'direction')+
  scale_x_continuous(breaks = seq(1,7,1))+
  theme_classic()+
  scale_fill_manual(values = c('darkgrey', 'black'))+
  theme(plot.title = element_text(hjust = 0.5))

# looking at RT

RTresp <- data1 %>% group_by(subject) %>% summarise_at(vars(respRT), list(name = mean)) # mean RT for each subject
RTconf <- data1 %>% group_by(subject) %>% summarise_at(vars(confRT), list(name = mean)) # mean RT for each subject
# they are all faster with confidence interval

# now look at RTs during hits
RTrespH <- data1 %>% filter(!is.nan(testorient)) %>% group_by(subject) %>% summarise_at(vars(respRT), list(name = mean)) # mean RT for each subject
RTconfH <- data1 %>% filter(!is.nan(testorient)) %>% group_by(subject) %>% summarise_at(vars(confRT), list(name = mean)) # mean RT for each subject

# now look at RTs during FAs
RTrespFA <- data1 %>% filter(is.nan(testorient)) %>% filter(hit == 0) %>% group_by(subject) %>% summarise_at(vars(respRT), list(name = mean)) # mean RT for each subject
RTconfFA <- data1 %>% filter(is.nan(testorient)) %>% filter(hit == 0) %>% group_by(subject) %>% summarise_at(vars(confRT), list(name = mean)) # mean RT for each subject

# doesn't look like there's a difference between H and FA RTs but don't have power (n) to test this

#make theme for plots
