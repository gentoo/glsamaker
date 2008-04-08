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
require_once './includes/xml.glsaparser';

initBegin('Repository');
bodyFooter_invoke();

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i>Pooled Gentoo GLSA Announcements</i></b></font></td><td align="right"><img src="images/icons/queue.lg.<? generateImageExt(); ?>" align="middle">&nbsp;</tr><tr><td colspan="2"><hr></td></tr>
		<?
		   $recentItems = fileGrepper_parsePool();
		   for ($i = 0; $i < count($recentItems); $i++) {
			$GLSABReady = false;
			$GLSAMSubmitter = '???';
			$GLSALReviewCounter = '-';
			$GLSATReviewCounter = 0;
			$GLSAUReviewed = 0;

			echo '<tr><td colspan="2"><table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr>';
			echo '<td width="250" align="center" class="monospace"><a href="frame-view.php?id=', $recentItems[$i][0], '">', $recentItems[$i][0], '</a></td>';
			echo '<td width="150">', date('Y-m-d H:i:s', $recentItems[$i][1]), '</td><td width="32">';

			$output = fileGrepper_getGLSAText(NULL, NULL, NULL, $recentItems[$i][0]);
			$Parser = new GLSAParser();

			if($output != '<nodata>')
			{
				$Parser->GLSAparse($output, true, true);
				$header = $Parser->GLSAShortSummary;

				// Set submitter
				if(is_array($GLSAMAuthor =& $Parser->searchMetadata($Parser->GLSAMetadata, 0, 'submitter')))
					$GLSAMSubmitter = trim($GLSAMAuthor['cdata']);

				// Check for reviews
				$GLSAFlagsPending = false;
				if(is_array($GLSAReviews =& $Parser->searchMetadata($Parser->GLSAMetadata, 0, 'reviews')))
				{
					$GLSALReviewCounter = 0;
					foreach($GLSAReviews['data'] as $GLSAMetadataItem)
					{
						$GLSACRevision = -1;
						$GLSALReviewBuffer = false;
						if(is_array($GLSAMetadataItem['data']) && count($GLSAMetadataItem['data']) > 0)
						{
							foreach($GLSAMetadataItem['data'] as $GLSAReview)
							{
								if($GLSAReview['tag'] == 'reviewApproval' || $GLSAReview['tag'] == 'reviewRejection' || $GLSAReview['tag'] == 'reviewComment'
								   && $GLSAMSubmitter != $GLSAMetadataItem['author'])
								{
									$GLSATReviewCounter++;

									if($GLSAReview['tag'] == 'reviewApproval')
									{
										if($GLSACRevision < $GLSAReview['revision'])
											$GLSALReviewBuffer = true;

										if($GLSAMetadataItem['author'] == authGetStatus())
											$GLSAUReviewed = 2;
									}
									else if($GLSAReview['tag'] == 'reviewRejection')
									{
										if($GLSACRevision < $GLSAReview['revision'])
											$GLSALReviewBuffer = false;
									}
									else if($GLSAMetadataItem['author'] == authGetStatus() && $GLSAUReviewed == 0)
										$GLSAUReviewed = 1;

									if($GLSACRevision < $GLSAReview['revision'])
										$GLSACRevision = $GLSAReview['revision'];
									if($GLSAReview['flag'] == '')
										$GLSAFlagsPending = true;
								}
							}
							$GLSALReviewCounter += $GLSALReviewBuffer;
						}
					}
				}

				// Check for a bugReady flag
				if(is_array($Parser->searchMetadata($Parser->GLSAMetadata, 0, 'bugReady')))
					$GLSABReady = true;			
			}
			else { $header = '<i>Not available!</i>'; }
			echo '<img align="left" src="images/icons/flag';
			if(preg_match('/Fight[ -]?Club/i', $header) || substr($header, 0, 9) == 'Request: ')
				echo '_star';
			else if($GLSALReviewCounter == '-' && $GLSATReviewCounter == 0)
			{
				$GLSATReviewCounter = 'No';
				echo '_disabled';
			}
			else if($GLSALReviewCounter >= $GLSAVNeededReviews)
				echo '_green'; 
			else if($GLSALReviewCounter > 0)
				echo '_yellow';
			echo '.';
			generateImageExt();
			echo '" title="', $GLSATReviewCounter, ' comment';
			if($GLSATReviewCounter != 1)
				echo 's';
			if($GLSALReviewCounter > 0)
				echo ' - ', $GLSALReviewCounter, ' review';
			if($GLSALReviewCounter > 1)
				echo 's';
			if($GLSABReady)
				echo ', marked as bug-ready';
			echo '..."';
			if($GLSABReady)
				echo ' style="background: #dddddd; border: 1px solid #aaaaaa;"';
			echo '></td><td width="32">';
			if($GLSAMSubmitter != authGetStatus() && substr($header, 0, 9) != 'Request: ')
			{
				echo '<img src="images/icons/';
				if($GLSAUReviewed == 0)
					echo 'cross';
				else if($GLSAUReviewed == 1)
					echo 'tick_p';
				else
					echo 'tick';
				echo '.';
				generateImageExt();
				echo '" title="';
				if($GLSAUReviewed == 0)
					echo 'Not reviewed';
				else if($GLSAUReviewed == 1)
					echo 'Reviewed as not positive';
				else
					echo 'Reviewed';
				echo ' by you...">';
			}
			echo '</td><td width="32">';
			if($GLSAFlagsPending)
			{
				echo '<img src="images/icons/warning.';
				generateImageExt();
				echo '" title="Not all comments reviewed - action may be required!">';
			}
			echo '</td><td><b>', $GLSAMSubmitter, '</b>: ', $header, '</td></tr></table>';
		   }

		?>
		</td></tr>
		<tr><td colspan="2">
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light">
			<tr><td valign="top"><b>Key</b>:</td>
			<td><img src="images/icons/flag_star.png" align="middle"> - GLSA Request; <img src="images/icons/flag_green.png" align="middle"> - GLSA approved but <b>not</b> necessarily bug ready!; <img src="images/icons/flag_yellow.png" align="middle"> - GLSA needs more approvals; <img src="images/icons/flag.png" align="middle"> - GLSA has no approvals; <span style="background: #dddddd; border: 1px solid #aaaaaa; height: 16px;">&nbsp;&nbsp;&nbsp;&nbsp;</span> - Bug ready marker; <img src="images/icons/tick.png" align="middle"> - GLSA approved by you; <img src="images/icons/tick_p.png" align="middle"> - GLSA reviewed by you but <b>not</b> approved; <img src="images/icons/cross.png" align="middle"> - GLSA not reviewed by you; <img src="images/icons/warning.png" align="middle"> - GLSA has comments which haven't been flagged so editing action <i>may</i> be required; if not please flag comments that are OK.
			</td></tr></table>
		</td></tr>
	</table>
	<br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i>Recent Gentoo GLSA Announcements</i></b></font></td><td align="right"><img src="images/icons/new.lg.<? generateImageExt(); ?>" align="middle">&nbsp;</td></tr><tr><td colspan="2"><hr></td></tr>
		<?
		   $recentItems = fileGrepper_parseTree(false, true);
		   for ($i = 0; $i < 15 && $i < count($recentItems); $i++) {

			sscanf($recentItems[$i][0], '%04d%02d-%d', $ID1, $ID2, $ID3);
			echo '<tr><td colspan="2" align="right"><table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr>';
			echo '<td width="140" align="center"><a href="frame-view.php?id=', $recentItems[$i][0]. '">GLSA ', $recentItems[$i][0], '</a></td>';
			echo '<td width="150">', date('Y-m-d H:i:s', $recentItems[$i][1]), '</td>';

			$output = fileGrepper_getGLSAText($ID1, $ID2, $ID3);
			$Parser = new GLSAParser();

			if($output != '<nodata>')
			{
				$Parser->GLSAparse($output, true);
				$header = $Parser->GLSAShortSummary;
			}
			else { $header = '<i>Not available!</i>'; }
			echo '<td>', $header, '</td></tr></table>';
		   }

		?>
		<br><i><? echo count($recentItems)-20; ?> out of <? echo count($recentItems); ?> GLSAs not shown...&nbsp;</i></td></tr>
	</table>
	<br>
	<? bodyHeader_invoke(); initEnd(); ?>
<?
   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
