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
YEAR=`date +'%Y'`

# regex to validate email patterns (supports multiple recipients)
email_regex="^(([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)(\s*;\s*|\s*$))*"

# regex allows trailing spaces which may create issues, removing all of them
set -f && notify_email="$( set -f; printf "%s" $notify_email )" && set +f

# validate email id patterns
if [[ ${notify_email} =~ $email_regex ]] ; then
  echo $'\xe2\x9c\x89  '" INFO:  $(date +${TIME_FORMAT}) :: Notifying ${notify_email} with installation status..."

  # SMTP settings
  SMTP_USER="ipm.cp4i@gmail.com"
  SMTP_PASS="c7d4540b72c44a30a72ae9f698062488"
  SMTP_SERVER="smtps://smtp.gmail.com:465"
  MAIL_FROM="ipm.cp4i@gmail.com"

  # curl command parameters construction
  curl_cmd="curl --ssl --url ${SMTP_SERVER} --user ${SMTP_USER}:${SMTP_PASS} --mail-from ${MAIL_FROM}"

  # setting the status_statement based on install_status which will be triggered in the mail body
  STATEMENT="Installation of ${release_name} completed successfully! Your ${release_name} in ${cluster_name} is ready to use."
  STATUS_LOGO="&#9989;"
  STATEMENT_COLOR="#02af02"
  attachment_section=""
  if [[ "$install_status" != "successful" && "$install_status" != "completed" ]]; then
    STATEMENT="We ran into a problem while ${release_name}. Please look for the logs which may specify failure reasons."
    STATEMENT_COLOR="#ca1111"
    STATUS_LOGO="&#10060;"
    if [ -e "${log_file}" ]; then
        attachment_section="

--Boundary
Content-Type: text/plain
Content-Transfer-Encoding: base64
Content-Disposition: inline; filename=${log_file}
Content-ID: CP4I_on_Azure_Installation_Log

$(base64 -w 0 ${log_file})

"
    fi 
  fi

  html_body="--upload-file - <<EOF
From: IPM CP4I <noreply@ipmcp4i.com>
To: ${notify_email}
Subject: CP4I Installation Status - ${release_name} - ${install_status^^}!
Content-Type: multipart/related; boundary=\"Boundary\"

--Boundary
Content-Type: text/html; charset=us-ascii
Content-ID: CP4I_on_Azure_Installation_Status

<html xmlns='http://www.w3.org/1999/xhtml'>

