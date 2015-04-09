setwd("C:\\Users\\D\\Dropbox\\Software\\TeachingDemos\\Demos\\Mapped Network From Data (Biochemical and Structural)")
setwd("C:\\Users\\Node\\Dropbox\\Software\\TeachingDemos\\Demos\\Mapped Network From Data (Biochemical and Structural)")
setwd("C:\\Users\\dgrapov\\Dropbox\\Software\\TeachingDemos\\Demos\\Mapped Network From Data (Biochemical and Structural)")
source("http://pastebin.com/raw.php?i=1Bs7G5ds")
#source devium 
source("http://pastebin.com/raw.php?i=UyDBTA57") #
#save()
# load objects
tmp.data<-read.csv("data.csv",row.names=1)
var.meta<-read.csv("variable info.csv")
sample.meta<-read.csv("sample info.csv")

# Calculate Network Connections
#---------------------------------
#identify required Pubchem CIDs and KEGG IDs
CIDS<-fixln(var.meta$PubChem)
KEGG<-fixlc(var.meta$KEGG)

#get KEGG RPAIRS
# load reaction DB and return all reactions of type main
reaction.DB<-get.KEGG.pairs(type="main")
kegg.edges<-get.Reaction.pairs(KEGG,reaction.DB,index.translation.DB=NULL,parallel=FALSE,translate=FALSE)

#create shared index to allow merging with other edge identifiers
index<-KEGG
edge.names<-data.frame(index, network.id = c(1:length(index)))
kegg.edges<-data.frame(make.edge.list.index(edge.names,kegg.edges))

#get structural similarity edges based on Tanimoto >0.7 
tanimoto.edges<-CID.to.tanimoto(cids=CIDS, cut.off = 0, parallel=FALSE)  #return all possible connections

#create shared index
index<-CIDS
edge.names<-data.frame(index, network.id = c(1:length(index)))
tmp<-make.edge.list.index(edge.names,tanimoto.edges)
tanimoto.edges[,1:2]<-tmp

#prepare tanimoto edges for merge with KEGG
tanimoto.edges$type<-"Tanimoto"

#merge the biochemical and structural similarity edge lists
kegg.edges$value<-1 # give arbitrary weight, here the max tanimoto can take
kegg.edges$type<-"KEGG" # set type to identify between KEGG and tanimoto

final.edge.list<-rbind(kegg.edges,tanimoto.edges) #note duplicated edges maybe prioritized diffrently in various orders 
#write.csv(final.edge.list,file="edge.list.csv") # uncomment to save the file

