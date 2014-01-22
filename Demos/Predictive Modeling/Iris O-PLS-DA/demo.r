# Orthogonal Signal Correction Partial Least Squares Discriminant Analysis
# O-PLS-DA demo using Iris data
source("http://pastebin.com/raw.php?i=JVyTrYRD") # load functions
# The goal is to predict the species of the flower based on four physical properties.
data(iris)
tmp.data<-iris[,-5]
tmp.group<-iris[,5] # species
tmp.y<-matrix(as.numeric(tmp.group),ncol=1) # make numeric matrix

# The data will be split into 1/3 test and 2/3 trainning sets
# Model performance will be estimated based
# generate external test set
train.test.index.main=test.train.split(nrow(tmp.data),n=1,strata=tmp.group,split.type="duplex",data=tmp.data)
train.id<-train.test.index.main=="train"

#partition data to get the trainning set
tmp.data<-tmp.data[train.id,]
tmp.group<-tmp.group[train.id]
tmp.y<-tmp.y[train.id,]

#the variables could be scaled now, or done internally in the model for each CV split (leave-one-out)
# scaled.data<-data.frame(scale(tmp.data,center=TRUE, scale=TRUE)) 
scaled.data<-tmp.data

#make OSC model
mods<-make.OSC.PLS.model(tmp.y,pls.data=scaled.data,comp=3,OSC.comp=2, validation = "LOO",method="oscorespls", cv.scale=TRUE, progress=FALSE)
# view out-of-bag error for cross-validation splits
plot.OSC.results(mods,plot="RMSEP",groups=tmp.group)
# the red line shows the score for a 3 component or latent variable (LV) PLS model with no orthogonal components
# because the dependant variable (Y) is discreet this is simply called PLS-DA
# looking for the simplest models with lowest error we could choose
# the 2 LV and 1 orthogonal LV (OLV) model, which has the lowest root mean squared error of prediction (RMSEP)
mods<-make.OSC.PLS.model(tmp.y,pls.data=scaled.data,comp=2,OSC.comp=1, validation = "LOO",method="oscorespls", cv.scale=TRUE, progress=FALSE)
#
#we can also look at the change in model scores for each sample as we increase the number of OLVs
plot.OSC.results(mods,plot="scores",groups=tmp.group)
# The goal is to capture the maximum separation between groups in the x-axis or the predictive LV
# Species scores for the chosen model look well resolved. 
# This suggest that we are off to a good start 
# or more specifically that the variables we have can be used to classify species of Iris flowers.

# Ideally the within species variance should be maximally orthogonal to the between species variance (goal to maximize)
# in this case we see this represented by the vertical spread of the three species scores

#The chosen model can be extracted and reploted to show individual sample scores
final<-results<-get.OSC.model(obj=mods,OSC.comp=1)
plot.PLS.results(obj=final,plot="scores",groups=tmp.group)

# next we can check how likely is our fit by generating
# model statistics while randomly shuffling the Y (permutation testing)
# now generate permuted statistics for 100 models
permuted.stats<-permute.OSC.PLS(data=scaled.data,y=as.matrix(tmp.y),n=100,ncomp=2,osc.comp=1, progress=FALSE)
#look how our model compares to random chance
OSC.validate.model(model=mods,perm=permuted.stats)
# Q2 represents the in-bag or error for the training data 
# Xvar the variance in the variables (X) explained or captured in the model
# RMSEP is the out-of-bag error 
# The p-values are from a single-sample t-Test comparing our models 
# performance parameters (single values) to the permuted distribution (n=100)

#next we can estimate the external (for our initial training set) out-of-bag error by conducting model training and testing
#generate 100 random splits of the data into 1/3 test and 2/3 trainning sets
# and sample equally for each species (strata)
train.test.index=test.train.split(nrow(scaled.data),n=100,strata=as.factor(tmp.y))
train.stats<-OSC.PLS.train.test(pls.data = scaled.data,pls.y  = tmp.y,train.test.index ,comp=2,OSC.comp=1,cv.scale=TRUE, progress=FALSE)

#Compare the ditributions for the models performance statistics permuted values
OSC.validate.model(model=mods,perm=permuted.stats,train=train.stats)
# This suggests that we have a strong model (far better than random chance)
#  which capable of correctly predicting the species of the flower.

# We can now test this assumption by predicting the species labels 
# for the test set we excluded from our data before we even started modeling
# (an interesting idea would to use the test set to predict the labels for the training set)

#reset data
scaled.data<-iris[,-5]
tmp.group<-iris[,5] # species
tmp.y<-matrix(as.numeric(tmp.group),ncol=1) # make numeric matrix

#make predictions for the test set
mods<-make.OSC.PLS.model(tmp.y,pls.data=scaled.data,comp=2,OSC.comp=1, validation = "LOO",
method="oscorespls", cv.scale=TRUE, progress=FALSE,train.test.index=train.test.index.main)

#get the true (actual) and predicted values, round them to integers representing the 
# discreet species labels
plot.data=data.frame(predicted = round(mods$predicted.Y[[2]][,1],0),actual= mods$test.y)
# note these are numeric but we would prefer to interpret classification of species a class
plot.data$predicted<-factor(plot.data$predicted,labels=levels(iris[,5]),levels=1:3)
plot.data$actual<-factor(plot.data$actual,labels=levels(iris[,5]),levels=1:3)

table(plot.data)
# we see that we misclassified two virginica as versicolor, but are otherwise perfect
#this is expected based on the similarity in physical properties between these two species
pairs(iris[,-5],pch=21,bg=rainbow(nlevels(iris[,5]),alpha=.75)[iris[,5]],upper.panel=NULL)
par(xpd=TRUE)
legend(.75,1,levels(iris[,5]),fill=rainbow(nlevels(iris[,5]),alpha=.75),bty="n")
# we can plot an O-PLS-DA m