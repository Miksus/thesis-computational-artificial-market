import pandas as pd
import numpy as np
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf

import seaborn as sns
from scipy.stats import norm
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from matplotlib import cm

from .calculate import get_market_depth_data, calc_supply_demand

def plot_order_book_heatmap(df, ax=None):
    df_map = df.pivot_table(
        columns="price",
        index=["side", "day"],
        values="quantity",
        aggfunc="sum"
    )

    dfs = []
    for idx in df_map.index:
        #print(idx)
        df_temp = df_map.loc[idx].dropna()



        max_price = df_temp.index.max()
        min_price = df_temp.index.min()

        #print(min_price, max_price)
        price_range = np.arange(min_price, max_price + 1)
        df_day = df_temp.reindex(price_range).fillna(0)

        #print(df_day)
        dfs.append(df_day)
    df_map = pd.concat(dfs, axis=1)

    min_price = df["price"].min()
    max_price = df["price"].max()
    price_range = np.arange(min_price, max_price + 1)

    df_ask = df_map["ask"].reindex(price_range, axis=0)
    df_bid = df_map["bid"].reindex(price_range, axis=0)


    df_ask = df_ask.sort_index(axis=0, ascending=True).cumsum(axis=0).sort_index(axis=0)
    df_bid = df_bid.sort_index(axis=0, ascending=False).cumsum(axis=0).sort_index(axis=0)

    book_matrix = df_ask.add(df_bid, fill_value=0).sort_index(axis=0, ascending=False).sort_index(axis=1, ascending=True)

    book_matrix = book_matrix.replace(0, np.nan)

    sns.heatmap(book_matrix.sort_index(axis=1, ascending=True), cmap='coolwarm', vmin=0, ax=ax)


def plot_market_depth(df_book, price_range=None):
    #%matplotlib notebook
    
    df = df_book.pivot_table(
        columns="side",
        index=["day", "price"],
        values="quantity",
        aggfunc="sum"
    ).groupby("day").apply(calc_supply_demand)
    
    df_plot = df[["supply", "demand"]].stack().rename("quantity").reset_index().sort_values(["day", "price"])
    df_plot = df_plot.groupby(["day", "price"])["quantity"].sum().reset_index()

    df_plt = pd.DataFrame()
    for day in df_plot["day"].unique():
        df_day = df_plot[df_plot["day"] == day]
        df_day = (
            df_day
            .sort_values("price")
            .set_index("price")
            .reindex(np.arange(df_plot["price"].min(), df_plot["price"].max() + 1))
        ).bfill().ffill()

        if price_range is not None:
            df_day = df_day[(df_day.index >= price_range[0]) & (df_day.index <= price_range[1])]

        df_plt = df_plt.append(df_day)

    df_plt = df_plt.reset_index()
    x = df_plt["day"]
    y = df_plt["price"]
    z = df_plt["quantity"]



    fig = plt.figure()
    ax = fig.gca(projection='3d')
    surf = ax.plot_trisurf(x, y, z, cmap=cm.coolwarm) # , linewidth=0.1
    #plt.clim(0,4)
    ax.set_zlim(0,df_plt["quantity"].max())
    #ax.set_ylim(50,100)

    plt.xlabel("Trading session")
    plt.ylabel("Price")
    plt.gca().set_zlabel('Quantity')

    plt.gca().view_init(60, -30)
    plt.margins(0, 0, 0)
    return fig


def plot_timeseries_two_scenarios(df_a, df_b, equilibrium, names):
    fig, axs = plt.subplots(3, 2, figsize=[10,10], sharex='col', sharey='row')

    for i, df in enumerate((
        df_a, 
        df_b
    )):
        df_plot = pd.DataFrame(index=df.trading_day.unique())
        df_plot["price"] = df.groupby("trading_day")["price"].mean()
        df_plot["quantity"] = df.groupby("trading_day")["quantity"].sum()
        df_plot["value"] = df_plot["price"] * df_plot["quantity"]
        
        df_plot["price"].plot(ax=axs[0, i])
        axs[0, i].axhline(equilibrium, linestyle="--", color="k", alpha=0.5)
        df_plot["quantity"].plot(ax=axs[1, i]) # , kind="bar"

        df_plot["value"].plot(ax=axs[2, i])

        axs[2, i].set_xlabel("Trading session")
        axs[0, i].set_ylabel("Price")
        axs[1, i].set_ylabel("Traded quantity (sum per session)")
        axs[2, i].set_ylabel("Traded value (sum per session)")

        axs[0, i].set_title(names[i])

    axs[2, 0].set_xlabel("Trading session")
    axs[2, 1].set_xlabel("Trading session")


