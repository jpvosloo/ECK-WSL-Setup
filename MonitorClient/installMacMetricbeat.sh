#!/bin/bash
echo This script will install Metricbeat on localhost using brew.

xcode-select --install

brew services stop elastic/tap/metricbeat-full

brew tap elastic/tap
brew install elastic/tap/metricbeat-full
cp metricbeat.yml /usr/local/etc/metricbeat/metricbeat.yml
brew services start elastic/tap/metricbeat-full
