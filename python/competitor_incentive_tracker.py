#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np

week_no = 39

file_path_1 = r'insert path here' + str(week_no) + '-RW-en.png_tables/page-1_table-1.csv'
file_path_2 = r'insert path here' + str(week_no) + '-RW-en.png_tables/page-1_table-2.csv'
file_path_3 = r'insert path here' + str(week_no) + '-RW-en.png_tables/page-1_table-3.csv'
file_path_4 = r'insert path here' + str(week_no) + '-RW-en.png_tables/page-1_table-4.csv'

df1 = pd.read_csv(file_path_1)
df2 = pd.read_csv(file_path_2)
df3 = pd.read_csv(file_path_3)
df4 = pd.read_csv(file_path_4)

df5 = pd.concat([df1,df2,df3,df4])

df_melted = df5.melt(id_vars=['Zone', 'Code'], value_vars=['SAT LUNCH', 'SAT DINNER', 'SUN LUNCH', 'SUN DINNER', 'MON FRI LUNCH', 'MON FRI DINNER'])

#remove rows where value is '-'
df_melted = df_melted[df_melted['value'] != '-']

def get_day(variable):
    if variable.startswith('SAT'): 
        return('Saturday')
    elif variable.startswith('SUN'):
        return('Sunday')
    elif variable.startswith('MON FRI'):
        return('Monday - Friday')
    else:
        return(np.nan)

df_melted['day'] = df_melted['variable'].apply(get_day)

def get_time(variable):
    if variable.endswith('LUNCH'): 
        return('11:45 - 13:45')
    elif variable.endswith('DINNER'):
        return('18:00 - 21:00')
    else:
        return(np.nan)

df_melted['time'] = df_melted['variable'].apply(get_time)

area_hk = ['Central',
'Causeway Bay',
'Hong Kong East',
'Heng Fa Chuen',
'Kennedy Town',
'Mid-Level East',
'North Point',
'Sheung Wan',
'Sai Ying Pun',
'Wanchai',
'Aberdeen',
'Ap Lei Chau',
'Southern District']

area_kt = ['Mong Kok',
'Kowloon Bay',
'Kowloon Tong',
'Kwun Tong',
'Ma Tau Wai',
'San Po Kong',
'Sham Shui Po',
'Mei Foo',
'To Kwa Wan',
'Tsim Sha Tsui']

area_nt = ['Fanling',
'Fo Tan',
'Ping Shan',
'Sheung Shui',
'Shatin',
'Tin Shui Wai',
'Tuen Mun',
'Tai Po',
'Tai Wai',
'Tsing Yi',
'Yuen Long',
'Kwai Shing',
'Tung Chung',
'Tsuen Wan',
'Ma On Shan',
'Tseung Kwan O']

def get_area(zone):
    if zone in area_hk:
        return('Hong Kong Island')
    elif zone in area_kt:
        return('Kowloon')
    elif zone in area_nt:
        return('New Territories')
    else:
        return('District not included')
    
df_melted['Area'] = df_melted['Zone'].apply(get_area)

df_melted.loc[(df_melted['Zone'] == 'Southern District') & (df_melted['day'] == ('Saturday')) & (df_melted['time'] == '18:00 - 21:00'), ['time']] = '17:30 - 20:30'
df_melted.loc[(df_melted['Zone'] == 'Southern District') & (df_melted['day'] == ('Sunday')) & (df_melted['time'] == '18:00 - 21:00'), ['time']] = '17:30 - 20:30'

df_melted = df_melted[['day','time','Zone','Area','Code','value']]

df_melted.to_csv(r'insert path here' + str(week_no) + '-RW-en.png_tables/w' + str(week_no) + '_output.csv', index=False)


    
    
    
    
    
    
    
    