#render network for preview
{
edge.list<-clean.edgeList(data=final.edge.list)
tmp.edge.list<-edge.list[fixln(edge.list$value)>=0.7,]
ggplot2.network(tmp.edge.list,edge.color.var="type", bezier=FALSE,node.size=3, node.names=fixlc(var.meta$Name2),node.label.size = 3)

#removing unconnected nodes and getting names right
tmp.edge.list$source<-paste(" ",tmp.edge.list$source,sep="")
tmp.edge.list$target<-paste(" ",tmp.edge.list$target,sep="")

ggplot2.network(tmp.edge.list,edge.color.var="type", bezier=FALSE,node.size=3, node.names=node.names,node.label.size = 3)

#create node attributes
id<-unique(unlist(tmp.edge.list[,1:2]))
node.names<-data.frame(fixlc(var.meta$Name2)[fixln(gsub(" ","",id))])#[order(id,decreasing=TRUE)]

fct<-rep(c(1:2),length.out=nrow(node.names))
len<-length(unique(fct))
node.data<-data.frame(name=node.names[,],color=rainbow(len)[fct],size=seq(1,6,by=.5)[fct])
rownames(node.data)<-unique(unlist(tmp.edge.list[,1:2]))

ggplot2.network(edge.list=tmp.edge.list,edge.color.var="type", bezier=FALSE,node.size=3, 
node.data=node.data,node.names=node.names,
max.edge.thickness = 1,node.label.size = 3)


#create function to remove duplicated edges and self edges
# from an edgelist with diffrent types controling heirarchy of existence
edge.list<-data.frame(data.frame(source=c(3,2,3,4),target=c(3,2,1,3)))
edge.list$type<-c("a","b","b","b")
edge.list$extra<-c(1:4)
clean.edgeList(data=edge.list)

clean.edgeList<-function(source="source",target="target",type="type", data=edge.list){
   
    library(igraph)
    #remove self edges else if all self passed will cause an error
    el<-data[,c(source,target)]
    self<-el[,1]==el[,2]
    el<-el[!self,]
    tmp.data<-as.data.frame(as.matrix(data)[!self,])
    lel<-split(el,tmp.data$type)
    
    el.res<-do.call("rbind",lapply(1:length(lel),function(i){
      nodes<-matrix(sort(unique(matrix(as.matrix(lel[[i]]),,1))),,1)
      g<-graph.data.frame(lel[[i]],directed=FALSE,vertices=nodes)
      g.adj<-get.adjacency(g,sparse=FALSE,type="upper")
      g.adj[g.adj>0]<-1
      adj<-graph.adjacency(g.adj,mode="upper",diag=FALSE,add.rownames="code")
      get.edgelist(adj)
  }))
    
  ids<-unique(join.columns(el.res))  
  tmp<-data.frame(el,tmp.data[,!colnames(tmp.data)%in%c(source,target)])
  rownames(tmp)<-make.unique(join.columns(tmp[,1:2])) 
  flip<-!ids%in%rownames(tmp) 
  ids[flip]<-unique(join.columns(el.res[,2:1]))    
  return(tmp[ids,])  
    
}




#over lay paths and nodes as separate images?
.theme<- theme(
			axis.line = element_blank(), 
			axis.ticks = element_blank(),
			axis.title.x =  element_blank(), 
			panel.background = element_blank(), 
			plot.background = element_blank(),
			panel.grid = element_blank(),
			axis.text.x = element_blank(),
			axis.text.y = element_blank(),
			axis.title.x = element_blank(),
			axis.title.y = element_blank(),
			legend.key = element_blank()
		 )
		 
vis<-data.frame(x=1:2,y=3:4)
p<-ggplot(vis, aes(x=x,y=y))
p+geom_line()+.theme
png(file ="layer1.png", pointsize=1,width=600,height=600, bg = "transparent")
p+geom_line()+.theme
dev.off()
png(file ="layer2.png", pointsize=1,width=600,height=600, bg = "transparent")
p+geom_point(color="red",size=2)+.theme
dev.off()



library(png)
i1 <- readPNG("layer1.png", native=FALSE)
i2 <- readPNG("layer2.png", native=FALSE)

ghostize <- function(r, alpha=0.5)
  matrix(adjustcolor(rgb(r[,,1],r[,,2],r[,,3],r[,,4]), alpha.f=alpha), nrow=dim(r)[1])

grid.newpage()
grid.rect(gp=gpar(fill="white"))
grid.raster(i1)
grid.raster(i2)

library(png)
img <- readPNG("layer1.png")
r = as.raster(img[,,1:3])
r[img[,,4] == 0] = "white"

plot(1:2,type="n")
rasterImage(r,1,1,2,2)

N <- 1000 # Warning: slow
d <- data.frame(x1=rnorm(N),
                x2=rnorm(N, 0.8, 0.9),
                y=rnorm(N, 0.8, 0.2),
                z=rnorm(N, 0.2, 0.4))

v <- with(d, dataViewport(c(x1,x2),c(y, z)))

png("layer1.png", bg="transparent")
with(d, grid.points(x1,y, vp=v,default="native",pch=".",gp=gpar(col="blue")))
dev.off()
png("layer2.png", bg="transparent")
with(d, grid.points(x2,z, vp=v,default="native",pch=".",gp=gpar(col="red")))
dev.off()

library(png)
i1 <- readPNG("layer1.png", native=FALSE)
i2 <- readPNG("layer2.png", native=FALSE)

ghostize <- function(r, alpha=0.5)
  matrix(adjustcolor(rgb(r[,,1],r[,,2],r[,,3],r[,,4]), alpha.f=alpha), nrow=dim(r)[1])

grid.newpage()
grid.rect(gp=gpar(fill="white"))
grid.raster(ghostize(i1))
grid.raster(ghostize(i2))


#function to plot network in ggplot 2
#ggplot based network drawing fxn

ggplot2.network<-function(edge.list, edge.color.var = NULL, edge.color = NULL, directed = FALSE,
						node.data=NULL, node.color = NULL,  node.names=NULL, show.names = TRUE, node.shape=15,
						bezier = FALSE, node.size = 7,node.label.size = 5, max.edge.thickness = 2, color.scale=NULL,fill.scale=NULL, group.bounds=NULL){
	# edge list  = 2 column data.frame representing source and target. 
	# 	Columns over 2 will be sorted with edgelist and can be segment mapped to color transparency and width
	# edge.color.var = name of variable in edge list to use to color
	# edge.color = color for each level of object edge.color.var
	# directed = logical, if FALSE edge will be transposed and duplicated making undirected
	# node.color = colors for nodes, need to take into account node name ordering
	# show.names = can be supplied names for nodes, TRUE = network index, FALSE = nothing
	# node names should be a 2 column matrix with edge IDs and mapped names
	
	#should have a global node attributes (names, color, size, etc) object form which colnames are used for various mappings
	
	library(network) # as.network
	library(sna) # layouts
	library(ggplot2)
	library(Hmisc) # bezier edges
	
	# Function to generate paths between each connected node (very slow when transparent!)
	# adapted from : https://gist.github.com/dsparks/4331058
	edgeMaker <- function(whichRow, len = 100, curved = TRUE){
	  fromC <- layoutCoordinates[adjacencyList[whichRow, 1], ]  # Origin
	  toC <- layoutCoordinates[adjacencyList[whichRow, 2], ]  # Terminus
	 
	  # Add curve:
	  graphCenter <- colMeans(layoutCoordinates)  # Center of the overall graph
	  bezierMid <- c(fromC[1], toC[2])  # A midpoint, for bended edges
	  distance1 <- sum((graphCenter - bezierMid)^2)
	  if(distance1 < sum((graphCenter - c(toC[1], fromC[2]))^2)){
		bezierMid <- c(toC[1], fromC[2])
		}  # To select the best Bezier midpoint
	  bezierMid <- (fromC + toC + bezierMid) / 3  # Moderate the Bezier midpoint
	  if(curved == FALSE){bezierMid <- (fromC + toC) / 2}  # Remove the curve
	 
	  edge <- data.frame(bezier(c(fromC[1], bezierMid[1], toC[1]),  # Generate
								c(fromC[2], bezierMid[2], toC[2]),  # X & y
								evaluation = len))  # Bezier path coordinates
	  edge$Sequence <- 1:len  # For size and colour weighting in plot
	  edge$Group <- paste(adjacencyList[whichRow, 1:2], collapse = ">")
	   if(ncol(adjacencyList)>2){
			tmp<-data.frame(matrix(as.matrix(adjacencyList[whichRow, -c(1,2),drop=FALSE]),nrow = nrow(edge), ncol=ncol(adjacencyList)-2, byrow=TRUE))
			colnames(tmp)<-colnames(adjacencyList)[-c(1:2)]
			edge$extra<-tmp
			edge<-do.call("cbind",edge)
			colnames(edge)<-gsub("extra.","",colnames(edge))
		}
	  return(edge)
	  }
	 
  #straight edges
	edgeMaker2<-function(whichRow){
	  fromC <- layoutCoordinates[adjacencyList[whichRow, 1], ]  # Origin
	  toC <- layoutCoordinates[adjacencyList[whichRow, 2], ]  # Terminus
	 
	  edge <- data.frame(c(fromC[1], toC[1]), c(fromC[2] ,toC[2]))  # Generate
								 # X & )  # Bezier path coordinates
	  edge$Sequence <- 1 # For size and colour weighting in plot
	  edge$Group <- paste(adjacencyList[whichRow, 1:2], collapse = ">")
	  #get other info if supplied with edge list
	  if(ncol(adjacencyList)>2){
			tmp<-data.frame(matrix(as.matrix(adjacencyList[whichRow, -c(1,2),drop=FALSE]),nrow = nrow(edge), ncol=ncol(adjacencyList)-2, byrow=TRUE))
			colnames(tmp)<-colnames(adjacencyList)[-c(1:2)]
			edge$extra<-tmp
			edge<-do.call("cbind",edge)
			colnames(edge)<-gsub("extra.","",colnames(edge))
		}
	  colnames(edge)[1:2]<-c("x","y")
	  return(edge)
	  }
	
	# adding transposed source target edges to make undirected bezier curves
	if (bezier == TRUE) {
		if(all(!directed)) { is.rev<-rep(TRUE, nrow(edge.list)) } else { is.rev<-directed==TRUE }
		rev.edge.list<-data.frame(rbind(as.matrix(edge.list[,1:2]),as.matrix(edge.list[is.rev,2:1]))) # need matrix else no reordering of columns?
	} else{ 
		rev.edge.list<-edge.list[,1:2,drop=FALSE]
	}
	#extra info (separate now, later recombine)
	info<-edge.list[,-c(1:2)]
	
	#getting layout and making sure edge list ids are in the same order
	g<-as.network(rev.edge.list[,1:2],matrix.type = "edgelist") # 
	
	#layout
	node.layout<-gplot.layout.fruchtermanreingold(g[,], layout.par = NULL)
	
	n.edge.list<-as.matrix.network.edgelist(g)
	dimnames(node.layout)<-list(rownames(g[,]),c("x","y"))
	
	#preparing for edge path
	layoutCoordinates<-node.layout
	adjacencyList<-data.frame(n.edge.list,info)

	if (bezier == TRUE) {
		allEdges <- lapply(1:nrow(adjacencyList), edgeMaker, len = 500, curved = TRUE)
		allEdges <- do.call(rbind, allEdges)  # a fine-grained path ^, with bend ^
	 } else {
		#straight edges using same controls(faster)
		allEdges <- lapply(1:nrow(adjacencyList), edgeMaker2)
		allEdges <- do.call(rbind, allEdges)
	}
	allEdges$neg.Sequence<- - allEdges$Sequence

	#Edge Attributes
	#-------------------
	#set default plotting variables
	# Edge colors
	edge.guide = TRUE
	
	if(is.null(edge.color.var)){edge.list$edge.color.var<-1;edge.color.var<-"edge.color.var";edge.guide = FALSE}
	
	if(is.null(edge.color)){
			edge.color<-rainbow(nlevels(as.factor(with (edge.list, get(edge.color.var)))))
	} 
	
	#Node Attributes
	#-------------------
	node.obj<-tryCatch(data.frame(layoutCoordinates,node.data[rownames(node.layout),]), error=function(e){data.frame(layoutCoordinates)})
	#set defaults
	default<-factor(rep(1,nrow(node.obj)))
	# could match input column to those below here
	attribute<-c("size","color","shape")
	for(i in 1:length(attribute)){if(is.null(node.obj[[attribute[i]]])){node.obj[[attribute[i]]]<-default} }#else {node.obj[[attribute[i]]]<-factor(node.obj[[attribute[i]]])}}
	
	#default input
	#color
	if(is.null(node.color)){
			node.color<-rainbow(length(unique(node.obj$color)))
			col.scale<-scale_color_manual(values=node.color)
	}
	
	
	#size
	if(is.null(node.size)){
		node.size<-seq(3,7,length.out=length(unique(node.obj$size)))
		
	} 
	#shape
	if(is.null(node.shape)){
		node.shape<-rep(c(15:18),length.out=length(unique(node.obj$shape)))
	} 
		
	node.points<-geom_point(data = node.obj, aes(x = x, y = y, color=color, size=size),shape=15,show_guide = TRUE) #,shape=shape
	
		# # testing
		# zp1+node.points
		
		# zp1 <- ggplot()  # Pretty simple plot code
	# # bezier edges	
	# zp1 <- zp1 + geom_path(data=allEdges,aes_string(x = "x", y = "y", group = "Group",  # Edges with gradient
							   # colour = edge.color.var, size = "neg.Sequence"))  # and tap
		
		# zp1<-zp1+geom_point(data = node.obj, aes(x = x, y = y, color=color,size=size, shape=shape,fill=color),shape=21)
		# col.scale#,size=node.size,show_guide = FALSE)
	
  #labels
	if(is.null(node.obj$name)){
		node.obj$name<-rownames(node.obj)
	} 
	if(show.names==FALSE){node.obj$name<-rep("",nrow(node.layout))} #nothing
	
	node.labels<-geom_text(data = node.obj,  aes(x = x, y = y-.2, label = name), size = node.label.size)	# node names
	
	polygons<-NULL
# 	#add grouping vis
# 	#Hoettellings T2 ellipse
# 	polygons<-NULL
# 	if(group.bounds=="ellipse"){		
# 		ell<-get.ellipse.coords(cbind(x=node.obj$x,y=node.obj$y), group=node.obj$group)# group visualization via 
# 		polygons<-if(is.null(color)){
# 				geom_polygon(data=data.frame(ell$coords),aes(x=x,y=y), fill="gray", color="gray",linetype=2,alpha=g.alpha, show_guide = FALSE) 
# 			} else {
# 				geom_polygon(data=data.frame(ell$coords),aes(x=x,y=y, fill=group),linetype=2,alpha=g.alpha, show_guide = FALSE) 
# 			}
# 	}
# 	
# 
# 	if(group.bounds=="polygon"){
# 		ell<-get.polygon.coords(data.frame(tmp.obj),tmp$color)# group visualization via 
# 		polygons<-if(is.null(color)){
# 				geom_polygon(data=data.frame(ell),aes(x=x,y=y), fill="gray", color="gray",linetype=2,alpha=g.alpha, show_guide = FALSE) 
# 			} else {
# 				geom_polygon(data=data.frame(ell),aes(x=x,y=y, fill=group),linetype=2,alpha=g.alpha, show_guide = FALSE) 
# 			}
# 	}
	
	#set up for plotting
	#theme 
	new_theme_empty <- theme_bw()
	new_theme_empty$line <- element_blank()
	new_theme_empty$rect <- element_blank()
	new_theme_empty$strip.text <- element_blank()
	new_theme_empty$axis.text <- element_blank()
	new_theme_empty$plot.title <- element_blank()
	new_theme_empty$axis.title <- element_blank()
	new_theme_empty$plot.margin <- structure(c(0, 0, -1, -1), unit = "lines", valid.unit = 3L, class = "unit")
    new_theme_empty$legend.text <-element_text( size = 20)
	new_theme_empty$legend.title    <-element_text(size = 20 )  
	
		  
	
	# # node names (set above)
	# if(length(show.names) == attr(n.edge.list,"vnames")) { node.names <- show.names} 
	# if (show.names) { node.names<-attr(n.edge.list,"vnames") } 
	# if(!show.names){node.names<-rep("",nrow(node.layout))}
	#make plot
	zp1 <- ggplot()  # Pretty simple plot code
	#area
	zp1<-zp1 + polygons
	#edges	
	zp1 <- zp1 + geom_path(data=allEdges,aes_string(x = "x", y = "y", group = "Group",  # Edges with gradient
							colour = edge.color.var),size=max.edge.thickness)  # and taper # Customize taper					   
	#nodes	
	zp1 <- zp1 + node.points + node.labels
	# node.obj<-data.frame(layoutCoordinates, color = as.factor(node.color), shape=as.factor(node.shape))	
	# zp1 <- zp1 + geom_point(data = node.obj, aes(x = x, y = y, fill=color, shape=shape), size = node.size, colour = "black",  show_guide = node.guide)# Add
	# zp1<-zp1 + scale_fill_manual(values=fixlc(node.obj$color)) + scale_shape_manual(values =fixln(node.obj$shape))
	# zp1<-zp1 + geom_text(data = data.frame(layoutCoordinates, label = node.names),  aes(x = x, y = y-.2, label = label), size = node.label.size)	# node names
	zp1 <- zp1 + scale_colour_manual(values = c(node.color,edge.color)
	)
	# zp1 <- zp1 + scale_size(range = c(1/100, max.edge.thickness), guide = "none")  #edge thickness
	zp1 <-zp1 + guides(color = guide_legend(override.aes = list (size = 3))) + labs(color='Edge Type')	
	# Customize gradient 
	zp1 <- zp1 + new_theme_empty   # Clean up plot
	print(zp1)
}

}

