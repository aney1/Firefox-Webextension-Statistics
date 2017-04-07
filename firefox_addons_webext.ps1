<#
#
# This script is using the REST API of addons.mozilla.org to get the number of webextensions compared to other types of extensions.
# It's exporting the data as a csv file.
# I'm running this script daily and the data is presented prettier and with charts at https://docs.google.com/spreadsheets/d/1c3MjM5vgpQCrUsmmAn9YDjQB6v6MG5PcEtFF43spxCg/edit?usp=sharing
# 
# MIT License
# Copyright (c) 2017 Emanuel Hajnžič
#
#>

[int[]]$numAddonsArray = 50,500,5000			#Three csv exports with 50, 500 and 5000 addons
[int]$pageSize = 50									#50 addons per page
[String]$URIaddonAPI = "https://addons.mozilla.org"	#URL to addon page
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$OutputEncoding = [Text.UTF8Encoding]::UTF8

foreach($numAddons in $numAddonsArray) { #Generate more than one export
	[hashtable]$compatStats = @{"compatible" = 0; "compatible-webextension" = 0; "incompatible" = 0; "unknown" = 0} #by the API returned types of extensions
	[int]$numPages = $numAddons/$pageSize

	for($page = 1; $page -le $numPages; $page++) { #Going through search pages (pages can't be as big as you want)
		"Page: $page of $numPages"
		[String]$URIpopularAddonsSearch = $URIaddonAPI + "/api/v3/addons/search/?page=" + $page + "&sort=users&page_size=" + $pageSize
		[int[]]$popularAddonsIDs = (Invoke-RestMethod -Method Get -Uri $URIpopularAddonsSearch).results.id		#get one page of popular addons

		foreach($popularAddonID in $popularAddonsIDs) { #Getting infos of all addons in current page
			"Extension ID: $popularAddonID"
			[String]$URIfeatureCompat = $URIaddonAPI + "/api/v3/addons/addon/" + $popularAddonID + "/feature_compatibility/"
			[String]$addonCompatibility = (Invoke-RestMethod -Method Get -Uri $URIfeatureCompat).e10s	#get feature_compatibility of one addon
			switch ($addonCompatibility) {
				"compatible"				{ $compatStats["compatible"]++ }
				"compatible-webextension"	{ $compatStats["compatible-webextension"]++ }
				"incompatible"				{ $compatStats["incompatible"]++ }
				"unknown"					{ $compatStats["unknown"]++ }
			}
		}
	}
	#Prepare line to export:
	[int]$nonwebextension = $compatStats["compatible"] + $compatStats["incompatible"] + $compatStats["unknown"]
	[String]$newline = (get-date).ToString() + "," + $compatStats["compatible-webextension"] + "," + $nonwebextension + "," + $compatStats["compatible"] + "," + $compatStats["incompatible"] + "," + $compatStats["unknown"]
	
	#CSV export:
    $newline >> ("C:\Users\Emanuel\Dropbox\FFwebExtStats" + $numAddons + ".csv")

	#export to a server over ssh:
    C:\ff-webext\plink.exe -i "C:\ff-webext\priv.ppk" pi@raspberrypi ('echo "' + $newline + '" >> /var/www/html/ff/FFwebExtStats' + $numAddons + '.csv')
}