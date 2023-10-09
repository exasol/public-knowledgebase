# When Exporting to Multiple Files, Can You Control the Number of Records Per File?

## Question
I am using an export statement to store the records of a table into multiple files. I noticed that the size of the files and also the number of records per file is not equal and varias quite a bit. In the EXASOL documentation I found the following [statement](https://docs.exasol.com/db/latest/sql/export.htm):

> When specifying multiple files, the actual data distribution depends on several factors. It is also possible that some files are completely empty.

Is there any documentation on the "several factors" or what could I do to make sure that the number of records is more or less evenly distributed?

My query looks like the following (This is generated code, out of Wherescape):
```sql
EXPORT SELECT  grl_mrt_mzlg_m_syr_update_file_export.fileline AS fileline  
  FROM edd_dwh_grl.grl_mrt_mzlg_m_syr_update_file_export grl_mrt_mzlg_m_syr_update_file_export  
   INTO CSV AT CON_IG_FTP_MZLG_SYR_SND_DEV FILE 'NC104_PartnerFlagging_DWH_update.txt_1_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_2_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_3_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_4_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_5_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_6_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_7_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_8_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_9_202110709'  
   FILE 'NC104_PartnerFlagging_DWH_update.txt_10_202110709'  
   COLUMN SEPARATOR=';'  
COLUMN DELIMITER=''  
ENCODING='UTF-8'  
REPLACE
```
This results in the following:

|File Name|File Size|
|-|-|
NC104_PartnerFlagging_DWH_update.txt_1_202110709| 16,805 KB
NC104_PartnerFlagging_DWH_update.txt_2_202110709|17,108 KB
NC104_PartnerFlagging_DWH_update.txt_3_202110709| 14,080 KB
NC104_PartnerFlagging_DWH_update.txt_4_202110709 | 14,719 KB
NC104_PartnerFlagging_DWH_update.txt_5_202110709  | 12,087 KB
NC104_PartnerFlagging_DWH_update.txt_6_202110709  | 13,411 KB
NC104_PartnerFlagging_DWH_update.txt_7_202110709  | 15,463 KB
NC104_PartnerFlagging_DWH_update.txt_8_202110709  | 14,184 KB
NC104_PartnerFlagging_DWH_update.txt_9_202110709  | 16,713 KB
NC104_PartnerFlagging_DWH_update.txt_10_202110709| 26,862 KB

## Answer
Basically, each file is written with the data which is on the corresponding node(s). If the number of files is equal to the number of nodes, then each file will receive the data on that node. If the number of files are less/greater than the number of nodes, then the data on some nodes will be combined/split according to the number of files.
There is no guarantee that the data will be equally distributed.

Generally there is a 1:1 node/file ratio.  However if this is not a given, the distribution across the files becomes a quite complicated process. For now, there's no real way to control file sizes or data distribution across those files (besides the 1:1 node/file ratio).

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 