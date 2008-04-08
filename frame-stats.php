<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<?php

/***************************************************************************
 *                                                                         *
 *   Copyright (C) 2003 Tim Yamin < plasmaroo >                            *
 *               < plasmaroo@plasmaroo.squirrelserver.co.uk >              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 *                                                                         *
 ***************************************************************************/

require_once './includes/ui.body';
require_once './includes/ui.init';

$rangeTree = fileGrepper_parseTree();
$rangeYears = array();

foreach($rangeTree as $rangeItem)
{
	if(!in_array(($rangeYear = date('Y', $rangeItem[1])), $rangeYears))
		$rangeYears[] = $rangeYear;
}
asort($rangeYears);

$GetYear = '-';
if(in_array($HTTP_GET_VARS['year'], $rangeYears))
	$GetYear = $HTTP_GET_VARS['year'];
if($HTTP_GET_VARS['noPooled'] != '')
	$noPooled = true;

$GetMap = true;
require_once './frame-stats.graph.php';

initBegin('Statistics');
bodyFooter_invoke();

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i>Gentoo Security Statistics</i></b></font><hr>
		<? generateKonqBreak(); ?><dl><dt></dt><dd>			The following graph shows GLSA releases along with the number of releases per month as well as the time of each GLSA in the month. Click on a star to view the GLSA. Red stars indicate that multiple GLSAs were released on that day; while the bars indicate the number of pooled GLSAs that still remain from that month.<? echo($ImageMap); ?>

		<br><table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light">
		<tr>
			<td width="75" align="center"><b>Year:</b></td>
			<td>
			<? foreach($rangeYears as $rangeYear)
			   {
				if(($GetYear == $rangeYear) || ($GetYear == '-' && $rangeYear == date('Y')))
					echo '<i>';
				else
					echo '<a href="frame-stats.php?year='.$rangeYear.'">';
				echo $rangeYear;
				if(($GetYear == $rangeYear) || ($GetYear == '-' && $rangeYear == date('Y')))
					echo '</i>';
				else
					echo '</a>';
				echo '&nbsp;';
			   }
			?>
			</td>
		</tr>
		</table>

		<p align="middle"><img align="middle" alt="Gentoo GLSA Release Statistics" src="frame-stats.graph.php<? if($GetYear != '') { echo '?year='.$GetYear; } if($noPooled) { echo '&noPooled'; } ?>" usemap="GraphMap" border="0"></p><? generateKonqBreak(); generateKonqBreak(); ?></dd></dl>
		</td></tr>
	</table>

	<br>
	<? bodyHeader_invoke(); initEnd(); ?>
<?
   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
