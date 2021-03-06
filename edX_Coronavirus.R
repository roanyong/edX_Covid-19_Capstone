# 1. Introduction 
##Covid-19 is an ongoing pandemic, which has affected more than 5 million people worldwide. This project uses the Covid-19 dataset maintained by Our World in Data. It is free for all purposes, updated daily, and includes data on confirmed cases, deaths, and testing - which will be the focus of this project. 
##The goal of the project is to build a machine learning model that can predict the daily number of new deaths, which is especially worth studying as it communicates how deadly the pandemic is and how successful our efforts in containing the pandemic. 
##To that end, we are going to:
##- Explore and study the Covid-19 data;
##- Determine the independent variables that could predict the daily number of new deaths; and
##- Propose and build the machine learning algorithm that has the least RSME

##Reference: Covid-19 dataset
##- [About the data set](https://ourworldindata.org/coronavirus-source-data)
##- [The data set in CSV](https://covid.ourworldindata.org/data/owid-covid-data.csv)


#2. Method / Analysis

## a. Getting the Data
##First, we have to ensure that the packages that we need for the project are installed and loaded onto the machine. 
## Note: this process could take a couple of minutes
if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(data.table)) install.packages("data.table", repos = "http://cran.us.r-project.org")

##Next, we can proceed to download the dataset. 
##The dataset can be obtained from the Our World in Data website and it is available in CSV format.  
dl <- tempfile()
download.file("https://covid.ourworldindata.org/data/owid-covid-data.csv", dl)
data <- read.csv(dl)
rm(dl) #we won't be needing dl anymore, so we should remove it to reduce clutter. 

## b. Data Exploration and Visualisation
##Let's start by getting some basic understanding of the variables, the structure of the data, and basic statistics. 
names(data)
str(data)
summary(data)

##We can see that the date is not formatted correctly. Let's fix that.  
data$date <- as.Date(data$date) 
class(data$date) #check if the date is correct

##We can now do some data visualisations to better understand the relationships among the variables.First, let's visualise the total number of cases as of date in the world as well as in Brazil, Russia, United Kingdom, and United States - four countries with the highest number of cases (as of 25 May 2020).  
data %>% filter(location %in% c("World", "United States", "Brazil", "Russia", "United Kingdom")) %>% ggplot(aes(x=date, y=total_cases, colour = location)) +
  geom_line(size = 1) 

##Aside from the staggering and rising total number of cases in the world, the chart indicates that United States has, by far, the fastest and highest rising total number of cases in the world (as of 25 May 2020).   

##Let's use a bar chart to take a closer look on the top 10 locations with the highest total cases. 
##Top 10 locations with the highest total cases since the start of the pandemic till today (i.e. Sys.Date()-1 to cater to the one day report publication lag)
data %>% filter(date == Sys.Date() - 1) %>% select(date, location, total_cases) %>% arrange(desc(total_cases)) %>% head(10) %>% ggplot() + geom_bar(mapping = aes(x=location, y=total_cases), stat = "identity") + coord_flip() + ggtitle("Top 10 Locations with the Highest Total Cases")

##With that insight, let's now examine the variables of interest for this project. Let's begin by visualising the top 10 locations with the highest means of new deaths per million. For comparison purposes, the number of new deaths per million is preferred over the total (absolute) number of new deaths.  
##top 10 location with the highest mean of new deaths per million, omitting NA values
data %>% group_by(location) %>% summarise(mean_new_deaths_per_million = mean(new_deaths_per_million, na.rm = TRUE)) %>% arrange(desc(mean_new_deaths_per_million)) %>% top_n(10) %>% ggplot() + geom_bar(mapping = aes(x=location, y=mean_new_deaths_per_million), stat = "identity") + coord_flip() + ggtitle("The Highest Means of New Deaths per Million")

##Andorra and San Marino are two awful places to live in due to the relatively high averages of new deaths per million (as of 25 May 2020). 

