#!/bin/bash

export cluster_name=$1
export domain_name=$2
export release_name=$3
export namespace=$4
export notify_email=$5
export install_status=$6
export log_file=$7

# Declaring variable
TIME_FORMAT="%Y-%m-%d_%H-%M-%S"

# regex to validate email patterns (supports multiple recipients)
email_regex="^(([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)(\s*;\s*|\s*$))*"

# regex allows trailing spaces which may create issues, removing all of them
set -f && notify_email="$( set -f; printf "%s" $notify_email )" && set +f

# validate email id patterns
if [[ ${notify_email} =~ $email_regex ]] ; then
  echo $'\xe2\x9c\x89  '" INFO:  $(date +${TIME_FORMAT}) :: Notifying ${notify_email} with installation status..."

  # SMTP settings
  SMTP_USER="830807bd9245a3"
  SMTP_PASS="99daecdec5778e"
  SMTP_SERVER="smtp://smtp.mailtrap.io:2525"
  MAIL_FROM="noreply@ipmcp4i.com"

  # curl command parameters construction
  curl_cmd="curl --ssl --url ${SMTP_SERVER} --user ${SMTP_USER}:${SMTP_PASS} --mail-from ${MAIL_FROM}"

  # setting the status_statement based on install_status which will be triggered in the mail body
  STATEMENT="Installation of ${release_name} completed successfully! Your ${release_name} in ${cluster_name} is ready to use."
  STATUS_LOGO="&#9989;"
  STATEMENT_COLOR="02af02"
  attachment_section=""
  if [[ "$install_status" != "successful" ]] 
  then
    STATEMENT="We ran into a problem while installing ${release_name}. Please look for the logs which may specify failure reasons."
    STATEMENT_COLOR="df1d1d"
    STATEMENT_COLOR="ca1111"
    STATUS_LOGO="&#10060;"
    attachment_section="

--Boundary
Content-Type: text/plain
Content-Transfer-Encoding: base64
Content-Disposition: inline; filename=${log_file}
Content-ID: CP4I_on_Azure_Installation_Log

$(base64 -w 0 ${log_file})

"
  fi

  html_body="--upload-file - <<EOF
From: IPM CP4I <noreply@ipmcp4i.com>
To: ${notify_email}
Subject: CP4I Installation Status - ${release_name} - ${install_status^^}!
Content-Type: multipart/related; boundary=\"Boundary\"

--Boundary
Content-Type: text/html; charset=us-ascii
Content-ID: CP4I_on_Azure_Installation_Status

