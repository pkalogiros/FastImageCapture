<?php

$root_path = '/srv/www/assets/upload/';

if (  !isset ($_GET['k']) ||
      $_GET['k'] !== 'g8ya0g84SFHSRngaduaEshdhufHfsirkLprghsrFUKariola' ||
      !isset ($_GET['d']) ||
      !isset ($_GET['e']))
{
	echo '{"success":0}';
	exit (0);
}

$encrypted_str = rawurldecode (urlencode($_GET['d']));
$picture_name = rawurldecode (urlencode($_GET['e']));

$root_path = $root_path . $picture_name . '.jpg';
$keyname = $root_path . '.xxx';

if (file_exists ($keyname)
	&& substr (file_get_contents ($keyname), 0, strlen ($encrypted_str) + 1) === ($encrypted_str . '~'))
{
	unlink ($root_path);
	unlink ($keyname);

	echo '{"success":1, "e":"' . $keyname . '"}';
}
else
	echo '{"success":0}';
