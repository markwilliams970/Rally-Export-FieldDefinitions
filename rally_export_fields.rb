# Copyright (c) 2013 Rally Software Development
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'rally_api'
require 'csv'

$rally_url                                     =  "https://rally1.rallydev.com"
$rally_username                                =  "user@company.com"
$rally_password                                =  "topsecret"
$rally_workspace                               =  "My Workspace"
$wsapi_version                                 =  "v2.0"

$my_delim                                      = ","

$file_encoding                                 = 'UTF-8'

# Mode:
# :custom_only   -> Exports Custom Field definitions Only
# :standard_only -> Exports Standard Field definitions Only
# :all_fields    -> Exports All field definitions
$mode = :custom_only

$output_filename = "exported_field_definitions.csv"


# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

begin
    #==================== Making a @rally to Rally ====================
    config                                     = {:base_url => "#{$rally_url}/slm"}
    config[:username]                          = $rally_username
    config[:password]                          = $rally_password
    config[:workspace]                         = $rally_workspace
    config[:version]                           = $wsapi_version

    @rally = RallyAPI::RallyRestJson.new(config)


    artifact_types                             = ["Defect","HierarchicalRequirement",
                                                    "PortfolioItem","Task","TestCase"]
    attribute_symbol_by_type = {}
    attribute_symbol_by_type["BOOLEAN"]        = :boolean
    attribute_symbol_by_type["DATE"]           = :date
    attribute_symbol_by_type["DECIMAL"]        = :decimal
    attribute_symbol_by_type["DROP_DOWN"]      = :dropdown
    attribute_symbol_by_type["INTEGER"]        = :integer
    attribute_symbol_by_type["STRING"]         = :string
    attribute_symbol_by_type["TEXT"]           = :text
    attribute_symbol_by_type["WEB_LINK"]       = :weblink
    attribute_symbol_by_type["MULTI_VALUE"]    = :multivalue
    attribute_symbol_by_type["USER"]           = :user

    artifact_hash = {}

    column_headers                             = ["Workspace", "ArtifactType", "TypeDefOID",
                                                    "AttrDefOID", "AttrDefName",
                                                    "AttrDefType", "Hidden", "Required",
                                                    "Custom","AllowedValues"]

    $output_fields = %w{Workspace ArtifactType TypeDefOID AttrDefOID AttrDefName AttrDefType Hidden Required Custom AllowedValues}

    column_header_string                       = column_headers.join($my_delim)

    # puts column_header_string

    puts "Summarizing field definitions for workspace: #{$rally_workspace}..."

    summary_csv = CSV.open($output_filename, "wb", {:col_sep => $my_delim, :encoding => $file_encoding})
    summary_csv << $output_fields

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

                this_attribute_def_workspace   = this_typedef["Workspace"]
                this_attribute_def_objectid    = this_attribute_def["ObjectID"]
                this_attribute_def_name        = this_attribute_def["Name"]
                this_attribute_def_type        = this_attribute_def["RealAttributeType"]
                this_attribute_def_hidden      = this_attribute_def["Hidden"]
                this_attribute_def_required    = this_attribute_def["Required"]
                this_attribute_def_iscustom    = this_attribute_def["Custom"]

                allowed_values = []
                this_attribute_def['AllowedValues'].each do | attribute_def_value |
                    this_value = attribute_def_value['StringValue']
                    if !this_value.eql?("") then allowed_values.push(this_value) end
                end

                this_attribute_symbol = attribute_symbol_by_type[this_attribute_def_type]

                field_hash[this_attribute_def['ElementName']] = {
                    "type" => this_attribute_def_type,
                    "allowed" => allowed_values
                }
                allowed_values_string = allowed_values.to_s.gsub("\"","")

if this_type == "HierarchicalRequirement" then
    this_type = "UserStory"
end

                output_string              = "#{this_attribute_def_workspace}#{$my_delim}"
                output_string              += "#{this_type}#{$my_delim}"
                output_string              += "#{this_typedef_objectid}#{$my_delim}"
                output_string              += "#{this_attribute_def_objectid}#{$my_delim}"
                output_string              += "#{this_attribute_def_name}#{$my_delim}"
                output_string              += "#{this_attribute_symbol}#{$my_delim}"
                output_string              += "#{this_attribute_def_hidden}#{$my_delim}"
                output_string              += "#{this_attribute_def_required}#{$my_delim}"
                output_string              += "#{this_attribute_def_iscustom}#{$my_delim}"
                output_string              += "#{allowed_values_string}#{$my_delim}"

                output_record              = []
                output_record              << this_attribute_def_workspace
                output_record              << this_type
                output_record              << this_typedef_objectid
                output_record              << this_attribute_def_objectid
                output_record              << this_attribute_def_name
                output_record              << this_attribute_symbol
                output_record              << this_attribute_def_hidden
                output_record              << this_attribute_def_required
                output_record              << this_attribute_def_iscustom
                output_record              << allowed_values_string

                case $mode
                when :custom_only
                    if this_attribute_def_iscustom then 
                        # puts output_string
                        summary_csv << output_record
                    end
                when :standard_only
                    if !this_attribute_def_iscustom then
                        # puts output_string
                        summary_csv << output_record
                    end
                when :all_fields
                    # puts output_string
                    summary_csv << output_record
                end
            end
        end
        artifact_hash[this_type] = field_hash
    end

    puts "Done!"

end