def plot_autocorrelation(df):
    fig, axs = plt.subplots(2, 1, figsize=[10,10], sharex='col', sharey='row')
    df_trd = df.sort_values("timestamp") # [df["trading_day"] >= 100]
    df_trd = df_trd.groupby("trading_day").last()
    #df_prices = df_trd.sort_values("timestamp").groupby("trading_day")["price"].last().iloc[50:]

    plot_acf(df_trd["price"], lags=30, title=f"ACF of Prices (per trading session)", ax=axs[0]);
    plot_pacf(df_trd["price"], lags=30, title=f"PACF of Prices (per trading session)", ax=axs[1]);
    return fig

def plot_volaclusters(df, clusters):
    df_trd = df.sort_values("timestamp") # [df["trading_day"] >= 100]
    df_trd = df_trd.groupby("trading_day").last()["price"].dropna() # .pct_change()


    fig, axs = plt.subplots(len(clusters), 2, figsize=[10,10], sharex='col', sharey='col')
    for i, cluster in enumerate(clusters):
        df_plot = df_trd.groupby(df_trd.index // cluster).std().dropna()
        plot_acf(df_plot, lags=20, title=f"ACF of volatility ({cluster} sessions)", ax=axs[i, 0])
        plot_pacf(df_plot, lags=20, title=f"PACF of volatility ({cluster} sessions)", ax=axs[i, 1])

def plot_volaclusters_per_session(df, clusters):

    df_trd = df.sort_values("timestamp") # [df_trd["trading_day"] >= 100]

    fig, axs = plt.subplots(len(clusters)+1, 2, figsize=[10,10], sharex='col', sharey='col')

    df_plot = df_trd.groupby("trading_day")["price"].std().dropna()
    plot_acf(df_plot, lags=10, title=f"ACF of volatility (per session)", ax=axs[0, 0])
    plot_pacf(df_plot, lags=10, title=f"PACF of volatility (per session)", ax=axs[0, 1])

    #df_trd = df_trd.groupby("trading_day")["price"].last().dropna() # .pct_change()
    for i, cluster in enumerate(clusters):
        i += 1
        df_plot = df_trd.groupby(df_trd["trading_day"] // cluster).std()["price"].dropna()
        #df_plot = df_trd.groupby("trading_day")["price"].std().dropna()
        plot_acf(df_plot, lags=10, title=f"ACF of volatility ({cluster} sessions)", ax=axs[i, 0])
        plot_pacf(df_plot, lags=10, title=f"PACF of volatility ({cluster} sessions)", ax=axs[i, 1])

def plot_fat_tails(df):
    df_trd = df.sort_values("timestamp") # [df_trd["trading_day"] >= 100]
    df_trd = df_trd["price"].dropna() # .pct_change()

    fig = plt.figure()

    ax = sns.distplot(df_trd.pct_change().dropna(), fit=norm, kde=False)
    ax.set_title(f"Distribution of returns & fitted normal distribution")
    plt.legend(["Fitted normal distribution", "Simulation"])
    ax.set_xlabel("Rate of returns")

def plot_fat_tails_per_session(df):
    df_trd = df.sort_values("timestamp") # [df["trading_day"] >= 100]
    df_trd = df_trd.groupby("trading_day").last()["price"].dropna() # .pct_change()

    fig = plt.figure()

    ax = sns.distplot(df_trd.pct_change().dropna(), fit=norm, kde=False)
    ax.set_title(f"Distribution of returns & fitted normal distribution")
    plt.legend(["Fitted normal distribution", "Simulation"])
    ax.set_xlabel("Rate of returns")

def plot_fat_tails_cumul(df):
    df_trd = df.sort_values("timestamp") # [df_trd["trading_day"] >= 100]
    df_trd = df_trd["price"].dropna() # .pct_change()

    fig = plt.figure()

    ax = sns.distplot(df_trd.pct_change().dropna(), hist_kws=dict(cumulative=True), kde_kws=dict(cumulative=True)) # , fit=norm, kde=False

    ax.set_title(f"Cumulative distribution of returns")
    #plt.legend(["Fitted normal distribution", "Simulation"])
    ax.set_xlabel("Rate of returns")