##We can surmise that the total number of new deaths (per million) is affected by not only the location (which has certain demographic charateristics such as median age), but also the number of tests that are conducted and the number of hospital beds that are available. 

##Let's quickly visualise the aforementioned variables. 
##Let's focus on the total number of tests per thousand in the US and the UK - two great countries - since 23 March 2020, the day that is widely recognised as the stock market bottom, till today (Sys.Date()-1 to cater to the one day report publication lag)
data %>% filter(date %between% c(as.Date("2020-03-23"), Sys.Date() - 1) & location == c("United States", "United Kingdom")) %>% ggplot(aes(x=date, y=total_tests_per_thousand, colour = location)) + geom_line(size = 1)  + ggtitle("Total Tests per Thousand in US and UK")

##Nothing surprising here. Both the United States and the United Kingdom have ramped up total number of tests per thousand since 23 March 2020. The United States has conducted more tests than the United Kingdom! (as of 25 May 2020) 

##Let's find out top 10 locations with the highest number of hospital beds per 100k. 
##The total numbers of hospital beds are mostly consistent across dates. To avoid the risk of having an NA value, 23 March 2020 - stock market bottom date - is picked as a benchmark date to find the number of hospital beds per 100k.
data %>% filter(date == as.Date("2020-03-23") & !is.na(hospital_beds_per_100k)) %>% arrange(desc(hospital_beds_per_100k)) %>% top_n(10) %>% ggplot() + geom_bar(mapping = aes(x=location, y=hospital_beds_per_100k), stat = "identity") + coord_flip() + ggtitle("Top 10 Locations with Total Hospital Beds per 100k")

##The United States and the United Kingdom are not in the chart! It is surprising to know that Ukraine, Belarus, and Russia - communist countries (or ex-communist  countries) - are among the top 10 countries with the highest number of hospital beds per 100k. 

## c. Data Cleaning and Processing
##Based on our surmise, the number of new deaths per million (the dependent variable of interest) can be predicted by:
##- location (which includes demographic characteristics)
##- total cases per million (some of earlier confirmed cases can result in new deaths)
##- total tests per thousand (total tests are preferred over new tests as there is a lag time between the test and its results that eventually would contribute to the total number of cases)
##- hospital beds per 100k (the lack of hospital beds availability contributes directly to mortality)

##So our machine learning formula is: new_deaths_per_million ~ location + total_cases_per_million + total_tests_per_thousand + hospital_beds_per_100k

##Let's check for NA values for those variables of interest. 
##check for NA values
sum(is.na(data$new_deaths_per_million))
sum(is.na(data$location))
sum(is.na(data$total_cases_per_million))
sum(is.na(data$total_tests_per_thousand))
sum(is.na(data$hospital_beds_per_100k))

##It seems that we need to do some data cleaning to remove those NA values. But first, we don't need the whole dataset. There is too much noise in the dataset if we were to do that. Let's instead focus on the past one week data, filtering out "International" and "World" as those are total figures. 
##Select today's date >=7 and remove International and World
##Select the variables of interest: date, location, population, total_cases_per_million, new_deaths, new_deaths_per_million, total_tests_per_thousand, hospital_beds_per_100k
todaydata <- data %>% filter(date >= Sys.Date() - 7 & location != c("International", "World")) %>% select(c(date, location, population, total_cases_per_million, new_deaths, new_deaths_per_million, total_tests_per_thousand, hospital_beds_per_100k))

##Take a peek at the dataset of interest
head(todaydata)


##Let's check for NA values for this dataset of interest. 
##Check for NA values
sum(is.na(todaydata$new_deaths_per_million))
sum(is.na(todaydata$location))
sum(is.na(todaydata$total_cases_per_million))
sum(is.na(todaydata$total_tests_per_thousand))
sum(is.na(todaydata$hospital_beds_per_100k))

