<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<title>Gentoo Security</title>
	<link rel="stylesheet" type="text/css" href="css/frames.css">
</head>

<body bgcolor="#739DD1" onLoad="revertFrame();">
<? require_once './includes/ui.body'; ?>
<script>
function collapseFrame()
{
	parent.document.body.cols = "20, *";
}
function revertFrame()
{
	/* If somebody hits "Back" the normal width is restored */
	parent.document.body.cols = "230, *";
}
</script>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
	<tr>
		<td align="center"><img src="images/glsaLogo.<? generateImageExt(); ?>" alt=""><br><font color="#FFFFFF"><br>Welcome to Gentoo Security<br><i>http://glsa.gentoo.org</i><br><br></font></td>
	</tr>
	<tr>
		<td valign="middle" align="right">
			<p class="frame_nav_item">
				<a target="rightFrame" href="frame-body.php" class="frame_nav_item">
					<img src="images/icons/view_text.<? generateImageExt(); ?>" border="0" align="middle" alt="">&nbsp;News
				</a>
			</p>
			<p class="frame_nav_item">
				<a target="rightFrame" href="frame-recent.php" class="frame_nav_item">
					<img src="images/icons/queue.<? generateImageExt(); ?>" border="0" align="middle" alt="">&nbsp;Announcement pool
				</a>
			</p>
			<p class="frame_nav_item">
				<a href="frame-new.php" target="rightFrame" class="frame_nav_item">
					<img src="images/icons/new.<? generateImageExt(); ?>" border="0" align="middle" alt="">&nbsp;File an announcement
				</a>
			</p>
<!--			<p class="frame_nav_item">
				<a href="" class="frame_nav_item">
					<img src="images/icons/query.<? generateImageExt(); ?>" border="0" align="middle" alt="">&nbsp;Query announcements
				</a>
			</p> -->
			<p class="frame_nav_item">
				<a target="rightFrame" href="frame-stats.php" class="frame_nav_item">
					<img src="images/icons/reporting.<? generateImageExt(); ?>" border="0" align="middle" alt="">&nbsp;Announcement stats
				</a>
			</p>

			<p class="frame_nav_item">
				<a href="frame-left-collapsed.php" class="frame_nav_item" onClick="collapseFrame()">
					<img src="images/icons/back.<? generateImageExt(); ?>" border="0" align="middle" alt="">&nbsp;Collapse this frame
				</a>
			</p>
			<p class="frame_nav_item">
				<a href="" class="frame_nav_item">
					<img src="images/icons/help.<? generateImageExt(); ?>" border="0" align="middle" alt="">&nbsp;Help
				</a>
			</p>
		</td>
	</tr>
</table>&nbsp;
</body>
</html>
