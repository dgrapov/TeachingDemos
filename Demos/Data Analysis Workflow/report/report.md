
##### The following is an example of a data analysis strategy for an integrated metabolomic and proteomic data set. This tutorial is meant to give examples of some of the major common steps in an omic integration analysis workflow. You can check out all of the code in `/report/report.Rmd`.


1. exploratory analysis

2. statistical analysis

3. predictive modeling

4. functional analysis







##### This data set contains 200 measurements for 54 samples. The samples are comprised of sick and healthy patients measured across two analytical batches.


```
## 
## healthy    sick 
##      27      27
```

```
## 
## batch_1 batch_2 
##      28      26
```

****

### Exploratory Analysis

****

##### A critical aspect of any data analysis should be to carry out an exploratory data analysis to see if there are any strange trends. Below is an example of a Principal Components Analysis (PCA). Lets start by looking at the raw data and caclculate PCA with out anys scaling. 

##### PCA has three main components we can use to evaluate our data. 
##### 1. Variance explained by each component
![](report_files/figure-html/unnamed-chunk-4-1.png) 

##### The scree plot above shows the total variance in the data explained (top) and the cumulative varince explained (bottom) by each principal component (PC). The green bars in the bottom plot show the cross-validated variance explained which can be used to give us an idea bout the stability of calculated components. How many PCs to keep can be determined based on a few criteria 1) each PC should explain some minnimum variance and 2)  calculate enough PCS to explain some target variance. The hashed line in the top plot shows PCs which explain less than 1% variance and the hashed line in the bottom plot shows how many PCs arerequired to explain 80% of the varince in the data. Based on an evaluation of the scree plot we may select 2 or 3 PCs. The cross-validated varince explained (green bars) also suggest that the variance explained does not increase after the first 2 PCs.

##### 2. The sample scores can be used to visualize multivariete similarities in samples given all the varibles for each PC. Lets plot the scores and highlight the sick and healthy groups.
![](report_files/figure-html/unnamed-chunk-5-1.png) 

#### Based on the scores above the sick and healthy samples look fairly similiar. Lets next look at the variable loadings.
#### 3. Variable loadings show the contribution of each varible to the calculated scores.

![](report_files/figure-html/unnamed-chunk-6-1.png) 

#### Evaluation of the loadings suggest that variance variables X838 abd X454 explain  ~90% of the varince in the data. Because we did not scale the data before conducting PCA, variables with the largest magnitude will contribute most to varince explained. 

#### Next lets recalculate the PCA and mean center and scale all the variables by their standard deviation (autoscale).
#### Variance explained
![](report_files/figure-html/unnamed-chunk-7-1.png) 

#### Variable loadings
![](report_files/figure-html/unnamed-chunk-8-1.png) 

#### Sample scores
![](report_files/figure-html/unnamed-chunk-9-1.png) 

#### There are some noticible differences in PCA after we scaled our data.
1. Variable magnitude no longer drives the majority of the variance.
2. We can see more resolution in variable loadings for the first 2 PCs.
3. There is an unexplained group structure in the score.

#### Next we can try mapping other meta data to score to see if we can explain the cluster pattern. Lets show the analytical batches in the samples scores.
![](report_files/figure-html/unnamed-chunk-10-1.png) 

#### We can see in the scores above that the analytical batch nicely explains 35% of the varince in the data. This is a common problem in large data sets which is best handled using various data normalization methods. Here is some more information about implementing data normalizations.

###### [Metabolomics and Beyond: Challenges and Strategies for Next-generation Omic Analyses](https://imdevsoftware.files.wordpress.com/2015/09/clipboard01.png?w=300&h=225)

