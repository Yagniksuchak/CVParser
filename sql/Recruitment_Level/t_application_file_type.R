library(reshape)
library(RMySQL)
mydb = dbConnect(MySQL(), user='root', password='kashauman10212015', dbname='final', host='localhost')
dbListTables(mydb)

qry1 = dbSendQuery(mydb, "select * from application_file_type")
data = fetch( qry1, n=-1)
data = data[,c(-4,-38)]
t_data = melt(data, id = c("application_file_type_id", "name", "file_type"))


tt_data = subset(t_data, value!=0)
tt_data = tt_data[order(tt_data$application_file_type_id),-5]
rownames(tt_data) = NULL
colnames(tt_data)[4] = 'filename'
head(tt_data)

dbWriteTable(mydb, name='t_application_file_type', value=tt_data, overwrite=T)

tt_data

dbDisconnect(mydb)