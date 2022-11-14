#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jul 18 16:13:14 2022

@author: uttsant
"""

import pandas as pd
from datetime import date

file_path = r'/Users/uttsant/Desktop/foodpanda_coding/tbq3_weekly.csv'

df = pd.read_csv(file_path)

print(df[df['name'].str.startswith(('TBQ3'))].groupby(['week']).sum()['total_discount_amount'])

df2 = df[df['name'].str.startswith(('TBQ3'))].groupby(['week']).sum()['total_discount_amount']

today = date.today()

df2.to_csv(r'/Users/uttsant/Desktop/foodpanda_coding/tbq3_output/weekly/' + str(today) + '.csv', index=False)