##Let's first do two things:
##- replace NA values with 0 for new_deaths_per_million and total_cases_per_million. It makes sense to do this as 0 is the likely value for blank (NA) new_deaths_per_million and the total_cases_per_million for the past one week.
##- impute values for total_tests_per_thousand with mean values as it is unlikely that the missing values are 0. 

##Let's first replace na values with 0 for new_deaths_per_million. (It seems that blank new_deaths_per_million and total_cases_per_million contain the same observations)
##Let's also replace na values with 0 for total_tests_per_thousand to enable us to compute the mean values. 
##Store the values in todaydata2.
todaydata2 <- todaydata %>% drop_na(new_deaths_per_million) %>% group_by(location) %>% mutate(total_tests_per_thousand = replace_na(total_tests_per_thousand, 0)) 

##compute the mean for each location for total_tests_per_thousand and store the values in todaydata3. 
todaydata3 <- todaydata2 %>% group_by(location) %>% summarise(mean_total_tests_per_thousand = mean(total_tests_per_thousand))
head(todaydata3)

##Replace 0 values for total_tests_per_thousand with the mean values and store these values in todaydata4
todaydata4 <- left_join(todaydata2, todaydata3, by = "location") %>% group_by(location) %>% mutate(total_tests_per_thousand = ifelse(total_tests_per_thousand==0, mean_total_tests_per_thousand,total_tests_per_thousand)) 

##Store the dataset back to the original dataset, which is "todaydata"
todaydata <- todaydata4 %>% select(-mean_total_tests_per_thousand)
todaydata

##remove the intermediary variables to avoid clutter
rm(todaydata2, todaydata3, todaydata4)

##Check for NA values for the dataset of interest. 
##Check for NA values
sum(is.na(todaydata$new_deaths_per_million))
sum(is.na(todaydata$location))
sum(is.na(todaydata$total_cases_per_million))
sum(is.na(todaydata$total_tests_per_thousand))
sum(is.na(todaydata$hospital_beds_per_100k))

##Finally, let's replace missing values with 0 for hospital_beds_per_100k. This is a reasonable estimate as countries with few hospital beds are the ones that are most likely not reporting the figures for hospital beds. 
##replace missing values for hospital_beds_per_100k with 0  
todaydata <- todaydata %>% mutate(hospital_beds_per_100k = replace_na(hospital_beds_per_100k, 0)) 
todaydata

##Make sure that we do not have any NA values in the dataset of interest, i.e. "todaydata". 
##Check for NA values
sum(is.na(todaydata$new_deaths_per_million))
sum(is.na(todaydata$location))
sum(is.na(todaydata$total_cases_per_million))
sum(is.na(todaydata$total_tests_per_thousand))
sum(is.na(todaydata$hospital_beds_per_100k))

##Ok, we are good to go for machine learning! 


