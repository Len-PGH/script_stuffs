#!/bin/sh

# Script created by: Len Graham len.pgh@gmail.com
#version1

#Sending a test fax from a Signalwire. Sign up at Signalwire.com
echo "Please enter your SignalWire Space url. ie.  example.signalwire.com"
read -p 'SignalWire Space URL: ' space_url
echo "Please paste the Project ID"
read -p 'Project ID: ' project_id
echo "Please paste the API Token. This will start with PT"
read -p 'Auth Token: ' api_token
echo "This must be a verified number or one from your SignalWire Space in this format +19998887777"
read -p 'From: ' dial_from
echo "This is the fax you are dialing to in this format +19998887777"
read -p 'To: ' dial_to




curl https://$space_url/api/laml/2010-04-01/Accounts/$project_id/Faxes.json   -X POST   --data-urlencode "From=$dial_from"   --data-urlencode "To=$dial_to"   --data-urlencode "MediaUrl=https://opensource.apple.com/source/cups/cups-136.9/cups/test/testfile.pdf"   -u "$project_id:$api_token"
