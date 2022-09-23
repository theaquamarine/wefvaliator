BeforeDiscovery {
	$xmlfiles = Get-ChildItem *.xml -Recurse
}

Describe '<_.Name>' -ForEach $xmlfiles {
	It 'File is valid xml' {
		[xml](Get-Content $_) | Should -BeOfType 'System.Xml.XmlDocument'
	}

	# >1 subscription in a file is invalid
	It 'Contains a subscription' -ForEach ([xml](Get-Content $_)) {
		$_.GetElementsByTagName('Subscription') | Should -HaveCount 1
	}

	# wecutil will import a file with >1 query, but ignore all other than the first
	It 'Has a query' -ForEach (([xml](Get-Content $_)).Subscription) {
		$_.GetElementsByTagName('Query') | Should -HaveCount 1
	}

	It 'Query CDATA is valid xml' -ForEach (([xml](Get-Content $_)).Subscription.Query) {
		[xml]$_.'#cdata-section' | Should -BeOfType 'System.Xml.XmlDocument'
	}

	Context 'Query <_.Id>' -ForEach (
		([xml](([xml](Get-Content $_)).Subscription.Query.'#cdata-section')).QueryList.Query
	) {
		It 'Select from <_.Path> is valid xpath' -ForEach ($_.Select) {
			[System.Xml.XPath.XPathExpression]::Compile($_.'#text') |
			Should -BeOfType 'System.Xml.Xpath.XpathExpression'
		}
	}
}
