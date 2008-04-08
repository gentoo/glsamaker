<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<?php

/***************************************************************************
 *                                                                         *
 *   Copyright (C) 2004 Tim Yamin < plasmaroo >                            *
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
require_once './includes/xml.glsaparser';

initBegin('Archive');
bodyFooter_invoke();

$rangeYears = array();

function shiftWeek($day)
{
	$day--;
	if($day < 0)
		return 6;
	return $day;
}

function stepDay($timeStamp, $direction = 1)
{
	$stampData = getdate($timeStamp);
	$day = &$stampData['mday'];
	$month = &$stampData['mon'];
	$year = &$stampData['year'];
	$day += $direction;
	if($day > date('t', $timeStamp))
	{
		$day = 1;
		$month++;
	}
	if($day < 1)
	{
		$month--;
		if($month < 0)
		{
			$month = 12;
			$year--;
		}
		$day = date('t', mktime(0, 0, 0, $month, 1, $year));
	}
	if($month > 12)
	{
		$month = 1;
		$year++;
	}
	if($month < 0)
	{
		$month = 12;
		$year--;
	}
	return mktime(0, 0, 0, $month, $day, $year);
}

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i>Gentoo GLSA Announcement Calendar</i></b></font></td><td align="right"><img src="images/icons/new.lg.<? generateImageExt(); ?>" align="middle">&nbsp;</td></tr><tr><td colspan="2"><hr></td></tr>
		<tr><td colspan="2"><table width="100%" border="0" cellspacing="2" cellpadding="2">
		<?
			$GLSAItems = fileGrepper_parseTree(true, true);
			foreach ($GLSAItems as $GLSAItem)
			{
				sscanf($GLSAItem[0], '%04d%02d-%d', $ID1, $ID2, $ID3);
				$output = fileGrepper_getGLSAText($ID1, $ID2, $ID3);

				if($output != '<nodata>')
				{
					$Parser = new GLSAParser();
					$Parser->GLSAparse($output, true);

					$GLSAs[strtotime($Parser->GLSADate)][] = $GLSAItem[0];
					$GLSAShortSummaries[$GLSAItem[0]] = $Parser->GLSAShortSummary;
					if(!isset($rangeYears[$ID1]))
						$rangeYears[$ID1] = array();
					if(!in_array($ID2, $rangeYears[$ID1]))
						$rangeYears[$ID1][] = $ID2;
				}
			}

			$HTTP_GET_VARS["GLSAMonth"] > 0 && $HTTP_GET_VARS["GLSAMonth"] <= 13 ? $month = $HTTP_GET_VARS["GLSAMonth"] : $month = date('m');
			isset($rangeYears[$HTTP_GET_VARS["GLSAYear"]]) ? $year = $HTTP_GET_VARS["GLSAYear"] : $year = date('Y');
			end($rangeYears[$year]);
			in_array($month, $rangeYears[$year]) ? false : $month = current($rangeYears[$year]);

			$monthStart = mktime(0, 0, 0, $month, 1, $year);

			$sDay = 2; // Set to '1' for StartOnSunday
			$tStamp = mktime(0, 0, 0, date('w', $monthStart) > 0 ? $month-1 : $month, date('w', $monthStart) > 0 ? date('t', mktime(0, 0, 0, $month-1, 1, $year))-date('w', $monthStart)+$sDay : 1, $year);
			$iStamp = $tStamp;

			echo '<tr bgcolor="#CCCCCC"><td colspan="9"><table width="100%"><tr><td><i><b>', date('F Y', $monthStart), '</b></i></td><td align="right">';
			foreach($rangeYears as $rangeYear => $rangeMonths)
			{
				if($rangeYear == $year)
					echo, $rangeYear, ' ';
				else
					echo '<a href="frame-archive.php?GLSAYear=', $rangeYear, '&GLSAMonth=', $month, '">', $rangeYear, '</a> ';
			}
			echo '</td></tr></table></td></tr>';
			for ($i = -1; $i < 5; $i++)
			{
				if($i == -1)
				{
					$nStamp = stepDay($monthStart, -1);
					echo '<tr bgcolor="#CCCCCC"><td rowspan="6">';
					if(@in_array(date('m', $nStamp), $rangeYears[date('Y', $nStamp)]))
						echo '<a href="frame-archive.php?GLSAYear=', date('Y', $nStamp), '&GLSAMonth=', date('m', $nStamp), '">&lt;&lt;</a>';
					echo '</td>';
				}
				else
					echo '<tr>';

				for ($ii = 0; $ii < 7; $ii++)
				{
					if($i == -1)
					{
						echo '<td align="center" width="14%">';
						echo '<font color="#222222"><b>', date('D', $iStamp), '</b></font>';
					}
					else
					{
						echo '<td width="14%" valign="top" style="border: 1px solid gray;"><table height="55px" width="100%" cellspacing="0" cellpadding="1"><tr><td valign="top"><font size="+1">';
						$stampData = getdate($iStamp);
						if($stampData['mon'] != $month)
							echo '<font color="#666666"><i>', date('d', $iStamp), '</i></font>';
						else
							echo date('d', $iStamp);
						echo '</font></td><td align="right" valign="top">';
						if(count($GLSAs[$iStamp]) > 0)
						{
							foreach($GLSAs[$iStamp] as $GLSAID)
							{
								echo '<a href="frame-view.php?id=', $GLSAID, '" title="', $GLSAShortSummaries[$GLSAID], '">', $GLSAID, '</a><br>';
							}
						}
						echo '</td></tr></table>';
					}
					$iStamp = stepDay($iStamp);
					echo '</td>';
				}
				if($i == -1)
				{
					$iStamp = $tStamp;
					$nStamp = stepDay(mktime(0, 0, 0, $month, date('t', $monthStart), $year));
					echo '<td rowspan="6">';
					if(@in_array(date('m', $nStamp), $rangeYears[date('Y', $nStamp)]))
						echo '<a href="frame-archive.php?GLSAYear=', date('Y', $nStamp), '&GLSAMonth=', date('m', $nStamp), '">&gt;&gt;</a>';
					echo '</td>';
				}
			}
?>
		</tr>
		<tr><td bgcolor="#CCCCCC" colspan="9" align="right"><i>
<?
			if(@count($rangeYears[$year]) > 0)
			{
				foreach($rangeYears[$year] as $rangeMonth)
				{
					if($rangeMonth == $month)
						echo date('F', mktime(0, 0, 0, $rangeMonth, 1, $year)), ' ';
					else
						echo '<a href="frame-archive.php?GLSAYear=', $year, '&GLSAMonth=', $rangeMonth, '">', date('F', mktime(0, 0, 0, $rangeMonth, 1, $year)), '</a> ';
				}

			}
?>
		</i></td></tr>
		</table></td></tr>
	</table>
	<br>
	<? bodyHeader_invoke(); initEnd(); ?>
<?
   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
