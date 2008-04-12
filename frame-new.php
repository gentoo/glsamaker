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

require './includes/common.auth';
require_once './includes/common.diff';
require_once './includes/common.spell';
require_once './includes/io.mailer';
require_once './includes/ui.body';
require_once './includes/ui.init';
require_once './includes/ui.newitems';
require_once './includes/xml.glsaparser';

$GLSAProcessed = array();
$GLSAReferences = array();
$GLSAVersions = array();

if($HTTP_GET_VARS['editGLSA'] != '')
{
	$ID = $HTTP_GET_VARS['editGLSA'];
	$startEdit = true;
}
else if($HTTP_GET_VARS['reGLSA'] != '')
{
	$ID = $HTTP_GET_VARS['reGLSA'];
	$reEdit = true;
}
else if($HTTP_POST_VARS['GLSA_ID'] != '')
{
	$ID = $HTTP_POST_VARS['GLSA_ID'];
	$continueEdit = true;
}

if($ID)
{
	if(sscanf($ID, '%04d%02d-%d', $GID1, $GID2, $GID3) == 3){ $validEdit = true; }
	else if(preg_match('/^[A-F0-9]{32}$/i', $ID)){ $validEdit = true; $pool = true; }
}

$Parser = new GLSAParser();
if($validEdit)
{
	$GLSA = fileGrepper_getGLSAText($pool ? NULL: $GID1, $pool ? NULL: $GID2, $pool ? NULL: $GID3, $pool ? $ID : NULL);
	$Parser->GLSAparse($GLSA);

	if($startEdit || $reEdit)
	{
		$HTTP_POST_VARS['GLSA_Title'] = $Parser->GLSAShortSummary;
		$HTTP_POST_VARS['GLSA_Access'] = ucfirst($Parser->GLSAAccess);
		$HTTP_POST_VARS['GLSA_Priority'] = $Parser->GLSASeverity;
		$HTTP_POST_VARS['GLSA_Synopsis'] = $Parser->GLSASynopsis;
		$HTTP_POST_VARS['GLSA_Bugs'] = implode(' ', $Parser->GLSABugs);
		$HTTP_POST_VARS['GLSA_Product'] = $Parser->GLSAProduct;
		$HTTP_POST_VARS['GLSA_ProductType'] = $Parser->GLSAProductType;
		$GLSAVersions = $Parser->GLSAPackages;
		$HTTP_POST_VARS['GLSA_Background'] = reformatString($Parser->GLSABackground, 2, 0);
		$HTTP_POST_VARS['GLSA_Description'] = reformatString($Parser->GLSADescription, 2, 0);
		$HTTP_POST_VARS['GLSA_Impact'] = reformatString($Parser->GLSAImpact, 2, 0);
		$HTTP_POST_VARS['GLSA_Workaround'] = reformatString($Parser->GLSAWorkaround, 2, 0);
		$HTTP_POST_VARS['GLSA_Resolution'] = reformatString($Parser->GLSAResolution, 2, 0);
		foreach( $Parser->GLSAReferences as $GLSAReferenceURL => $GLSAReference)
		{
			$GLSAReferences[] = array($GLSAReference => $GLSAReferenceURL);
		}
	}
}

if($reEdit)
	$validEdit = false;