#create Node attribute mappings
#---------------------------------
# color 	= direction or fold change or O-PLS-DA absolute loading
# size 		= log fold change or absolute value of O-PLS-DA loading on LV 1
# border 	= O-PLS-DA VIP >=1
# shape		= chemical class

# calculate summary statistics (fold change and p-value) for main hypothesis in study
{
# set main factor to sample.meta$group 
test.data<-log(tmp.data+1)#test shifted log transformed data
p.values<-multi.t.test(data=test.data, factor=sample.meta$group,paired=FALSE,progress=TRUE)
fold.change<-calc.FC(data=tmp.data,factor=sample.meta$group,denom=levels(sample.meta$group)[2],sig.figs=1,log=FALSE)
#fold change will need scaling and has some problems with 0 values 
fold.change[fold.change=="Inf"]<-0
#create summary table

stats<-data.frame(name=fixlc(var.meta$Name2),p.values,fold.change)
write.csv(stats,file="statistics.csv")
}

# do PCA 
{
pca.data<-tmp.data

#set PCA args
pca.inputs<-list()
pca.inputs$pca.algorithm<-"svd"
pca.inputs$pca.components<-4
pca.inputs$pca.center<-TRUE
pca.inputs$pca.scaling<-"uv"
pca.inputs$pca.data<-pca.data
pca.inputs$pca.cv<-"q2"

#calculate model
res<-devium.pca.calculate(pca.inputs,return="list",plot=FALSE) # need to recreate model in another format to plot

#plot scores by type
results<-"scores"#"biplot"#"scores","loadings","biplot")"screeplot"
color<-data.frame(group=sample.meta$group)
xaxis<-1
yaxis=2
group.bounds="ellipse"
plot.PCA(pca=res,results=results,yaxis=yaxis,xaxis=xaxis,size=4,color=color, label=T, legend.name =  NULL,font.size=1.75,group.bounds,alpha=.75)
# samples 37 and 13 maybe outliers
}

