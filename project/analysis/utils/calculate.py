
import numpy as np

def get_market_depth_data(df):
    df = df.pivot_table(
        columns="side",
        index=["day", "price"],
        values="quantity",
        aggfunc="sum"
    ).groupby("day").apply(calc_supply_demand)
    
    df = df[["supply", "demand"]].stack().rename("quantity").reset_index().sort_values(["day", "price"])
    df = df.groupby(["day", "price"])["quantity"].sum().reset_index()
    return df

def calc_supply_demand(df):
    #print(df)
    df = df.reset_index(level=0, drop=True)
    df = df.reindex(np.arange(df.index.min(), df.index.max() + 1))
    df = df.sort_index().fillna(0)
    df["supply"] = df["ask"].sort_index(ascending=True).cumsum()
    df["demand"] = df["bid"].sort_index(ascending=False).cumsum()
    return df