initBegin($validEdit ? 'Edit a GLSA' : 'File an announcement');
bodyFooter_invoke();

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i><? if($validEdit){ echo 'Edit a GLSA Announcement'; } else { echo 'File a new GLSA Announcement'; } ?></i></b></font></td><td align="right"><img src="images/icons/new.lg.<? generateImageExt(); ?>" align="middle">&nbsp;</td></tr><tr><td colspan="2"><hr></td></tr>
		<tr><td colspan="2"><table width="100%" border="0" cellspacing="0" cellpadding="4"><tr><td colspan="2">Our GLSA filing process is designed to improve QA speed and security performance. Please file all announcements in good, detailed English and try to be verbose where you can. If you have any queries, ask #gentoo-security. Thank you for your help in making a more secure Gentoo!<br><br></td></tr><? if(!$validEdit){ ?><tr><td valign="top"><b>Important: </b></td><td>Please check if your announcement is already in the pending queue or has already been released before filing any more announcements. Also note, that these announcements <b>must</b> be for a valid package in Portage.</td></tr><? } ?><tr><td valign="top"><b>Important: </b></td><td>For legal reasons, please do not copy and paste text from copyrighted sources without giving references; if you do make sure a reference is added as well as a reference pointer near the copyrighted text. Also make sure that the license on the copyrighted text allows copying.</td></tr></table><br></td></tr>
	</table>
	<br>
	<? if(!$validEdit)
	   {
		recentItems_invoke(true); ?>
	<br>
	<? }
	   if($HTTP_POST_VARS == array()) { echo generateInfo('Please complete all the fields which are marked in <i>italics</i>. To insert a new paragraph, use a double linebreak. To insert a preformatted code fragment, wrap your text in <span class="monospace">&lt;code&gt;</span> tags. Hover your mouse over a help icon for help with that particular field.<br><br>All other fields are optional, but recommended. <i>You may need to resize your browser window width to make this form functional.</i>'); } ?>
	<? 
		function array_combine_recursive(&$into, $source)
		{
			$MergeMap = array_keys($source);
			$MergeMap = array_flip($MergeMap);
			foreach( $MergeMap as $key => $value ){ $MergeMap[$key] = -1; }

			foreach( $into as $key => $value )
			{
				foreach( $source as $skey => $svalue )
				{
//					echo('<pre>!!! '); print_r($into); print_r($source); print_r($MergeMap); echo('!!!</pre>');
					if($value['arch'] == $svalue['arch'] && $value['name'] == $svalue['name'])
					{
						if(isset($value['unaffected']) && isset($svalue['unaffected']))
						{
							$into[$key]['unaffected'] = array_merge_recursive($value['unaffected'], $svalue['unaffected']);
						}
						elseif(isset($svalue['unaffected']))
						{
							$into[$key]['unaffected'] = $svalue['unaffected'];
						}
						if(isset($value['vulnerable']) && isset($svalue['vulnerable']))
						{
							$into[$key]['vulnerable'] = array_merge_recursive($value['vulnerable'], $svalue['vulnerable']);
						}
						elseif(isset($svalue['vulnerable']))
						{
							$into[$key]['vulnerable'] = $svalue['vulnerable'];
						}

						// This sets 'auto' to 'no' if unless both are 'yes'
						$value['auto'] = SBMod(SBMod($value['auto']) & SBMod($svalue['auto'])); 
						$MergeMap[$skey] = $key;
					}
				}
			}
			foreach( $MergeMap as $key => $value )
			{
				if($value == -1)
				{
					array_push($into, $source[$key]);
				}
			}
//			echo('<pre>!!! '); print_r($into); echo('!!!</pre>');
		}

		function array_uniqueArray($input)
		{
			$newArray = array();
			foreach($input as $search)
			{
				if(!in_array($search, $newArray))
					$newArray[] = $search;
			}
			return $newArray;
		}

		if(!$startEdit)
		{
			foreach($HTTP_POST_VARS as $key => $value)
			{
				$HTTP_POST_VARS[$key] = stripslashes($value);
			}
		}

		foreach($HTTP_POST_VARS as $key => $value)
		{
			if(sscanf($key, 'GLSA_UP_%d_%d_', $ID1, $ID2) == 2)
			{
				if($GLSAProcessed['UP'.$ID1.$ID2] != true)
				{
					if($HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_Name'] != '' && $HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_VXP'] != '' && $HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_Version'] != '' &&
					   $HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_Arch'] != '')
					{
						$GLSAVersions_Add = array();
						$GLSAVersions_Add[0]['arch'] = str_replace('all', '*', $HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_Arch']);
						$GLSAVersions_Add[0]['auto'] = $HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_Auto'];
						$GLSAVersions_Add[0]['name'] = $HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_Name'];
						$GLSAVersions_Add[0]['unaffected'] = array(0 => array($HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_VXP'] => $HTTP_POST_VARS['GLSA_UP_'.$ID1.'_'.$ID2.'_Version']));

						array_combine_recursive(&$GLSAVersions, $GLSAVersions_Add);
//						echo('<pre>!!!* '); print_r($GLSAVersions); echo('!!!</pre>');
					}
					$GLSAProcessed['UP'.$ID1.$ID2] = true;
				}
			}
			if(sscanf($key, 'GLSA_VP_%d_%d_', $ID1, $ID2) == 2)
			{
				if($GLSAProcessed['VP'.$ID1.$ID2] != true)
				{
					if($HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_Name'] != '' && $HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_VXP'] != '' && $HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_Version'] != '' &&
					   $HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_Arch'] != '')
					{
						$GLSAVersions_Add = array();
						$GLSAVersions_Add[0]['arch'] = str_replace('all', '*', $HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_Arch']);
						$GLSAVersions_Add[0]['auto'] = $HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_Auto'];
						$GLSAVersions_Add[0]['name'] = $HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_Name'];
						$GLSAVersions_Add[0]['vulnerable'] = array(0 => array($HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_VXP'] => $HTTP_POST_VARS['GLSA_VP_'.$ID1.'_'.$ID2.'_Version']));

						array_combine_recursive($GLSAVersions, $GLSAVersions_Add);
					}
					$GLSAProcessed['VP'.$ID1.$ID2] = true;
				}
			}
			if(sscanf($key, 'GLSA_RF_%d_', $ID1) == 1)
			{
				if($GLSAProcessed['RF'.$ID1] != true)
				{
					if($HTTP_POST_VARS['GLSA_RF_'.$ID1.'_Title'] != '' && $HTTP_POST_VARS['GLSA_RF_'.$ID1.'_URL'] != '')
					{
						array_push($GLSAReferences, array($HTTP_POST_VARS['GLSA_RF_'.$ID1.'_Title'] => $HTTP_POST_VARS['GLSA_RF_'.$ID1.'_URL']));
					}
					$GLSAProcessed['RF'.$ID1] = true;
				}
			}
		}

		if(substr_count($HTTP_POST_VARS['GLSA_UP_Name'], '/') == 1 && $HTTP_POST_VARS['GLSA_UP_VXP'] != '' && $HTTP_POST_VARS['GLSA_UP_Version'] != '' && $HTTP_POST_VARS['GLSA_UP_Auto'] != '')
		{
			if($HTTP_POST_VARS['GLSA_UP_Arch'] == '')
			{
				$HTTP_POST_VARS['GLSA_UP_Arch'] = '*';
				echo generateWarning('The entered "unaffected" did not contain an architecture, assuming "*"');
			}
			$GLSAVersions_Add = array();
			$GLSAVersions_Add[0]['arch'] = str_replace('all', '*', strtolower($HTTP_POST_VARS['GLSA_UP_Arch']));
			$GLSAVersions_Add[0]['auto'] = strtolower($HTTP_POST_VARS['GLSA_UP_Auto']);
			$GLSAVersions_Add[0]['name'] = strtolower($HTTP_POST_VARS['GLSA_UP_Name']);
			$GLSAVersions_Add[0]['unaffected'] = array(0 => array(strtolower($HTTP_POST_VARS['GLSA_UP_VXP']) => strtolower($HTTP_POST_VARS['GLSA_UP_Version'])));

			array_combine_recursive(&$GLSAVersions, $GLSAVersions_Add);
//			echo('<pre>!!!* '); print_r($GLSAVersions); echo('!!!</pre>');
		}
		else if(($HTTP_POST_VARS['GLSA_UP_Name'] != '' && substr_count($HTTP_POST_VARS['GLSA_UP_Name'], '/') != 1) || $HTTP_POST_VARS['GLSA_UP_Version'] != '')
		{
			if(substr_count($HTTP_POST_VARS['GLSA_UP_Name'], '/') != 1)
				echo generateWarning('The entered "unaffected" version expression was ignored - a valid package name such as "net-www/mozilla" is required!');
			else if($HTTP_POST_VARS['GLSA_UP_Version'] == '')
				echo generateWarning('The entered "unaffected" version expression was ignored - a package version is required!');
		}

		if(substr_count($HTTP_POST_VARS['GLSA_VP_Name'], '/') == 1 && $HTTP_POST_VARS['GLSA_VP_VXP'] != '' && $HTTP_POST_VARS['GLSA_VP_Version'] != '' && $HTTP_POST_VARS['GLSA_VP_Auto'] != '')
		{
			if($HTTP_POST_VARS['GLSA_VP_Arch'] == '')
			{
				$HTTP_POST_VARS['GLSA_VP_Arch'] = '*';
				echo generateWarning('The entered "vulnerable" did not contain an architecture, assuming "*"');
			}
			$GLSAVersions_Add = array();
			$GLSAVersions_Add[0]['arch'] = str_replace('all', '*', strtolower($HTTP_POST_VARS['GLSA_VP_Arch']));
			$GLSAVersions_Add[0]['auto'] = strtolower($HTTP_POST_VARS['GLSA_VP_Auto']);
			$GLSAVersions_Add[0]['name'] = strtolower($HTTP_POST_VARS['GLSA_VP_Name']);
			$GLSAVersions_Add[0]['vulnerable'] = array(0 => array(strtolower($HTTP_POST_VARS['GLSA_VP_VXP']) => strtolower($HTTP_POST_VARS['GLSA_VP_Version'])));

			array_combine_recursive(&$GLSAVersions, $GLSAVersions_Add);
		}
		else if(($HTTP_POST_VARS['GLSA_VP_Name'] != '' && substr_count($HTTP_POST_VARS['GLSA_VP_Name'], '/') != 1) || $HTTP_POST_VARS['GLSA_VP_Version'] != '')
		{
			if(substr_count($HTTP_POST_VARS['GLSA_VP_Name'], '/') != 1)
				echo generateWarning('The entered "vulnerable" version expression was ignored - a valid package name such as "net-www/mozilla" is required!');
			else if($HTTP_POST_VARS['GLSA_VP_Version'] == '')
				echo generateWarning('The entered "vulnerable" version expression was ignored - a package version is required!');
		}

		if($HTTP_POST_VARS['GLSA_RF_Title'] != '' && $HTTP_POST_VARS['GLSA_RF_URL'] != '')
		{
			array_push($GLSAReferences, array($HTTP_POST_VARS['GLSA_RF_Title'] => $HTTP_POST_VARS['GLSA_RF_URL']));
		}
		else if($HTTP_POST_VARS['GLSA_RF_Title'] != '' || $HTTP_POST_VARS['GLSA_RF_URL'] != '')
		{
			if($HTTP_POST_VARS['GLSA_RF_Title'] == '')
				echo generateWarning('The entered reference was ignored - a reference title is required!');
			else if($HTTP_POST_VARS['GLSA_RF_URL'] == '')
			{
				if(strpos($HTTP_POST_VARS['GLSA_RF_Title'], 'CVE-') === 0)
					array_push($GLSAReferences, array($HTTP_POST_VARS['GLSA_RF_Title'] => 'http://cve.mitre.org/cgi-bin/cvename.cgi?name='.$HTTP_POST_VARS['GLSA_RF_Title']));
				else if(strpos($HTTP_POST_VARS['GLSA_RF_Title'], 'GLSA ') === 0)
					array_push($GLSAReferences, array($HTTP_POST_VARS['GLSA_RF_Title'] => 'http://www.gentoo.org/security/en/glsa/glsa-'
					. substr($HTTP_POST_VARS['GLSA_RF_Title'], 5)
					. '.xml'));
				else
					echo generateWarning('The entered reference was ignored - a reference URL is required!');
			}
		}

		if ($HTTP_POST_VARS['SortReferences']) {
			$names = array();
			foreach ($GLSAReferences as $index => $array) {
				$name = array_keys($array);
				$names[$index] = $name[0];
			}
			array_multisort($names, SORT_ASC, $GLSAReferences);
		}

		// echo('<pre>'); print_r($GLSAVersions); echo('</pre>');

		/*! Remove duplicate entries from the versions */
		foreach($GLSAVersions as $key => $value)
		{
			if(isset($value['unaffected']))
				$GLSAVersions[$key]['unaffected'] = array_uniqueArray($GLSAVersions[$key]['unaffected']);
			if(isset($value['vulnerable']))
				$GLSAVersions[$key]['vulnerable'] = array_uniqueArray($value['vulnerable']);
		}

		/*! If we're submitting, check things, and continue if OK */
		$newLine = "\n";
		if($HTTP_POST_VARS['Submit'] == 'Boilerplate')
		{
			# Set Workaround if it's not already set
			if (trim($HTTP_POST_VARS['GLSA_Workaround']) != 'There is no known workaround at this time.') {
				if($HTTP_POST_VARS['GLSA_Workaround'])
					$HTTP_POST_VARS['GLSA_Workaround'] .= $newLine.$newLine;
				$HTTP_POST_VARS['GLSA_Workaround'] .= 'There is no known workaround at this time.';
			}

			if(count($GLSAVersions) > 0)
			{
				foreach($GLSAVersions as $GLSAVersion)
				{
					$tmp = explode('/', $GLSAVersion['name']);
					$product = $tmp[1];

					# Include the ebuild in product if it's not there yet
					if(!$HTTP_POST_VARS['GLSA_Product'])
						$HTTP_POST_VARS['GLSA_Product'] = $product;
					else if (strpos($HTTP_POST_VARS['GLSA_Product'], $product) === FALSE) {
						# If this product is not listed, list it
						$HTTP_POST_VARS['GLSA_Product'] .= " ".$product;
					}

					# Update resolution
					if(count($GLSAVersion['unaffected']) > 0 && count($GLSAVersion['vulnerable']) > 0)
					{
						# Give update advice
						foreach($GLSAVersion['unaffected'] as $FixedVersion) {
						
						$tmpV = current($FixedVersion);
		
						if($HTTP_POST_VARS['GLSA_Resolution'])
							$HTTP_POST_VARS['GLSA_Resolution'] .= $newLine.$newLine;
						$HTTP_POST_VARS['GLSA_Resolution'] .= 'All '.$product.' users should upgrade to the latest version:'.$newLine.$newLine.'<code>'.$newLine.'# emerge --sync'.$newLine.'# emerge --ask --oneshot --verbose ">='.$GLSAVersion['name'].'-'.$tmpV.'"</code>';

						}
					}
					else if (count($GLSAVersion['unaffected']) == 0 && count($GLSAVersion['vulnerable']) > 0)
					{
						# Give unmerge advice
						if($HTTP_POST_VARS['GLSA_Resolution'])
							$HTTP_POST_VARS['GLSA_Resolution'] .= $newLine.$newLine;
						$HTTP_POST_VARS['GLSA_Resolution'] .= 'We recommend that users unmerge '.$product.':'.$newLine.$newLine.'<code>'.$newLine.'# emerge --unmerge "'.$GLSAVersion['name'].'"</code>';
					}

				}

				# Go through description and see if it lists any GLSAs or CVEs
				if (preg_match_all("/(CVE-\d{4}-\d{4}|GLSA \d{6}-\d{2})/", $HTTP_POST_VARS['GLSA_Description'], $hits)) {
					# Stuff we already have in references
					$names = array();
					foreach ($GLSAReferences as $index => $array) {
						$name = array_keys($array);
						$names[$name[0]] = $name[0];
					}

					$hits = $hits[0];
					foreach($hits as $hit) {
						if (array_key_exists($hit, $names) === FALSE) {
							array_push($GLSAReferences, array($hit => ""));
						}
					}
				}
			} else
				echo generateWarning('Not all fields are completed - please make sure you have completed all the necessary fields!');				
		}
		else if($HTTP_POST_VARS['Submit'] == 'Preview' || $HTTP_POST_VARS['Submit'] == 'Confirm' || $HTTP_POST_VARS['Submit'] == 'Submit')
		{
			if($HTTP_POST_VARS['GLSA_Title'] != '' && $HTTP_POST_VARS['GLSA_Synopsis'] != '' && $HTTP_POST_VARS['GLSA_Priority'] != '' &&
			   $HTTP_POST_VARS['GLSA_Product'] != '' && $HTTP_POST_VARS['GLSA_ProductType'] != '' && $HTTP_POST_VARS['GLSA_Impact'] != '' &&
			   $HTTP_POST_VARS['GLSA_Description'] != '' && $HTTP_POST_VARS['GLSA_Workaround'] != '' && $HTTP_POST_VARS['GLSA_Resolution'] != '')
			{
				if($HTTP_POST_VARS['Submit'] == 'Confirm' || $HTTP_POST_VARS['Submit'] == 'Preview')
					echo '<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable"><tr><td>';

				$HTTP_POST_VARS['GLSA_ID'] ? $Parser->GLSAID = $HTTP_POST_VARS['GLSA_ID'] : $Parser->GLSAID = '!-- Insert ID here! --!';
				$Parser->GLSAShortSummary = $HTTP_POST_VARS['GLSA_Title'];
				$Parser->GLSASynopsis = $HTTP_POST_VARS['GLSA_Synopsis'];

				$Parser->GLSAProductType = $HTTP_POST_VARS['GLSA_ProductType'];
				$Parser->GLSAProduct = rtrim(htmlspecialchars($HTTP_POST_VARS['GLSA_Product']));

				if($Parser->GLSARevision == '')
					$Parser->GLSARevision = date('F d, Y').': 01';
				if($Parser->GLSADate == '')
					$Parser->GLSADate = date('F d, Y');

				$Parser->GLSABugs = array();
				$temp = explode(' ', $HTTP_POST_VARS['GLSA_Bugs']);
				$HTTP_POST_VARS['GLSA_Bugs'] = '';
				foreach( $temp as $bug ){ if(is_numeric($bug)) { $Parser->GLSABugs[] = $bug; $HTTP_POST_VARS['GLSA_Bugs'] .= $bug.' '; } }

				if($HTTP_POST_VARS['GLSA_Access'])
				{
					$Parser->GLSAAccess = rtrim(strtolower($HTTP_POST_VARS['GLSA_Access']));
				}

				$Parser->GLSAPackages = $GLSAVersions;

				if($HTTP_POST_VARS['GLSA_Background'])
					$Parser->GLSABackground = paragraphifyFromPlain($HTTP_POST_VARS['GLSA_Background']);

				$Parser->GLSADescription = paragraphifyFromPlain($HTTP_POST_VARS['GLSA_Description']);
				$Parser->GLSASeverity = $HTTP_POST_VARS['GLSA_Priority'];
				$Parser->GLSAImpact = paragraphifyFromPlain($HTTP_POST_VARS['GLSA_Impact']);

				$Parser->GLSAWorkaround = paragraphifyFromPlain($HTTP_POST_VARS['GLSA_Workaround']);
				$Parser->GLSAResolution = paragraphifyFromPlain($HTTP_POST_VARS['GLSA_Resolution']);
//				echo 'Debug:';
//				echo paragraphifyFromPlain($HTTP_POST_VARS['GLSA_Resolution']), '###';

				$Parser->GLSAReferences = array();
				if(count($GLSAReferences) > 0)
				{
					foreach( $GLSAReferences as $reference )
					{
						$Parser->GLSAReferences[$reference[key($reference)]] = key($reference);
					}
				}

				foreach($Parser->GLSAMetadata as $MetadataItem)
				{
					if($MetadataItem['tag'] == 'submitter')
						$haveSubmitter = true;
				}
				if(!$haveSubmitter)
					$Parser->GLSAMetadata[] = array('data' => array(), 'parent' => '', 'tag' => 'submitter', 'cdata' => authGetStatus(), 'timestamp' => genMetadataTimestamp());

				$canSubmit = true;

				if(($HTTP_POST_VARS['Submit'] == 'Preview' || $HTTP_POST_VARS['Submit'] == 'Confirm') && $validEdit && $continueEdit)
				{
					diffHighlight(diffStringToFile($Parser->GLSAToXML(), $GLSALocation = fileGrepper_getGLSAText($pool ? NULL: $GID1, $pool ? NULL: $GID2, $pool ? NULL: $GID3, $pool ? $ID : NULL, true)), $GLSALocation.'.new');

					if($HTTP_POST_VARS['SpellMode'])
					{
						$speller = new Speller();
						echo $newLine, '<pre>', $speller->HighlightSpell($Parser->GLSAToText()), '</pre>';
					}

					echo '</td></tr></table><br>';
				}
				else if($HTTP_POST_VARS['Submit'] == 'Confirm')
				{
					echo '<pre>'.$newLine, htmlspecialchars($Parser->GLSAToXML()), '</pre></td></tr></table><br>';
				}
				else if($HTTP_POST_VARS['Submit'] == 'Preview')
				{
					$speller = new Speller();
					echo '<pre>'.$newLine, $speller->HighlightSpell($Parser->GLSAToText(true)), '</pre></td></tr></table><br>';
				}
				else if($HTTP_POST_VARS['Submit'] == 'Submit' && $validEdit && $continueEdit)
				{
					$diff = diffStringToFile($Parser->GLSAToXML(false), $GLSALocation = fileGrepper_getGLSAText($pool ? NULL: $GID1, $pool ? NULL: $GID2, $pool ? NULL: $GID3, $pool ? $ID : NULL, true));
					if(fileGrepper_getGLSAText($pool ? NULL: $GID1, $pool ? NULL: $GID2, $pool ? NULL: $GID3, $pool ? $ID : NULL, false, $Parser->GLSAToXML()))
						generateInfo('Updated GLSA successfully committed (ID <a href="frame-view.php?id='.$ID.'">'.$ID.'</a>!');
					else
						generateWarning('Could not commit updated GLSA!');
					if(!$HTTP_POST_VARS['MailDisable']) {
						mailGLSA('%'.$GLSAMAddress, 'GLSA Update: ['.authGetStatus(true).'] '.$Parser->GLSAShortSummary, $newLine.$diff, array(), 'In-Reply-To: <glsa-'.$ID.'@glsamaker.gentoo.org>');
					}
				}
				else if($HTTP_POST_VARS['Submit'] == 'Submit')
				{
					if(($hash = fileGrepper_commitToPool($Parser->GLSAToXML(false), true)) != false)
						echo generateInfo('GLSA successfully committed to the pool; ID #'.$hash);
					else 
						echo generateWarning('Could not commit GLSA to pool!');

					if($hash == false)
						$hash = md5(uniqid(''));

					$Parser->GLSAID = $hash;
					if(!$HTTP_POST_VARS['MailDisable']) {
						if(mailGLSA('%'.$GLSAMAddress, 'GLSA Draft: ['.authGetStatus(true).'] '.$hash, $Parser->GLSAToText(true), array($hash.'.xml' => $newLine.$Parser->GLSAToXML(false))))
							echo generateInfo('GLSA successfully queued with ID #<a href="frame-view.php?id='.$hash.'">'.$hash.'</a>...');
						else
							echo generateWarning('Could not mail GLSA!');
					}
				}
			}
			else
				echo generateWarning('Not all fields are completed - please make sure you have completed all the necessary fields!');
		}

	?>
	<form action="frame-new.php" method="post">
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160"><b><i>Title:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><input type="text" value="<? echo htmlspecialchars($HTTP_POST_VARS['GLSA_Title']); ?>" name="GLSA_Title" class="grayinput_fullWidth" size="64"><td width="30" align="right"><? echo generateHelpIcon('Please enter a quick 4 to 5 word description.'); ?></td></tr></table></td></tr></table><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160"><b>Access:</b></td><td><table width="100%" cellspacing="0"><tr><td><input type="text" value="<? echo htmlspecialchars($HTTP_POST_VARS['GLSA_Access']); ?>" name="GLSA_Access" class="grayinput_fullWidth" size="64"></td><td width="30" align="right"><? echo generateHelpIcon('Please enter a range of the vulnerability, e.g. local or remote.'); ?></td></tr></table></td><td align="right" width="100"><b><i>Severity:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><select name="GLSA_Priority" style="width:100%;"><option value="low" <? if($HTTP_POST_VARS['GLSA_Priority'] == 'low') echo 'selected="selected"'; ?>>Low</option><option value="normal" <? if($HTTP_POST_VARS['GLSA_Priority'] == 'normal') echo 'selected="selected"'; ?>>Normal</option><option value="high" <? if($HTTP_POST_VARS['GLSA_Priority'] == 'high') echo 'selected="selected"'; ?>>High</option></select></td><td width="30" align="right"><? echo generateHelpIcon('Please select the priority.'); ?></td></tr></table></td></tr></table><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b><i>Synopsis:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><textarea name="GLSA_Synopsis" class="grayinput_fullWidth" cols="64" rows="2"><? echo $HTTP_POST_VARS['GLSA_Synopsis']; ?></textarea></td><td width="30" align="right"><? echo generateHelpIcon('Please enter a synopsis of the vulnerability which should be concise and short.'); ?></td></tr></table></td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160"><b>Bug IDs:</b></td><td><table width="100%" cellspacing="0"><tr><td><input type="text" value="<? echo htmlspecialchars(rtrim($HTTP_POST_VARS['GLSA_Bugs'], ' ')); ?>" name="GLSA_Bugs" class="grayinput_fullWidth" size="64"><td width="30" align="right"><? echo generateHelpIcon('Enter any relevant Gentoo Bugzilla Bug IDs separated by spaces.'); ?></td></tr></table></td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160"><b><i>GLSA Keyword:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><input type="text" value="<? echo htmlspecialchars($HTTP_POST_VARS['GLSA_Product']); ?>" name="GLSA_Product" class="grayinput_fullWidth" size="64"></td><td width="30" align="right"><? echo generateHelpIcon('Please enter one keyword to define the issue, e.g. OpenSSL.'); ?></td></tr></table></td><td align="right" width="150"><b><i>GLSA Category:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><select name="GLSA_ProductType" style="width:100%;"><option value="ebuild" <? if($HTTP_POST_VARS['GLSA_ProductType'] == 'ebuild') echo 'selected="selected"'; ?>>Ebuild</option><option value="informational" <? if($HTTP_POST_VARS['GLSA_ProductType'] == 'informational') echo 'selected="selected"'; ?>>Informational</option><option value="infrastructure" <? if($HTTP_POST_VARS['GLSA_ProductType'] == 'infrastructure') echo 'selected="selected"'; ?>>Infrastructure</option><option value="portage" <? if($HTTP_POST_VARS['GLSA_ProductType'] == 'portage') echo 'selected="selected"'; ?>>Portage</option></select></td><td width="30" align="right"><? echo generateHelpIcon('Please select the category of this GLSA.'); ?></td></tr></table></td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="5" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b><i>Unaffected packages:</i></b></td>
				<td class="body_rootTable_center"><acronym title="Enter a valid Portage package name, such as 'net-www/mozilla'.">Name</acronym></td><td colspan="2" class="body_rootTable_center"><acronym title="Pick an operator from the combo box and enter the version in the text box.">Version</acronym></td><td class="body_rootTable_center"><acronym title="Use '*' for all architectures or specify a supported architecture.">Architecture</acronym></td><td class="body_rootTable_center"><acronym title="Can this package be automatically updated by Portage?">Auto</acronym></td><td></td><td></td></tr>
						<? foreach( $GLSAVersions as $key => $value )
						{
							if(isset( $value['unaffected'] ))
							{
								foreach( $value['unaffected'] as $vkey => $vvalue )
								{
									// <mark/>
									echo '<tr><td></td><td width="20%"><input type="text" name="GLSA_UP_', $key, '_', $vkey, '_Name" class="grayinput_fullWidth" value="', htmlspecialchars($value['name']), '"></td><td width="1%">';
									echo '<select class="center" name="GLSA_UP_', $key, '_', $vkey, '_VXP">';

									$kvalue = key($vvalue);
									if($kvalue == 'ge')
										echo '<option value="ge" selected="selected" class="ge">&gt;=</option>';
									else
										echo '<option value="ge" class="ge">&gt;=</option>';

									if($kvalue == 'gt')
										echo '<option value="gt" selected="selected" class="gt">&gt;</option>';
									else
										echo '<option value="gt" class="gt">&gt;</option>';

									if($kvalue == 'rge')
										echo '<option value="rge" selected="selected" class="rge">*&gt;=</option>';
									else
										echo '<option value="rge" class="rge">*&gt;=</option>';

									if($kvalue == 'rgt')
										echo '<option value="rgt" selected="selected" class="rgt">*&gt;</option>';
									else
										echo '<option value="rgt" class="rgt">*&gt;</option>';

									if($kvalue == 'le')
										echo '<option value="le" selected="selected" class="dtop">&lt;=</option>';
									else
										echo '<option value="le" class="dtop">&lt;=</option>';

									if($kvalue == 'lt')
										echo '<option value="lt" selected="selected">&lt;</option>';
									else
										echo '<option value="lt">&lt;</option>';

									if($kvalue == 'rle')
										echo '<option value="rle" selected="selected">*&lt;=</option>';
									else
										echo '<option value="rle">*&lt;=</option>';

									if($kvalue == 'rlt')
										echo '<option value="rlt" selected="selected">*&lt;</option>';
									else
										echo '<option value="rlt">*&lt;</option>';

									if($kvalue == 'eq')
										echo '<option value="eq" selected="selected" class="eq">==</option>';
									else
										echo '<option value="eq" class="eq">==</option>';

									echo '</select></td><td><input type="text" name="GLSA_UP_', $key, '_', $vkey, '_Version" class="grayinput_fullWidth" value="', htmlspecialchars($vvalue[key($vvalue)]), '"></td><td width="20%"><input type="text" name="GLSA_UP_', $key, '_', $vkey, '_Arch" class="grayinput_fullWidth" value="', htmlspecialchars($value['arch']), '"></td><td width="1%"><select class="center" name="GLSA_UP_', $key, '_', $vkey, '_Auto">';
									if($value['auto'] == 'yes')
										echo '<option value="yes" selected="selected">Yes</option>';
									else
										echo '<option value="yes">Yes</option>';

									if($value['auto'] == 'no')
										echo '<option value="no" selected="selected">No</option>';
									else
										echo '<option value="no">No</option>';

									echo '</select></td><td width="1%">', generateButton('<b>Change</b>'), '</td><td width="20" align="right">', generateHelpIcon('Modify any field and press \'Change\'. To delete, make any field empty.'), '</td></tr>';
								}
							}
						}
						?>
				<tr><td></td><td><input type="text" name="GLSA_UP_Name" class="grayinput_fullWidth" size="32"></td><td><select class="center" name="GLSA_UP_VXP"><option value="ge" selected="selected" class="ge">&gt;=</option><option value="gt" class="gt">&gt;</option><option value="rge" class="rge">*&gt;=</option><option value="rgt" class="rgt">*&gt;</option><option value="le" class="dtop">&lt;=</option><option value="lt">&lt;</option><option value="rle">*&lt;=</option><option value="rlt">*&lt;</option><option value="eq" class="eq">==</option></select></td><td><input type="text" name="GLSA_UP_Version" class="grayinput_fullWidth" size="32"></td><td><input type="text" name="GLSA_UP_Arch" class="grayinput_fullWidth" size="32"></td><td><select class="center" name="GLSA_UP_Auto"><option value="yes">Yes</option><option value="no">No</option></select></td><td><? echo generateButton('<b>Change</b>'); ?></td><td width="25" align="right"><? echo generateHelpIcon('Complete all three fields and press \'Change\'.'); ?></td>
			</tr></table><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="5" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b><i>Vulnerable packages:</i></b></td>
				<td class="body_rootTable_center"><acronym title="Enter a valid Portage package name, such as 'net-www/mozilla'.">Name</acronym></td><td colspan="2" class="body_rootTable_center"><acronym title="Pick an operator from the combo box and enter the version in the text box.">Version</acronym></td><td class="body_rootTable_center"><acronym title="Use '*' for all architectures or specify a supported architecture.">Architecture</acronym></td><td class="body_rootTable_center"><acronym title="Can this package be automatically updated by Portage?">Auto</acronym></td><td></td><td></td></tr>
						<? foreach( $GLSAVersions as $key => $value )
						{
							if(isset( $value['vulnerable'] ))
							{
								foreach( $value['vulnerable'] as $vkey => $vvalue )
								{
									echo '<tr><td></td><td width="20%"><input type="text" name="GLSA_VP_', $key, '_', $vkey, '_Name" class="grayinput_fullWidth" value="', htmlspecialchars($value['name']), '"></td><td width="1%"><select class="center" name="GLSA_VP_', $key, '_', $vkey, '_VXP">';

									$kvalue = key($vvalue);

									if($kvalue == 'le')
										echo '<option value="le" selected="selected" class="le">&lt;=</option>';
									else
										echo '<option value="le" class="le">&lt;=</option>';

									if($kvalue == 'lt')
										echo '<option value="lt" selected="selected" class="lt">&lt;</option>';
									else
										echo '<option value="lt" class="lt">&lt;</option>';

									if($kvalue == 'rle')
										echo '<option value="rle" selected="selected" class="rle">*&lt;=</option>';
									else
										echo '<option value="rle" class="rle">*&lt;=</option>';

									if($kvalue == 'rlt')
										echo '<option value="rlt" selected="selected" class="rlt">*&lt;</option>';
									else
										echo '<option value="rlt" class="rlt">*&lt;</option>';

									if($kvalue == 'ge')
										echo '<option value="ge" selected="selected" class="dtop">&gt;=</option>';
									else
										echo '<option value="ge" class="dtop">&gt;=</option>';

									if($kvalue == 'gt')
										echo '<option value="gt" selected="selected">&gt;</option>';
									else
										echo '<option value="gt">&gt;</option>';

									if($kvalue == 'rge')
										echo '<option value="rge" selected="selected">*&gt;=</option>';
									else
										echo '<option value="rge">*&gt;=</option>';

									if($kvalue == 'rgt')
										echo '<option value="rgt" selected="selected">*&gt;</option>';
									else
										echo '<option value="rgt">*&gt;</option>';

									if($kvalue == 'eq')
										echo '<option value="eq" selected="selected" class="eq">==</option>';
									else
										echo '<option value="eq" class="eq">==</option>';

									echo '</select></td><td><input type="text" name="GLSA_VP_', $key, '_', $vkey, '_Version" class="grayinput_fullWidth" value="', htmlspecialchars($vvalue[key($vvalue)]), '"></td><td width="20%"><input type="text" name="GLSA_VP_', $key, '_', $vkey, '_Arch" class="grayinput_fullWidth" size="32" value="', htmlspecialchars($value['arch']), '"></td><td width="1%"><select class="center" name="GLSA_VP_', $key, '_', $vkey, '_Auto">';

									if($value['auto'] == 'yes')
										echo '<option value="yes" selected="selected">Yes</option>';
									else
										echo '<option value="yes">Yes</option>';
									
									if($value['auto'] == 'no')
										echo '<option value="no" selected="selected">No</option>';
									else
										echo '<option value="no">No</option>';

									echo '</select></td><td width="1%">', generateButton('<b>Change</b>'), '</td><td width="20" align="right">', generateHelpIcon('Modify any field and press \'Change\'. To delete, make any field empty.'), '</td></tr>';
								}
							}
						}
						?>
				<tr><td></td><td><input type="text" name="GLSA_VP_Name" class="grayinput_fullWidth" size="32"></td><td><select class="center" name="GLSA_VP_VXP"><option value="le" class="le">&lt;=</option><option value="lt" selected="selected" class="lt">&lt;</option><option value="rle" class="rle">*&lt;=</option><option value="rlt" class="rlt">*&lt;</option><option value="ge" class="dtop">&gt;=</option><option value="gt">&gt;</option><option value="rge">*&gt;=</option><option value="rgt">*&gt;</option><option value="eq" class="eq">==</option></select></td><td><input type="text" name="GLSA_VP_Version" class="grayinput_fullWidth" size="32"></td><td><input type="text" name="GLSA_VP_Arch" class="grayinput_fullWidth" size="32"></td><td><select class="center" name="GLSA_VP_Auto"><option value="yes">Yes</option><option value="no">No</option></select></td><td><? echo generateButton('<b>Change</b>'); ?></td><td width="25" align="right"><? echo generateHelpIcon('Complete all three fields and press \'Change\'.'); ?>
			</td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b>Background:</b></td><td><table width="100%" cellspacing="0"><tr><td><textarea name="GLSA_Background" class="grayinput_fullWidth" cols="64" rows="2"><? echo $HTTP_POST_VARS['GLSA_Background']; ?></textarea></td><td width="30" align="right"><? echo generateHelpIcon('Please enter a passage outlining the package.'); ?></td></tr></table></td></tr></table><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b><i>Description:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><textarea name="GLSA_Description" class="grayinput_fullWidth" cols="64" rows="4"><? echo $HTTP_POST_VARS['GLSA_Description']; ?></textarea></td><td width="30" align="right"><? echo generateHelpIcon('Please enter a description of the vulnerability.'); ?></td></tr></table></tr></table><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b><i>Impact:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><textarea name="GLSA_Impact" class="grayinput_fullWidth" cols="64" rows="4"><? echo $HTTP_POST_VARS['GLSA_Impact']; ?></textarea></td><td width="30" align="right"><? echo generateHelpIcon('Please enter the impact of the vulnerability.') ?></td></tr></table></td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b><i>Workaround:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><textarea name="GLSA_Workaround" class="grayinput_fullWidth" cols="64" rows="2"><? echo $HTTP_POST_VARS['GLSA_Workaround']; ?></textarea></td><td width="30" align="right"><? echo generateHelpIcon('Please enter a workaround for the vulnerability, if one exists.'); ?></td></tr></table></td></tr></table><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b><i>Resolution:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><textarea name="GLSA_Resolution" class="grayinput_fullWidth" cols="64" rows="4"><? echo $HTTP_POST_VARS['GLSA_Resolution']; ?></textarea></td><td width="30" align="right"><? echo generateHelpIcon('Please enter a resolution of the vulnerability, enclose commands with <code> tags.'); ?></td></tr></table></td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="5" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b>References:</b></td>
				<td class="body_rootTable_center" width="25%"><acronym title="Enter a title for the link, such as 'Reference to CERT Advisory'.">Title</acronym></td><td class="body_rootTable_center"><acronym title="Enter the URL to the reference.">URL</acronym></td></tr>
				<?
					foreach($GLSAReferences as $key => $reference)
					{
						echo '<tr><td></td><td width="25%"><input type="text" name="GLSA_RF_', $key, '_Title" class="grayinput_fullWidth" size="96" value="', htmlspecialchars(key($reference)), '"></td><td><input type="text" name="GLSA_RF_', $key, '_URL" class="grayinput_fullWidth" size="64" value="', htmlspecialchars($reference[key($reference)]), '"></td><td>', generateButton('<b>Change</b>'), '</td><td width="20" align="right">';
						generateHelpIcon('Please complete both fields and press the \'Change\' button.');
						echo '</td></tr>';
					}
				?>
				<tr><td></td><td width="25%"><input type="text" name="GLSA_RF_Title" class="grayinput_fullWidth" size="64"></td><td><input type="text" name="GLSA_RF_URL" class="grayinput_fullWidth" size="64"></td><td><? echo generateButton('<b>Change</b>'); ?></td><td width="25" align="right"><? generateHelpIcon('Please complete both fields and press the \'Change\' button.'); ?></td></tr>
			</table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr>
				<td><? echo generateButton('<b>Confirm</b>', 'name="Submit" value="Confirm"');
					if(!$validEdit){ echo '&nbsp;', generateButton('<b>Preview</b>', 'name="Submit" value="Preview"'); }
					echo '&nbsp;', generateButton('<b>Boilerplate</b>', 'name="Submit" value="Boilerplate"'); ?>
					<input type="checkbox" name="SpellMode"<? if($HTTP_POST_VARS['SpellMode']) echo ' checked'; ?>>Spell-checkify</input>
					<input type="checkbox" name="MailDisable"<? if($HTTP_POST_VARS['MailDisable']) echo ' checked'; ?>>Don't email</input>
					<input type="checkbox" name="SortReferences"<? if($HTTP_POST_VARS['SortReferences']) echo ' checked'; ?>>Sort References</input>
				</td><td align="right">
					<? if($canSubmit) echo generateButton('<b>Submit</b>', 'name="Submit" value="Submit"');
					else echo '<i>Please confirm your GLSA before submitting it!</i>'; ?>
				</td></tr></table>
		</td></tr>
	</table>
	<?
		if($validEdit)
			echo '<input type="hidden" name="GLSA_ID" value="', $ID, '">';
	?>
	</form>
	<? generateKonqBreak();
	   bodyHeader_invoke();
	   initEnd();

   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
