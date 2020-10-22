args<-commandArgs(TRUE)

vectr<-read.csv(args[1], header = FALSE, sep = ",")[,-1]
size<-nrow(vectr)

if (size == 1) {
	three <- rep(3,ncol(vectr))
	zero <- rep(0,ncol(vectr))
	vectr <- rbind(three, zero)
}

tool<-basename(args[1])
split<-strsplit(tool, "_")

distance<-mean(dist(vectr, method = "manhattan"))

#write(paste0(split[[1]][1], " cluster ",split[[1]][2] ," euclidian middle distance ",rating),file=args[1],append=TRUE)

cat(paste0(split[[1]][1],",",split[[1]][2],",",distance,",",size,'\n'))
