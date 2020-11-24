# Master's Thesis Code: [Building a Computational Artificial Market](http://urn.fi/URN:NBN:fi-fe2020102787864)

> Julia version: 1.3.1
> Python: 3.6.6

---

## Source Files

simulation.ipynb
- Set of executed/example simulations. Results are dumped to csv files to results/

analysis/
- Set of notebooks (in Python) used to analyze the results of the simulations.

main.jl
- Utility functions used to run the simulation with given settings.

src/botmarket.jl
- Actual Julia package that exports the relevant components of the ASM model.

src/builtin
- Collection of concrete and complete types/structs that are to be exported 
and used in the simulation.

src/abstracts.jl
- Collection of abstract types/structs.

Other source files contain utility functions and structs for the simulation.