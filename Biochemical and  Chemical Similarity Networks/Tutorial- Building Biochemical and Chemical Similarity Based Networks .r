#load needed functions: package devium which is stored on a github 
source("http://pastebin.com/raw.php?i=JVyTrYRD")

# get sample chemical identifiers here:https://docs.google.com/spreadsheet/ccc?key=0Ap1AEMfo-fh9dFZSSm5WSHlqMC1QdkNMWFZCeWdVbEE#gid=1
#Pubchem CIDs = cids
cids # overview
nrow(cids) # how many
str(cids) # structure, wan't numeric 
cids<-as.numeric(as.character(unlist(cids))) # hack to break factor 

#get KEGG RPAIRS
#making an edge list based on CIDs from KEGG reactant pairs
KEGG.edge.list<-CID.to.KEGG.pairs(cid=cids,database=get.KEGG.pairs(),lookup=get.CID.KEGG.pairs())
head(KEGG.edge.list)
dim(KEGG.edge.list) # a two column list with CID to CID connections based on KEGG RPAIS
# how did I get this?
#1) convert from CID to KEGG  using get.CID.KEGG.pairs(), which is a table stored:https://gist.github.com/dgrapov/4964546
#2) get KEGG RPAIRS  using get.KEGG.pairs() which is a table stored:https://gist.github.com/dgrapov/4964564
#3) return CID pairs

#get EDGES based on chemical similarity (Tanimoto distances >0.07)
tanimoto.edges<-CID.to.tanimoto(cids=cids, cut.off = .7, parallel=FALSE)
head(tanimoto.edges)
# how did I get this?
#1) Use R package ChemmineR to querry Pubchem PUG to get molecular fingerprints
#2) calculate simialrity coefficient
#3) return edges with similarity above cut.off

#after a little bit of formatting make combined KEGG + tanimoto edge list
# https://docs.google.com/spreadsheet/ccc?key=0Ap1AEMfo-fh9dFZSSm5WSHlqMC1QdkNMWFZCeWdVbEE#gid=2

#now upload this and a sample node attribute table (https://docs.google.com/spreadsheet/ccc?key=0Ap1AEMfo-fh9dFZSSm5WSHlqMC1QdkNMWFZCeWdVbEE#gid=1)
#to Cytoscape
