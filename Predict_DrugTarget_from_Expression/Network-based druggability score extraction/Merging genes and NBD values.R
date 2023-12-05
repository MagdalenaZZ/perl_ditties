setwd()
#Map gene list to uniprots if needed
#List of Uniprot IDs with header "PAC"
prot_list<-read.csv("Uniprots.csv")

#Spreadsheet of NBD values from Costas' paper - https://doi.org/10.1371/journal.pcbi.1004597
nbd<-read.csv("NBD_from_paper.csv")

total <- merge(gene_list,nbd,by="PAC")
write.csv(total, "Network-based_druggability_assesment_of_hits.csv")
