Rally-Export-FieldDefinitions
=============================


A simple Ruby Script that uses rally_api to query Field attributes for all Types in a specified Rally Workspace.

![Rally-Export-CustomFields](https://raw.githubusercontent.com/markwilliams970/Rally-Export-FieldDefinitions/master/img/screenshot1.png)

Requirements:

1. Tested with Ruby 2.2.10p489
2. [Rally API](https://rubygems.org/gems/rally_api) 1.2.1 or higher

Usage:

Configure the my_vars.rb file with the relevant environment variables.

    # Rally Parameters
    $rally_url                   =  "https://rally1.rallydev.com"
    $rally_username              =  "user@company.com"
    $rally_password              =  "t0p$3cr3t"
    $rally_api_key               =  '_pX.......................................nM'
    $rally_workspace             =  "My Workspace"
    $wsapi_version               =  "v2.0"

    $my_delim                    = ","

    # Mode:
    # :custom_only   -> Exports Custom Field definitions Only
    # :standard_only -> Exports Standard Field definitions Only
    # :all_fields    -> Exports All field definitions
    $mode                        = :all_fields

    $output_filename             = "exported_field_definitions.csv"

Then run the script:

    ruby rally_export_fields.rb

By default, the script will create a comma-delimited text file that you can open with Excel,
delineating the Field definitions for your Rally Workspace.
