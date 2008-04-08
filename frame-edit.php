<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Frameset//EN" "http://www.w3.org/TR/REC-html40/frameset.dtd">
<html>
<head>
	<title>Gentoo Security - GLSA Edit</title>
</head>
<frameset rows="75%, *" name="frameSet">
	<frame name="topFrame" src="frame-new.php<? if($HTTP_GET_VARS['editGLSA'] != '') { echo '?editGLSA=', $HTTP_GET_VARS['editGLSA']; } ?>">
	<frame name="bottomFrame" src="frame-view.php<? if($HTTP_GET_VARS['editGLSA'] != '') { echo '?reviewsOnly&id=', $HTTP_GET_VARS['editGLSA']; } ?>">
</frameset>
</html>
