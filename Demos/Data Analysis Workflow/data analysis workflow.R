#------------------------
# Dmitry Grapov, PhD
# CDS- Creative Data Solutions
# 10/2/15
#------------------------

#------------------------
# Example of an Omics 
# data analysis strategies
# 1) exploratory analysis
# 2) statistical analysis
# 3) predictive modeling
# 4) functional analysis

#dependencies
{
pkg<-c("ggplot2","dplyr","R.utils","fdrtool","caret","randomForest","pROC")
lapply(pkg, function(x) {
  if(!require(x,character.only = TRUE)) install.packages(x,character.only = TRUE)
	}
)


#bioConductor
source("https://bioconductor.org/biocLite.R")
if(!require("pcaMethods")) biocLite("pcaMethods")
if(!require("pathview")) biocLite("pathview")
if(!require("KEGGREST")) biocLite("KEGGREST")


}


#set working directory
wd<-"C:/Users/Dmitry/Dropbox/Software/TeachingDemos/Demos/Data Analysis Workflow/"
setwd(wd)

#load devium functions
{
sourceDirectory( "R",recursive=TRUE,verbose=TRUE)
}

# load data
# anonymized real-world data set
# comparing sick and healthy patients
# metabolite and protein profiles
{
load(file="data/data cube") # data.obj
data.cube<-data.obj$raw
#take a look at the parts
str(data.cube)
}

# 1) exploratory analysis
{

#Principal Components Analysis (PCA)
{

#raw
{
args<-list(	pca.data 		= data.cube$data,
			pca.algorithm 	= "svd",
			pca.components 	= 8,
			pca.center 		= FALSE,
			pca.scaling 	= "none",
			pca.cv 			= "q2"
			)
			
#calculate and view scree plot			
res<-devium.pca.calculate(args,return="list",plot=TRUE)

#plot results
#scores highlighting healthy and sick
p.args<-list( 
			pca = res,
			results = "scores",
			color = data.cube$sample.meta[,"group",drop=FALSE],
			font.size = 3
			)

do.call("plot.PCA",p.args)

#loadings
p.args<-list( 
			pca = res,
			results = "loadings",
			color = data.cube$variable.meta[,"type",drop=FALSE],
			font.size = 3
			)

do.call("plot.PCA",p.args)

#now try with scaling
args<-list(	pca.data 		= data.cube$data,
			pca.algorithm 	= "svd",
			pca.components 	= 8,
			pca.center 		= TRUE,
			pca.scaling 	= "uv",
			pca.cv 			= "q2"
			)
			
#calculate and view scree plot			
res2<-devium.pca.calculate(args,return="list",plot=TRUE)

#plot results
#scores highlighting healthy and sick
p.args<-list( 
			pca = res2,
			results = "scores",
			color = data.cube$sample.meta[,"group",drop=FALSE],
			font.size = 3
			)

do.call("plot.PCA",p.args)

#loadings
p.args<-list( 
			pca = res2,
			results = "loadings",
			color = data.cube$variable.meta[,"type",drop=FALSE],
			font.size = 3
			)

do.call("plot.PCA",p.args)


#scores highlighting batches
p.args<-list( 
			pca = res2,
			results = "scores",
			color = data.cube$sample.meta[,"batch",drop=FALSE],
			font.size =3
			)

do.call("plot.PCA",p.args)
}

#normalized
{
data.cube<-data.obj$normalized
#now try with scaling
args<-list(	pca.data 		= data.cube$data,
			pca.algorithm 	= "svd",
			pca.components 	= 8,
			pca.center 		= TRUE,
			pca.scaling 	= "uv",
			pca.cv 			= "q2"
			)
			
#calculate and view scree plot			
res<-devium.pca.calculate(args,return="list",plot=TRUE)

#plot results
#scores highlighting healthy and sick
p.args<-list( 
			pca = res,
			results = "scores",
			color = data.cube$sample.meta[,"group",drop=FALSE],
			font.size = 3
			)

do.call("plot.PCA",p.args)

#scores highlighting batches
p.args<-list( 
			pca = res,
			results = "scores",
			color = data.cube$sample.meta[,"batch",drop=FALSE],
			font.size =3
			)

do.call("plot.PCA",p.args)
}



}
}

