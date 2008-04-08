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

require_once './includes/io.mailer';
require_once './includes/common.spell';
require_once './includes/ui.body';
require_once './includes/ui.init';
require_once './includes/xml.glsaparser';

if($HTTP_GET_VARS['type'] == 'text')
{
	$plainOutput = true;
	header('Content-type: text/plain');
} else if($HTTP_GET_VARS['type'] == 'xml')
{
	$plainXML = true;
	header('Content-type: text/plain');
} else if($HTTP_GET_VARS['type'] == 'spell')
{
	$spellMode = true;
	$speller = new Speller();
	if($HTTP_GET_VARS['addSpell'] != '')
		$speller->AddLocal($HTTP_GET_VARS['addSpell']);
}

if(!$plainOutput && !$plainXML)
{
	echo '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">';
	initBegin('GLSA Viewer - '.$HTTP_GET_VARS['id']);

	if(!isset($HTTP_GET_VARS['reviewsOnly']))
	{
	bodyFooter_invoke();

	if($HTTP_GET_VARS['action'] == 'review')
	{
		$reviewChangeDetected = true;
		$reviewingGLSA = true;
		if($HTTP_POST_VARS['reviewType'] == '+')
			$reviewApproval = 'reviewApproval';
		else if($HTTP_POST_VARS['reviewType'] == '-')
			$reviewApproval = 'reviewRejection';
		else if($HTTP_POST_VARS['reviewType'] == 'C')
			$reviewApproval = 'reviewComment';
		else
			$reviewChangeDetected = false;

		$reviewComment = htmlspecialchars(stripslashes($HTTP_POST_VARS['reviewComment']));
		if(trim($reviewComment) == '')
			$reviewChangeDetected = false;
	} else if ($HTTP_GET_VARS['action'] == 'reviewClear')
	{
		$reviewingGLSA = true;
		$reviewClearingGLSA = true;
	} else if ($HTTP_GET_VARS['action'] == 'toggleReady')
	{
		$reviewingGLSA = true;
		$toggleReady = true;
	}
?>
	<table width='100%' border='0' cellspacing='0' cellpadding='4' class='body_rootTable'>
		<tr><td><font size='+1'><b><i>Gentoo Security GLSA Viewer</i></b></font><hr></td></tr><tr><td><? if(substr_count($_SERVER['HTTP_USER_AGENT'], 'Gecko') != 0) echo '<img src="images/icons/glsa.', generateImageExt(true), '" align="right" style="padding-bottom: 6px; padding-left: 6px;" alt="Welcome image">'; ?><div><dl><dt></dt><dd>
		<? 
		   generateKonqBreak('');
}}
		   if($HTTP_GET_VARS['id'] != '')
			$ID = $HTTP_GET_VARS['id'];
		   if($HTTP_GET_VARS['moveTo'] != '')
			$IDNew = $HTTP_GET_VARS['moveTo'];
		   if($IDNew)
		   {
		   	if(($IDPassed = fileGrepper_moveGLSA($ID, $IDNew)) != '<error>')
				$ID = $IDPassed;
			else
				generateWarning('Move failed!');
		   }
		   if(preg_match('/^[A-F0-9]{32}$/i', $ID)){ $valid = true; $pool = true; }
                   else if(sscanf($ID, '%04d%02d-%d', $ID1, $ID2, $ID3) == 3){ $valid = true; }

		   if($ID == ''){ $valid = false; echo 'No GLSA ID has been specified.'; }
		   else if ( $valid == false ) { echo 'Invalid GLSA ID [` ', $ID, ' `] specified!'; }
		   if(($plainOutput || $plainXML) && $valid == false) die();
		   if( $valid )
		   {
			$output = fileGrepper_getGLSAText( $pool ? NULL: $ID1, $pool ? NULL: $ID2, $pool ? NULL: $ID3, $pool ? $ID : NULL);
			if($output != '<nodata>')
			{
				$Parser = new GLSAParser();
				$Parser->GLSAparse($output);

				$GLSASubmitter =& $Parser->searchMetadata($Parser->GLSAMetadata, 0, 'submitter');
				if($reviewingGLSA)
				{
					// Check if we have a review block...
					if(!is_array($GLSAReviews =& $Parser->searchMetadata($Parser->GLSAMetadata, 0, 'reviews')) && !$reviewClearingGLSA && !$toggleReady && $reviewChangeDetected)
					{
						$Parser->GLSAMetadata[] = array('data' => array(
											0 => array(
												'data' => array(
													0 => array(
														'data' => array(),
														'revision' => 1,
														'tag' => $reviewApproval,
														'cdata' => $reviewComment,
														'timestamp' => genMetadataTimestamp()
													)
												),
												'tag' => 'reviewSet',
												'author' => authGetStatus(true),
											)
										), 'tag' => 'reviews');
					} else if (!$reviewClearingGLSA && !$toggleReady && $reviewChangeDetected)
					{
						// Now find us a reviewSet
						if(!is_array($GLSAReviewSet =& $Parser->searchMetadata($GLSAReviews['data'], 0, 'reviewSet', authGetStatus(true))))
						{
							$GLSAReviews['data'][] = array('data' => array(
													0 => array(
														'data' => array(),
														'revision' => 1,
														'tag' => $reviewApproval,
														'cdata' => $reviewComment,
														'timestamp' => genMetadataTimestamp()
													)
											),
											'tag' => 'reviewSet',
											'author' => authGetStatus(true)
										);
						} else {
							$GLSAReviewLastEntry = end($GLSAReviewSet['data']);
							$GLSAReviewSet['data'][] = array('data' => array(),
											 'revision' => $GLSAReviewLastEntry['revision']+1,
											 'tag' => $reviewApproval,
											 'cdata' => $reviewComment,
											 'timestamp' => genMetadataTimestamp());
						}
					} else if($reviewClearingGLSA)
					{
						// Clearing reviews

						// We have to use a classic $i iteration here since foreach doesn't return
						// pointers...

						for ($i = 0; is_array($GLSAReviews['data'][$i]); $i++)
						{
							if(is_array($GLSAReviews['data'][$i]['data']) &&
							   count($GLSAReviews['data'][$i]['data']) > 0)
							{
								for($ii = 0; is_array($GLSAReviews['data'][$i]['data'][$ii]); $ii++)
								{
									if($GLSAReviews['data'][$i]['data'][$ii]['tag'] == 'reviewApproval')
										$GLSAReviews['data'][$i]['data'][$ii]['tag'] = 'reviewComment';
								}
							}	
						}
					} else if($toggleReady)
					{
						if(!is_array($GLSAToggleFlag =& $Parser->searchMetadata($Parser->GLSAMetadata, 0, 'bugReady')))
						{
							$Parser->GLSAMetadata[] = array('data' => '', 'parent' => '', 'tag' => 'bugReady', 'cdata' => authGetStatus(), 'timestamp' => genMetadataTimestamp());
						} else
						{
							$GLSAToggleFlag = NULL;
							if($GLSAToggleIndex = array_search(NULL, $Parser->GLSAMetadata, true))
								unset($Parser->GLSAMetadata[$GLSAToggleIndex]);
						}
					}

					// See if we're flagging any reviewSets
					$reviewChangeMade = false;
					foreach ($HTTP_POST_VARS as $Var => $Data)
					{
						if($Data == 'on' && substr($Var, 0, 24) == 'reviewCommentFlagToggle:')
						{
							$tmpArray = explode(':', $Var);
							if($tmpArray[1] != '' && $tmpArray[2] != '' && is_array($GLSAReviewSet =& $Parser->searchMetadata($GLSAReviews['data'], 0, 'reviewSet', $tmpArray[1])))
							{
								if(is_array($GLSAReviewComment =& $Parser->searchMetadata($GLSAReviewSet['data'], 0, NULL, NULL, $tmpArray[2])))
								{
									$reviewChangeMade = true;
									if($GLSAReviewComment['flag'] != '')
										$GLSAReviewComment['flag'] = '';
									else
										$GLSAReviewComment['flag'] = authGetStatus(true).': '.genMetadataTimestamp();
								}
							}
						}
					}

					// Commit
					if($reviewChangeDetected || $reviewChangeMade || $toggleReady || $reviewClearingGLSA)
					{
						if(fileGrepper_getGLSAText($pool ? NULL: $ID1, $pool ? NULL: $ID2, $pool ? NULL: $ID3, $pool ? $ID : NULL, false, $Parser->GLSAToXML(false)))
							generateInfo('Updated GLSA successfully committed! [[ <a href="frame-view.php?id='.$ID.'">Refresh</a> ]]');
						else
							generateWarning('Could not commit updated GLSA!');
					}
				}
				if($plainOutput)
				{
					if(isset($HTTP_GET_VARS['errata']))
						$updateMode = 2;
					else if(isset($HTTP_GET_VARS['update']))
						$updateMode = 1;
					$GLSAOutput = $Parser->GLSAToText(false, $updateMode);
					echo $GLSAOutput;
				}
				else if($plainXML)
				{
					echo $Parser->GLSAToXML(false);
				}

				if($plainOutput || $plainXML)
					die();

				if(!isset($HTTP_GET_VARS['reviewsOnly']))
				{{
				echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">';
				echo '<tr><td width="160" align="right" valign="top"><b>GLSA ID:</b></td><td>', $Parser->GLSAID;
				if($Parser->GLSAID != $ID && !$IDNew)
					echo '<b> &lt;&lt; Mismatch!</b>';
				echo '</td></tr>';
				if($Parser->GLSARevision)
					echo '<tr><td width="160" align="right" valign="top"><b>GLSA Revision:</b></td><td>', $Parser->GLSARevision, '</td></tr>';
				if($Parser->GLSADate)
					echo '<tr><td width="160" align="right" valign="top"><b>GLSA Release Date:</b></td><td>', $Parser->GLSADate, '</td></tr>';
				echo '</table><br><table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">';
				echo '<tr><td width="160" align="right" valign="top"><b>Title:</b></td><td>'.__spell__($Parser->GLSAShortSummary, $spellMode, &$speller).'</td></tr>';
				if($Parser->GLSAAccess)
					echo '<tr><td width="160" align="right" valign="top"><b>Access:</b></td><td>'.ucfirst($Parser->GLSAAccess).'</td></tr>';
				echo '<tr><td width="160" align="right" valign="top"><b>Product:</b></td><td>'.$Parser->GLSAProduct.'</td></tr>';
				if($Parser->GLSASeverity)
					echo '<tr><td width="160" align="right" valign="top"><b>Severity:</b></td><td>'.ucfirst($Parser->GLSASeverity).'</td></tr>';
				echo '<tr><td width="160" align="right" valign="top"><b>Synopsis:</b></td><td>';
				if(strlen($Parser->GLSASynopsis) > 160)
					echo '<img src="images/icons/warning.', generateImageExt(true), '" align="top" style="float: right; padding-left: 6px;" alt="" title="Longer than 160 characters!">';
				echo padHTML($Parser->GLSASynopsis, $spellMode, &$speller).'</td></tr>';
				echo '</table><br>';
				if(count($Parser->GLSABugs) > 0)
				{
					echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light"><tr><td width="160" align="right" valign="top"><b>Related bugs:</b></td><td>';
					foreach ($Parser->GLSABugs as $Bug)
					{
						echo '<a href="https://bugs.gentoo.org/show_bug.cgi?id=', $Bug, '">#', $Bug, '</a>&nbsp;';
					}
					echo '</td></tr></table><br>';
				}
				if(count($Parser->GLSAPackages) > 0)
				{
					echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">';

					$i = 0;
					echo '<tr><td width="160" align="right" valign="top"><b>Unaffected packages:</b></td><td>';
					foreach ($Parser->GLSAPackages as $Package)
					{
						foreach ($Package['unaffected'] as $VersionArray)
						{
							foreach ($VersionArray as $VXP => $Version)
							{
								$PackageNames = explode('/', $Package['name']);
								if($i != 0) echo '<br>'; $i++;
								echo '<a href="http://packages.gentoo.org/package/', $PackageNames[0], '/', $PackageNames[1], '">', $Package['name'], '</a> ', VXPToText($VXP), ' ', $Version, ' on ', str_replace('*', 'all architectures', $Package['arch']);

								if($Package['auto'] == 'no') echo ' - <i>remerge required!</i>';
							}
						}
					}
					$i = 0;
					echo '<tr><td width="160" align="right" valign="top"><b>Vulnerable packages:</b></td><td>';
					foreach ($Parser->GLSAPackages as $Package)
					{
						foreach ($Package['vulnerable'] as $VersionArray)
						{
							foreach ($VersionArray as $VXP => $Version)
							{
								$PackageNames = explode('/', $Package['name']);

								if($i != 0) echo '<br>'; $i++;
								echo '<a href="http://packages.gentoo.org/package/', $PackageNames[0], '/', $PackageNames[1], '">', $Package['name'], '</a> ', VXPToText($VXP), ' ', $Version, ' on ', str_replace('*', 'all architectures', $Package['arch']);
							}
						}
					}
					echo '</td></tr></table><br>';
				}
				echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">';
				if($Parser->GLSABackground != '')
					echo '<tr><td width="160" align="right" valign="top"><b>Background:</b></td><td>', stripParagraphTags(padHTML($Parser->GLSABackground, $spellMode, &$speller)), '</td></tr>';
				echo '<tr><td width="160" align="right" valign="top"><b>Description:</b></td><td>', stripParagraphTags(padHTML($Parser->GLSADescription, $spellMode, &$speller)), '</td></tr>';
				echo '<tr><td width="160" align="right" valign="top"><b>Impact:</b></td><td>', stripParagraphTags(padHTML($Parser->GLSAImpact, $spellMode, &$speller)), '</td></tr>';
				echo '</table><br><table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">';
				echo '<tr><td width="160" align="right" valign="top"><b>Workaround:</b></td><td>', stripParagraphTags(padHTML($Parser->GLSAWorkaround, $spellMode, &$speller)), '</td></tr>';
				echo '<tr><td width="160" align="right" valign="top"><b>Resolution:</b></td><td>', stripParagraphTags(padHTML($Parser->GLSAResolution, $spellMode, &$speller)), '</td></tr>';
				echo '</table><br>';
				if(count($Parser->GLSAReferences) > 0)
				{
					echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light"><tr><td width="160" align="right" valign="top"><b>References:</b></td><td>';
					if(substr_count($_SERVER['HTTP_USER_AGENT'], 'Konqueror/') == 0)
						echo '<ul>';
					else
						echo '<dl><dt></dt><dd>';

					foreach ($Parser->GLSAReferences as $URI => $Text)
					{
						echo '<li><a href="', $URI, '">', $Text, '</a></li>';
					}

					if(substr_count($_SERVER['HTTP_USER_AGENT'], 'Konqueror/') == 0)
						{ if(substr_count($_SERVER['HTTP_USER_AGENT'], 'MSIE 6') == 0) echo '</ul>'; }
					else
						{ echo '</dd></dl>'; }
					echo '</td></tr></table><br>';
				}

				if($Parser->GLSAMetadata != array())
				{
					echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light"><tr><td width="160" align="right" valign="top"><b>Metadata:</b></td><td>';
					function __iterateMetadata__(&$MetadataSet, $iterationLevel = 0)
					{
						foreach($MetadataSet as $GLSAMetadataItem)
						{
							// Reviews are handled elsewhere...
							if($iterationLevel == 0 && $GLSAMetadataItem['tag'] == 'reviews')
								continue;

							echo '<table width="100%" border="0" cellspacing="0" cellpadding="0"><tr>';
							if($GLSAMetadataItem['revision'] != '')
								echo '<td valign="top" width="1%"><b><u>R:</u> </b>', $GLSAMetadataItem['revision'], ';&nbsp;</td>';
							else
								echo '<td width="0%"></td>';
							echo '<td valign="top" width="1%"><b>';
							if($GLSAMetadataItem['author'])
								echo $GLSAMetadataItem['author'], '::';
							echo '<i>', ucfirst($GLSAMetadataItem['tag']), '</i></b>:&nbsp;</td><td>';
							if($GLSAMetadataItem['cdata'])
								echo ltrim($GLSAMetadataItem['cdata']);
							if(is_array($GLSAMetadataItem['data']) && count($GLSAMetadataItem['data']) > 0)
								__iterateMetadata__(&$GLSAMetadataItem['data'], $iterationLevel+1);
							echo '</td>';
							if($GLSAMetadataItem['timestamp'])
								echo '<td align="right">(', $GLSAMetadataItem['timestamp'], ')</td>';
							echo '</tr></table>';
						}
					}
					__iterateMetadata__(&$Parser->GLSAMetadata);
					echo '</td></tr></table><br>';
				}

				}}
?>
				<form action="frame-view.php?id=<? echo $ID; ?>&action=review" method="post">
				<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">				<tr><td width="160" align="right" valign="top"><? if(isset($HTTP_GET_VARS['reviewsOnly'])) { echo '<a style="float: left;" href="#" onclick="javascript: parent.document.body.rows = \'100%, *\';">Hide Pane</a>'; } ?><b>Reviews:</b></td><td valign="top">
<?
				// Check if we have a review block...
				if(!is_array($GLSAReviews =& $Parser->searchMetadata($Parser->GLSAMetadata, 0, 'reviews')))
					echo '<i>No reviews available!</i>';
				else
				{
					echo '<div style="text-align: right;"><i>';
					if(isset($HTTP_GET_VARS['reviewsOnly']))
						$append = '&amp;reviewsOnly';
					if(isset($HTTP_GET_VARS['hide_flagged_reviews']))
						echo '<a href="frame-view.php?id=', $ID, $append, '">Show flagged reviews</a>';
					else
						echo '<a href="frame-view.php?id=', $ID, $append, '&amp;hide_flagged_reviews">Hide flagged reviews</a>';
					echo '</i></div>';

					echo '<table width="100%" border="0" cellspacing="0" cellpadding="1">';
					$GLSALReviewCounter = 0;
					foreach($GLSAReviews['data'] as $GLSAMetadataItem)
					{
						echo '<tr><td></td><td valign="top" align="right"><b>';
						if($GLSAMetadataItem['author'])
							echo $GLSAMetadataItem['author'];
						echo '</b>:</td><td valign="top">&nbsp;</td><td width="100%">';
						$GLSACRevision = -1;
						$GLSALReviewBuffer = false;
						if(is_array($GLSAMetadataItem['data']) && count($GLSAMetadataItem['data']) > 0)
						{
							$i = 0;
							echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">';
							foreach($GLSAMetadataItem['data'] as $GLSAReview)
							{
								// Check if our tag is a supported type and filter out tags if needed if flagged
								if(($GLSAReview['tag'] == 'reviewApproval' || $GLSAReview['tag'] == 'reviewRejection' || $GLSAReview['tag'] == 'reviewComment') && !(isset($HTTP_GET_VARS['hide_flagged_reviews']) && $GLSAReview['flag'] != ''))
								{
									echo '<tr><td valign="top" align="right" width="10"><acronym title="', ($GLSAReview['timestamp'] ? $GLSAReview['timestamp'] : 'No timestamp available!'), '">', padNumber($GLSAReview['revision']), '</acronym></td><td valign="top" width="1"><b>';
									if($GLSAReview['tag'] == 'reviewApproval')
									{
										if($GLSACRevision < $GLSAReview['revision'])
											$GLSALReviewBuffer = true;
										echo 'Approval:';
									}
									else if($GLSAReview['tag'] == 'reviewRejection')
									{
										if($GLSACRevision < $GLSAReview['revision'])
											$GLSALReviewBuffer = false;
										echo '<i>Rejection</i>:';
									}
									else if($GLSAReview['tag'] == 'reviewComment')
										echo 'Comment:';
									if($GLSACRevision < $GLSAReview['revision'])
										$GLSACRevision = $GLSAReview['revision'];

									/* You don't have to understand this ... it just happens to work; plasmaroo */
									echo '</b></td><td>', preg_replace(array('/(s\/[^\/]+?\/[^\/]*?\/[^\/.]*?) (s\/[^\/]+?\/[^\/]*?\/[^\/.]*?)/', '/(s\/[^\/]+?\/[^\/]*?\/[^\/.]*?) (s\/[^\/]+?\/[^\/]*?\/[^\/.]*?)/', '/s\/(.+?)[\\\]\/(.*?)\//', '/(^|[ .,;])(s\/[^\/]+?\/[^\/]*?\/)(\w+?)([ .,;]|$)/', '/(^|[ .,;])s\/(.+?)\/(.*?)\//', '/&backslash;/'), array('\1 <b>::</b> \2', '\1 <b>::</b> \2', 's/\1&backslash;\2/', '\1\2<i>\3</i>\4\5', '\1<span class="highlightComment"><b>s</b>/</span><span class="highlightAddedLine">\2</span><span class="highlightComment">/</span><span class="highlightRemovedLine">\3</span><span class="highlightComment">/</span>', '/'), trim($GLSAReview['cdata']));

									// echo '<span class="datestamp">', preg_replace(array('/ \+.+$/', '/^\w+, /'), array('', ''), $GLSAReview['timestamp']), '</span>', 
									echo '</td><td width="45" align="right" valign="top">';
									if($GLSAReview['flag'] == '')
										echo '<img src="images/icons/flag.'.generateImageExt(true).'" align="top">';
									else
										echo '<img src="images/icons/flag_green.'.generateImageExt(true).'" title="', $GLSAReview['flag'], '" align="top">';
									if(!isset($HTTP_GET_VARS['reviewsOnly']))
										echo '&nbsp;<input type="checkbox" name="reviewCommentFlagToggle:', $GLSAMetadataItem['author'], ':', $GLSAReview['revision'], '">';
									echo '</td></tr>';

									$i++;
								}
							}
							if($i == 0)
								echo 'No reviews to show.';

							echo '</table>';
							$GLSALReviewCounter += $GLSALReviewBuffer;
						}
					}
					echo '</table>';
				}
?>
				</td></tr>
<?				if($pool && !isset($HTTP_GET_VARS['reviewsOnly']))
				{?>
				<tr><td width="160" align="right" valign="top"><b>Add Review:</b></td><td>
					<table width="100%" border="0" cellspacing="0" cellpadding="1"><tr><td>
					<textarea class="grayinput_fullWidth" name="reviewComment"></textarea></td><td width="205"><table width="100%" cellspacing="0" cellpadding="0"><tr><td align="center" width="100%">
<?				if(trim($GLSASubmitter['cdata']) != authGetStatus(true))
				{ ?>
					<input type="radio" name="reviewType" value="+"><font color="#336633"><b>+</b></font></input>
					<input type="radio" name="reviewType" value="-"><b><font color="#990033">-</font></b></input>
<?				} ?>
					<input type="radio" name="reviewType" value="C"><b><font color="#9900FF">&plusmn;</font></b></input>
				</td><td align="right"><button class="grayinput" type="submit"><b>Commit</b></button></td></tr></table></td></tr></table>
<?				}
				echo '</td></tr></table><br><input type="hidden" name="id" value="', $Parser->GLSAID, '"><input type="hidden" name="action" value="review"></form>';
/*				echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">';
				echo '<tr><td width="160" align="right" valign="top"><b>MD5:</b></td><td>', md5($output), '</td></tr>';
				echo '<tr><td width="160" align="right" valign="top"><b>SHA1:</b></td><td>'.sha1($output).'</td></tr>';
				echo '</table><br>';
*/

				if(!isset($HTTP_GET_VARS['reviewsOnly']))
				{
					echo '<table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light"><tr><td width="160" align="right" valign="top"><b>XML:</b></td><td>';
					if($pool)
						echo '<a href="pool/', $ID, '.xml">', $ID, '.xml</a>';
					else
						echo '<a href="data/', $ID1, '/', padNumber($ID2), '/', padNumber($ID3), '.xml">', $Parser->GLSAID, '.xml</a>';
					echo ' [ <a href="frame-fetch.php?id=', $ID, '">Fetch</a> ]';
					echo ' [ <a href="frame-view.php?id=', $ID, '&amp;type=xml">Show as text</a> ]';

					echo '</td></tr><tr><td width="160" align="right" valign="top"><b>Text:</b></td><td>';
					echo '<a href="frame-view.php?id=', $ID, '&amp;type=text">', $ID, '.txt</a>';
					echo ' [ <a href="frame-view.php?id=', $ID, '&amp;type=text&amp;update">Add update sections</a> ]';
					echo ' [ <a href="frame-view.php?id=', $ID, '&amp;type=text&amp;errata">Add errata sections</a> ]';
					echo '</td></tr><tr><td width="160" align="right" valign="top"><b>Spell:</b></td><td>';
					if(!$spellMode)
						echo '<a href="frame-view.php?id=', $ID, '&amp;type=spell">Show with spell-checking</a>';
					else
						echo '<a href="frame-view.php?id=', $ID, '">Show without spell-checking</a>';
					echo '</td></tr></table>';
				}

				if(authGetLevel() && !isset($HTTP_GET_VARS['reviewsOnly']))
				{?>
					<form action="frame-view.php" name="form" method="get">
					<input type="hidden" name="id" value="<? echo $ID; ?>">
					<br><table width="100%" border="0" cellspacing="0" cellpadding="3" class="body_rootTable_light">
					<tr><td width="160" align="right" valign="middle"><b>Actions:</b></td><td>
<?php					echo '<a target="_top" href="frame-edit.php?editGLSA=', $ID, '">Edit</a> ';
					echo ' <a target="_top" href="frame-new.php?editGLSA=', $ID, '">(NR)</a> ';
					echo '<font color="gray"><b>::</b></font> ';
					echo '<a href="frame-new.php?reGLSA=', $ID, '">Reuse</a> ';
					if($pool)
					{
						$GLSABReady = is_array($Parser->searchMetadata($Parser->GLSAMetadata, 0, 'bugReady'));

						echo '<font color="gray"><b>::</b></font> ';
						echo '<a href="frame-view.php?id='.$ID.'&action=toggleReady">Toggle ready flag</a> ';
						echo '<font color="gray"><b>::</b></font> ';

						if($GLSALReviewCounter > 0) // && trim($GLSASubmitter['cdata']) == authGetStatus(true))
						{
							echo '<a href="frame-view.php?id='.$ID.'&action=reviewClear">Downgrade approvals</a> ';
							echo '<font color="gray"><b>::</b></font> ';
						}

						if($GLSALReviewCounter == 0)
							echo '<i>There are no positive reviews; ', $GLSAVNeededReviews, ' more are needed to allow a move...</i>';
						else if($GLSALReviewCounter < $GLSAVNeededReviews)
						{
							echo '<i>', ($GLSAVNeededReviews-$GLSALReviewCounter), ' more review';
							if(($GLSAVNeededReviews-$GLSALReviewCounter) == 1)
								echo ' is';
							else
								echo 's are';
							echo ' needed to allow a move!</i>';
						}
						else if(!$GLSABReady)
						{
							echo '<i>This GLSA needs to be marked as bugReady to allow a move!</i>';
						}
						else
						{
							if(substr_count($_SERVER['HTTP_USER_AGENT'],'Konqueror/') != 0)
								echo '<a onclick="javascript:document.form.submit();" style="cursor:hand;">Move</a>';
							else
								echo '<a href="#ClickToMoveGLSA" onclick="document.form.submit();">Move</a>';
							echo ' [ To: <input class="grayinput" name="moveTo" type="text" size="10" value="AutoMove"> ]';
						}

					}
					echo '</td></tr></table></form>';
				}
				generateKonqBreak('');

			}
			else echo '<b>Error:</b> non-existent GLSA entered.';
			if($plainOutput) die();
		   }

	if(!isset($HTTP_GET_VARS['reviewsOnly']))
	{
		?>
		</dd></dl></div></td></tr>
	</table>
	<br>
<? } bodyHeader_invoke(); initEnd(); ?>
<?
   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
