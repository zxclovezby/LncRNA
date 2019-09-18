#!/share/nas2/genome/biosoft/R/3.1.1/lib64/R/bin/Rscript


# usage function
usage <- function() {
	print("-------------------------------------------------------------------------------")
	print("Usage: Rscript bin/kog_anno_plot.r in.stat out.png")
	print("1) in.stat: the stat file for KOG anno")
	print("2) out.png: the filename for output")
	print("3) title: the title of the png ")
	print("-------------------------------------------------------------------------------")
}


# get args
args <-commandArgs(TRUE)

# check args length
if( length(args) != 3 ) {
	print(args)
	usage()
	stop("the length of args != 2")
}



# load library
library(ggplot2)
library(grid)


# get args
args <-commandArgs(TRUE)


# reading data
data <- read.delim(args[1], header=TRUE, sep="\t",check.names = FALSE)
head(data)


# plot
df <- data.frame(Frequency=data[,3], group=data[,1])
labels <- paste(data[,1], data[,2], sep=": ")
p <- ggplot(data=df, aes(x=group, y=Frequency)) + geom_bar(aes(fill=group), stat="identity")
p <- p + theme_classic()
p<- p+theme(panel.border = element_rect(colour = "black", fill=NA, size=0.5))
p <- p + scale_fill_discrete(name="", breaks=sort(data[,1]), labels=sort(labels))
p <- p + theme(legend.key.size=unit(0.5, "cm"))+guides(fill=guide_legend(ncol=1))
p <- p + labs(x="Function Class", title=args[3])

# remove background, horizontal & vertical grid lines 
p <- p  + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# output plot
png(filename=args[2], height = 3000, width = 5000, res = 500, units = "px")
print(p)
dev.off()




