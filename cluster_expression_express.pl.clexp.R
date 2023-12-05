 x<-read.table("/users/k1470436/bin/perl/cluster_expression_express.pl.ts",header=T) 
pdf("/users/k1470436/bin/perl/cluster_expression_express.pl.ts.clexp.pdf", useDingbats=FALSE)
     x.sd1 <- apply(x,1, sd) 
#x.sd
     x.mean <- apply(x, 1, mean) 
#x.mean
     losd <- x.mean - x.sd1  
#losd 
     hisd <-  x.mean + x.sd1  
#hisd 
     x.sd <- rbind(losd,hisd)
x.sd
 plot(x=1:5,y=apply(x,1,mean),ylim=c(min(x),max(x)),type="n",xaxt="n",xlab="Lifecycle stage",ylab="Normalised log fold expression change") 
axis(side=1, at=seq(1,5), labels=c("","","","",""), las=2) 
apply(x,2,function(x) { lines(x,lwd=1,col=sample(colours())) } ) 
polygon(x=c(1:5,5:1),y=c(x.sd[1,],rev(x.sd[2,])),col=rgb(0.3,0.3,0.3,0.4), border=NA) 
lines(apply(x,1,mean), col = "brown4", lwd=2) 
dev.off() 
