# PLE: Probabilistic Line Extraction from 2-D Laser Range Scans

![Line extraction example](./line_extraction.svg)

Exemplary result of our polyline extraction method applied to a scan captured in an office. The scan consists of 361 rays, of which every second is displayed as a red line. Gray lines indicate maximum-range readings. The extracted polyline map, drawn as blue lines, consists of ten vertices, reducing memory requirements to less than 3%.  

## About this Repository

This repository contains the [MATLAB](https://www.mathworks.com/products/matlab.html) implementation of [our maximum likelihood approach to extract polylines from 2-D range scans](./ple_iros2018.pdf). It also comprises the scripts we used in the experiments to compare our method to several state-of-the-art line extractors.

## The Algorithm in a Nutshell

Our approach extracts polylines from 2-D laser range scans. In contrast to prevalent line extraction techniques, it does not rely on a geometric heuristic, but maximizes the measurement probability of the scan to accurately determine polylines. The method consists of two steps.
1. **Polyline Extraction.** Polyline extraction starts by connecting all neighboring scan endpoints to form a set of initial polylines. It then iteratively removes the vertex that incurs the least error in terms of measurement probability until it reaches a given threshold. The result is a set of polylines whose vertex locations coincide with the locations of a subset of the scan endpoints. 
1. **Polyline Optimization.** To do away with the limitation that vertex locations coincide with endpoint locations, we formulate an optimization problem that moves the vertices to the positions that maximize the measurement probability of the scan. We call this latter process polyline optimization.

For a short illustration of the algorithm, please take a look at the [Powerpoint presentation from IROS 2018](./ple_iros2018.pptx).
For a detailed description of our method and the experiments, consult our [paper](./ple_iros2018.pdf).

## Quick Start Instructions

The code does not require compilation or installation. To run a line extraction example, follow these steps:

1. Clone or [download](https://github.com/acschaefer/ple/archive/master.zip) the repository.
2. Run the `startup` script in the `matlab` folder to set up your MATLAB searchpath.
3. Run the example script `extrlin`.

## Repository Organization

The repository is organized using the following folders:

| Folder | Content |
| --- | --- |
| `data` | laser scan files and results of experiments with Veeck's method |
| `matlab` | functions and classes required to run examples and experiments |
| `matlab/script` | example scripts and experiments scripts |
| `matlab/output` | output of our experiments, see below |

## How to Reproduce Our Experiments

To reproduce our experimental results, run the following scripts one after the other from the folder `matlab`:

| Script | Description |
| --- | --- |
| `startup` | Set up MATLAB search path. |
| `gendata` | Create real-world dataset from Carmen files and simulated dataset using randomized polygons. |
| `runexp`  | Apply all line extraction methods to all datasets with various parameter settings. This script usually runs for a few hours until completion. |
| `evalexp` | Calculate various figures of merits from the results. |
| `ploteval` | Create the evaluation plots. |

After running `evalexp`, individual results can be plotted using the function [`inspectresult`](matlab/script/inspectresult.m), e.g. `inspectresult(1,1,1,1)`. See function help for details.
Note that the `.mat` and `.fig` files containing the results from the above steps are already present in the `output` folder. Consequently, every script can be directly executed.

## Supported Platforms and MATLAB Versions

It is not bound to any specific platform. It was tested on MATLAB R2017b and MATLAB R2018a on Windows and Linux systems. If you experience any problems, please do not hesitate to [create an issue](https://github.com/acschaefer/ple/issues/new).

## License

All code in this repository is licensed under [GPL-3.0](LICENSE).

## How to Cite

If you use our line extraction method in your research, please cite our [paper](./ple_iros2018.pdf) that describes the approach:
```
A Maximum Likelihood Approach to Extract Polylines from 2-D Laser Range Scans
Alexander Schaefer, Daniel Büscher, Lukas Luft, Wolfram Burgard
IEEE International Conference on Intelligent Robots 2018, Madrid, Spain
```
[BibTeX](./ple_iros2018.bib)
