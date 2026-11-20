# Precise Backdoor Detection in Network Servers via Protocol-Aware Fuzzing - Supplementary material

## Context

This supplementary material embeds all the source code of software used to evaluate Tulip, including:

* CSL models developed for HTTP, IMAP, FTP and POP3
* The code of Tulip itself, with its adapted version of AFL++
* All benchmark samples and evaluation infrastructure
* All seeds for ROSA

## Content

When extracted or cloned, some directories become available:

* `ablation_studies/`: The different Tulip versions used for the ablation study (RQ4 in the paper)
  * `aflpp_vanilla/` is the AFL++, and checking out the commit `c340a022`.
  * `cbd_aflpp_vanilla_default_seed/` corresponds to the "Baseline" version of Tulip used in table 5a.
  * `cbd_aflpp_vanilla/` corresponds to the "Seeded Baseline (2)" version of Tulip used in table 5a.
  * `cbd_without_multilayer_fuzzing/` corresponds to the "Seeded + Guided Baseline (3)" version of Tulip used in table 5a
* `aflplusplus-wildcards/` corresponds to the modified AFL++ fuzzer used in Tulip.
  * Since it is an huge repository, it has been omitted from this artifact. It can be recovered by cloning the AFL++ repository, checking out the commit `c340a022` and applying the file `aflplusplus-wildcards/tulip.patch` provided in this artifact.
  * Hence, the file `tulip.patch` summarizes modifications done on the AFL++ baseline.
* `benchmark/`, `benchmark-analysis/` and `config-benchmark.sh` correspond to scripts used to run and evaluate the Tulip technique. They are used to generate tables of the paper.
  * `benchmark/rosa/` contains used seeds to evaluate Rosa
* `configs-rosa/` contains configuration files used to evaluate Rosa
* `csl/` contains CSL models and associated configuration used to evaluate Tulip
* `misc/` contains some extra tools to harness targets for both fuzzing and oracle testing
* `rosa/` contains the Rosa tool as it was used to evaluate Tulip
  * `fuzzers/aflpp/aflpp` has been deleted because of its size. It can be recovered by cloning the AFL++ repository and checking out the commit `c340a022`.
* `rosarum/` is a fork of the Rosarum benchmark containing all targets used to evaluate Tulip
* `stringer/` contains the \stringer tool used to evaluate Tulip. However, it is not runnable without IDA Pro.
* `tool/` contains the code of the main tool which on Tulip rely
  * `tool/ext/cslprocess_v2` contains the tool used to process CSL models

Each component contain a `README.md` file explaining how to build and use it. **A complete turnkey Docker image will be submitted to the artifact evaluation in case of paper acceptance.**