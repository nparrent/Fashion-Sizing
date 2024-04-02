setwd("C:\\Users\\npleg\\OneDrive\\Documents\\University of Montana\\BGEN 694\\Anthropometric Project")

##install.packages("tidyverse")
install.packages("moments")
library(tidyverse)
library(dplyr)
library(foreign)

## Merging Data###################################################################################################################

anthrodata <- read.xport("P_BMX.xpt")
head(anthrodata)
str(anthrodata)
summary(anthrodata)


demodata <-read.xport("P_DEMO.xpt")
head(demodata)
summary(demodata)

mergeddata <-merge(anthrodata, demodata, by=c("SEQN"), all=FALSE)
head(mergeddata)
summary(mergeddata)

summary(mergeddata)
mergeddata$BMXBMI

# Cleaning Data########################################################################################################################

# Keeping only usable columns
variables.of.interest<- mergeddata[ , c("SEQN","RIAGENDR", "RIDAGEYR", "RIDRETH3", "RIDRETH1", "RIDEXPRG", "INDFMPIR", "BMDSTATS", "BMXWT","BMIWT", "BMXHT", "BMIHT", "BMXBMI", "BMXWAIST", "BMIWAIST", "BMXHIP", "BMIHIP")]

## Change class types of variables
glimpse(variables.of.interest)
variables.of.interest$RIAGENDR <- as.integer(variables.of.interest$RIAGENDR)
variables.of.interest$RIDAGEYR <- as.integer(variables.of.interest$RIDAGEYR)
variables.of.interest$RIDRETH3 <- as.factor(variables.of.interest$RIDRETH3)
variables.of.interest$RIDRETH1 <- as.factor(variables.of.interest$RIDRETH1)
variables.of.interest$RIDEXPRG <- as.integer(variables.of.interest$RIDEXPRG)
variables.of.interest$INDFMPIR <- as.numeric(variables.of.interest$INDFMPIR)
variables.of.interest$BMDSTATS <- as.factor(variables.of.interest$BMDSTATS)
variables.of.interest[,c(8,10,12,15,17)] <- sapply(variables.of.interest[,c(8,10,12,15,17)],as.integer)

class(variables.of.interest$RIAGENDR)

## Convert to in and lbs

variables.of.interest$BMXWT_lbs <- round((variables.of.interest$BMXWT * 2.20462),2)
variables.of.interest$BMXWAIST_in <- round((variables.of.interest$BMXWAIST * 0.393701),2)
variables.of.interest$BMXHIP_in <- round((variables.of.interest$BMXHIP * 0.393701),2)
variables.of.interest$BMXHT_in <- round((variables.of.interest$BMXHT * 0.393701),2)

## Why is there only 8000 for gender
##unique_values <- unique(mergeddata$RIAGENDR)
##print(unique_values)
##category_counts_df <- as.data.frame(table(mergeddata$RIAGENDR))
##print(category_counts_df )


#### Filter out men, children, pregnant women and add income
finalDataset <- variables.of.interest %>% 
  select(RIDAGEYR, RIAGENDR, BMXWT_lbs, BMXHT_in, BMXWAIST_in, BMXHIP_in, RIDEXPRG, BMXBMI,) %>% 
  filter(RIAGENDR == 2) %>% 
  filter(RIDAGEYR >=18) %>% 
  filter(data_wo_preg <-RIDEXPRG %in% c(2,3,NA))%>% 
  mutate(RIDEXPRG = replace_na(RIDEXPRG, 4))%>% 
  filter(complete.cases(.))



## Full Final Dataset#####################################################################################################################
summary(finalDataset)

##write.table(variables.of.interest, file = "C:\\Users\\npleg\\Documents\\GitHub\\project-deliverable-1-fashion-industry-standardized-sizing\\data\\Final.csv")

summary(finalDataset$BMXWAIST_in)


## FUll Dataset Histograms

