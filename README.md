# Firefox-Webextension-Statistics

This Powershell script is using the REST API of addons.mozilla.org to get the number of webextensions compared to other types of extensions.
It's exporting the data as a csv file and uploading it to a server. The upload is done with plink.exe over SSH.

I'm running this script daily and the data is presented prettier and with charts [here](https://docs.google.com/spreadsheets/d/1c3MjM5vgpQCrUsmmAn9YDjQB6v6MG5PcEtFF43spxCg/edit?usp=sharing).

MIT License
Copyright (c) 2017 Emanuel Hajnžič
