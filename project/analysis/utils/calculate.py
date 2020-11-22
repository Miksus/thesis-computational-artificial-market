
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
    df = df.reset_index(level=0, drop=True)
    df = df.reindex(np.arange(df.index.min(), df.index.max() + 1))
    df = df.sort_index().fillna(0)
    df["supply"] = df["ask"].sort_index(ascending=True).cumsum()
    df["demand"] = df["bid"].sort_index(ascending=False).cumsum()
    return df


def get_positions(trades, pos_start):

    trades["value"] = trades["quantity"] * df_trades["price"]

    # Stock transactions
    df_stock = trades.pivot_table(
        index="trading_day",
        columns="buyer",
        values="quantity",
        aggfunc="sum"
    ).fillna(0) - trades.pivot_table(
        index="trading_day",
        columns="seller",
        values="quantity",
        aggfunc="sum"
    ).fillna(0)

    # Currency
    df_curr = -trades.pivot_table(
        index="trading_day",
        columns="buyer",
        values="value",
        aggfunc="sum"
    ).fillna(0) + trades.pivot_table(
        index="trading_day",
        columns="seller",
        values="value",
        aggfunc="sum"
    ).fillna(0)

    df_main = pd.concat([df_stock, df_curr], axis=1, keys=["stock", "ccy"])

    pos_start["trading_day"] = 0
    pos_start = pos_start.rename({"generic_currency_position": "ccy", "generic_stock_position": "stock"}, axis=1)
    df_start = pos_start.pivot_table(
        index="trading_day",
        columns="name",
        values=["ccy", "stock"],
        aggfunc="sum"
    ).fillna(0)

    df_main = pd.concat([df_start, df_main], axis=0)
    df_main = df_main.fillna(0).cumsum(axis=0)
    return df_main