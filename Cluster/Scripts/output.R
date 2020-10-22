args<-commandArgs(TRUE)
vectr<-read.csv(args[1], header = FALSE, sep = ",")

summe <- setNames(aggregate(vectr$V4, list(vectr$V1), sum ), c("V1", "V5"))
tab2 <- merge(vectr, summe, by.x = "V1", by.y="V1")
tab2$V6 <- tab2$V3*(tab2$V4/tab2$V5)

tab3<-setNames(aggregate(tab2$V6, list(tab2$V1), FUN = function(x) c(sum = round(sum(x, na.rm = T),3)) ), c("tool", "distance"))

write.csv(tab3, args[2], quote=FALSE, row.names = FALSE) 