#O-PLS-DA
{
#calculate preliminary model
comp<-3
ocomp<-2

pls.y<-data.frame(group=as.numeric(sample.meta$group))
scaled.data<-data.frame(scale(pca.data,center=TRUE,scale=TRUE))
mods1<-make.OSC.PLS.model(pls.y=pls.y,pls.data=scaled.data,comp=comp,OSC.comp=ocomp,validation = "LOO",method="oscorespls",cv.scale=T)
plot.OSC.results(mods1,plot="scores",groups=color)
final<-get.OSC.model(obj=mods1,OSC.comp=ocomp)

#collect results for mapping
node.obj<-data.frame()

# plot scores
plot.PLS(obj=final,results="scores",color=color,group.bounds="ellipse")


#carry out feature selection

#feature selection
obj<-final
type<-"quantile"#"number"
top<-0.9
p.value=0.05
FDR=FALSE
separate=FALSE
.scores<-obj$scores[,]
.loadings<-obj$loadings[,]	
selected.features<-PLS.feature.select(pls.data=scaled.data,pls.scores=.scores[,1],pls.loadings=.loadings[,1],pls.weight=.loadings[,1],
				p.value=p.value, FDR=FDR,cut.type=type,top=top,separate=separate,type="spearman",make.plot=FALSE)
selected.features<-selected.features[,c(1,3,7)]
selected.features$VIP<-as.matrix(obj$VIP[,1,drop=F])
}

#map node attributes
{
tmp<-list()
tmp$ID<-1:length(selected.features$VIP)
tmp$color<-ifelse(fold.change>=1,"up","down")
tmp$size<-selected.features$VIP
tmp$selected<-selected.features$VIP>=1
tmp$name<-fixlc(var.meta$Name2)


node.attributes<-data.frame(do.call("cbind",tmp))
colnames(node.attributes)<-names(tmp)

#get db info for analytes
DB<-IDEOMgetR()
info<-enrichR.IDEOM(id=CIDS, from="PubChem CID",IDEOM.DB=DB)
tmp<-fixlc(info$Map)
tmp[is.na(tmp)]<-"other"

node.attributes$class<-tmp

write.csv(node.attributes,file="node.attributes.csv")

}