<html>
<head>
    <title>CP4I on Azure Notification</title>
    <meta charset=\"utf-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\" />
    <style>
        body,table,td, a {-webkit-text-size-adjust: 100%;-ms-text-size-adjust: 100%;}
        table, td {mso-table-lspace: 0pt;mso-table-rspace: 0pt;}
        img {-ms-interpolation-mode: bicubic;}
        img {border: 0;height: auto;line-height: 100%;outline: none;text-decoration: none;}
        table {border-collapse: collapse !important;}
        a[x-apple-data-detectors] {color: inherit !important;text-decoration: none !important;font-size: inherit !important;font-family: inherit !important;font-weight: inherit !important;line-height: inherit !important;}
        body {height: 100% !important;margin: 0 !important;padding: 0 !important;width: 100% !important;}
        h1,table,td,th,a,div,i,.img-block,img {font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;}
        a {text-decoration: none;color: #000000;}
        a:visited {color: #068fff;}
        td {font-size: 16px;}
        @media screen and (max-width: 525px) {.container {padding: 0 !important;}.header {padding: 10px 30px !important;}.logo img {margin: 0 auto !important;}.responsive-table {width: 100% !important;}.logo {margin: 0 auto;padding: 10px 0 10px 5% !important;}}
        h1 {font-size: 22px;font-weight: 600;margin: 0;color: #$STATEMENT_COLOR;}
        div[style*=\"margin: 16px 0;\"] {margin: 0 !important;}
    </style>
</head>
<body>
    <div class=\"container\" style=\"background:#e8e8e8; min-height:fit-content; font-family: Segoe UI, Helvetica, Arial, sans-serif;  color:#444444; font-size:14px; padding: 10px;\">
        <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" class=\"\">
            <tr>
                <td style=\"background: #e8e8e8;\"></td>
                <td width=\"660\" style=\"background: #fff;\">
                    <!--[if (gte mso 9)|(IE)]> <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"width:660px; height:0;\"><tr><td></td></tr></table> <![endif]-->
                    <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" style=\"min-width: 100%;\">
                        <tr>
                            <td style=\"padding: 15px 0 0 35px; background: linear-gradient(90deg, #003b68 20%, #171717 100%);\">
                                <table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"100%\" style=\"min-height:45px;\" class=\"responsive-table\">
                                    <tr><td><table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" class=\"logo\"><tr><td><a href=\"https://portal.azure.com\" target=\"_blank\"><img src=\"https://raw.githubusercontent.com/DauthjanCTS/cloud-pak-for-integration/main/Azure_NewStyle.png\" width=\"170\" height=\"170\" alt=\"Azure\" class=\"img-block\"/></a></td></tr></table></td></tr>
                                    <tr><td align=\"center\" valign=\"middle\" style=\"padding: 5px 0 25px 0; font-size: x-large;font-family: 'Lucida Sans', 'Lucida Sans Regular', 'Lucida Grande', 'Lucida Sans Unicode', Geneva, Verdana, sans-serif; color: #fff;\">Cloud Pak For Integration</td></tr>
                                </table>
                            </td>
                        </tr>
                        <tr>
                            <td valign=\"center\"  style=\"padding: 40px 30px 30px 40px; background:#fff; border-bottom: 2px solid #e8e8e8;\">
                                <table border=\"0\" cellspacing=\"0\" cellpadding=\"0\" align=\"center\" valign=\"middle\"><tr><td style=\"padding: 0 0 30px;\"><h1>${STATUS_LOGO} Notification from CP4I on Azure!</h1></td></tr></table>
                                <table border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr><td style=\"padding: 0 0 30px; text-align: justify;\">$STATEMENT</td></tr></table>
                            </td>
                        </tr>
                        <tr valign=\"middle\"  style=\"height: 70px; width: 30px; background: #171717;\">
                            <td valign=\"middle\" align=\"center\" >
                                <table border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
                                    <tr>
                                        <td width=\"37\" style=\"text-align: center; padding: 0 10px 0 10px;\"><a href=\"https://www.ibm.com/cloud\" target=\"_blank\"><img title=\"IBM Cloud\" alt=\"IBM Cloud\" src=\"https://avatars.githubusercontent.com/u/7284885?s=200&v=4\" width=\"37\" height=\"37\" border=\"0\" /></a></td>
                                        <td width=\"37\" style=\"text-align: center; padding: 0 10px 0 10px;\"><a href=\"https://www.openshift.com\" target=\"_blank\"><img title=\"Red Hat Openshift\" alt=\"Red Hat Openshift\" src=\"https://avatars.githubusercontent.com/u/792337?s=200&v=4\" width=\"37\" height=\"37\" border=\"0\" /></a></td>
                                        <td width=\"37\" style=\"text-align: center; padding: 0 10px 0 10px;\"><a href=\"https://www.ibm.com/in-en/cloud/cloud-pak-for-integration\" target=\"_blank\"><img title=\"Cloud Pak For Integration\" alt=\"Cloud Pak For Integration\" src=\"https://www.oss-group.co.nz/hs-fs/hubfs/IBM%20Cloud%20Paks%20Icons/IBM%20Cloud%20Paks%2003%20Integration.png\" width=\"33\" height=\"33\" border=\"0\" /></a></td>
                                        <td width=\"37\" style=\"text-align: center; padding: 0 10px 0 10px;\"><a href=\"https://www.ibm.com/\" target=\"_blank\"><img title=\"IBM\" alt=\"IBM\" src=\"https://cybersecuritysummit.co.uk/wp-content/uploads/2020/06/IBM-logo.png\" width=\"39\" height=\"39\" border=\"0\" /></a></td>
                                        <td width=\"37\" style=\"text-align: center; padding: 0 10px 0 10px;\"><a href=\"https://www.cognizant.com/\" target=\"_blank\"><img title=\"Cognizant Technology Solutions\" alt=\"Cognizant Technology Solutions\" src=\"https://digileaders.com/wp-content/uploads/2018/08/Cognizant.png\" width=\"87\" height=\"37\" border=\"0\" ></a></td>
                                    </tr>
                                </table>
                            </td> 
                        </tr>
                        <tr style=\"height: 60px; width: 30px; background: #171717;\"><td valign=\"top\" align=\"center\" style=\"font-weight: 400;color: rgba(255, 255, 255, 0.8);\">© Copyright $(date +'%Y') - All Rights Reserved. <br/>This was an auto-generated email. Please do not reply. </td> </tr>
                    </table>
                </td>
                <td style=\"background: #e8e8e8;\"></td>
            </tr>
        </table>
    </div>
</body>

</html>
${attachment_section}
--Boundary--
EOF
"

  # creating mail_rcpt array for multiple recipients
  declare -a mail_rcpt
  IFS=";" read -a email_array <<< $notify_email
  i=0
  while [ $i -lt ${#email_array[@]} ]
  do
    mail_rcpt=("${mail_rcpt[@]}" --mail-rcpt "${email_array[i]}")
    ((i++))
  done

  # trigger email
  eval "${curl_cmd} ${mail_rcpt[@]} ${html_body}"

else
  echo -e $'\xE2\x9D\x97  '"$ WARN:  $(date +${TIME_FORMAT}) :: Email ID pattern could not be validated, unable to trigger mail..."
fi