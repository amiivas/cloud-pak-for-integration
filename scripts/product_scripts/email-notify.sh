#!/bin/bash

export cluster_name=$1
export domain_name=$2
export release_name=$3
export namespace=$4
export notify_email=$5
export install_status=$6

MAIL=
TIME_FORMAT="%Y-%m-%d_%H-%M-%S"

email_regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

if [[ ${notify_email} =~ $regex ]] ; then
  echo $'\xe2\x9c\x89  '" INFO:  $(date +${TIME_FORMAT}) :: Notifying ${notify_email} with installation status..."

  # setting the status_statement based on install_status which will be triggered in the mail body
  STATEMENT="Installation of ${release_name} completed successfully! Your ${release_name} in ${cluster_name} is ready to use."
  STATEMENT_COLOR="2ae261"
  if [[ "$install_status" != "successful" ]] 
  then
      STATEMENT="We ran into a problem while installing ${release_name}. Please look for the logs which may specify failure reason."
      STATEMENT_COLOR="df1d1d"
  fi

# trigger email using curl
curl --ssl \
--url 'smtp://smtp.mailtrap.io:2525' \
--user '830807bd9245a3:99daecdec5778e' \
--mail-from noreply@ipmcp4i.com \
--mail-rcpt ${notify_email} \
--upload-file - <<EOF
From: IPM CP4I <noreply@ipmcp4i.com>
To: ${notify_email}
Subject: CP4I Installation Status - ${release_name}
Content-Type: multipart/related; boundary="Boundary"

--Boundary
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: inline
Content-ID: CP4I on Azure Installation Status

<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta http-equiv='X-UA-Compatible' content='IE=edge'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <style>
        body { width: 100%; background-color: #ffffff; margin: 0; padding: 0; -webkit-font-smoothing: antialiased; font-family: Georgia, Times, serif }
        table { border-collapse: collapse; }
        .border-complete { border-top: 1px solid #dadada; border-left: 1px solid #dadada; border-right: 1px solid #dadada; }
        .border-lr { border-left: 1px solid #dadada; border-right: 1px solid #dadada;}
        h2#text-msg { font-family: 'Pacifico'; margin: 23px auto 5px auto; font-size: 27px; color: #${STATEMENT_COLOR}; }
        p.text-msg { text-align: center; font-family: arial; color: #7c7b7b; font-size: 12px; padding: 10px 10px 24px 10px; }
        p#footer-txt { text-align: center; color: #303032; font-family: arial; font-size: 12px; padding: 0 32px; }
        @media only screen and (max-width: 640px) {body[yahoo] .deviceWidth { width: 440px !important;padding: 0; } body[yahoo] .center { text-align: center !important; } }
        @media only screen and (max-width: 479px) {body[yahoo] .deviceWidth { width: 280px !important; padding: 0; } body[yahoo] .center { text-align: center !important; } }
    </style>
    <title>CP4I on Azure Alert</title>
</head>
<body leftmargin='0' topmargin='0' marginwidth='0' marginheight='0' yahoo='fix' style='font-family: Georgia, Times, serif'>
    <table width='100%' border='0' cellpadding='0' cellspacing='0' align='center'>
        <table width='600' height='108' border='0' cellpadding='0' cellspacing='0' align='center' class='border-lr deviceWidth' bgcolor='#3baaff'></table>
        <table width='600' border='0' cellpadding='0' cellspacing='0' align='center' class='border-lr deviceWidth' bgcolor='#fff'>
            <tr><td align='center'><h2 id='text-msg'>Notification from CP4I on Azure!</h2></td></tr>
            <tr><td class='center'><p class='text-msg'>$STATEMENT</p></td></tr>
        </table>
        <table width='600' border='0' cellpadding='0' cellspacing='0' align='center' class='border-complete deviceWidth' bgcolor='#eeeeed'>
            <tr><td style='text-align: center;'> <p id='footer-txt'> <b>© Copyright $(date +'%Y') - All Rights Reserved</b><br /><br />This was an auto-generated email. Please do not reply.</p></td></tr>
        </table>
    </table>
</body>
</html>

--Boundary--
EOF
  else
    echo -e $'\xE2\x9D\x97  '"$ WARN:  $(date +${TIME_FORMAT}) :: Email ID pattern could not be validated, unable to trigger mail..."
  fi