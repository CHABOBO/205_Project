Extract, Transform and Load

Steps to extract Common Core Data, transform to csv file and load into PostgreSQL:

1. Run ./extract_transform.sh

This process retrieves data files from the National Center for Educational Statistics website based on URLs recorded in the fiscal.txt and nonfiscal*.txt text files in the same directory. The URLs do not follow a consistent file naming scheme. An earlier version of the script attempted to use pattern matching to retrieve the filenames, but due to website redirects the script was attempting to access files not intended. The hardcoded URLs are a safer approach to ensure that only the files we intend to download are accessed. There are three different input files for nonfiscal data because the file format changed and the script needed to be adjusted.

The output of the script is two csv files: fiscal.csv and nonfiscal.csv

The most likely cause of problems running the script is network glitches preventing the files from being downloaded. The script will capture those errors and exit rather than extracting an incomplete data set. The simplest approach to handling those errors is to just rerun the script. The script completes very quickly.

2. The load.sql script is executed within PostgreSQL: \i /home/w205/205_Project/ETL/load.sql

After creating the schema, the data is loaded from csv files in /home/w205/205_Project/ETL. Make sure the extract_transform.sh process has been completed first to generate those files.