# 2) statistical analysis
{
#get summaries and t-test stats
data<-data.cube$data
meta<-data.cube$sample.meta[,"group",drop=FALSE] 

#get summary
.summary<-stats.summary(data,comp.obj=meta,formula=colnames(meta),sigfigs=3,log=FALSE,rel=1,do.stats=TRUE)
stats.obj<-cbind(data.cube$variable.meta,.summary)
head(stats.obj)
write.csv(stats.obj,file="results/statistical_results.csv")
}

# 3) Predictive modeling
{
#create a classification model using random forests
#generate training/test set
set.seed(998)
data<-data.cube$data
inTraining <- createDataPartition(data.cube$sample.meta$group, p = 2/3, list = FALSE)
train.data <- data[ inTraining,]
test.data  <- data[-inTraining,]
train.y <- data.cube$sample.meta$group[ inTraining] %>% droplevels()
test.y <- data.cube$sample.meta$group[ -inTraining] %>% droplevels()

#set model parameters
fitControl <- trainControl(## 10-fold CV
                           method = "repeatedcv",
                           number = 3,
                           ## repeated ten times
                           repeats = 3,
						   classProbs = TRUE,
						   verboseIter =TRUE,
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
fit
# create ROC curve
#create ROC curve for test
plot(roc(as.numeric(predict(fit,newdata=train.data)),as.numeric(train.y)))


#predict the test set
pred<-predict(fit,newdata=test.data)
prob<-predict(fit,newdata=test.data,type="prob")
obs<-test.y
#get performance stats
twoClassSummary(data=data.frame(obs,pred,prob),lev=levels(pred))
#create ROC curve for test
plot(roc(as.numeric(pred),as.numeric(obs)))

}

# 4) pathway enrichment analysis
{
# carry out analysis to identify enriched pathways
# Here  used IMPaLa: http://impala.molgen.mpg.de/
# load gene names as entrez, metbolites as KEGG

#format data to show fold changes in pathway
#get formatted data for pathview
library(KEGGREST)
library(pathview)
data<-stats.obj
#metabolite
met<-data %>% dplyr::filter(type =="metabolite") %>%
	dplyr::select(ID,mean.sick_mean.healthy) %>% 
	mutate(FC=log(mean.sick_mean.healthy)) %>% dplyr::select(-mean.sick_mean.healthy)
#protein
prot<-data %>% dplyr::filter(type =="protein") %>%
	dplyr::select(ID,mean.sick_mean.healthy) %>% 
	mutate(FC=log(mean.sick_mean.healthy)) %>% dplyr::select(-mean.sick_mean.healthy)

#set rownames
rownames(met)<-met[,1];met<-met[,-1,drop=FALSE]
rownames(prot)<-prot[,1];prot<-prot[,-1,drop=FALSE]	

#select pathway to view
path<-"Glycolysis / Gluconeogenesis"
#get KEGG code and pathway IDs
data(korg)
organism <- "homo sapiens"
matches <- unlist(sapply(1:ncol(korg), function(i) {
    agrep(organism, korg[, i])
}))
(kegg.code <- korg[matches, 1, drop = F])

#get kegg pathway names
library(KEGGREST)
pathways <- keggList("pathway", kegg.code)
#get code of our pathway of interest
map<-grepl(path,pathways) %>% pathways[.] %>% names(.) %>% gsub("path:","",.)
#create image
setwd("./images")

pv.out <- pathview(gene.data = prot, cpd.data = met, gene.idtype = "SYMBOL", 
    pathway.id = map, species = kegg.code, out.suffix = map, keys.align = "y", 
    kegg.native = T, match.data = T, key.pos = "topright")
}