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

require_once './includes/common.auth';
require_once './includes/io.mailer';
require_once './includes/ui.body';
require_once './includes/ui.init';
require_once './includes/ui.newitems';
require_once './includes/xml.glsaparser';

initBegin('File a GLSA Request');
bodyFooter_invoke();

?>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td><font size="+1"><b><i>File a GLSA Request</i></b></font></td><td align="right"><img src="images/icons/new.lg.<? generateImageExt(); ?>" align="middle">&nbsp;</td></tr><tr><td colspan="2"><hr></td></tr>
		<tr><td colspan="2"><table width="100%" border="0" cellspacing="0" cellpadding="4"><tr><td colspan="2">This page files a skeleton GLSA, placing it into the GLSA pool. It can then be edited as any other pooled GLSA. Although a Synopsis and Bug ID is not required for a request, it helps if you would add one in for identification purposes.<br></td></tr></table></td></tr>
	</table>
	<br>
	<?	/*! If we're submitting, check things, and continue if OK */
		if($HTTP_POST_VARS['Submit'] == 'Submit')
		{
			if($HTTP_POST_VARS['GLSA_Title'])
			{
				$Parser = new GLSAParser();

				$Parser->GLSAID = '!-- Insert ID here! --!';
				$Parser->GLSAShortSummary = 'Request: '.$HTTP_POST_VARS['GLSA_Title'];
				$Parser->GLSASynopsis = $HTTP_POST_VARS['GLSA_Synopsis'];

				$Parser->GLSAProductType = 'ebuild';
				$Parser->GLSASeverity = 'normal';

				if($Parser->GLSARevision == '')
					$Parser->GLSARevision = date('F d, Y').': 01';
				if($Parser->GLSADate == '')
					$Parser->GLSADate = date('F d, Y');

				$Parser->GLSABugs = array();
				$temp = explode(' ', $HTTP_POST_VARS['GLSA_Bugs']);
				$HTTP_POST_VARS['GLSA_Bugs'] = '';
				foreach( $temp as $bug ){ if(is_numeric($bug)) { $Parser->GLSABugs[] = $bug; $HTTP_POST_VARS['GLSA_Bugs'] .= $bug.' '; } }

				$Parser->GLSAPackages[] = array('unaffected' => array(array('ge' => '1.2.3')), 'vulnerable' => array(array('lt' => '1.2.3')), 'name' => 'fill/me', 'arch' => '*', auto => 'yes');
				$Parser->GLSAReferences = array();
				$Parser->GLSAMetadata[] = array('data' => array(), 'parent' => '', 'tag' => 'requester', 'cdata' => authGetStatus(), 'timestamp' => genMetadataTimestamp());

				if(($hash = fileGrepper_commitToPool($Parser->GLSAToXML(false), true)) != false)
					echo generateInfo('Request successfully committed to the pool; ID #'.$hash);
				else 
					echo generateWarning('Could not commit GLSA to pool!');

				if($hash == false)
					$hash = md5(uniqid(''));

				$mString = 'Title: '.$HTTP_POST_VARS['GLSA_Title']."\n";
				if($Parser->GLSASynopsis)
					$mString .= 'Synopsis: '.$Parser->GLSASynopsis."\n";
				if(count($Parser->GLSABugs) > 0)
					$mString .= 'Bug IDs: '. rtrim($HTTP_POST_VARS['GLSA_Bugs'], ' ')."\n";

				$Parser->GLSAID = $hash;
				if(mailGLSA('%'.$GLSAMAddress, 'GLSA Request: ['.authGetStatus(true).'] '.$hash, $mString))
					echo generateInfo('Request successfully queued with ID #'.$hash.'...');
				else
					echo generateWarning('Could not mail GLSA!');
			}
			else
			{
				echo generateWarning('The title is not complete - a title is needed for a GLSA Request!');
			}
		}

	?>
	<form action="frame-request.php" method="post">
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160"><b><i>Title:</i></b></td><td><table width="100%" cellspacing="0"><tr><td><input type="text" value="<? echo htmlspecialchars($HTTP_POST_VARS['GLSA_Title']); ?>" name="GLSA_Title" class="grayinput_fullWidth" size="64"><td width="30" align="right"><? echo generateHelpIcon('Please enter a quick 4 to 5 word description.'); ?></td></tr></table></td></tr></table><br>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160" valign="top"><b>Synopsis:</b></td><td><table width="100%" cellspacing="0"><tr><td><textarea name="GLSA_Synopsis" class="grayinput_fullWidth" cols="64" rows="2"><? echo $HTTP_POST_VARS['GLSA_Synopsis']; ?></textarea></td><td width="30" align="right"><? echo generateHelpIcon('Please enter a synopsis of the vulnerability which should be concise and short.'); ?></td></tr></table></td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right" width="160"><b>Bug IDs:</b></td><td><table width="100%" cellspacing="0"><tr><td><input type="text" value="<? echo htmlspecialchars(rtrim($HTTP_POST_VARS['GLSA_Bugs'], ' ')); ?>" name="GLSA_Bugs" class="grayinput_fullWidth" size="64"><td width="30" align="right"><? echo generateHelpIcon('Enter any relevant Gentoo Bugzilla Bug IDs separated by spaces.'); ?></td></tr></table></td></tr></table>
		</td></tr>
	</table><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable">
		<tr><td>
			<table width="100%" border="0" cellspacing="0" cellpadding="4" class="body_rootTable_light"><tr><td align="right"><button class="grayinput" name="Submit" value="Submit"><b>Submit</b></button></td></tr></table>
		</td></tr>
	</table>
	</form>
	<? generateKonqBreak();
	   bodyHeader_invoke();
	   initEnd();

   // Local Variables: ***
   // truncate-lines:true ***
   // End: ***
?>
