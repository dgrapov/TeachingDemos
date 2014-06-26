#------------------------------------
# getting started with R lesson 1
# by Dmitry Grapov
#------------------------------------

#------------------------------------
# GOALS:
# 1) limited overview of basic objects 
# 2) plot some data
# 3) create a data summary
# 4) focus on bare bones (try to avid convenience fxns for now) to learn basic concepts
#------------------------------------


#R tutorial
# this is a comment R doesn't interpret this
10 # works
a # what happens here
"a" # works
a<-10 # assignment
b<-a+1 # using a pre assigned variable

#Arithmetic
a + b #addition
a - b #subtraction
a * b #multiplication
a / b #division
a^b #exponentiation
a %/% b #integer division
a %% b #modulo (remainder) b%%a makes more sense
#Relational
a==b #is a equal to b
a>b # a is greater than b, use < for less than
a>=b # a is greater than or equal to

#Logical
! #not
a!=b # could also do !a==b    
& #and
| #or
&& #sequential and
|| #sequential or

#lets create a new variable to test the logical operators
x<-1:10 # note ':' creates a sequence
x!=a # notice how the shorter a is recycled
(id<-!x>=a) # notice we assigned the results to id and use () to print this
x>a|x<b # check if any criteria specified is TRUE
x>a&x<b # check if all criteria specified is TRUE

#Indexing
a[1] # get the first 'unit' of a
a[2] #  trying to reference something which doesn't exist, NA stands for missing value
x[2] # this works because x has length >=2
x[c(1,2,6:8)] # can use c() to get many specific elements
x[id] # we can also use a logical to get our object

# lets find out more about x
str(x) #structure, x is an integer vector (one dimension)
class(id) # is logical
length(x) # length

# next lets load some real data to experiment with
data(iris) # we use a function named data to load the iris data
str(iris) # structure
#notice we have 2 dimensions now, rows and columns
# now subset the object as object[rows,columns]
iris[1:5,3:4]
species<-iris$Species # in data.frames and list we can also reference columns with '$'
species<-iris[,"Species"] # or by name

#lets make some plots
plot(iris[,1:2]) # plot the first 2 columns
help(plot) #see what other arguments plot could take
plot(iris[,1],species) 
plot(iris[,1]~species) # plot is different because species is factor and formula notation "~" is used
plot(iris[,1]~species, col =c("red","green","blue")) # add a color
plot(iris[,1]~species, col =c("red","green","blue"),ylab=colnames(iris)[1]) # and label, use function colnames() to get column names and take the first columns name
plot(iris) # because we gave the whole data frame R calls pairs() and creates a scatterplot matrix
color<-c("red","green","blue")[species] # we can use the factor to subset our colors to create a color for each point
plot(iris, pch=21,bg=color, main="My Awesome Plot!") # here we give custom point shape 'pch', border 'col' and inner color 'bg' as well as a title 'main'

#next lets experiment with getting summary statics
mean(iris) # we want to get the mean but giving the whole data.frame with the factor does not make sense?
mean(iris[,1]) # this works
mean(iris[,"Species"]) # this was the issue, it is not numeric (we could coerce 'as.numeric' but why?)
mean(iris[iris$Species=="setosa",1]) # here we subset the rows to only get values for the species setosa and return the mean for column 1 for this group

#get all column means for setosa
apply(iris[iris$Species=="setosa",1:4],2,mean) #here we use function apply to for each column  use the function mean (see help(apply)) 
# we also removed species because we know mean wont work on this and also causes bad behaviour for other columns

# now lets get the means for each species
big.l<-split(iris[,1:4], iris$Species) # create a list holding a data.frame for each level of the species
(res<-lapply(big.l,apply,2,mean)) # get means for each species and variable
data.frame(res) # get results combined
t(data.frame(res)) # transpose results 










