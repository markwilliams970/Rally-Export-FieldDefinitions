Rally-Export-CustomFields
=========================


A simple Ruby Script that uses rally_api to query Custom Field attributes for all Artifact Types in a specified Rally Workspace.

![Rally-Export-CustomFields](https://raw.githubusercontent.com/markwilliams970/Rally-Export-FieldDefinitions/master/img/screenshot1.png)

Requirements:

1. Tested with Ruby 2.0
2. [Rally API](https://rubygems.org/gems/rally_api) 0.9.25 or higher

Usage:

Configure the my_vars.rb file with the relevant environment variables.

	# Rally Parameters
	$rally_url                   =  "https://rally1.rallydev.com"
	$rally_username              =  "user@company.com"
	$rally_password              =  "topsecret"
	$rally_workspace             =  "My Workspace"
	$wsapi_version               =  "1.43"

	$my_delim                    = "\t"

    # Mode:
    # :custom_only   -> Exports Custom Field definitions Only
    # :standard_only -> Exports Standard Field definitions Only
    # :all_fields    -> Exports All field definitions
    $mode                        = :all_fields

    $output_filename             = "exported_field_definitions.txt"

Then run the script:

    ruby rally_export_fields.rb

The script will by default prepare a Tab-Delimited text file that you can open with Excel, delineating the Custom Fields for your Rally Workspace.