bin_width <- 5
finalDataset$BMXWAIST_in_groups <- cut(finalDataset$BMXWAIST_in, breaks = seq(min(finalDataset$BMXWAIST_in), max(finalDataset$BMXWAIST_in) + bin_width, bin_width))

# Display descriptive statistics
summary(finalDataset$BMXWAIST_in_groups)


# Histogram of Population by Waist Size
hist(finalDataset$BMXWAIST_in, main="Survey Population by Waist Size",
     xlab="Waist Size (inches)",
     ylab="Frequency",
     border="black",
     col=rgb(214, 196, 198, maxColorValue = 255),
     xlim=c(18,90),
     ylim=c(0, 500), 
     las=1,
     breaks=20)
median_value <- median(finalDataset$BMXWAIST_in)
abline(v = median_value, col = "black", lty = 1, lwd = 3, lend = 3)
label <- "Median: "

text(x = max(finalDataset$BMXWAIST_in) + -23, y = 500, 
     labels = paste(label, round(median_value, 2), "inches"), col = "black", pos = 2, cex = 1.2)

# Boxplot
boxplot(finalDataset$BMXWAIST_in,
        hotizontal = TRUE,
        main = "Box Plot for Waist Size in Inches",
        xlab = "Sample Population",
        border = "black",
        col = rgb(214, 196, 198, maxColorValue = 255),
        ylab = "Waist Size (inches)")

##text(x = boxplot.stats(finalDataset$BMXWAIST_in)$stats, labels = boxplot.stats(finalDataset$BMXWAIST_in)$stats, y = 1.25)
boxplot_obj <- boxplot(finalDataset$BMXWAIST_in, add = TRUE, col = "transparent", boxwex = 0.5)
text(seq_along(boxplot_obj$stats[, 1]), boxplot_obj$stats[, 3], 
     labels = sprintf("Median: %.2f\nIQR: %.2f", boxplot_obj$stats[, 3], diff(boxplot_obj$stats[, c(2, 4)])), 
     pos = 3, offset = 1)

# Compute IQR using boxplot.stats
summary_stats <- boxplot.stats(finalDataset$BMXWAIST_in)

# Display the summary
cat("Summary Statistics:\n")
cat("Min:", summary_stats$stats[1], "\n")
cat("Q1 (25th percentile):", summary_stats$stats[2], "\n")
cat("Median (50th percentile):", summary_stats$stats[3], "\n")
cat("Q3 (75th percentile):", summary_stats$stats[4], "\n")
cat("Max:", summary_stats$stats[5], "\n")
cat("IQR:", diff(summary_stats$stats[c(2, 4)]), "\n")

# Skewness and Kurtosis
library("moments")
skewness(finalDataset$BMXWAIST_in)
kurtosis(finalDataset$BMXWAIST_in)



### Percentiles#####################################################################################################

value <- 34
half <- finalDataset$BMXWAIST_in

# Use ecdf to create the cumulative distribution function
ecdf_function <- ecdf(half)

# Use the ecdf function to find the percentile
percentile <- round(ecdf_function(value) * 100, 2)

# Print the result
print(paste("The value", value, "is at the", percentile, "th percentile."))


# Outliers ##############################################################################################################################
quantile(finalDataset$BMXWAIST_in, 0.25, type=2)
quantile(finalDataset$BMXWAIST_in, 0.5, type=2)
quantile(finalDataset$BMXWAIST_in, 0.75, type=2)

Q1 <- quantile(finalDataset$BMXWAIST_in, 0.25, type=2)
Q3 <- quantile(finalDataset$BMXWAIST_in, 0.75, type=2)

IQR <- (Q3 - Q1)

lower_limit <- Q1 - 1.5 * IQR 
print(lower_limit)
upper_limit <- Q3 + 1.5 * IQR
print(upper_limit)
outliers <- finalDataset[finalDataset$BMXWAIST_in < lower_limit | finalDataset$BMXWAIST_in > upper_limit,]
print(outliers)
count(outliers)


