#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import numpy as np
from fuzzywuzzy import process

# file path for product list and order + discount info
product_path = r'/insert path here/products_export_1.csv'
discount_path = r'/insert path here/fleet_benefit_weekly.csv'

df_product = pd.read_csv(product_path)
df_discount = pd.read_csv(discount_path)

# keep necessary columns
df_product = df_product[['Handle', 'Title','Custom Product Type', 'Tags', 'Variant Price',
         'Variant Compare At Price','Cost per item', 'Status']]

# drop rows where "Custom Product Type" field is empty
df_product.dropna(axis=0, subset=['Custom Product Type'], inplace=True)

# get the sum of all the entries with an empty product title --> this line of code validates the need for the next line
df_discount[df_discount['product_title'].isnull() == True].sum()

# drop rows where "product_title" field is empty
df_discount.dropna(axis=0, subset = ['product_title'], inplace=True)

# create a list containing unique product titles
product_list = df_product['Title'].unique()

# create a function which using the fuzzywuzzy package to return the best match for the product titles in the order info file, 
# as product titles in the product list file and order info file may not be consistent, to facilitate the merge later

def match_title(product_title):
    try:
        official_title = process.extractOne(product_title, product_list)[0]
        return(official_title)
    except:
        return(np.nan)

# create new column in the order dataframe using the product titles generates from the function above
df_discount['official_title'] = df_discount['product_title'].apply(match_title)

# merge the two dataframes
final_df = pd.merge(df_discount, df_product, how='left', left_on=['official_title'], right_on=['Title'])

# categorise the consolidated order info into 3 different series i.e. Merchandise (MER), Mandatory Equipment (MAN), Equipment (EQP)
# the 3 series contain the weekly total discount amount for their respective product categories
mer_series = final_df[final_df['Custom Product Type'].str.contains('MER')].groupby(['week'])['total_discount_amount'].sum()
man_series = final_df[final_df['Custom Product Type'].str.contains('MAN')].groupby(['week'])['total_discount_amount'].sum()
eqp_series = final_df[final_df['Custom Product Type'].str.contains('EQP')].groupby(['week'])['total_discount_amount'].sum()

# concatenate the 3 series vertically and export it as a csv
data = {"MERCHANDISE": mer_series,
        "MANDATORY EQUIPMENT": man_series,
        "EQUIPMENT": eqp_series}
export_df = pd.concat(data, axis = 1)
export_df.to_csv('/insert path here/weekly_fleet_export.csv')
