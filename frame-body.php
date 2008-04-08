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

initBegin('Welcome');
bodyFooter_invoke();

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i>Welcome to Gentoo GLSAMaker</i></b></font><hr><img src="images/gentooLogo.<? generateImageExt(); ?>" align="right" style="padding-bottom: 6px; padding-left: 6px;" alt="Gentoo Logo"><div><dl><dt></dt><dd><? generateKonqBreak(); ?>			Security is a primary focus of Gentoo Linux and ensuring the confidentiality and security of our users' machines is of utmost importance to us.<br><br>The Gentoo Linux Security Response team is tasked with providing timely information about security vulnerabilities in Gentoo Linux, along with patches to secure those vulnerabilities. We work directly with vendors, end users and other OSS programs to ensure all security incidents are responded to quickly and professionally.<? generateKonqBreak();generateKonqBreak(''); ?>		</dd></dl></div></td></tr>
	</table>
	<br>
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

									if($GLSAMetadataItem['author'] == authGetStatus())
										$GLSAUReviewed = 1;

									if($GLSAReview['tag'] == 'reviewApproval')
									{
										if($GLSACRevision < $GLSAReview['revision'])
											$GLSALReviewBuffer = true;
									}
									else if($GLSAReview['tag'] == 'reviewRejection')
									{
										if($GLSACRevision < $GLSAReview['revision'])
											$GLSALReviewBuffer = false;
									}
									if($GLSACRevision < $GLSAReview['revision'])
										$GLSACRevision = $GLSAReview['revision'];
								}
							}
							if($GLSALReviewBuffer == true && $GLSAUReviewed > 0)
								$GLSAUReviewed = 2;
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
			echo '</td><td><b>', $GLSAMSubmitter, '</b>: ', $header, '.</td></tr></table>';
		   }

		?>
		</td></tr>
	</table>
	<br>
	<? bodyHeader_invoke(true); initEnd(); ?>
<?
   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
