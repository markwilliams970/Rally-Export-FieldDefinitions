Rally-Export-CustomFields
=========================


A simple Ruby Script that uses rally_api to query Custom Field attributes for all Artifact Types in a specified Rally Workspace.

Requirements:

1. Tested with Ruby 1.9.3
2. [Rally API](https://rubygems.org/gems/rally_api) 0.9.25 or higher

Usage:

Configure the my_vars.rb file with the relevant environment variables.

	# Rally Parameters
	$rally_url                   =  "https://rally1.rallydev.com"
	$rally_username              =  "user@company.com"
	$rally_password              =  "topsecret"
	$rally_workspace             =  "My Workspace"
	$rally_project               =  "My Project"
	$wsapi_version               =  "1.43"

	$my_delim                    = "\t"

Then run the script:

    ruby rally_export_custom_fields.rb > custom_field_list.txt

The script will by default prepare a Tab-Delimited text file that you can open with Excel, delineating the Custom Fields for your Rally Workspace.