#Remove Outliers #################################################################################################
CleanData <- finalDataset[finalDataset$BMXWAIST_in >= lower_limit & finalDataset$BMXWAIST_in <= upper_limit, ]
count(CleanData)

IQR(finalDataset$BMXWAIST_in, type=2)

# Histogram Outliers Removed
hist(CleanData$BMXWAIST_in, main="Clean Data Histo Outliers Removed",
     xlab="Waist Size (inches)",
     ylab="Frequency",
     border="blue",
     col="green",
     xlim=c(20,90),
     las=1,
     breaks=25)

# Descriptive Stats
summary(CleanData$BMXWAIST_in)

# Skewness and Kurtosis
library("moments")
skewness(CleanData$BMXWAIST_in)
kurtosis(CleanData$BMXWAIST_in)
mean(CleanData$BMXWAIST_in)
median(CleanData$BMXWAIST_in)

CleanData$difHipWst <- CleanData$BMXHIP_in - CleanData$BMXWAIST_in
diff <- CleanData$difHipWst
summary(diff)

## Add a Column for Difference in Hip to Waist Size#########################################
finalDataset$difHipWst <- finalDataset$BMXHIP_in - finalDataset$BMXWAIST_in
finalDiff <- finalDataset$difHipWst

summary(finalDiff)

# Histogram of Hip/Waist Difference #########################################################################
hist(finalDataset$difHipWst, main="Survey Population Difference in Hip-Waist",
     xlab="Waist Size (inches)",
     ylab="Frequency",
     border="black",
     col=rgb(214, 196, 198, maxColorValue = 255),
     xlim=c(-10,22),
     ylim=c(0, 600), 
     las=1,
     breaks=20)
median_value <- median(finalDataset$difHipWst)
abline(v = median_value, col = "black", lty = 1, lwd = 3, lend = 3)
label <- "Median: "

text(x = max(finalDataset$difHipWst) + -6, y = 500, 
     labels = paste(label, round(median_value, 2), "inches"), col = "black", pos = 2, cex = 1.2)

# Boxplot
boxplot(finalDataset$difHipWst,
        hotizontal = TRUE,
        main = "Box Plot for Waist Size in Inches",
        xlab = "Sample Population",
        border = "black",
        col = rgb(214, 196, 198, maxColorValue = 255),
        ylab = "Waist Size (inches)")

##text(x = boxplot.stats(finalDataset$BMXWAIST_in)$stats, labels = boxplot.stats(finalDataset$BMXWAIST_in)$stats, y = 1.25)
boxplot_obj <- boxplot(finalDataset$BMXWAIST_in, add = TRUE, col = "transparent", boxwex = 0.5)
text(seq_along(boxplot_obj$stats[, 1]), boxplot_obj$stats[, 3], 
     labels = sprintf("Median: %.2f\nIQR: %.2f", boxplot_obj$stats[, 3], diff(boxplot_obj$stats[, c(2, 4)])), 
     pos = 3, offset = 1)

# Compute IQR using boxplot.stats
summary_stats <- boxplot.stats(finalDataset$difHipWst)

# Display the summary
cat("Summary Statistics:\n")
cat("Min:", summary_stats$stats[1], "\n")
cat("Q1 (25th percentile):", summary_stats$stats[2], "\n")
cat("Median (50th percentile):", summary_stats$stats[3], "\n")
cat("Q3 (75th percentile):", summary_stats$stats[4], "\n")
cat("Max:", summary_stats$stats[5], "\n")
cat("IQR:", diff(summary_stats$stats[c(2, 4)]), "\n")

# Skewness and Kurtosis
library("moments")
skewness(finalDataset$BMXWAIST_in)
kurtosis(finalDataset$BMXWAIST_in)

## Correlation
waist <- finalDataset$BMXWAIST_in
diff <- finalDataset$difHipWst
plot(waist, diff, col = "blue", pch = 16,
     xlab = "Waist Size (inches)", 
     ylab = "Difference in Waist to Hip (inches)",
     main = "Correlation between Waist Size and Waist to Hip Difference")

