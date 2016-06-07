table = read.csv("/Users/xuxinyan/Documents/GSR/UC_Recruit_SQL/STEM/Diversity_Datasets.csv")
names = unique(unlist(strsplit(as.character(table[,1]), ';')))
dataset_names = names[order(names)]
write.csv(dataset_names,file="/Users/xuxinyan/Documents/GSR/UC_Recruit_SQL/STEM/Unique_Diversity_Datasets.csv")
