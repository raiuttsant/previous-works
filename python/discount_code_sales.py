#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 18 16:13:14 2022

@author: uttsant
"""

# import necessary modules
import pandas as pd
from datetime import date

# file path of raw csv file; the name of the raw file in our case is "tbq3_weekly.csv"
file_path = r'/insert path here/tbq3_weekly.csv'

# convert raw csv file into pandas dataframe
df = pd.read_csv(file_path)

# print results i.e. the weekly total sales of all orders that start with the discount code "TBQ3"
print(df[df['name'].str.startswith(('TBQ3'))].groupby(['week']).sum()['total_discount_amount'])

# create another dataframe to output the result
df2 = df[df['name'].str.startswith(('TBQ3'))].groupby(['week']).sum()['total_discount_amount']

# output the final result as a csv file with today's date as the name
today = date.today()
df2.to_csv(r'/insert path here/tbq3_output/weekly/' + str(today) + '.csv', index=False)