# Add correlation coefficient to the plot
correlation_coefficient <- cor(waist, diff)
text(x = min(waist), y = max(diff), 
     labels = paste("Correlation =", round(correlation_coefficient, 2)), pos = 4)

regression_model <- lm(diff ~ waist)
abline(regression_model, col = "red", lty = 1)


#############################################################
##    Split Data into two sets   ############################
############################################################
# Choose the splitting threshold (e.g., median or number)
Split_Data <- data.frame(finalDataset)
split_threshold <- 34

# Use dplyr to split the dataset
half1 <- subset(Split_Data, finalDataset$BMXWAIST_in <= split_threshold)
half2 <- subset(Split_Data, finalDataset$BMXWAIST_in > split_threshold)

# Print the results
print("First Half:")
summary(half1)

print("Second Half:")
summary(half2)


## Standard Deviations
sd(half1$BMXWAIST_in)
sd(half2$BMXWAIST_in)
sd(half1$difHipWst)
sd(half2$difHipWst)

#Variance
varSkinny <- var(half1$difHipWst)
print(varSkinny)

varFat <- var(half2$difHipWst)
print(varFat)


## Comparing 

skinny <- half1$difHipWst
fat <- half2$difHipWst

mean(skinny)
mean(fat)

sd(skinny)
sd(fat)

varSkinny <- var(half1$difHipWst)
print(varSkinny)

varFat <- var(half2$difHipWst)
print(varFat)

t.test(skinny, fat, paired = FALSE, alternative = "less") 

#### # Histogram of Skinny Waist Size
hist(skinny, main="Difference Hip/Waist (< size 14)",
     xlab="Waist Size (inches)",
     ylab="Frequency",
     border="black",
     col=rgb(214, 196, 198, maxColorValue = 255),
     xlim=c(-3,20),
     ylim=c(0,250), 
     las=1,
     breaks=20)
mean_value <- mean(skinny)
abline(v = mean_value, col = "black", lty = 1, lwd = 3, lend = 3)
label <- "Mean: "

text(x = max(skinny) + -4, y = 200, 
     labels = paste(label, round(mean_value, 2), "inches"), col = "black", pos = 2, cex = 1.2)

#### # Histogram of Fat Waist Size
hist(fat, main="Difference Hip/Waist (> size 14)",
     xlab="Waist Size (inches)",
     ylab="Frequency",
     border="black",
     col=rgb(214, 196, 198, maxColorValue = 255),
     xlim=c(-7,20),
     ylim=c(0,500), 
     las=1,
     breaks=20)
mean_value <- mean(fat)
abline(v = mean_value, col = "black", lty = 1, lwd = 3, lend = 3)
label <- "Mean: "

text(x = max(fat) + -12, y = 475, 
     labels = paste(label, round(mean_value, 2), "inches"), col = "black", pos = 2, cex = 1.2)


library("moments")
skewness(skinny)
kurtosis(skinny)
mean(skinny)
median(skinny)

skewness(fat)
kurtosis(fat)
### Percentiles#####################################################################################################

value <- 10
diffPercent<- finalDataset$difHipWst

# Use ecdf to create the cumulative distribution function
ecdf_function <- ecdf(diffPercent)

# Use the ecdf function to find the percentile
percentile <- round(ecdf_function(value) * 100, 2)

# Print the result
print(paste("The value", value, "is at the", percentile, "th percentile."))

############################################
########   Hip-Waist Calcs    ##############
############################################
#Statistic on Difference Hip-Waist 
summary(finalDataset)
summary(finalDataset$difHipWst)

#Assign variable names to DataFrame Column objects#############################
waist <- finalDataset$BMXWAIST_in
hip <- finalDataset$BMXHIP_in
diff <- hip - waist
var <- var(diff)

summary(diff)
print(var)

##(samp_means <- c(mean(waist), mean(hip)))
##(samp_sd <- c(sd(waist), sd(hip)))
##(samp_cor <- cor(waist, hip))

