args<-commandArgs(TRUE)
vectr<-read.csv(args[1], header = FALSE, sep = ",")

tab<-setNames(aggregate(vectr$V5, list(vectr$V1), FUN = function(x) c(min = round(min(x, na.rm = T),3), max = round(max(x, na.rm = T), 3), mean = round(mean(x, na.rm = T), 3), std = round(sd(x, na.rm = T), 3)) ), c("x", "x"))
write.csv(tab, args[2], quote=FALSE, row.names = FALSE) 

tab2<-setNames(aggregate(vectr$V3, list(vectr$V1), FUN = function(x) c(min = round(min(x, na.rm = T),3), max = round(max(x, na.rm = T), 3), mean = round(mean(x, na.rm = T), 3), std = round(sd(x, na.rm = T), 3)) ), c("x", "x"))
write.csv(tab2, args[3], quote=FALSE, row.names = FALSE) 