[![Metabolomics and Beyond: Challenges and Strategies for Next-generation Omic Analyses](https://imdevsoftware.files.wordpress.com/2015/09/clipboard01.png?w=300&h=225)](https://www.youtube.com/watch?v=4AhBN5Q1oMs)

##### [Evaluation of data normalization methods](http://www.slideshare.net/dgrapov/case-study-metabolomic-data-normalization-example)

****

### Statistical Analysis

****

##### Next lets carry out a statistical analysis and summarise the changes between the sick and ghealthy groups. Below we identify significantly altered analytes using a basic t-test with adjustment for multiple hypotheses tested. We probably want to use more sophisticated and non-parametric tests for real applications.


```
## Generating data summary... 
## Conducting tests... 
## Conducting FDR corrections...
```

```
##       ID                     description       type
## 1 C00077                       ornithine metabolite
## 2 C02477                tocopherol alpha metabolite
## 3 C00097                        cysteine metabolite
## 4 C00031                         glucose metabolite
## 5 C00170 5'-deoxy-5'-methylthioadenosine metabolite
## 6 C00385                        xanthine metabolite
##   healthy.mean.....std.dev sick.mean.....std.dev mean.sick_mean.healthy
## 1            7300 +/- 2900         3910 +/- 2100                   0.54
## 2            1160 +/- 1400         2600 +/- 1200                   2.24
## 3            5160 +/- 2500         8460 +/- 3400                   1.64
## 4         335000 +/- 2e+05     144000 +/- 140000                   0.43
## 5               216 +/- 83           355 +/- 160                   1.64
## 6              574 +/- 350         1670 +/- 1500                   2.91
##   group_p.values group_adjusted.p.values group_q.values
## 1   9.433317e-06             0.001886663    0.000900412
## 2   1.505034e-04             0.007714558    0.003632462
## 3   1.507843e-04             0.007714558    0.003633836
## 4   1.542912e-04             0.007714558    0.003650646
## 5   2.004055e-04             0.008016221    0.003825749
## 6   3.909048e-04             0.013030159    0.006072846
```

#### We can visualize the differences in means for the top most altered metabolite and protein as a box plot.
![](report_files/figure-html/unnamed-chunk-12-1.png) ![](report_files/figure-html/unnamed-chunk-12-2.png) 

****

### Predictive Modeling

****

#### Next we can try a generate a non-linear multivarite classification model to identify important variables in our data. Below we will train and validate a random forest classifier. The full data set is split into 2/3 trainning and 1/3 test set while keeping the propotion of sick and healthy samples equivalent. The model is trained using 3-fold cross-validation repeated 3 times and the ```mtry``` parameter is optimized to maximize the are under the reciever operator characteristic curve (AUCROC).



#### Below the optimal model is chosen while varying the ```mtry``` or the number of variables randomly sampled as candidates at each split. 

```
## Random Forest 
## 
##  36 samples
## 199 predictors
##   2 classes: 'healthy', 'sick' 
## 
## No pre-processing
## Resampling: Cross-Validated (3 fold, repeated 3 times) 
## 
## Summary of sample sizes: 24, 24, 24, 24, 24, 24, ... 
## 
## Resampling results across tuning parameters:
## 
##   mtry  ROC        Sens       Spec       ROC SD      Sens SD    Spec SD  
##     2   0.7870370  0.7222222  0.7777778  0.08098544  0.2041241  0.1666667
##   101   0.8549383  0.7777778  0.7592593  0.10090044  0.1443376  0.2060055
##   200   0.8750000  0.8333333  0.7222222  0.09107554  0.1178511  0.2204793
## 
## ROC was used to select the optimal model using  the largest value.
## The final value used for the model was mtry = 200.
```

#### Next we can evaluate the model performance based on predictions for the test set. We can also look at the ROC curve. 

```
##          obs
## pred      healthy sick
##   healthy       7    2
##   sick          2    7
```

```
##       ROC      Sens      Spec 
## 0.9135802 0.7777778 0.7777778
```

#### We can also look at the ROC curve. 
![](report_files/figure-html/unnamed-chunk-16-1.png) 

```
## 
## Call:
## roc.default(response = obs, predictor = prob[, levels(pred)[1]],     silent = TRUE)
## 
## Data: prob[, levels(pred)[1]] in 9 controls (obs healthy) > 9 cases (obs sick).
## Area under the curve: 0.9136
```

#### Having validated our model next we can look at the most important variables driving the classification. We can look at the differences in performance when each variable is randomly permuted or the VIP.
![](report_files/figure-html/unnamed-chunk-17-1.png) ![](report_files/figure-html/unnamed-chunk-17-2.png) 

****

### Functional Analysis

****

#### Finally we can identify enriched biological pathways based on the integrated changes in genes and proteins. [IMPaLA: Integrated Molecular Pathway Level Analysis](http://impala.molgen.mpg.de/) can be used to calculate enriched pathways in genes or proteins and metabolites.To do this we can querry the significantly alterd proteins and metabolites for enriched pathways (see `results/statistical_results_sig.csv`). We can view the full analysis results in `results/IMPaLA_results.csv`. next lets take an enriched pathway and fisualize the fold changes between sick and healthy in the enriched species. 



#### Lets take a looka at the Glycolysis / Gluconeogenesis pathway. Our data needs to be formatted as below. You can also take a look at the following more detailed example of [mapping fold changes to biochemical pathways](https://github.com/dgrapov/TeachingDemos/blob/master/Demos/Pathway%20Analysis/KEGG%20Pathway%20Enrichment.md).

#### Metabolite data showing KEGG ids and log fold change

```
##                  FC
## C00379   0.41871033
## C00385   1.06815308
## C00105   0.07696104
## C00299  -0.24846136
## C00366   0.33647224
## C00086  -0.05129329
```

#### Protein data showing the Entrez gene name and log fold changes

```
##                 FC
## SPTAN1  -0.3424903
## CFH      0.1133287
## VPS13C   0.3148107
## XRCC6    1.0715836
## APOA1   -0.1392621
## SUPT16H  0.7129498
```

#### Next we need to get the pathway code for or pathway of interest.

```
##      kegg.code
## [1,] "hsa"
```

#### Now we can visualize the changes between sick and healthy in the Glycolysis / Gluconeogenesis pathway.

```
## [1] "hsa00010"
```
![](hsa00010.hsa00010.png)

****

#### This concludes this short tutorial. You may also find the following links useful.

* [Software tools](https://github.com/dgrapov)
* [More examples and demos](https://imdevsoftware.wordpress.com/)

&copy; Dmitry Grapov (2015) <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/" target="_blank"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-sa/4.0/80x15.png" /></a>
