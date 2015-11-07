Orthogonal Signal Correction Partial Least Squares (O-PLS) Discriminant Analysis (O-PLS-DA)
========================================================

See here for more [O-PLS](https://raw.github.com/dgrapov/devium/master/R/Devium%20PLS%20%20and%20OPLS.r) methods or try [PLS](http://cran.r-project.org/web/packages/pls/index.html).



```r
source("http://pastebin.com/raw.php?i=UyDBTA57") # source Devium
```

```
## [1] "can't load: https://raw.githubusercontent.com/dgrapov/devium/master/R/Devium%20PCA.r"
```

O-PLS-DA demo using Iris data
The goal is to predict the species of the flower based on four physical properties.

This demonstration is focused on O-PLS-DA model: 
- [data pretreatment and preparation](#prep) 
- [model optimization](#oplsda)
- [permutation testing](#perm)
- [internal cross-validation](#intOOB)
- [external cross-validation](#extOOB)
- [Comparison of O-PLS-DA and Random Forest classification](#vergin_versi) (updated 11/7/15)


<a name="prep"/>
## Preparation for modeling

```r
data(iris)
tmp.data<-iris[,-5]
tmp.group<-iris[,5] # species
tmp.y<-matrix(as.numeric(tmp.group),ncol=1) # make numeric matrix
```

The data will be split into 1/3 test and 2/3 training sets.
The training data will be used for:

- model optimization
- permutation testing
- internally cross-validated estimate of training and out-of-bag error (OOB)

The hold out set or the test data will be used to estimate the externally validated OOB.

Generate external test set using the duplex or kennard stone method.

```r
train.test.index.main=test.train.split(nrow(tmp.data),n=1,strata=tmp.group,split.type="duplex",data=tmp.data)
train.id<-train.test.index.main=="train"

#partition data to get the trainning set
tmp.data<-tmp.data[train.id,]
tmp.group<-tmp.group[train.id]
tmp.y<-tmp.y[train.id,]

#the variables could be scaled now, or done internally in the model for each CV split (leave-one-out)
#scaled.data<-data.frame(scale(tmp.data,center=TRUE, scale=TRUE)) 
scaled.data<-tmp.data
```

<a name="oplsda"/>
## Train O-PLS-DA model 
Compare a 2 latent variable (LV) PLS-DA and 2 LV with one orthogonal LV (OLV) O-PLS-DA model.

```r
mods<-make.OSC.PLS.model(tmp.y,pls.data=scaled.data,comp=2,OSC.comp=1, validation = "LOO",method="oscorespls", cv.scale=TRUE, progress=FALSE)
#extract model
final<-get.OSC.model(obj=mods,OSC.comp=1)
#view out-of-bag error for cross-validation splits
plot.OSC.results(mods,plot="RMSEP",groups=tmp.group)
```

![](O-PLS_modeling_of_Iris_data_files/figure-html/unnamed-chunk-4-1.png) 

Ideally we want to select the simplest models with lowest root mean squared error of prediction (RMSEP), which in this case is calculated based on leave-one-one cross-validation. 

The 1 LV and 1 orthogonal LV (O-PLS-DA) model has similar error to a simple 2 LV PLS-DA model.

Next we can also compare the change in scores with the addition of the OLV. 

```r
plot.OSC.results(mods,plot="scores",groups=tmp.group)
```

![](O-PLS_modeling_of_Iris_data_files/figure-html/unnamed-chunk-5-1.png) 
Non-overlapping scores for each species could signify a well fit model, but we need to carry out some further validations to be sure.

```r
# plot.PLS.results(obj=final,plot="scores",groups=tmp.group)
plot.PLS(obj=final, results = "scores", color=data.frame(species=tmp.group), group.bounds="ellipse",g.alpha=.5, label=FALSE)
```

![](O-PLS_modeling_of_Iris_data_files/figure-html/unnamed-chunk-6-1.png) 
Ideally the within species variance should be maximally orthogonal to the between species variance (our goal to maximize)in this case we see this represented by the vertical spread of the three species scores.

<a name="perm"/>
# Permutation Testing
Next we can compare our model fit to random chance. We can do this using permutation testing by generating models for a randomly permuted species label (Y). We will generate 50 permuted models and compare their performance statics to our model. We also first want to generate a pseudo-training/test split for our training data in order to correctly simulate the RMSEP. The permuted models will be fit using the pseudo-training data and then used to predict the species label for the pseudo-test set.

```r
train.test.index<- test.train.split(nrow(scaled.data),n=100,strata=as.factor(tmp.y)) # strata controls if the species are sampled from equally
permuted.stats<- permute.OSC.PLS(data=scaled.data,y=as.matrix(tmp.y),n=50,ncomp=2,osc.comp=1, progress=FALSE,train.test.index=train.test.index)
#look how our model compares to random chance
OSC.validate.model(model=final,perm=permuted.stats)
```

```
##                            RX2                  Q2            RMSEP
## model                    99.51              0.9246           0.2242
## permuted model 99.05 +/- 0.747 -0.08075 +/- 0.0541 0.837 +/- 0.0528
## p-value               7.56e-05           4.078e-64        4.087e-54
```

- Q2 represents the in-bag or error for the training data 
- Xvar the variance in the variables (X) explained or captured in the model
- RMSEP is the out-of-bag error (OOB)
- The p-values are from a single-sample t-Test comparing our models 
 performance parameters (single values) to their respective permuted distributions 

<a name="intOOB"/>
# Internal (training set) Cross-validation
Next we can estimate the OOB error within the training set by conducting model training and testing. This is done using the pseudo-training/test split we generated for the model permutations. 


```r
train.stats<-OSC.PLS.train.test(pls.data = scaled.data,pls.y  = tmp.y,train.test.index ,comp=2,OSC.comp=1,cv.scale=TRUE, progress=FALSE)
```

Now we can compare the distributions for our models' performance statistics to their respective permuted distributions.


```r
OSC.validate.model(model=mods,perm=permuted.stats,train=train.stats)
```

```
##                            Xvar                  Q2             RMSEP
## model          99.51 +/- 0.0777   0.8982 +/- 0.0393 0.2233 +/- 0.0243
## permuted model  99.05 +/- 0.747 -0.08075 +/- 0.0541  0.837 +/- 0.0528
## p-value               6.745e-05           2.076e-86         1.068e-61
```

This suggests that we have a strong model (far better than random chance) which capable of correctly predicting the species of the flower.
<a name="extOOB"/>
# Model testing
Finally we want to estimate the true estimate of the OOB error by predicting the species labels for the test set we excluded from our data before we even started modeling.

The idea is that the test set was never involved in any of our modeling decisions (pretreatment, feature selection, etc) and is the most honest estimate of our models predictive performance.

```r
#reset data
scaled.data<-iris[,-5]
tmp.group<-iris[,5] 
tmp.y<-matrix(as.numeric(tmp.group),ncol=1)  

#make predictions for the test set
mods<-make.OSC.PLS.model(tmp.y,pls.data=scaled.data,comp=2,OSC.comp=1, validation = "LOO",
method="oscorespls", cv.scale=TRUE, progress=FALSE,train.test.index=train.test.index.main)

#get the true (actual) and predicted values
#round them to integers to represent discreet species labels
plot.data=data.frame(predicted = round(mods$predicted.Y[[2]][,1],0),actual= mods$test.y)
#note these are numeric but we would prefer to interpret classification of species a class
plot.data$predicted<-factor(plot.data$predicted,labels=levels(iris[,5]),levels=1:3)
plot.data$actual<-factor(plot.data$actual,labels=levels(iris[,5]),levels=1:3)

table(plot.data)
```

```
##             actual
## predicted    setosa versicolor virginica
##   setosa         17          0         0
##   versicolor      0         15         0
##   virginica       0          2        17
```

Based on the similarity between virginica and versicolor species' physical properties we expect this to be the most difficult classification to get correct.


```r
pairs(iris[,-5],pch=21,bg=rainbow(nlevels(iris[,5]),alpha=.75)[iris[,5]],upper.panel=NULL,cex=2)
par(xpd=TRUE)
legend(.75,1,levels(iris[,5]),fill=rainbow(nlevels(iris[,5]),alpha=.75),bty="n")
```

![](O-PLS_modeling_of_Iris_data_files/figure-html/unnamed-chunk-11-1.png) 

O-PLS-DA becomes very useful when there are many variables. Model loadings on LV 1 (x-axis) can be used to linearly rank variables with respect to explaining differences in samples which are represented by the model scores. This approach is useful for reducing multidimensional comparisons (e.g. multiple class comparisons, genotype/treatment/time point) to single dimensional ranking of each variable representing it's weight for explaining a given hypothesis (Y) and the goodness of the answer depends on the strength of the produced model. 

<a name="vergin_versi"/>
#### Lets see if we can build a model to discriminate between verginica and versicolor and compare performance between O-PLS-DA and random 
#### Predict classes using O-PLS-DA
Lets split the data into train (2/3) test (1/3) sets and compare O-PLS-DA to Random Forest classification performance.

```r
library(dplyr)
library(caret)
# set up data 
data<-iris %>% filter(Species != "setosa") %>% droplevels()
#make numeric
group<-data$Species %>% as.numeric()

#convert to (horrible idea "train", "test")
set.seed(106)
inTraining <- createDataPartition(group, p = 2/3, list = FALSE)
train.index<-rep("test",nrow(data)) 
train.index[inTraining]<-"train"

mods<-make.OSC.PLS.model(group,
                         pls.data=data %>% select(-Species),
                         train.test.index = train.index,
                         comp=2,OSC.comp=1, validation = "LOO",
                         method="oscorespls", cv.scale=TRUE, progress=FALSE)
#extract model
final<-get.OSC.model(obj=mods,OSC.comp=1)

#get performance for test set
pred<-mods$predicted.Y[[2]] %>% matrix() %>%
#predictions need to be made descreet
  round(0)
#constrained to original bounds
pred[pred<0]<-1
pred[pred>2]<-2
obs<-mods$test.y
#back convert from numeric
obs<-obs %>% factor(.,labels=c("versicolor","verginica"))
pred<-pred %>% factor(.,labels=c("versicolor","verginica"))

table(pred,obs)
```

```
##             obs
## pred         versicolor verginica
##   versicolor         15         0
##   verginica           1        16
```

#### The performance does not look bad. Lets visualize the misclassified sample using PCA.

```r
#PCA to visualize test and train samples
args<-list(  pca.data       = data,
            pca.algorithm   = "svd",
            pca.components  = 2,
            pca.center      = FALSE, #need to fix requirement...
            pca.scaling     = "none"
            )

#calculate and view scree plot          
res<-devium.pca.calculate(args,return="list",plot=TRUE)
```

![](O-PLS_modeling_of_Iris_data_files/figure-html/unnamed-chunk-13-1.png) 

```r
#set up plot
#show groups
group<-data$Species 
group<-join.columns(data.frame(group,train.index),"_")
#id misclassified samples
id<-seq_along(1:nrow(data))
id<-id[!id %in% inTraining]
#mis
miss<-id[obs != pred]
tmp<-rep("_",length(group))
tmp[miss]<-"wrong"
group<-join.columns(data.frame(group,tmp),"_") %>% gsub("__","",.)

p.args<-list( 
            pca = res,
            results = "scores",
            color = data.frame(group),
            label=FALSE,
            group.bounds ="none",
            size=5
            )

do.call("plot.PCA",p.args)
```

![](O-PLS_modeling_of_Iris_data_files/figure-html/unnamed-chunk-13-2.png) 

#### Now lets fit and evaluate a random forest model using the `caret` library. 

```r
#create a classification model using random forests
#generate training/test set
group<-data$Species

train.data <- data[ inTraining,]
test.data  <- data[-inTraining,]
train.y <- group[ inTraining] %>% droplevels()
test.y <- group[ -inTraining] %>% droplevels()

#set cross-validation parameters
fitControl <- trainControl(
                          method = "repeatedcv",
                          number = 3,
                          ## repeated ten times
                          repeats = 3,
                          classProbs = TRUE,
                          summaryFunction = twoClassSummary
                )


#fit model to the training data
set.seed(825)
fit<- train(train.y ~ ., data = train.data,
            method = "rf",
            trControl = fitControl,
            metric = "ROC",
            tuneLength = 3  
         )

#fit to the trainning data
print(fit)
```

```
## Random Forest 
## 
## 68 samples
##  4 predictor
##  2 classes: 'versicolor', 'virginica' 
## 
## No pre-processing
## Resampling: Cross-Validated (3 fold, repeated 3 times) 
## 
## Summary of sample sizes: 46, 46, 44, 45, 46, 45, ... 
## 
## Resampling results across tuning parameters:
## 
##   mtry  ROC  Sens  Spec  ROC SD  Sens SD  Spec SD
##   2     1    1     1     0       0        0      
##   3     1    1     1     0       0        0      
##   5     1    1     1     0       0        0      
## 
## ROC was used to select the optimal model using  the largest value.
## The final value used for the model was mtry = 2.
```

```r
#predict RF
#predict the test set
pred<-predict(fit,newdata=test.data)
prob<-predict(fit,newdata=test.data,type="prob")
obs<-test.y
table(pred,obs)
```

```
##             obs
## pred         versicolor virginica
##   versicolor         16         0
##   virginica           0        16
```

```r
#twoClassSummary(data=data.frame(obs,pred,prob),lev=levels(pred))
```

#### The random forest (RF) model does better than O-PLS, but this is pretty siple data set. From my experience RF is far more robust than O-PLS-DA for classification. It nicely handles multiple classes, is robust to over fitting and unlike O-PLS can be calculated in parallel.
