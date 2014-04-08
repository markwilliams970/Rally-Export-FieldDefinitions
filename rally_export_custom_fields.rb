# Copyright 2002-2012 Rally Software Development Corp. All Rights Reserved.

require 'rally_api'
require 'csv'

$rally_url                                     =  "https://rally1.rallydev.com"
$rally_username                                =  "user@company.com"
$rally_password                                =  "topsecret"
$rally_workspace                               =  "My Workspace"
$rally_project                                 =  "My Project"
$wsapi_version                                 =  "1.43"

$my_delim                                      = "\t"


# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

begin
    #==================== Making a @rally to Rally ====================
    config                                     = {:base_url => "#{$rally_url}/slm"}
    config[:username]                          = $rally_username
    config[:password]                          = $rally_password
    config[:workspace]                         = $rally_workspace
    config[:project]                           = $rally_project
    config[:version]                           = $wsapi_version

    @rally = RallyAPI::RallyRestJson.new(config)


    artifact_types                             = ["Defect","HierarchicalRequirement",
                                                    "PortfolioItem","Task","TestCase"]
    attribute_symbol_by_type = {}
    attribute_symbol_by_type["BOOLEAN"]        = :boolean
    attribute_symbol_by_type["DATE"]           = :date
    attribute_symbol_by_type["DECIMAL"]        = :decimal
    attribute_symbol_by_type["DROPDOWN"]       = :dropdown
    attribute_symbol_by_type["INTEGER"]        = :integer
    attribute_symbol_by_type["STRING"]         = :string
    attribute_symbol_by_type["TEXT"]           = :text
    attribute_symbol_by_type["WEB_LINK"]       = :weblink

    artifact_hash = {}

    column_headers                             = ["ArtifactType", "TypeDefOID",
                                                    "AttrDefOID", "AttrDefName",
                                                    "AttrDefType", "Hidden", "Required",
                                                    "AllowedValues"]
    column_header_string                       = column_headers.join($my_delim)

    puts column_header_string

    artifact_types.each do | this_type |

        typedef_query                          = RallyAPI::RallyQuery.new()
        typedef_query.type                     = :typedefinition
        typedef_query.workspace                = @rally.rally_default_workspace
        typedef_query.query_string             = "(ElementName = \"#{this_type}\")"

        type_definitions                       = @rally.find(typedef_query)
        field_hash                             = {}

        type_definitions.each do | this_typedef |
            this_typedef.read
            this_typedef_objectid              = this_typedef["ObjectID"]
            this_typedef_name                  = this_typedef["Name"]
            attribute_defs                     = this_typedef["Attributes"]
            attribute_defs.each do | this_attribute_def |

                this_attribute_def_objectid    = this_attribute_def["ObjectID"]
                this_attribute_def_name        = this_attribute_def["Name"]
                this_attribute_def_type        = this_attribute_def["AttributeType"]
                this_attribute_def_hidden      = this_attribute_def["Hidden"]
                this_attribute_def_required    = this_attribute_def["Required"]
                this_attribute_def_iscustom    = this_attribute_def["Custom"]

                allowed_values = []
                this_attribute_def['AllowedValues'].each do | attribute_def_value |
                    this_value = attribute_def_value['StringValue']
                    if !this_value.eql?("") then allowed_values.push(this_value) end
                end
                if allowed_values.length > 0 && this_attribute_def_type == "STRING"
                    this_attribute_def_type = "DROPDOWN"
                end

                this_attribute_symbol = attribute_symbol_by_type[this_attribute_def_type]

                field_hash[this_attribute_def['ElementName']] = {
                    "type" => this_attribute_def_type,
                    "allowed" => allowed_values
                }
                allowed_values_string = allowed_values.to_s.gsub("\"","")
                if this_attribute_def_iscustom
                    output_string              = "#{this_type}#{$my_delim}"
                    output_string              += "#{this_typedef_objectid}#{$my_delim}"
                    output_string              += "#{this_attribute_def_objectid}#{$my_delim}"
                    output_string              += "#{this_attribute_def_name}#{$my_delim}"
                    output_string              += "#{this_attribute_symbol}#{$my_delim}"
                    output_string              += "#{this_attribute_def_hidden}#{$my_delim}"
                    output_string              += "#{this_attribute_def_required}#{$my_delim}"
                    output_string              += "#{allowed_values_string}#{$my_delim}"

                    puts output_string
                end
            end
        end
        artifact_hash[this_type] = field_hash
    end
end
