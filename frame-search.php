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

initBegin('Search');
bodyFooter_invoke();

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i>Gentoo GLSA Search</i></b></font></td><td align="right"><img src="images/icons/queue.lg.<? generateImageExt(); ?>" align="middle">&nbsp;</td></tr><tr><td colspan="2"><hr></td></tr>
		<tr><td colspan="2">
			<form action="frame-search.php" method="get">
			<table class="body_rootTable_light" border="0" cellpadding="4" cellspacing="0" width="100%"><tr><td align="right" width="160"><b><i>Title contains:</i></b></td><td><table cellspacing="0" width="100%"><tr><td><input value="<? echo $HTTP_GET_VARS['queryString']; ?>" name="queryString" class="grayinput_fullWidth" size="64" type="text"></td><td align="right" width="90"><button class="grayinput"><b>Search</b></button></td></tr></table></td></tr></table><br>
		<?
			if($HTTP_GET_VARS['queryString'] != '')
			{
				$GLSAItems = fileGrepper_parseTree(true, true);
				foreach ($GLSAItems as $GLSAItem)
				{
					sscanf($GLSAItem[0], '%04d%02d-%d', $ID1, $ID2, $ID3);
					$output = fileGrepper_getGLSAText($ID1, $ID2, $ID3);

					if($output != '<nodata>')
					{
						$Parser = new GLSAParser();
						$Parser->GLSAparse($output, true);

						if(strpos(strtolower($Parser->GLSAShortSummary), strtolower($HTTP_GET_VARS['queryString'])) !== false)
							$GLSAMatches[$Parser->GLSAID] = $Parser->GLSAShortSummary;
					}
				}

				echo '<table class="body_rootTable_light" border="0" cellpadding="4" cellspacing="0" width="100%"><tr><td>';
				if(!isset($GLSAMatches))
					echo 'No matches found; try another query...</td></tr></table>';
				else
				{
					echo count($GLSAMatches), ' matches found (', count($GLSAItems), ' searched) for query string "', $HTTP_GET_VARS['queryString'], '":</td></tr></table><br><table class="body_rootTable_light" border="0" cellpadding="4" cellspacing="0" width="100%">';
					foreach ($GLSAMatches as $GLSAID => $GLSATitle)
					{
						echo '<tr><td><a href="frame-view.php?id=', $GLSAID, '">', $GLSAID, '</a>: ', $GLSATitle, '</td></tr>';
					}	
				}
			}
?>
		</table>
		</td></tr>
	</table>
	<br>
	<? bodyHeader_invoke(); initEnd(); ?>
<?
   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
