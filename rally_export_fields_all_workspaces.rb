#!/usr/bin/env ruby
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
$rally_api_key                                 =  nil
$rally_workspace                               =  "My Workspace"
$wsapi_version                                 =  "v2.0"

$my_delim                                      = ","
$output_filename                               = "exported_field_definitions.csv"

$file_encoding                                 = 'UTF-8'


# Load (and maybe override with) my personal/private variables from a file...
my_vars= File.dirname(__FILE__) + "/my_vars.rb"
if FileTest.exist?( my_vars ) then require my_vars end

begin
    #==================== Making a @rally to Rally ====================
    config                                     = {:base_url => "#{$rally_url}/slm"}
    config[:username]                          = $rally_username
    config[:password]                          = $rally_password
    config[:api_key]                           = $rally_api_key
    config[:workspace]                         = $rally_workspace
    config[:version]                           = $wsapi_version

    puts "Connecting to Rally:"
    puts "\t  :base_url : #{config[:base_url]}"
    puts "\t  :username : #{config[:username]}"
    if  !config[:api_key].nil? && !config[:api_key].empty?
        hidden_apikey = config[:api_key][0..4] + config[:api_key][5..-5].gsub(/./,'.') + config[:api_key][-4,4]
        puts "\t  :api_key  : #{hidden_apikey}"
    end
    puts "\t  :workspace: #{config[:workspace]}"
    puts "\t  :version  : #{config[:version]}"

    begin
        @rally = RallyAPI::RallyRestJson.new(config)
        puts "Connected:"
        puts "\tSubscription: #{@rally.rally_default_workspace.rally_object['Subscription']['_refObjectName']}"
        puts "\tWorkspace   : #{@rally.rally_workspace_name}"
    rescue Exception => ex
        puts "ERROR: #{ex.message}"
        puts "       Cannot connect to Rally"
        raise "       Problem connecting to Rally at: '#{config[:base_url]}'"
    end

    subscription_query                         = RallyAPI::RallyQuery.new()
    subscription_query.type                    = :subscription
    subscription_query.fetch                   = "Name,Workspaces,Name,State"
    subscription_results                       = @rally.find(subscription_query)
    this_subscription                          = subscription_results.first
    workspaces                                 = this_subscription["Workspaces"]

    column_headers                             = [
                                                    "Workspace", "ArtifactType", "TypeDefOID",
                                                    "AttrDefOID", "AttrDefName",
                                                    "AttrDefType", "Hidden", "Required",
                                                    "Custom","AllowedValues"
                                                ]

    $output_fields = %w{Workspace ArtifactType TypeDefOID AttrDefOID AttrDefName AttrDefType Hidden Required Custom AllowedValues}

    column_header_string                       = column_headers.join($my_delim)


    summary_csv = CSV.open($output_filename, "wb", {:col_sep => $my_delim, :encoding => $file_encoding})
    summary_csv << $output_fields

    artifact_types                             = ["Defect","HierarchicalRequirement",
                                                            "PortfolioItem","Task","TestCase"]
    closed_ws = 0
    workspaces.each_with_index do | this_workspace, index_ws | #{

        # starting point for debugging
        # next if index_ws < 18

        # found hang on this sub/ws
        if @rally.rally_default_workspace.rally_object['Subscription']['_refObjectName'] == 'Rally - Sheri Quarfoot'
            if this_workspace['Name'] == 'zDisney'
                puts "(#{index_ws+1} of #{workspaces.length}) Skipping hang-prone workspace '#{this_workspace}'"
                next
            end
        end

        workspace_state = this_workspace["State"]
        if workspace_state != "Open" then #{
            puts "(#{index_ws+1} of #{workspaces.length}) Skipping closed workspace '#{this_workspace}'"
            closed_ws += 1
        else
            puts "(#{index_ws+1} of #{workspaces.length}) Summarizing field definitions for workspace '#{this_workspace}'"
            this_workspace_name = this_workspace["Name"]

            workspace_config = {
                :username    => $rally_username,
                :password    => $rally_password,
                :api_key     => $rally_api_key,
                :workspace   => this_workspace_name,
                :version     => $wsapi_version
            }
            
            rally_workspace_connection = RallyAPI::RallyRestJson.new(workspace_config)

            artifact_types.each do | this_type | #{
                puts "\tProcessing artifact type: #{this_type}"

                typedef_query                          = RallyAPI::RallyQuery.new()
                typedef_query.type                     = :typedefinition
                typedef_query.workspace                = this_workspace
                typedef_query.query_string             = "(ElementName = \"#{this_type}\")"

                type_definitions                       = rally_workspace_connection.find(typedef_query)
                field_hash                             = {}

                type_definitions.each do | this_typedef | #{
                    this_typedef.read
                    this_typedef_objectid              = this_typedef["ObjectID"]
                    this_typedef_name                  = this_typedef["Name"]
                    attribute_defs                     = this_typedef["Attributes"]
                    attribute_defs.each do | this_attribute_def | #{

                        this_attribute_def_workspace   = this_typedef["Workspace"]
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

                        this_attribute_def_type = this_attribute_def['RealAttributeType']

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
                        output_string              += "#{this_attribute_def['RealAttributeType']}#{$my_delim}"
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
                        output_record              << this_attribute_def['RealAttributeType']
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
                    end #} of 'attribute_defs.each do | this_attribute_def |'
                end #} of 'type_definitions.each do | this_typedef |'
            end #} of 'artifact_types.each do | this_type |'
        end #} of 'if workspace_state == "Open" then'
    end #} of 'workspaces.each do | this_workspace |'

    puts "Ignored '#{closed_ws}' closed workspaces."
    puts "Output file: '#{$output_filename}'"
    puts "Done!"

end
