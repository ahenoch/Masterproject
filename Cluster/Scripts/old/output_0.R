args<-commandArgs(TRUE)
vectr<-read.csv(args[1], header = FALSE, sep = ",")
tab<-setNames(aggregate(vectr$V5, list(vectr$V1), FUN = function(x) c(min = min(x, na.rm = T),max = max(x, na.rm = T),mean = mean(x, na.rm = T),std = sd(x, na.rm = T)) ), c("x", "x"))
write.csv(tab, args[2], quote=FALSE, row.names = FALSE) 