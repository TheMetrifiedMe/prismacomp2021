# Overview
This repository contains the analysis code for the publication: *Schniedermann, A. (2021): "A comparison of systematic reviews and guideline-based systematic reviews in medical studies"* [doi: 10.1007/s11192-021-04199-0](https://doi.org/10.1007/s11192-021-04199-0). The purpose of this repo is to document the different analytical steps code-wise. Because different platforms and techniques were used, this repo does not provide a single, executable file or script but rather a collection of analytical code.
The data can be found on [Zenodo](https://doi.org/10.5281/zenodo.14277542).

The analytical process of the project consisted of three steps:
1. The retrieval of document type data from PubMed via the PubMed parser tool([GitHub](https://github.com/TheMetrifiedMe/pubmedparser),[Zenodo](https://doi.org/10.5281/zenodo.14015253)) 
2. The preparation and cleaning of that data, as describbed in ["01sql-calculations.sql"](./01sql-calculations.sql).
3. The matching of PubMed Data to the inhouse version of Web of Science, hosted by the German Competence Network Bibliometrics, as described in ["01sql-calculations.sql"](./01sql-calculations.sql).
4. The calculation of fractional items counts, impact indicators and the analysis of the data, as describbed in ["01sql-calculations.sql"](./01sql-calculations.sql)
5. The visualization with ggplot2 as described in , as describbed in ["01rmd-visualizations.Rmd"](./01rmd-visualizations.Rmd.r).
