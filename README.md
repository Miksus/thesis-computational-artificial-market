
# Master's Thesis Project: [Building a Computational Artificial Market](http://urn.fi/URN:NBN:fi-fe2020102787864)

> Keywords: Computational economics, experimental economics, artificial stock market

---

## Abstract
Computational economics is a branch of experimental economics that aims to recreate and explain the dynamics of real markets using computational simulations. Researchers of empirical economics have often very limited ability to control the market environment to study specific phenomena but such restrictions do not apply in pure computational environments. The purpose of this thesis is to build a generic computational market. As the previous literature is lacking in thorough examples of how to build such a model, the mechanics of this model are discussed in detail.

The microstructure of the model is organized as limit order book market with continuous clearing. The trading agents of the model are budget constrained and zero-intelligent. The model supports multi-asset simulations and the meaning of currency is abstracted and any asset in the model can act as the currency or the traded asset for a market. The representativeness of the model is validated using stylized facts and the price behaviour is studied with different initiation price and by destabilizing the sides of the market.

The model produced similar results as the similar models from previous literature: zero intelligent traders do converge efficiently to equilibrium and some of the stylized facts can be produced with such a simplistic model. As a contribution to the existing literature, the testing of the model revealed several additional interesting observations such as that the global balance between assets in zero-intelligent markets is not the only factor driving the equilibrium price: also the probability of issuing bid and ask orders affect the equilibrium. The structure of the order book has itself an effect on the equilibrium price.

Link: [http://urn.fi/URN:NBN:fi-fe2020102787864](http://urn.fi/URN:NBN:fi-fe2020102787864)

---

## What is this exactly?
- A thesis about computational artificial market using Julia language
    - directory __thesis__ include the Latex source for the thesis itself
    - directory __project__ include the Julia source for the model
- The model's __microstructure__ can be described as:
    - A continuous double auction (CDA)
    - Limit order book market
    - Order driven market
- The model's __traders/investors__ are:
    - Budget constrained:
        - Cannot short sell
        - Cannot borrow
    - Zero intelligent:
        - Randomly submits a bid or ask order to the market
        - Picks random price for the order from a normal distribution (mean = last market price, std = constant)
        - Picks random quantity for the order from a uniform distribution (low = 0, high = maximum possible)

---

## Author

* **Mikael Koli** - [Miksus](https://github.com/Miksus) - koli.mikael@gmail.com

