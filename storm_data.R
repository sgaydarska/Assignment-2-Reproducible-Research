library(plyr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(RColorBrewer)


# Downloading file
URL <- "https://d396qusza40orc.cloudfront.net/repdata%2Fdata%2FStormData.csv.bz2"
download.file(URL, destfile = "storm_data.csv", method = "curl")
storm_data <- read.csv(file = "storm_data.csv", sep = ",", header = T, stringsAsFactors = F)

# Downloading additional variable info
URL2 <- "https://d396qusza40orc.cloudfront.net/repdata%2Fpeer2_doc%2Fpd01016005curr.pdf"
download.file(URL2, destfile = "storm_data_documentation.pdf", method = "curl")

# Selecting useful variables
clean_storm = storm_data %>%
  select(STATE, EVTYPE, FATALITIES, INJURIES, PROPDMG, PROPDMGEXP, CROPDMG, CROPDMGEXP) 

# Add together fatalities and injuries
health_damage = clean_storm %>%
  select(EVTYPE, FATALITIES, INJURIES) %>%
  mutate(TOTAL = FATALITIES + INJURIES) %>%
  group_by(EVTYPE) %>%
  summarize(FATALITIES=sum(FATALITIES), INJURIES=sum(INJURIES), TOTAL=sum(TOTAL)) %>%
  arrange(desc(TOTAL))
  
#Selecting Top 5
health_damage = health_damage[1:5,]

# Split by damage type
health_damage = health_damage %>%
  gather(DMG_TYPE, TTL_DMG, FATALITIES:INJURIES)

# Plotting the health damage by event type
ggplot(health_damage, aes(y=TTL_DMG, x=reorder(EVTYPE, -TTL_DMG), fill = DMG_TYPE)) +
  geom_bar(stat="identity") +
  xlab("Event Type") +
  ylab("Total Health Damage") +
  ggtitle("Top 5 events in the USA causing the highest number of fatalities and injuries") +
  scale_fill_brewer(palette = "Set1") +
  scale_fill_discrete(name="Damage Type", labels=c("Total Fatalities","Total Injuries"))



# Review Property_Damage_Exp and Crop_Damage_Exp
unique(clean_storm$PROPDMGEXP)
unique(clean_storm$CROPDMGEXP)

# Change Exp to their corresponding values
economic_damage = clean_storm %>%
  select(EVTYPE, PROPDMG, PROPDMGEXP, CROPDMG, CROPDMGEXP)

# Converting property Exp to values
economic_damage$PROPDMGEXP_CONV = as.numeric(mapvalues(economic_damage$PROPDMGEXP,
                                            c("K","M","", "B","m","+","0","5","6","?","4","2","3","h","7","H","-","1","8"), 
                                            c(1e3,1e6, 1, 1e9,1e6,1,1,1e5,1e6,1,1e4,1e2,1e3,1,1e7,1e2,1,10,1e8)))

# Converting crop Exp to values
economic_damage$CROPDMGEXP_CONV = as.numeric(mapvalues(economic_damage$CROPDMGEXP,
                                            c("","M","K","m","B","?","0","k","2"),
                                            c( 1,1e6,1e3,1e6,1e9,1,1,1e3,1e2)))


# Adding together crop and property damage
economic_damage = economic_damage %>%
  group_by(EVTYPE) %>%
  mutate(TTL_PROPDMG=PROPDMG*PROPDMGEXP_CONV, TTL_CROPDMG=CROPDMG*CROPDMGEXP_CONV) %>%
  mutate(TTL_DMG=TTL_PROPDMG + TTL_CROPDMG) %>%
  summarize(TTL_PROPDMG=sum(TTL_PROPDMG), TTL_CROPDMG=sum(TTL_CROPDMG),
            TTL_DMG=sum(TTL_DMG)) %>%
  arrange(desc(TTL_DMG))

economic_damage <- economic_damage[1:5,]

# Split by damage type
economic_damage = economic_damage %>%
  gather(DMG_TYPE, DMG_VALUE, TTL_PROPDMG:TTL_CROPDMG)


# Plotting crop damage by event type
ggplot(economic_damage, aes(y=DMG_VALUE, x=reorder(EVTYPE, +DMG_VALUE), fill=DMG_TYPE)) +
         geom_bar(stat = "identity") +
         xlab("Event Type") +
         ylab("Total Economic Damage") +
         ggtitle("Top 5 events in the USA causing the highest economic damage") +
         scale_fill_brewer(palette = "Set3") +
         coord_flip() +
         scale_fill_discrete(name="Damage Type", labels=c("Total Crop Damage","Total Property Damage"))

