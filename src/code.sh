#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail


# TODO in the below: Remove unneeded R packages


main() {
  # Fetch inputs
  dx-download-all-inputs --parallel

  # Create a list of all input files
  cat /dev/null > input_files.txt
  for path in ~/in/rdslist/*/*; do
    echo $path >> input_files.txt
  done

  # Locate the assets bundle, the location of which varies, depending on whether
  # this is an app or an applet.
  if [[ "$DX_RESOURCES_ID" != "" ]]; then
    # This is an app; fetch assets from the app's private asset container
    DX_ASSETS_ID="$DX_RESOURCES_ID"
  else
    # This is an applet; fetch assets from the parent project
    DX_ASSETS_ID="$DX_PROJECT_CONTEXT_ID"
  fi

  # Stream and unpack assets bundle
  mkdir ~/resources
  cd ~/resources
  dx cat "${DX_ASSETS_ID}:/assets/kccg_performance_reporter_resources_bundle-2.0.tar" | tar xf -

  # Setup R
  cd ~
  # This R is Aaron's R-3.2.0 with pre-installed packages, with the following 
  # additional packages pre-installed:
  # CRAN: inline, RSQLite, png, gsalib
  # BioC: VariantAnnotation, GenomicRanges, BSgenome
  dx cat "${DX_ASSETS_ID}:/assets/R-3.2.0.compiled.packages_v2.tar.gz" | tar -zxf -
  export PATH="$PWD/bin:$PATH"
  export RHOME=${HOME} # This is needed to make RScript work, since it was compiled in a different dir.

  # Run report
  mkdir -p ~/out/report/
  ./performance_report.sh input_files.txt ~/out/report/performance_report.pdf

  # upload results
  dx-upload-all-outputs
  propagate-user-meta vcfgz report
}