#### Create regression model #################################################

waistHip <- lm(finalDiff ~ waist)
summary(waistHip)

# Generate predicted values and residuals 
# and add them to the data frame
waistHip$diff <- predict(waistHip) 
waistHip$waist <- residuals.lm(waistHip)

waistHip

# Plot of Waist(in) vs Hip (in) 
plot(waist, diff, col=rgb(186, 156, 160, maxColorValue = 255), 
     xlab = "Waist Size (inches)", 
     ylab = "Difference in Hip to Waist (inches)", 
     xlim = c(20, 76), ylim= c(-10, 20))
##text(hip, waist, waist, cex = 0.6, pos = 3)

# Add Predicted Values to the Plot
abline(waistHip, col = "black", lty = 1)

##par(new = TRUE)
##plot(waist, diff, type=2,
     ##yaxt='n', ann=FALSE, col="blue",  xlim = c(0, 80), ylim= c(0, 80))

# Obtaining Sums of Squares using ANOVA
(AnovaTest <- anova(waistHip))

#### 



### Multiple Regression Hip to Waist Diff vs multiple variables######################################################################
mod_waist <- lm(diff ~ waist) ##RIAGENDR, BMXWT_lbs, BMXHT_in, BMXWAIST_in, BMXHIP_in, RIDEXPRG, BMXBMI
summary(mod_waist)


#### Outlier Tests ###################################################################################
mod_waist <- lm(diff ~ waist)
summary(mod_waist)

leverage <- hatvalues(mod_waist)
stud_res <- rstudent(mod_waist)
cook_dist <- cooks.distance(mod_waist)

df_home <-data.frame(diff, waist, leverage, stud_res, cook_dist)
print(round(df_home,4))

max(df_home$cook_dist)

plot(leverage, diff, xlab = "Leverage for Difference", ylab = "Waist Size")
text(leverage, diff, labels=paste(waist), cex = 0.6, pos = 3, col = 2)

# Plot of Leverage (hat-value) versus Studentized Residuals
plot(leverage, stud_res, xlab = "Leverage for Home Value", ylab = "Studentized Residuals")

# Collinearity diagnostics using library "olsrr"
install.packages("olsrr")
library(olsrr)
ols_vif_tol(mod_waist)
ols_vif_tol(mod_waist)

ols_vif_tol(mod_waist)
ols_vif_tol(mod_waist)

# Alternatively, you can use the library "car"
# to calculate the VIF. Additionally, it
# provides the Durbin-Watson test
install.packages("car")
library(car)

vif(mod_waist)
vif(mod_waist)


### MR Waist and Hip Predicted by Weight######################################################################
mod_wtWaist <- lm(waist ~ CleanData$BMXWT_lbs) ## CleanData$RIDAGEYR +  +CleanData$BMXWT_lbs +  CleanData$BMXHT_in) ##RIAGENDR, BMXWT_lbs, BMXHT_in, BMXWAIST_in, BMXHIP_in, RIDEXPRG, BMXBMI
summary(mod_wtWaist)


mod_hip <- lm(hip ~ CleanData$BMXWT_lbs) ## CleanData$RIDAGEYR +  +CleanData$BMXWT_lbs +  CleanData$BMXHT_in) ##RIAGENDR, BMXWT_lbs, BMXHT_in, BMXWAIST_in, BMXHIP_in, RIDEXPRG, BMXBMI
summary(mod_hip)


mod_htHip <- lm(hip ~ CleanData$BMXHT_in + CleanData$BMXWAIST_in) ## CleanData$RIDAGEYR +  +CleanData$BMXWT_lbs +  CleanData$BMXHT_in) ##RIAGENDR, BMXWT_lbs, BMXHT_in, BMXWAIST_in, BMXHIP_in, RIDEXPRG, BMXBMI
summary(mod_htHip)

summay(finalDataset$BMXWAIST_in)

  