#3. Results
##Let's start by partitioning our dataset of interest (todaydata) into training and test sets.  
##We need to set seed to ensure consistent partitioning of dataset
set.seed(1, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(1)` instead

##Test set to be 20% of the data
test_index <- createDataPartition(y = todaydata$new_deaths_per_million, times = 1, p = 0.2, list = FALSE)
train_set <- todaydata[c(-test_index),]
test_set <- todaydata[c(test_index),]

##Alright, now we have our training and test sets. 

##Just to recap our machine learning formula is new_deaths_per_million ~ location + total_cases_per_million + total_tests_per_thousand + hospital_beds_per_100k

##Random forest and linear regression are proposed to be the machine learning algorithms to predict the new_deaths_per_million. Random forest is proposed due to its built-in ensembling capacity, which is suitable in examining and predicting the values in the dataset. We are going to compare its performance with that of linear regression using the RMSE method. 

##Let's start with random forest algorithm. 
##rerun the set seed again to ensure a consistent result
set.seed(1, sample.kind="Rounding")

##fit the random forest algorithm
##tune the parameters by minimising the RMSE metric and ntree = 285 - which was discovered by trial and error.
##warning: this may take some time - around 30 minutes depending on the computer specifications. 
fit <- train(new_deaths_per_million ~ location + total_cases_per_million + total_tests_per_thousand + hospital_beds_per_100k, data = todaydata, method = "rf", metric = "RMSE", maximise = FALSE, ntree = 285)

##Let's see how accurate the prediction is by checking the result for one observation in the test set.  
y_hat_rf_1 <- predict(fit, data.frame(location = "Malaysia", total_cases_per_million = 215.597, total_tests_per_thousand = 14.2820000, hospital_beds_per_100k = 1.900))
y_hat_rf_1

##Given that the actual result for the observation is 0.031, the predicted result: 0.03503344 seems quite close!

##Let's now use linear regression algorithm. 
##rerun the set seed again to ensure a consistent result
set.seed(1, sample.kind="Rounding")

##fit the linear regression algorithm
##ignoring the rank deficient warnings are we are using standardised figures, i.e. per million, per thousand, etc. 
fit_lm <- train(new_deaths_per_million ~ location + total_cases_per_million + total_tests_per_thousand + hospital_beds_per_100k, data = todaydata, method = "lm")

##Let's see how accurate the prediction is by checking the result for one observation in the test set.  
y_hat_lm_1 <- predict(fit_lm, data.frame(location = "Malaysia", total_cases_per_million = 215.597, total_tests_per_thousand = 14.2820000, hospital_beds_per_100k = 1.900))
y_hat_lm_1

##Given that the actual result for the observation is 0.031, the predicted result: 0.03764966 seems close too!

##We need a more objective way to evaluate the performance of the two proposed algorithms. This can be done via RMSE, which is taught in the course.

#RMSE formula
RMSE <- function(true_ratings, predicted_ratings){
  sqrt(mean((true_ratings - predicted_ratings)^2))
}


##Let's see how well our random forest algorithm performs
##Random forest performance
y_hat_rf <- predict(fit, test_set)

##RMSE of the random forest algorithm
RMSE(y_hat_rf, test_set$new_deaths_per_million)

##And compare that with the performance of the linear regression model. 
##Linear regression performance
y_hat_lm <- predict(fit_lm, test_set)

##RMSE of the random forest algorithm
RMSE(y_hat_lm, test_set$new_deaths_per_million)


#4. Conclusion
##We have shown that new_deaths_per_million is correlated with location, total_cases_per_million, total_tests_per_thousand, and hospital_beds_per_100k. And it is easy to see why. Location captures most of the information pertaining to the demographic characteristics that contribute to the number of deaths. Number of total cases, tests, and hospital beds are directly correlated with mortality too. 

##With that understanding, we have also proceeded to predict the proposed dependent variable - new_deaths_per_million - using random forest and linear regression algorithms. The random forest algorithm with ntree=285 gives a far more accurate prediction than the linear regression algorithm, as we can see from the RMSE of the random forest algorithm - 0.7913566 - which is almost twice better than the RMSE of the linear regression algorithm - 1.565675. Given that lives are potentially at stake here, it is clear that the random forest algorithm should be used for predicting the number of new deaths instead of the linear regression algorithm. 

##There is scope to further build on this project to better predict the total number of new deaths. This project is limited by one week worth of data, and by the proposed random forest algorithm which is slow and prone to inconsistent results induced by the daily update of the dataset (if we were to run the prediction model on a daily basis). As such, the random forest algorithm has to be tuned regularly based on the new update of the dataset to derive accurate predictions - which takes time and could cause frustrations given the high stakes.  

##Future work can overcome such limitations by using time series analysis (e.g. ARIMA) that allows the whole dataset - not just one week worth of data - to be digested and incorporated into a machine learning algorithm suitable for time series. One should also consider using a machine learning algorithm that can outperform the random forest algorithm, such as XGBoost - an algorithm that is quite popular in Kaggle. 