<head>
    <meta http-equiv='content-type' content='text/html; charset=utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0;'>
    <meta name='format-detection' content='telephone=no' />
    <style>
        body {margin: 0;padding: 0;min-width: 100%;width: 100% !important;height: 100% !important;}
        body,table,td,div,p,a {-webkit-font-smoothing: antialiased;text-size-adjust: 100%;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;line-height: 100%;}
        table,
        td {mso-table-lspace: 0pt;mso-table-rspace: 0pt;border-collapse: collapse !important;border-spacing: 0;}
        img {border: 0;line-height: 100%;outline: none;text-decoration: none;-ms-interpolation-mode: bicubic;}
        #outlook a {padding: 0;}
        @media all and (min-width: 660px) {.container {border-radius: 8px;-webkit-border-radius: 8px;-moz-border-radius: 8px;-khtml-border-radius: 8px;}}
        a,a:hover {color: #127DB3;}
        .footer a,.footer a:hover {color: #999999;}
    </style>
    <title>CP4I - Azure</title>
</head>
<body topmargin='0' rightmargin='0' bottommargin='0' leftmargin='0' marginwidth='0' marginheight='0' width='100%'
    style='border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; width: 100%; height: 100%; -webkit-font-smoothing: antialiased; text-size-adjust: 100%; -ms-text-size-adjust: 100%; -webkit-text-size-adjust: 100%; line-height: 100%; background-color: #F0F0F0; color: #000000;'
    bgcolor='#F0F0F0' text='#000000'>
    <table width='100%' align='center' border='0' cellpadding='0' cellspacing='0'
        style='border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; width: 100%;' class='background'>
        <tr>
            <td align='center' valign='top' style='border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0;'
                bgcolor='#F0F0F0'>
                <table border='0' cellpadding='0' cellspacing='0' align='center' width='660'
                    style='border-collapse: collapse; border-spacing: 0; padding: 0; width: inherit; max-width: 660px;'>
                </table>
                <table border='0' cellpadding='0' cellspacing='0' align='center' bgcolor='#FFFFFF' width='660'
                    style='border-collapse: collapse; border-spacing: 0; padding: 0; width: inherit; max-width: 660px;' class='container'>
                    <tr style='background-color: #1C1C1C; background: linear-gradient(90deg, #003b68 20%, #1C1C1C 100%); height: 55px;'>
                        <td align='left' valign='bottom' style='border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; padding-left: 6.25%; padding-right: 6.25% ;width: 87.5%;'>
                            <a href='https://portal.azure.com' target='_blank'><img src='https://raw.githubusercontent.com/Dauthjan/generic/main/Azure_NewStyle.png' width='170' alt='Azure' class='img-block'/></a>
                        </td>
                    </tr>
                    <tr style='background-color: #1C1C1C; background: linear-gradient(90deg, #003b68 20%, #1C1C1C 100%);height: 75px'>
                        <td align='center' valign='top' style='border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; padding-left: 6.25%; padding-right: 6.25% ;width: 87.5%; font-size: 24px; font-weight: 400; line-height: 130%; padding-top: 25px; color: #fff; font-family: sans-serif;'>Cloud Pak For Integration</td>
                    </tr>
                    <tr style='height: 200px'>
                        <td align='center' valign='middle' 
                            style='border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; padding-left: 6.25%; padding-right: 6.25%;'>
                            <table align='center' border='0' cellspacing='0' cellpadding='0' style='width: inherit; margin: 0; padding: 0; border-collapse: collapse; border-spacing: 0;'>
                                <tr>
                                    <td align='left' valign='middle' style='border-collapse: collapse; border-spacing: 0; padding-top: 30px; padding-right: 20px; font-size: 2em; color: ${STATEMENT_COLOR};'>${STATUS_LOGO}</td>
                                    <td align='left' valign='middle' style='font-size: 17px; font-weight: 400; line-height: 160%; border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; padding-top: 25px; color: #000000; font-family: sans-serif;'>
                                        <b style='color: ${STATEMENT_COLOR};  font-size: 1.3em;'>Notification from CP4I on Azure!</b><br /><br />
                                        <i style='color: #333333;'>${STATEMENT}</i>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    <tr style='background-color: #1C1C1C; background: #1C1C1C;height: 60px'>
                        <td width='37' style='text-align: center; padding: 0 10px 0 10px;' align='center' valign='bottom' >
                            <a style='text-decoration:none;' href='https://www.ibm.com/cloud' target='_blank'><img title='IBM Cloud' alt='IBM Cloud' src='https://avatars.githubusercontent.com/u/7284885?s=200&v=4'width='45' border='0' />&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</a>
                            <a style='text-decoration:none;' href='https://www.openshift.com' target='_blank'><img title='Red Hat Openshift' alt='Red Hat Openshift' src='https://avatars.githubusercontent.com/u/792337?s=200&v=4'width='45' border='0' />&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</a>
                            <a style='text-decoration:none;' href='https://www.ibm.com/in-en/cloud/cloud-pak-for-integration' target='_blank'><img title='Cloud Pak For Integration' alt='Cloud Pak For Integration' src='https://raw.githubusercontent.com/Dauthjan/generic/main/Cloud-pak-for-integration.png' width='45' border='0' /></a>
                        </td>
                    </tr>
                    <tr style='background-color: #1C1C1C; background: #1C1C1C;height: 40px;'>
                        <td width='37' style='text-align: center; padding: 0 10px 0 10px;' align='center' valign='center' >
                            <a style='text-decoration:none;' href='https://www.ibm.com/' target='_blank'><img title='IBM' alt='IBM' src='https://cybersecuritysummit.co.uk/wp-content/uploads/2020/06/IBM-logo.png' width='45' border='0' />&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</a>
                            <a href='https://www.cognizant.com/' target='_blank'><img title='Cognizant Technology Solutions' alt='Cognizant Technology Solutions' src='https://raw.githubusercontent.com/Dauthjan/generic/main/Cognizant.png' width='87' border='0'></a>
                        </td>
                    </tr>
                </table>
                <table border='0' cellpadding='0' cellspacing='0' align='center' width='660' style='border-collapse: collapse; border-spacing: 0; padding: 0; width: inherit; max-width: 660px;'>
                    <tr>
                        <td align='center' valign='top' style='border-collapse: collapse; border-spacing: 0; margin: 0; padding: 0; padding-left: 6.25%; padding-right: 6.25%; width: 87.5%; font-size: 13px; font-weight: 400; line-height: 150%; padding-top: 20px; padding-bottom: 20px; color: #999999; font-family: sans-serif;'
                            class='footer'>&copy; Copyright $YEAR - All Rights Reserved. <br />This was an auto-generated email. Please do not reply.
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
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
