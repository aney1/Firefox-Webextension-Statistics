<#
#
# This script is using the REST API (http://addons-server.readthedocs.io/en/latest/topics/api/addons.html) of addons.mozilla.org to get the number of webextensions compared to other types of extensions.
# It's exporting the data as a csv file.
# I'm running this script daily and the data is presented prettier and with charts at https://docs.google.com/spreadsheets/d/1c3MjM5vgpQCrUsmmAn9YDjQB6v6MG5PcEtFF43spxCg/edit?usp=sharing
# 
# MIT License
# Copyright (c) 2017 Emanuel Hajnžič
#
#>

function getNumberOfAddons {
	#http://dotnethappens.com/powershell-screen-scraping-using-xpath-selectors-and-htmlagilitypack/
	Import-Module ‘C:\ff-webext\HtmlAgilityPack.dll’
	$url = ‘https://addons.mozilla.org/en-US/firefox/search/?sort=users&appver=any&atype=1’
	$xpath = ‘(//*[@class="pos"]/b)[3]’
	$doc = New-Object HtmlAgilityPack.HtmlDocument
	$doc.LoadHtml((iwr $url).RawContent)
	return $doc.DocumentNode.SelectSingleNode($xpath).InnerText | foreach {$_.replace(",","") }  #https://stackoverflow.com/questions/9218060/powershell-decimal-format-without-comma
}

function export($pageSizeForExport) {
	#Prepare line for export:
	[int]$nonwebextension = $compatStats["compatible"] + $compatStats["incompatible"] + $compatStats["unknown"]
	[String]$percent = [Single](($compatStats["compatible-webextension"]/$nonwebextension)*100)
	[String]$percent = $percent.replace(".",",")
	[String]$newline = (get-date).ToString() + "`t" + $compatStats["compatible-webextension"] + "`t" + $nonwebextension + "`t" + $percent + "`t" + $compatStats["compatible"] + "`t" + $compatStats["incompatible"] + "`t" + $compatStats["unknown"]

	#CSV export:
	$newline >> ("C:\Users\Emanuel\Dropbox\FFwebExtStats" + $pageSizeForExport + ".tsv")
}

[int[]]$numAddonsArray = 50,500,5000,(getNumberOfAddons)	#Four csv exports with 50, 500 and 5000 addons; Must be a multiple of $pageSize;  #https://addons.mozilla.org/en-US/firefox/search/?sort=users&appver=any&_pjax=true&atype=1&page=&cat=
[int]$pageSize = 50		#50 addons per page
[int]$numPages = (($numAddonsArray | measure -Maximum).Maximum)/$pageSize
[String]$URIaddonAPI = "https://addons.mozilla.org"	#URL to addon page
[hashtable]$compatStats = @{"compatible" = 0; "compatible-webextension" = 0; "incompatible" = 0; "unknown" = 0} #by the API returned types of extensions
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$OutputEncoding = [Text.UTF8Encoding]::UTF8

for($page = 1; $page -le $numPages; $page++) { #Going through search pages (pages can't be as big as you want)
	Write-Progress -Id 0 -Activity 'Processing pages' -CurrentOperation "Page: $($page)" -PercentComplete (($page/$numPages) * 100)
	[String]$URIpopularAddonsSearch = $URIaddonAPI + "/api/v3/addons/search/?app=firefox&type=extension&page=" + $page + "&sort=users&page_size=" + $pageSize
	[int[]]$popularAddonsIDs = (Invoke-RestMethod -Method Get -Uri $URIpopularAddonsSearch).results.id		#get one page of popular addons
	$counter=0
	foreach($popularAddonID in $popularAddonsIDs) { #Getting infos of all addons in current page
		#"Extension ID: $popularAddonID"
		Write-Progress -Id 1 -Activity 'Processing Extensions' -CurrentOperation "Processing Extension ID: $($popularAddonID)" -PercentComplete (($counter / $popularAddonsIDs.count) * 100)
		$counter++
		[String]$addonCompatibility="unknown"
		[String]$URIfeatureCompat = $URIaddonAPI + "/api/v3/addons/addon/" + $popularAddonID + "/feature_compatibility/"
		[String]$addonCompatibility = (Invoke-RestMethod -Method Get -Uri $URIfeatureCompat).e10s	#get feature_compatibility of one addon
		switch ($addonCompatibility) {
			"compatible"				{ $compatStats["compatible"]++ }
			"compatible-webextension"	{ $compatStats["compatible-webextension"]++ }
			"incompatible"				{ $compatStats["incompatible"]++ }
			"unknown"					{ $compatStats["unknown"]++ }
		}
	}
	if ( ($page -eq [int]($numAddonsArray[0]/$pageSize)) -or ($page -eq [int]($numAddonsArray[1]/$pageSize)) -or ($page -eq [int]($numAddonsArray[2]/$pageSize)) ) {
		export($page*$pageSize)
	}
}
export("All")
