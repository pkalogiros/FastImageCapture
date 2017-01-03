<?php

$root_path = '/srv/www/assets/upload/';
$root_name = 'https://pantel.is/upload/';

function err ($msg = '')
{
  echo '{"success":0,"msg":"' . $msg . '"}';
  exit (0);
}

function hex2str ($hex)
{
  $map = 'abcdefghijklmnopqrstuvwxyz0123456789';
  $str = '';
  for ($i = 0, $hxlen = strlen ($hex); $i < $hxlen; $i += 2 )
       $str .= $map[ hexdec (substr ($hex, $i, 2)) % 36 ];
  return ($str);
}

function simpleEncrypt ($encoded_data, $key) {
  $key_length = strlen ($key);
  $result = '';

  $length = strlen ($encoded_data);
  for ($i = 0; $i < $length; ++$i) {
        $tmp = $encoded_data[$i];

  for ($j = 0; $j < $key_length; ++$j)
        $tmp = chr (ord ($tmp) ^ ord ($key[$j]));

    $result .= $tmp;
  }

  return ($result);
}

function getUserIP () {
  if( array_key_exists ('HTTP_X_FORWARDED_FOR', $_SERVER) && !empty ($_SERVER['HTTP_X_FORWARDED_FOR']) )
  {
      if (strpos ($_SERVER['HTTP_X_FORWARDED_FOR'], ',') > 0)
      {
        $addr = explode (",", $_SERVER['HTTP_X_FORWARDED_FOR']);
        return (preg_replace("/[^A-Za-z0-9 ]/", '', trim ($addr[0])));
      }
      else
        return (preg_replace("/[^A-Za-z0-9 ]/", '',  trim ($_SERVER['HTTP_X_FORWARDED_FOR'])));
  }
  else
    return (preg_replace("/[^A-Za-z0-9 ]/", '',  trim ($_SERVER['REMOTE_ADDR'])));
}

if ($_SERVER['REQUEST_METHOD'] !== 'PUT') err ($_SERVER['REQUEST_METHOD'] . " not supported");
if (!isset ($_GET['k']) || $_GET['k'] !== 'g8ya0g84SFHSRngaduaEshdhufHfsirkLprghsrFUKariola')
        err ("invalid request identifier");
if (!($putdata = fopen ('php://input', 'w')))
        err ("Could not open INPUT pipe");

$name_root = hex2str (substr (sha1 (mt_rand (10000,999999) . microtime (true)), 0, 22) ) . '.jpg';
$name = $root_path . $name_root;

$fp = fopen ($name, 'w+');
if (!$fp) err ("Could not find a writeable file, sorry");

// read the request's data
while ($data = fread ($putdata, 2048 * 32)) fwrite ($fp, $data);

fclose ($fp);

$len = filesize ($name);
if ($len < 100 || $len > (1024 * 1024 * 4)) {
  unlink ($name);
  err ("what's wrong with your filesize? $len");
}

// validate if the file is a jpeg file if not delete if
if (exif_imagetype ($name) != IMAGETYPE_JPEG) {
    unlink ($name);
    err ("jpeg only club");
}


$name_root = $root_name . $name_root;

// key generation for updating or deleting the image
$key = substr (sha1(uniqid(mt_rand(), true)), 0, 20);
$key .= simpleEncrypt ( strrev ($name_root), 'voltoeuvasjd');
$key = base64_encode ($key) . '~~~' . getUserIP () . '~~~' . time ();

file_put_contents ($name . '.xxx', $key);
echo '{"success":1,"u":"' . $name_root . '","k":"' . $key . '"}';

