#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jul  7 14:27:27 2022

@author: uttsant
"""


import pandas as pd
import numpy as np
from fuzzywuzzy import process

product_path = r'/Users/uttsant/Desktop/foodpanda_coding/products_export_1.csv'
discount_path = r'/Users/uttsant/Desktop/foodpanda_coding/fleet_benefit_weekly.csv'

df_product = pd.read_csv(product_path)
df_discount = pd.read_csv(discount_path)

df_product = df_product[['Handle', 'Title','Custom Product Type', 'Tags', 'Variant Price',
         'Variant Compare At Price','Cost per item', 'Status']]

df_product.dropna(axis=0, subset=['Custom Product Type'], inplace=True)

# get the sum of all the entries with an empty product title
df_discount[df_discount['product_title'].isnull() == True].sum()

df_discount.dropna(axis=0, subset = ['product_title'], inplace=True)

product_list = df_product['Title'].unique()

def match_title(product_title):
    try:
        official_title = process.extractOne(product_title, product_list)[0]
        return(official_title)
    except:
        return(np.nan)

#create new column in discount dataframe using product titles from product dataframe
df_discount['official_title'] = df_discount['product_title'].apply(match_title)

#merge the two dataframes
final_df = pd.merge(df_discount, df_product, how='left', left_on=['official_title'], right_on=['Title'])

mer_series = final_df[final_df['Custom Product Type'].str.contains('MER')].groupby(['week'])['total_discount_amount'].sum()
man_series = final_df[final_df['Custom Product Type'].str.contains('MAN')].groupby(['week'])['total_discount_amount'].sum()
eqp_series = final_df[final_df['Custom Product Type'].str.contains('EQP')].groupby(['week'])['total_discount_amount'].sum()
data = {"MERCHANDISE": mer_series,
        "MANDATORY EQUIPMENT": man_series,
        "EQUIPMENT": eqp_series}
export_df = pd.concat(data, axis = 1)
export_df.to_csv('/Users/uttsant/Desktop/foodpanda_coding/weekly_fleet_export.csv')

print(f"MERCHANDISE\n{final_df[final_df['Custom Product Type'].str.contains('MER')].groupby(['week'])['total_discount_amount'].sum()}")
print(f"MANDATORY EQUIPMENT\n{final_df[final_df['Custom Product Type'].str.contains('MAN')].groupby(['week'])['total_discount_amount'].sum()}")
print(f"EQUIPMENT\n{final_df[final_df['Custom Product Type'].str.contains('EQP')].groupby(['week'])['total_discount_amount'].sum()}")
print(f"TOTAL\n{final_df.groupby('week')['total_discount_amount'].sum()}")
print(f"BLACK THERMAL\n{final_df[final_df['product_title'] == 'Limited Edition Black Thermal Bags'].groupby('week')['total_discount_amount'].sum()}")
