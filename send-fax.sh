#!/bin/sh
#
#Script created by: len.pgh@gmail.com
#
#
#Define your Signalwire Project ID
project_id=00003364-a001-400c-9002-054000000065

#Define your Signalwire API Token
api_token=PTomgthisisareallylongapitokenthatstartswithPT

#Replace example.signalwire.com with your signalwire space url
space_url=example.signalwire.com

#Define the fax from number. This must be a Signalwire number or verified number in this format +19998887777".
dial_from=+15559994444

stage1() {

 while true;do

    read -p "Press (Y) to fax a pdf URL. Press (T) to fax a test page. (yes/test/exit) " yno
    case $yno in
        [Yy]*) stage3;;
        [Tt]*) stage2;;
        [Ee]*) exit 0;;
        [Nn]*) stage2;;
                  *) echo "Done";;
    esac
done

}

stage3() {

echo "Enter the number you want to fax in this format +19998887777"
read -p 'To: ' dial_to
echo "Use a valid URL to a PDF"
read -p 'Define a PDF URL: ' custom_url

command curl https://$space_url/api/laml/2010-04-01/Accounts/$project_id/Faxes.json   -X POST   --data-urlencode "From=$dial_from"   --data-urlencode "To=$dial_to"   --data-urlencode "MediaUrl=$custom_url"   -u "$project_id:$api_token"
}

stage2() {

echo "Enter the number you want to fax in this format +19998887777"
read -p 'To: ' dial_to

command curl https://$space_url/api/laml/2010-04-01/Accounts/$project_id/Faxes.json   -X POST   --data-urlencode "From=$dial_from"   --data-urlencode "To=$dial_to"   --data-urlencode "MediaUrl=https://opensource.apple.com/source/cups/cups-136.9/cups/test/testfile.pdf"   -u "$project_id:$api_token"

}

stage1
exit 0
